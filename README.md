# Fumoctl Technical Blog

The personal technical blog and digital sovereign space of **Juan (Fumoctl)** — Argentinian systems administrator and Business Informatics student writing about declarative operating systems, NixOS, homelabbing, containerization, and modern Linux infrastructure engineering.

Built with [Hugo](https://gohugo.io/) and the [Blowfish](https://blowfish.page/) theme, customized with a dark glassmorphic aesthetic ("Nokstella"), Nix Flake environment management, and reader-first UX.

---

## Features

- **Nix-Powered Declarative Environment**: Fully reproducible development and build environment managed with Nix Flakes (`flake.nix`).
- **Dark Glassmorphic UI**: Custom dark theme with blurred backdrops (`backdrop-filter`), subtle borders, cyan (`#38bdf8`) and purple (`#a855f7`) glowing accents, and terminal prompt branding (`>_ Fumoctl`).
- **Floating Pill Navigation**: Sleek, thin glass navbar that dynamically appears when scrolling past the hero section on the homepage, and stays pinned with comfortable clearance across all inner pages.
- **Unified Articles Hub (`/posts/`)**:
  - Live client-side search box with instant filtering and clear button.
  - Filter pills for categories with dynamic article count badges.
  - Inline tag filter dropdown (`🏷️ Filter by Tag`) and optional expandable tag cloud (`Browse Tags ▾`).
  - Active filter indicators with one-click dismiss chips.
  - Card-level tag and category click integration.
- **Enhanced Post Reading Experience**:
  - Unconstrained reading width (~1100px) avoiding artificial narrow text margins.
  - Fully readable syntax-highlighted code blocks with line numbers.
  - Sticky on-the-side "Jump to" Table of Contents (Index) with active section tracking.
  - Glowing reading progress bar fixed to the top edge of the browser viewport.
- **Custom Brand Identity**: Fully customized browser tab favicons (SVG, ICO, multi-size PNG) using the Fumoctl terminal prompt mark.

---

## Quick Start (Nix Flakes)

Ensure you have [Nix](https://nixos.org/) installed with flakes enabled:

```bash
# Clone the repository
git clone https://github.com/fumoctl/hugosite.git
cd hugosite

# Run local development server with draft preview (binds to http://127.0.0.1:1313)
nix run .

# Or enter the nix development shell
nix develop
hugo server -D
```

To build the static site for production deployment:

```bash
nix build
# The compiled static assets will be located in ./result
```

---

## Deployment (GitHub Pages)

The blog is fully configured for automated continuous deployment to **GitHub Pages** using GitHub Actions:

1. In your GitHub repository, navigate to **Settings > Pages**.
2. Under **Build and deployment > Source**, select **GitHub Actions**.
3. Push to `main` (or trigger the workflow manually under the **Actions** tab).

The workflow (`.github/workflows/deploy.yml`):
- Checks out submodules recursively (`themes/blowfish`).
- Installs the latest extended Hugo CLI.
- Automatically resolves the correct `baseURL` (supporting either `https://fumoctl.com/` or `https://<username>.github.io/<repo>/`).
- Builds minified assets with `.nojekyll` and `CNAME` support and deploys in under 30 seconds.

### Custom Domain (`fumoctl.com`) DNS Setup
To point your custom domain to GitHub Pages:
- **Apex domain (`fumoctl.com`)**: Add four `A` records pointing to GitHub's Anycast IPs:
  ```
  185.199.108.153
  185.199.109.153
  185.199.110.153
  185.199.111.153
  ```
- **`www` subdomain (`www.fumoctl.com`)**: Add a `CNAME` record pointing to `fumoctl.github.io.`
- In GitHub repository **Settings > Pages > Custom domain**, enter `fumoctl.com` and check **Enforce HTTPS**.

---

## Project Structure

```
.
├── .github/
│   └── workflows/
│       └── deploy.yml         # GitHub Actions deployment to GitHub Pages
├── flake.nix                  # Nix Flake defining devShell, build package, and run app
├── config/
│   └── _default/
│       ├── hugo.toml          # Base Hugo configuration (outputs, related content, sitemap)
│       ├── params.toml        # Blowfish theme parameters, header, footer, TOC settings
│       ├── languages.en.toml  # Site title ("Fumoctl"), metadata, author bio & socials
│       ├── menus.en.toml      # Navigation menus (About, Articles)
│       └── markup.toml        # Goldmark markdown parser, syntax highlighting, heading IDs
├── content/
│   ├── about/
│   │   └── index.md           # About Fumoctl biography & areas of focus
│   └── posts/
│       ├── packaging-github-copilot-desktop-and-cli-on-nixos/
│       ├── the-definitive-guide-to-playing-visual-novels-on-linux/
│       └── building-fumoctl-a-declarative-homelab-blog/
├── layouts/
│   ├── _default/
│   │   ├── baseof.html        # Base HTML skeleton & viewport structure
│   │   └── single.html        # 2-column post layout (wide prose + sticky TOC)
│   ├── partials/
│   │   ├── favicons.html      # Fumoctl terminal brand favicons
│   │   ├── reading-progress.html # Top gradient glowing progress bar
│   │   ├── toc.html           # Sticky "Jump to" index with scroll-spy
│   │   └── header/
│   │       └── floating.html  # Floating pill navigation header
│   └── posts/
│       └── list.html          # Articles page with live search & unified filter toolbar
├── assets/
│   └── css/
│       └── custom.css         # Glassmorphism, layout widths, responsive styles
├── static/
│   ├── .nojekyll              # Disables Jekyll processing on GitHub Pages
│   ├── CNAME                  # Custom domain (fumoctl.com)
│   ├── favicon.ico            # Fumoctl multi-res icon
│   ├── favicon-16x16.png
│   ├── favicon-32x32.png
│   ├── apple-touch-icon.png
│   └── images/
│       ├── avatar.jpg         # Fumoctl avatar
│       ├── hero-bg.jpg        # Nokstella landscape hero background
│       └── fumoctl-logo.svg   # Fumoctl terminal logo mark
└── themes/
    └── blowfish/              # Upstream Blowfish theme submodule
```

---

## Writing Content

New articles should be placed in `content/posts/<slug>/index.md` with an optional `featured.jpg`:

```markdown
---
title: "Your Article Title"
date: 2026-09-20T12:00:00+00:00
draft: false
tags: ["NixOS", "Homelab", "Linux"]
categories: ["Guides"]
summary: "Short summary of the article displayed on cards and search results."
showSummary: true
---

Your markdown content here...
```

### Taxonomy Standard

- **Categories**: Standardized to title case (e.g. `Guides`, `Gaming`, `Networking`, `Packaging`, `AI & LLM`).
- **Tags**: Case-insensitive keywords (e.g. `NixOS`, `Flakes`, `Flatpak`, `Wine`).

---

## License

Content and branding &copy; Fumoctl. Theme based on [Blowfish](https://blowfish.page/) (MIT License).
