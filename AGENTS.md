# AGENTS.md - Developer & AI Assistant Guide

This document defines the architecture, environment constraints, design invariants, and operating procedures for AI coding assistants and autonomous agents working on the **Fumoctl** Hugo codebase.

---

## 1. Operating Environment & Constraints

- **Host Operating System**: Minimal Linux / NixOS.
- **Environment Management**: Nix Flakes (`flake.nix`).
- **Command Invocation Rule**: Tools like `hugo` or `git` may not exist in the global system `$PATH`. **Always run Hugo and development commands inside the Nix flake environment**:
  ```bash
  nix develop --command hugo
  nix develop --command hugo server -D
  nix run .
  ```
- **Temporary Server & Port Hygiene**:
  - The local Hugo preview server binds to `127.0.0.1:1313`.
  - When starting a background server for automated QA or verification, always terminate/kill the process and ensure port 1313 is released after testing:
    ```bash
    ss -tlpn | grep 1313 || echo "Port 1313 is free"
    ```

---

## 2. Architecture & Tech Stack

- **Static Site Generator**: Hugo Extended (v0.166.0+)
- **Base Theme**: Blowfish (`themes/blowfish`) managed via Nix input / submodule.
- **CSS Architecture**:
  - Tailwind CSS precompiled in the Blowfish theme bundle.
  - Custom overrides and components reside strictly in [`assets/css/custom.css`](assets/css/custom.css).
- **Templates**: Standard Go HTML templates in [`layouts/`](layouts/) taking priority over `themes/blowfish/layouts/`.
- **Content**: Markdown with YAML frontmatter in [`content/`](content/).
- **Configuration**: Modular TOML files in [`config/_default/`](config/_default/).

---

## 3. Critical Architectural Invariants

### A. Precompiled Tailwind Guardrail
Blowfish uses a precompiled Tailwind CSS bundle (`themes/blowfish/assets/css/compiled/main.css`).
- **Do NOT** assume arbitrary Tailwind utility classes exist in this project (e.g. `w-3.5`, `lg:w-64`, `inset-y-0 start-0`, `gap-1.5` are missing from the precompiled bundle).
- For any custom positioning, flexbox alignment, sizing, or responsive behavior, define explicit CSS rules in `assets/css/custom.css` using class selectors.

### B. Reading Width & Screen Fit
- Single post reading layout in [`layouts/_default/single.html`](layouts/_default/single.html) is an expansive 2-column flex row on desktop:
  - Post content (`.single-post-content`): `flex: 1 1 0%; min-width: 0; max-width: calc(100% - 20rem);` (~1100px on 1440px displays).
  - Sticky TOC (`.single-post-toc`): `width: 17rem; flex-shrink: 0; align-self: stretch;`.
- **Do NOT** restore Blowfish's default `max-w-prose` (65ch) restriction on post content or headers.
- Code blocks (`.prose pre`), tables, and media must span 100% width of the reading column.

### C. Sticky TOC & Scroll Mechanics
- The TOC aside (`.single-post-toc`) has `align-self: stretch !important;` so it spans the entire vertical height of the post.
- The inner `.toc` element has `position: sticky !important; top: 5.5rem !important; max-height: calc(100vh - 7rem); overflow-y: auto;`.
- Active section detection in [`layouts/partials/toc.html`](layouts/partials/toc.html) inspects `.anchor, h1[id], h2[id], h3[id], h4[id], h5[id], h6[id]`.
- All article headings (`.prose h1` through `h6` and `.anchor`) must have `scroll-margin-top: 5.5rem !important;` in `custom.css` to prevent anchor jumps from hiding beneath the floating navbar.

### D. Floating Header & Spacers
- The floating header (`.homepage-header`) is fixed at `top: 0.5rem; z-index: 100;`.
- On all non-homepage views, a spacer (`<div class="header-spacer" aria-hidden="true"></div>`, height `~5.75rem`) is rendered before page content to prevent navbar overlap.
- The light/dark theme toggle button is disabled (`showAppearanceSwitcher = false` and `autoSwitchAppearance = false` in `config/_default/params.toml`). The site remains locked to dark mode.

### E. Branding & Favicons
- **Site Title**: Strictly `Fumoctl` (capitalized 'F') in `config/_default/languages.en.toml`.
- **Logo Mark**: Terminal prompt `>_` (`static/images/fumoctl-logo.svg`).
- **Favicons**: Custom partial [`layouts/partials/favicons.html`](layouts/partials/favicons.html) injects SVG, PNG, and ICO icons generated from the Fumoctl brand mark. Upstream Blowfish pufferfish favicons are completely overridden.

### F. Taxonomies & Metadata
- **Categories**: Standardized to title-case plural form (e.g., `Guides`, `Gaming`, `Networking`, `Packaging`, `AI & LLM`). Do not mix singular `Guide` and plural `Guides`.
- **Tags**: Keyword tags (e.g., `NixOS`, `Flakes`, `Flatpak`, `Wine`).

---

## 4. Common Agent Workflows

### Creating a New Article
1. Create the post folder:
   ```bash
   mkdir -p content/posts/my-new-article-slug
   ```
2. Create `content/posts/my-new-article-slug/index.md`:
   ```markdown
   ---
   title: "Title Here"
   date: 2026-09-20T12:00:00+00:00
   draft: false
   tags: ["NixOS", "Homelab"]
   categories: ["Guides"]
   summary: "One to two sentences summarizing the post."
   showSummary: true
   ---

   Article body here...
   ```
3. Add a high-resolution `featured.jpg` image in the post folder.

### Verifying Site Builds
Always run a test build before concluding work:
```bash
nix develop --command hugo
```
Confirm `0 errors` and clean exit code `0`.

### Modifying UI Styles
- Add or modify CSS rules in [`assets/css/custom.css`](assets/css/custom.css).
- When adding new interactive components to [`layouts/posts/list.html`](layouts/posts/list.html) or other templates, use self-contained vanilla JavaScript with passive event listeners and query parameter persistence where applicable.
