---
title: "Packaging GitHub Copilot Desktop and CLI for NixOS (And its challenges)"
date: 2026-09-18T09:22:00+00:00
draft: false
tags: ["Github Copilot", "Agent", "LLM", "Tool Use", "Agentic", "Nix", "NixOS", "Flakes"]
categories: ["AI & LLM", "Packaging"]
summary: "How to handle single-executable Node binaries, Tauri AppImages, and automated daily version locking in Nix."
showSummary: true
---

If you use NixOS as your daily driver, you know the routine whenever a new developer tool is released:
1. Download the official Linux binary.
2. Run `./app`.
3. Get hit with: `bash: ./app: No such file or directory` (because the traditional `/lib64/ld-linux-x86-64.so.2` dynamic interpreter doesn't exist at the root).

Recently, GitHub released the official Linux builds for the **GitHub Copilot Desktop App** (an AppImage built on Tauri) and the new standalone **GitHub Copilot CLI**.

To make these first-class citizens on NixOS, I built **[GithubCopilot-Nix](https://github.com/fumoctl/GithubCopilot-Nix)**, a Nix flake supporting both `x86_64-linux` and `aarch64-linux`. Along the way, packaging them revealed some great lessons in Nix packaging strategies, Node SEA quirks, and automated maintenance.

Here is a breakdown of how it works under the hood.

---

### Challenge 1: The Copilot CLI and the Node SEA Dilemma

The GitHub Copilot CLI is distributed as a single 160MB binary. Inspecting it reveals it is compiled as a **Node.js Single Executable Application (Node SEA)**.

#### Why standard Nix tools break it:
In standard Nix derivations, when packaging proprietary or pre-compiled binaries, you typically add `autoPatchelfHook` to patch the interpreter and inject RPATHs.

However, Node SEA binaries bundle JavaScript assets and V8 snapshots at specific byte offsets within the binary. Running `patchelf` rewrites ELF sections and shifts table offsets. Worse, stdenv’s default `strip` step discards trailing payloads. This corrupts the executable or leaves it behaving like an empty Node runtime.

#### The Solution: The Dynamic Linker Wrapper
Instead of modifying the binary, we keep the raw binary untouched and launch it explicitly using the system's dynamic linker:

```nix
stdenv.mkDerivation {
  pname = "github-copilot-cli";
  inherit version src;

  dontStrip = true;
  dontPatchELF = true;

  installPhase = ''
    mkdir -p $out/libexec $out/bin
    cp copilot $out/libexec/copilot
    chmod +x $out/libexec/copilot

    cat <<EOF > $out/bin/copilot
#!/bin/sh
exec ${stdenv.cc.bintools.dynamicLinker} \
  --library-path "${lib.makeLibraryPath [ stdenv.cc.libc stdenv.cc.cc.lib ]}" \
  $out/libexec/copilot "\$@"
EOF
    chmod +x $out/bin/copilot
  '';
}
```

This bypasses binary patching entirely while ensuring glibc and `libstdc++.so.6` resolve cleanly on any NixOS system.

#### Generating Shell Completions in the Sandbox
The Copilot CLI has built-in completion generation (`copilot completion bash|zsh|fish`). However, running the binary inside the Nix sandbox threw:
```
Failed to extract bundled package: Error: EACCES: permission denied, mkdir '/homeless-shelter'
```
Because Node SEA extracts runtime cache items to `$HOME`, and Nix sandboxes set `$HOME=/homeless-shelter` (which is read-only). By briefly setting `export HOME=$(mktemp -d)` inside `installPhase`, we were able to run the wrapper during build and generate fully standalone completions for Bash, Zsh, and Fish into `$out/share/`.

---

### Challenge 2: The Desktop App (Tauri AppImage)

The Desktop app is an AppImage with a Tauri frontend. To package this cleanly:

1. **FHS Environment**: We use Nixpkgs' `appimageTools.wrapType2`, which constructs a Bubblewrap FHS container with the necessary graphics, X11, Wayland, and WebKit libraries.
2. **Metadata & Icons**: We use `appimageTools.extract` to unpack the SquashFS filesystem at build time. We pull the 256x256 icons into `$out/share/icons/hicolor/` and register a `.desktop` file handling the `x-scheme-handler/github-app` URL protocol.

*(Pro-tip: when copying extracted AppImage directories in Nix, remember to run `chmod -R u+w` on the target icon directories, since extracted SquashFS permissions remain strictly read-only).*

---

### Zero-Maintenance Upstream Updates

A package flake is only useful if it doesn't get abandoned after the next release.

Rather than running impure curl operations inside derivation builds (which breaks reproducibility and sandbox rules), we decoupled version tracking into a lockfile: `artifacts/versions.json`:

```json
{
  "GitHub Copilot Desktop": {
    "x86_64-linux": {
      "url": "https://github.com/github/app/releases/download/v1.1.21/GitHub-Copilot-linux-x64.AppImage",
      "hash": "1yjqs029k4a4zrdm0d5qga14lq9zdjayj22zmzs887m7igpily22"
    }
  }
}
```

A daily GitHub Actions workflow:
1. Queries the GitHub API for new tags in `github/app` and `github/copilot-cli`.
2. Runs `nix-prefetch-url` to grab the new SHA-256 hashes for both `x86_64` and `aarch64`.
3. Runs `nix flake check` and `nix build` to ensure the new binaries actually compile.
4. Opens an auto-merging Pull Request.
5. On merge, generates a tagged release on `main`.

---

### Trying It Out

You can run either application immediately without modifying your system configuration:

```bash
# Run the Copilot CLI
nix run github:fumoctl/GithubCopilot-Nix#copilot-cli

# Run the Copilot Desktop GUI
nix run github:fumoctl/GithubCopilot-Nix
```

To add them permanently to your NixOS configuration:

```nix
# flake.nix
inputs.github-copilot-nix.url = "github:fumoctl/GithubCopilot-Nix";

# In your NixOS or Home Manager module:
environment.systemPackages = [
  inputs.github-copilot-nix.packages.${pkgs.system}.github-copilot-desktop
  inputs.github-copilot-nix.packages.${pkgs.system}.github-copilot-cli
];
```

Check out the full repository here: **[github.com/fumoctl/GithubCopilot-Nix](https://github.com/fumoctl/GithubCopilot-Nix)**.

Happy hacking!