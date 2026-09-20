---
title: "Building a Declarative, Sovereign Tech Blog with Hugo and NixOS"
date: 2026-09-20T12:00:00+00:00
draft: false
tags: ["NixOS", "Hugo", "Blowfish", "Flakes", "Web Development", "CSS"]
categories: ["Guides", "Homelab"]
summary: "How I architected and built Fumoctl using Hugo Extended, Blowfish, Nix Flakes, and custom glassmorphism for a blazing-fast, reader-first technical blog."
showSummary: true
---

Every technologist eventually reaches a crossroads with their digital presence. You start out hosting notes across various third-party platforms, proprietary publishing services, or heavy CMS setups like WordPress or Ghost. But over time, the friction accumulates: database backups, security patches for abandoned plugins, slow page loads, and fragile build pipelines that crumble the moment your local node or python runtime updates.

When I set out to build **Fumoctl**, my personal technical corner on the web, I wanted something completely aligned with my engineering philosophy:
1. **Digital Sovereignty**: Every single article, image, and template must live as plain text and standard assets in a Git repository. No hidden databases, no vendor lock-in.
2. **Reproducibility & Zero Drift**: If I clone this repository on a fresh NixOS workstation, a headless homelab server, or CI/CD five years from now, it must build bit-for-bit identically with a single command.
3. **Sub-100ms Build & Load Performance**: Instant static asset generation with zero client-side JavaScript framework bloat.
4. **Reader-First Technical UX**: High-density reading layouts with ample room for long code blocks, sticky table of contents navigation, and seamless search.

Here is an architectural walkthrough of how Fumoctl was designed, customized, and deployed using **Hugo Extended**, **Blowfish**, and **Nix Flakes**.

---

## 1. The Core Stack: Hugo Extended + Blowfish

Static site generators are a crowded field, but for pure raw speed, stability, and markdown flexibility, **[Hugo](https://gohugo.io/)** (written in Go) remains unmatched. Hugo compiles hundreds of content pages in milliseconds without spinning up a heavy V8 runtime.

For the theme base, I chose **[Blowfish](https://blowfish.page/)** (a descendant of Congo built on Tailwind CSS). Blowfish provides:
- Clean, semantic HTML5 structure.
- Pre-configured OpenGraph metadata, RSS feeds, and Twitter cards.
- Modular layout partials that can be easily overridden in the site's top-level `layouts/` directory.

However, default theme presets rarely satisfy specific design demands. Blowfish ships with opinions tailored for general writing: narrow reading widths (capped at 65 characters `max-w-prose`), standard pufferfish branding, and segregated taxonomy pages. To turn it into a dedicated systems engineering blog, we needed deep architectural customizations.

---

## 2. Declarative Environment with Nix Flakes

On a traditional Linux distribution, setting up Hugo might involve `apt install hugo` or `brew install hugo`. But on **NixOS**, dependencies must be declared hermetically. Moreover, standard Hugo repositories often run into discrepancies between vanilla Hugo and `hugo-extended` (which includes embedded libsass and asset pipelines).

To ensure anyone (and any CI system) can build Fumoctl without installing Hugo globally, the entire lifecycle is declared in [`flake.nix`](https://github.com/fumoctl/hugosite/blob/main/flake.nix):

```nix
{
  description = "Hugo static website blog with Blowfish theme";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    self.submodules = true;
    blowfish = {
      url = "github:nunocoracao/blowfish";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, blowfish }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        # Development shell: 'nix develop'
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            hugo
            git
          ];
          shellHook = ''
            echo "✨ Hugo + Blowfish development environment loaded."
            echo "Hugo version: $(hugo version)"
          '';
        };

        # Hermetic production build: 'nix build'
        packages.default = pkgs.stdenv.mkDerivation {
          name = "hugosite";
          src = ./.;
          buildInputs = [ pkgs.hugo ];
          buildPhase = ''
            mkdir -p themes
            if [ ! -d themes/blowfish ] || [ -z "$(ls -A themes/blowfish 2>/dev/null)" ]; then
              cp -r ${blowfish} themes/blowfish
              chmod -R u+w themes/blowfish
            fi
            hugo --minify
          '';
          installPhase = ''
            cp -r public $out
          '';
        };

        # One-line preview runner: 'nix run .'
        apps.default = {
          type = "app";
          program = "${pkgs.writeShellScript "hugo-server" ''
            exec ${pkgs.hugo}/bin/hugo server -D "$@"
          ''}";
        };
      });
}
```

### The Developer Experience
With this flake in place, spinning up the blog on any machine with Nix takes exactly one command:
```bash
# Instant local preview server with live-reloading and draft rendering
nix run .
```
And building the production distribution is completely reproducible:
```bash
nix build
# Static HTML/CSS/JS ready for deployment in ./result
```

---

## 3. Dark Glassmorphism: The "Nokstella" Aesthetic

Most tech blogs default to stark white or flat monochromatic gray palettes. For Fumoctl, I wanted a modern, atmospheric aesthetic inspired by deep night skies and glowing phosphor terminals:
- **Base Background**: Deep navy-slate (`#0a0f1d` / `#0f172a`).
- **Accents**: Cyberpunk cyan (`#38bdf8`) and electric violet (`#a855f7`).
- **Glassmorphism**: Translucent card backgrounds (`rgba(15, 23, 42, 0.75)`), subtle hairline borders (`rgba(255, 255, 255, 0.08)`), and hardware-accelerated backdrop blur (`backdrop-filter: blur(12px)`).

### The Floating Pill Navigation
Rather than a traditional clunky top banner, the site uses a floating glass pill navbar.
- On the **homepage**, the navbar stays invisible while the reader takes in the hero section, fading smoothly into view only after scrolling past the header.
- On **inner pages**, a pre-calculated spacer (`.header-spacer`, height `~5.75rem`) prevents any content from clipping behind the fixed glass header.

```css
/* assets/css/custom.css */
.homepage-header {
  position: fixed !important;
  top: 0.5rem;
  left: 0;
  right: 0;
  z-index: 100;
  display: flex;
  justify-content: center;
  pointer-events: none;
}

.homepage-header > div {
  pointer-events: auto;
  background: rgba(15, 23, 42, 0.78) !important;
  backdrop-filter: blur(16px) saturate(180%) !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
  box-shadow: 0 10px 30px -10px rgba(0, 0, 0, 0.5),
              0 0 20px rgba(56, 189, 248, 0.12) !important;
  border-radius: 9999px !important;
}
```

### Committing to Pure Dark Mode
Many websites carry unnecessary runtime overhead trying to support auto-switching light and dark modes with conflicting color tokens. Because Fumoctl's visual identity is intrinsically tied to terminal luminescence, I intentionally disabled the theme switcher (`showAppearanceSwitcher = false` and `autoSwitchAppearance = false`). This eliminated DOM flicker on page load, pruned unused CSS paths, and kept the interface cohesive.

---

## 4. Reader-First Layout: Liberating Technical Content

The single most frustrating aspect of reading technical articles on modern blogs is narrow formatting. Many themes limit reading columns to `65ch` (~650px). While optimal for short narrative essays, this constraint is disastrous for technical writing:
- Complex shell one-liners or Nix derivations wrap onto three lines, breaking readability.
- Multi-column performance comparison tables get clipped or require cumbersome horizontal scrollbars.
- Terminal output logs turn into unreadable walls of wrapped text.

### Breaking the Prose Ceiling
In `layouts/_default/single.html` and `assets/css/custom.css`, I re-architected the reading view into an expansive 2-column flex layout on desktop displays:

```css
/* Reading column spans comfortably on desktop up to ~1100px */
.single-post-content {
  flex: 1 1 0% !important;
  min-width: 0 !important;
  max-width: calc(100% - 20rem) !important;
}

/* Ensure code blocks, tables, and pre tags utilize full available width */
.prose pre,
.prose table,
.prose img {
  max-width: 100% !important;
  width: 100% !important;
}
```

### Sticky "Jump To" Table of Contents (Index)
Long-form guides can easily span 2,000 to 4,000 words. Readers need to know where they are and navigate effortlessly between sections:
- **Sticky Positioning**: The TOC aside (`.single-post-toc`) spans the full vertical height of the article (`align-self: stretch !important;`) while the inner container stays pinned:
  ```css
  .toc {
    position: sticky !important;
    top: 5.5rem !important;
    max-height: calc(100vh - 7rem);
    overflow-y: auto;
  }
  ```
- **Heading Offset Calculations**: To prevent anchor links from jumping *underneath* the floating glass navbar, all article headings receive an explicit scroll margin:
  ```css
  .prose h1, .prose h2, .prose h3, .prose h4, .anchor {
    scroll-margin-top: 5.5rem !important;
  }
  ```
- **Active Section Scroll-Spy**: A lightweight IntersectionObserver dynamically highlights the active heading in the TOC as the user reads.

### Viewport Reading Progress Bar
Fixed to the top edge of the browser viewport sits a subtle gradient indicator (`linear-gradient(to right, #38bdf8, #a855f7)`). It tracks exact scroll depth, giving the reader immediate visual feedback on their progress through deep technical breakdowns.

---

## 5. The Unified Articles Hub (`/posts/`)

Default Hugo blogs often split taxonomies across multiple fragmented pages: `/posts/` for articles, `/tags/` for tag lists, and `/categories/` for category archives. This forces the reader to click back and forth between different URLs just to explore related topics.

In Fumoctl, I consolidated all post discovery into a single **Unified Articles Hub** powered by vanilla JavaScript:

1. **Instant Client-Side Search**: A debounced search input filters articles in real-time across post titles, excerpts, summaries, tags, and categories without any backend requests or external search APIs.
2. **Category Filter Pills**: Interactive pills with dynamic badge counts allow filtering by primary domains (`Guides`, `Gaming`, `Packaging`, `AI & LLM`, `Homelab`).
3. **Inline Tag Dropdown & Expandable Cloud**: A clean `🏷️ Filter by Tag` dropdown lets users narrow by specific technologies (e.g. `NixOS`, `Wine`, `Flatpak`) with an expandable cloud view for browsing all available keywords.
4. **URL State Synchronization**: Active filters sync to URL parameters, allowing readers to share filtered views (e.g. `/posts/?cat=Guides&tag=NixOS`) directly.

```javascript
// Instant client-side filter orchestration (layouts/posts/list.html)
function applyFilters() {
  const query = searchInput.value.toLowerCase().trim();
  let visibleCount = 0;

  articleCards.forEach(card => {
    const cardTitle = card.dataset.title || '';
    const cardSummary = card.dataset.summary || '';
    const cardCat = card.dataset.category || '';
    const cardTags = card.dataset.tags || '';

    const matchesQuery = !query || 
      cardTitle.includes(query) || 
      cardSummary.includes(query) || 
      cardTags.includes(query);

    const matchesCategory = !activeCategory || 
      cardCat.toLowerCase() === activeCategory.toLowerCase();

    const matchesTag = !activeTag || 
      cardTags.toLowerCase().split(',').includes(activeTag.toLowerCase());

    const isVisible = matchesQuery && matchesCategory && matchesTag;
    card.style.display = isVisible ? '' : 'none';
    if (isVisible) visibleCount++;
  });

  updateEmptyState(visibleCount);
}
```

---

## 6. Brand Identity: Retiring Upstream Pufferfish

Blowfish ships by default with pufferfish iconography for tab headers, favicons, and manifest files. To establish a clean personal brand, I designed and injected custom Fumoctl terminal prompt assets (`>_`):
- `static/images/fumoctl-logo.svg`: Scalable vector mark.
- `static/favicon.ico`: Multi-resolution binary icon (16x16, 32x32, 48x48).
- `static/apple-touch-icon.png`: High-density iOS touch icon.
- `layouts/partials/favicons.html`: Overriding the theme's default favicon injection to ensure no upstream pufferfish assets are loaded by browsers.

---

## 7. The Result & What's Next

By combining Hugo's compilation speed with NixOS's declarative guarantees and a modern CSS layer, Fumoctl delivers:
- **Zero Runtime Dependencies**: Pure static output served with optimal caching headers.
- **Flawless Code Presentation**: Wide layouts with syntax highlighting that don't cramp complex derivations or configs.
- **Effortless Maintenance**: Writing a new post is as simple as creating a markdown file and running `nix run .`.

Future iterations will explore automated NixOS homelab CI pipelines for Git push deployments, localized LLM-assisted search embeddings, and interactive diagram widgets.

If you're building your own tech blog or homelab portal, consider taking the declarative route. The upfront investment in reproducible tooling pays dividends every time you publish.
