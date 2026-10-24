---
title: "Packaging DeepSeek Harness (and Declarative Plugins) for NixOS"
date: 2026-10-24T17:30:00-03:00
draft: false
tags: ["DeepSeek", "DeepSeek Harness", "dsh", "Agent", "LLM", "MCP", "Nix", "NixOS", "Flakes", "Home Manager"]
categories: ["AI & LLM", "Packaging"]
summary: "From V8 memory-scanning native addons and pnpm peer-dependency traps to 3-way YAML merges on an impermanent root: the journey of building dsh-nix."
showSummary: true
---

When DeepSeek open-sourced **[DeepSeek Harness (`dsh`)](https://github.com/deepseek-ai/deepseek-harness)**—a modular, Cordis-powered agent runtime with a web UI, headless CLI, MCP bridge, and extensible profile system—I immediately wanted it running natively on my NixOS machines.

Not just *"installed imperatively in a mutable folder with `npm install -g`"*, either. On an impermanent NixOS setup where `/` is wiped on every boot, I wanted:

1. **A reproducible `pkgs.dsh` package** built from the upstream pnpm monorepo inside the Nix sandbox.
2. **Declarative profile and plugin management** in Home Manager (`programs.dsh`)—where adding a TUI, a theme, or an MCP server happens in Nix, resolution failures fail at `nix build` time rather than runtime, and removing a plugin from my flake cleanly removes it from the profile.
3. **Zero state loss across rebuilds and reboots**, even when `dsh` writes custom providers and model configurations directly into profile files at runtime.

That effort became **[dsh-nix](https://github.com/fumoctl/dsh-nix)**. Getting from a raw pnpm monorepo to a working Home Manager module with build-time boot checks took solving a series of genuinely fun rabbit holes. Here is the full story of everything that broke along the way—and how we fixed it.

---

### Hurdle 1: V8 Memory Scanning vs. Nixpkgs Node.js (`node-addon-require-builtin`)

Getting the monorepo dependencies fetched with `fetchPnpmDeps` and `pnpmConfigHook` was only the warm-up. First, `node-pty` ships no prebuilt Linux binaries in its npm tarball, so we had to run `node-gyp rebuild` explicitly inside `buildPhase` with `python3` and the `nodejs` headers so both `pty.node` and `spawn-helper` landed in `build/Release`.

Then came the first real boss fight. When booting `dsh` with Nixpkgs' Node.js binary, it immediately crashed during host preparation:

```text
Error: dsh: host preparation failed: node-addon-require-builtin unsupported:
Unsupported/no-getter (x64 sysv getter is not a recognized this->field accessor)
```

#### What was happening?
To intercept internal Node module loading for its plugin package router and hot-module reload (HMR) engine, `dsh` uses a native C++ addon (`node-addon-native-custom-loader` / `node-addon-require-builtin`). At startup, that addon literally disassembles V8's compiled machine code in memory looking for a specific `x64 sysv` `this->field` accessor instruction sequence so it can grab `internal/modules/esm/loader`.

Because Nixpkgs compiles `nodejs` with different compiler flags and optimization passes than upstream Node's official binary tarballs, the machine code layout of that getter didn't match the addon's byte-pattern scanner.

#### The Fix
If you launch Node with `--expose-internals`, Node exposes `internal/*` builtins directly to standard `require()` without needing any V8 memory introspection at all. By wrapping `bin/dsh` with `makeBinaryWrapper` to pass `--expose-internals` and patching `requireBuiltin` to try `require(moduleId)` first before falling back to the native addon, `dsh` booted cleanly on Nixpkgs Node:

```nix
# In buildPhase:
sed -i 's|function requireBuiltin(moduleId) {|function requireBuiltin(moduleId) { try { return require(moduleId); } catch {}|' \
  node_modules/.pnpm/node-addon-require-builtin@*/node_modules/node-addon-require-builtin/lib/index.js

# In installPhase:
makeBinaryWrapper "${nodejs}/bin/node" "$out/bin/dsh" \
  --add-flags "--expose-internals" \
  --add-flags "$out/apps/cli/lib/bin.js"
```

---

### Hurdle 2: Replacing Imperative `dsh plugin add` with Build-Time Profiles

Out of the box, `dsh` manages profiles under `~/.dsh/profiles/<name>`. When you run `dsh plugin --profile web add <spec>`, `dsh` invokes `pnpm` at runtime, mutates `package.json`, and reconciles `dsh.profile.bundles`.

For `dsh-nix`, we replaced that runtime mutation with a pure build-time profile packager (`lib/plugins.nix` and `lib/profiles.nix`) that accepts three kinds of plugins in one ordered list:

- **In-box bundles** (`"@deepseek-ai/dsh-base"`, `"@deepseek-ai/dsh-web-app"`, `"@deepseek-ai/dsh-headless"`): shipped inside `pkgs.dsh`, requiring zero network fetches.
- **pnpm spec strings** (`"@deepseek-harness-tui/dsh-tui@0.16.1"`, `"@nonamelego/dsh-catppuccin@0.6.2"`, `"github:owner/repo#tag"`): resolved at build time in a fixed-output derivation (`fetchSpecs`) pinned by a single `specsHash`.
- **Nix paths or derivations** (`./my-plugin`, `pkgs.fetchFromGitHub { ... }`): symlinked directly from the Nix store.

To make sure a composed profile actually works before Home Manager ever activates it, we added `scripts/check-profile.mjs` and wired it into `nix flake check`. Inside the Nix build sandbox, it boots the profile through `dsh`'s own `boot()` and `assertEntriesActivated` audit—meaning a missing service or broken plugin layer fails `nix build` immediately.

---

### Hurdle 3: The `@deepseek-ai/*` Peer Dependency Trap

The moment we tried installing third-party community plugins—specifically **[`dsh-TUI`](https://github.com/ccch1mneyyy/dsh-TUI)** (`@deepseek-harness-tui/dsh-tui@0.16.1`) to give `dsh` a full terminal UI—pnpm's peer dependency resolution blew up inside `fetchSpecs`.

#### Why it broke:
1. Third-party DSH plugins declare `"@deepseek-ai/cordis": "^4.0.1-rc.1"` and various `"@deepseek-ai/dsh-*"` packages in `peerDependencies`.
2. In pnpm, `autoInstallPeers` defaults to `true`. When `pnpm add` tried to auto-install `@deepseek-ai/dsh-scope` or `@deepseek-ai/dsh-typert-protocol` from npm, it failed with `ERR_PNPM_NO_MATCHING_VERSION` because npm's `latest` dist-tag pointed to `0.0.1-rc.1` while the plugin asked for `>=0.1.7-alpha.1` (published under a prerelease tag).
3. Even worse: `@deepseek-ai/*` packages **must never** be installed into a profile's own `node_modules`! They have to resolve from the host `pkgs.dsh` installation at runtime so that `@deepseek-ai/cordis` keeps its singleton service identity.
4. Simply setting `autoInstallPeers = false` globally would break plugins that legitimately rely on pnpm auto-installing third-party peers (like `react`).

#### The Fix
In `fetchSpecs` (`lib/plugins.nix`), we combined `pnpm-workspace.yaml` rules with a `.pnpmfile.cjs` `readPackage` hook that marks only `@deepseek-ai/*` peers as `optional: true`:

```yaml
# pnpm-workspace.yaml
packages:
  - .
nodeLinker: hoisted
peerDependencyRules:
  ignoreMissing:
    - "@deepseek-ai/*"
```

```js
// .pnpmfile.cjs
module.exports = {
  hooks: {
    readPackage(pkg) {
      if (pkg.peerDependencies) {
        pkg.peerDependenciesMeta = pkg.peerDependenciesMeta || {};
        for (const k of Object.keys(pkg.peerDependencies)) {
          if (k.startsWith('@deepseek-ai/')) {
            pkg.peerDependenciesMeta[k] = { optional: true };
          }
        }
      }
      return pkg;
    }
  }
};
```

That kept `autoInstallPeers` active for normal third-party dependencies while completely skipping `@deepseek-ai/*` packages so the host `dsh` installation supplies them at runtime.

---

### Hurdle 4: Symlinks vs. Real Directories in DSH's Module Resolver

With `dsh-tui` fetched and built, we hit the most subtle bug of the entire journey when booting the `tui` profile:

```text
Cannot find package 'dsh-working-activity' imported from .../@deepseek-harness-tui/dsh-tui/lib/index.js
```

And right after fixing that:

```text
Cannot find package '@deepseek-ai/dsh-session-persistence-jsonl' imported from .../@deepseek-harness-tui/dsh-tui/lib/index.js
```

Digging into `dsh`'s runtime module resolver (`packages/boot/app-boot/src/profile-resolution/resolver.ts`) revealed three subtle invariants:

1. **Hoisted `node_modules`**: Because `fetchSpecs` deletes `node_modules/.pnpm` after running `pnpm add` to keep the fixed-output derivation compact, pnpm's default isolated linker left transitive dependencies (like `dsh-working-activity`) dangling. Setting `nodeLinker: hoisted` (matching upstream `dsh`'s own `initProfile`) placed every transitive dependency directly at the top level of `node_modules/`.
2. **Real `@scope` directories**: Both `dsh`'s `symlinksUnder` scanner and its HMR watcher only look for symlinks one level inside real `@scope` directories. Symlinking `@scope` as a whole directory hid scoped plugins from HMR; `buildProfileBundle` needed `mkdir -p "$out/node_modules/@scope"` with symlinks at `$out/node_modules/@scope/<pkg>`.
3. **`routeLinked` vs. `routeScoped` (`cp -a` vs. `cp -rL`)**: When `dsh` resolves imports from a plugin inside `~/.dsh/profiles/<name>/node_modules`, it checks `realpathSync(pkgDir)`.
   - If the plugin is a **symlink** pointing outside the profile directory (into `/nix/store`), `dsh` classifies it as a developer `git link` (`kind: "linked"`) and routes it through `routeLinked`—which **only** intercepts `@deepseek-ai/*` packages explicitly listed in the plugin's `peerDependencies`!
   - If the plugin is a **real directory** inside the profile, `dsh` classifies it as `kind: "profile"` and routes it through `routeScoped`, which intercepts **all** host `@deepseek-ai/*` packages.

Because `dsh-TUI` imports `@deepseek-ai/dsh-session-persistence-jsonl` without listing it in `peerDependencies`, symlinking profile `node_modules` into `/nix/store` triggered the strict `routeLinked` path. Switching Home Manager activation from `cp -a` to `cp -rL` materialised real directories under `~/.dsh/profiles/<name>`, switching `dsh` to `routeScoped` and making `dsh --profile tui` boot with zero warnings.

---

### Hurdle 5: Bundled Cordis Plugins (`@deepseek-ai/dsh-mcp-client`)

Next, I wanted to wire up two MCP servers across all my profiles (`headless`, `web`, and `tui`):
- **`dbcode`** (stdio): running the DBCode CLI bundled inside my VSCodium extension directory.
- **`rivalsearch`** (`streamable-http`): connecting to `https://RivalSearchMCP.fastmcp.app/mcp`.

My first instinct was to add `"@deepseek-ai/dsh-mcp-client"` to `plugins`. That immediately failed:
1. On npm, `@deepseek-ai/dsh-mcp-client`'s `latest` tag points to an ancient `0.0.1-rc.1` build that doesn't match `dsh` `0.2.1-rc.2`.
2. More importantly, `@deepseek-ai/dsh-mcp-client` is **already bundled inside `pkgs.dsh`**! Unlike profile bundles (`dsh-base`, `dsh-web-app`), it has no `dsh.bundle.patch`—it is a plain Cordis plugin meant to be instantiated once per MCP server inside `cordis.patch.yml`.

That meant we didn't need to fetch anything at all. We just needed a shared `mcpPatches` list passed to each profile's `userPatches` option in Home Manager!

---

### Hurdle 6: Why Did My Custom Models Disappear After Rebooting?

Everything worked—until I added a new plugin to `profiles.web`, ran `nixos-rebuild switch`, rebooted, and discovered all my custom providers and models were gone (even though `~/.dsh` was persisted on `/persist`!).

Inspecting `~/.dsh` solved the mystery:
- Earlier versions of `dsh` stored user settings in `~/.dsh/settings.yaml`.
- In `dsh` `0.2.1-rc.2`, the settings engine (`@deepseek-ai/dsh-settings` and `@deepseek-ai/dsh-config-editor`) migrates `settings.yaml` once to `settings.yaml.imported` and **writes all UI settings, custom providers (`llm-pi-ai`), and custom models directly into the active profile's `~/.dsh/profiles/<name>/cordis.patch.yml`!**
- Meanwhile, whenever a profile's Nix derivation changed, `dsh-nix`'s activation script saw a new `.dsh-nix-stamp`, ran `rm -rf ~/.dsh/profiles/<name>`, and copied the fresh Nix store artifact over it—wiping the runtime entries `dsh` had saved into `cordis.patch.yml`.

#### The Fix: A 3-Way YAML Merge on Activation
We still wanted Nix to own declarative `userPatches` (so adding, updating, or removing an entry in Nix updates `cordis.patch.yml` without cluttering or duplicating lines), while letting `dsh` own runtime UI entries.

We updated `activateProfile` in `modules/home-manager/dsh.nix` to store a copy of the raw Nix-generated patch at `~/.dsh/profiles/<name>/.dsh-nix-patch.yml` and run a **3-way merge** using `yq-go` whenever a profile is re-materialised:

- **`$decl` (`fi == 0`)**: The new declarative `cordis.patch.yml` from `/nix/store`.
- **`$prev` (`fi == 1`)**: The existing live `~/.dsh/profiles/<name>/cordis.patch.yml`.
- **`$oldDecl` (`fi == 2`)**: The previous Nix-declared `.dsh-nix-patch.yml`.

```yaml
((select(fi == 0) // []) | .. style="") as $decl
| ((select(fi == 1) // []) | .. style="") as $prev
| ((select(fi == 2) // []) | .. style="") as $oldDecl
| (($decl + $oldDecl) | map(select(has("id") and (has("insert") | not)) | .id)) as $nixIds
| ($prev | map(select(has("id") and (has("insert") | not)) | select(([.id] - $nixIds) | length > 0))) as $kept
| ($decl + $kept)
| (select(length == 0) | . style="flow") // .
```

Now:
1. **Nix `insert` blocks** (like `mcpPatches`) are always taken fresh from `$decl`—never duplicated.
2. **Nix-owned `{ id, ... }` overrides** are tracked in `$oldDecl` + `$decl`; updating or removing one in Nix updates or removes it cleanly.
3. **Runtime UI entries** (`llm-pi-ai`, `llm-deepseek`, `ui-settings-*`, including `!!js` tags) have `id`s outside `$nixIds`, so they survive every profile rebuild and reboot untouched.

---

### The Final Result: My Declarative `dsh` Config

Here is the complete Home Manager configuration I now run in **[ultix](https://github.com/fumoctl/ultix)**, including `headless`, `web` (with the Catppuccin theme), `tui` (`dsh-TUI`), shared MCP servers, and an XDG `.desktop` launcher that re-opens the active web session without spawning duplicate daemons:

```nix
programs.dsh =
  let
    mcpPatches = [
      {
        insert = [
          {
            id = "mcp-dbcode";
            name = "@deepseek-ai/dsh-mcp-client";
            config = {
              serverName = "dbcode";
              transport = "stdio";
              command = "${pkgs.bash}/bin/bash";
              args = [
                "-c"
                ''exec ${pkgs.nodejs}/bin/node "$(ls -d "$HOME"/.vscode-oss/extensions/dbcode.dbcode-*/out/cli/dbcode | sort -V | tail -n1)" mcp''
              ];
            };
          }
          {
            id = "mcp-rivalsearch";
            name = "@deepseek-ai/dsh-mcp-client";
            config = {
              serverName = "rivalsearch";
              transport = "streamable-http";
              url = "https://RivalSearchMCP.fastmcp.app/mcp";
            };
          }
        ];
      }
    ];
  in
  {
    enable = true;

    profiles.headless = {
      plugins = [
        "@deepseek-ai/dsh-base"
        "@deepseek-ai/dsh-headless"
      ];
      userPatches = mcpPatches;
    };

    profiles.web = {
      plugins = [
        "@deepseek-ai/dsh-base"
        "@deepseek-ai/dsh-web-app"
        "@nonamelego/dsh-catppuccin@0.6.2"
      ];
      specsHash = "sha256-Ophk7VuohWNwRSsX+9ktMVFwA9JFXuumvnKdzqcAhgE=";
      userPatches = mcpPatches;
    };

    profiles.tui = {
      plugins = [
        "@deepseek-ai/dsh-base"
        "@deepseek-harness-tui/dsh-tui@0.16.1"
      ];
      specsHash = "sha256-KqSShSzXYsDVLY05tNl2mz/MDTl2Hxzs5m53V/l19+8=";
      userPatches = mcpPatches;
    };
  };

xdg.desktopEntries.dsh-web = {
  name = "DeepSeek Harness Web";
  genericName = "AI Coding Agent";
  comment = "Launch the DeepSeek Harness Web UI";
  icon = "${config.programs.dsh.package}/apps/desktop/resources/icon.svg";
  terminal = false;
  categories = [ "Development" "Utility" ];
  exec = toString (
    pkgs.writeShellScript "dsh-web-launch" ''
      runtime_dir="''${XDG_RUNTIME_DIR:-/tmp}"
      pid_file="$runtime_dir/dsh-web.pid"
      url_file="$runtime_dir/dsh-web.url"

      if [ -s "$pid_file" ] && kill -0 "$(cat "$pid_file")" 2>/dev/null && [ -s "$url_file" ]; then
        exec ${pkgs.xdg-utils}/bin/xdg-open "$(cat "$url_file")"
      fi

      ${pkgs.procps}/bin/pkill -u "$USER" -f 'apps/cli/lib/bin\.js --profile web' 2>/dev/null || true
      rm -f "$pid_file" "$url_file"

      umask 077
      printf '%s\n' "$$" > "$pid_file"
      exec ${config.programs.dsh.package}/bin/dsh --profile web > >(
        while IFS= read -r line; do
          case "$line" in
            "dsh web: http"*)
              umask 077
              printf '%s\n' "''${line#dsh web: }" > "$url_file"
              ;;
          esac
        done
      )
    ''
  );
};
```

And for NixOS Impermanence (`environment.persistence."/persist"`), only three user directories are needed:
- `.dsh` — core DSH single-root home (`.credentials.yaml`, `sessions/`, `storages/`, `profiles/`)
- `.dsh-tui` — `dsh-TUI` preferences (`theme.json`, `themes/`, `effort.json`, `extension-grants.json`)
- `.agents` — shared user-level agent/skills root (`$DSH_AGENTS_HOME`)

Check out the flake repository here: **[github.com/fumoctl/dsh-nix](https://github.com/fumoctl/dsh-nix)**.

Happy hacking!
