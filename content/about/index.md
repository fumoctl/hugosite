---
title: "About"
description: "About Juan - Fumoctl: Argentinian systems administrator, student, and FOSS advocate."
layout: "simple"
showAuthor: false
showBreadcrumbs: false
showDate: false
showWordCount: false
showReadingTime: false
build:
  list: never
---

Hi, I’m **Juan - Fumoctl**.

I’m an Argentinian systems administrator and Business Informatics student with a passion for free and open-source software, rock-solid systems architecture, and digital sovereignty.

This is where I write about the intersection of modern infrastructure engineering, declarative operating systems, and practical homelabbing. If you care about building infrastructure that is deterministic, auditable, and resilient to breaking updates, you’ll feel right at home here.

---

## What I Work On & Write About

- **Declarative & Immutable Linux**: Deep dives into managing systems where configuration is code—primarily focusing on Nix / NixOS, flakes, container layering, and modern atomic deployments.
- **Homelab Architecture & Self-Hosting**: Designing reliable, reproducible services using rootless containers, reverse proxies, and automated deployment pipelines.
- **Systems Administration & Automation**: Orchestration and config management with Ansible, systemd units, Quadlets, and custom automation scripts in Python, Go, and Bash.
- **Privacy & Security Sovereignty**: Practical guides to data autonomy, encrypted backups, PGP verification, and hardening cloud/VPS instances.

---

## Subscribe via RSS

Stay up to date with new articles and infrastructure deep dives without algorithms or tracking:

<div class="info-card">
  <div class="rss-card-header">
    <div class="rss-icon-badge" aria-hidden="true">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M4 11a9 9 0 0 1 9 9"></path>
        <path d="M4 4a16 16 0 0 1 16 16"></path>
        <circle cx="5" cy="19" r="1"></circle>
      </svg>
    </div>
    <div>
      <h3 class="!mt-0 !mb-1 text-lg font-bold text-white">Subscribe via RSS</h3>
      <p class="!my-0 text-sm text-neutral-400">Get new articles delivered directly to your feed reader, without algorithms, ads, or tracking.</p>
    </div>
  </div>

  <div class="rss-feed-box">
    <span class="rss-feed-url" id="rss-feed-url">https://fumoctl.com/index.xml</span>
    <button type="button" class="copy-btn" id="rss-copy-btn" onclick="navigator.clipboard.writeText('https://fumoctl.com/index.xml').then(() => { const b = document.getElementById('rss-copy-btn'); b.textContent = '✓ Copied!'; setTimeout(() => b.textContent = 'Copy', 2000); })">
      Copy
    </button>
  </div>

  <div class="rss-actions">
    <a href="/index.xml" target="_blank" rel="noopener noreferrer" class="rss-btn-primary">
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 11a9 9 0 0 1 9 9"></path><path d="M4 4a16 16 0 0 1 16 16"></path><circle cx="5" cy="19" r="1"></circle></svg>
      Open Site Feed
    </a>
    <a href="/posts/index.xml" target="_blank" rel="noopener noreferrer" class="rss-btn-secondary">
      Articles Only Feed (/posts/index.xml)
    </a>
  </div>

  <p class="!mt-3 !mb-0 text-xs text-neutral-400">
    Compatible with any open-source or commercial RSS reader including <a href="https://netnewswire.com/" target="_blank" rel="noreferrer">NetNewsWire</a>, <a href="https://miniflux.app/" target="_blank" rel="noreferrer">Miniflux</a>, <a href="https://newsboat.org/" target="_blank" rel="noreferrer">Newsboat</a>, <a href="https://feedly.com/" target="_blank" rel="noreferrer">Feedly</a>, and Thunderbird.
  </p>
</div>

---

## PGP & Cryptographic Identity

For encrypted communications, verifying git commits, or checking signed documents:

<div class="info-card">
  <div class="rss-card-header">
    <div class="rss-icon-badge" style="background: rgba(56, 189, 248, 0.15); color: #38bdf8; border-color: rgba(56, 189, 248, 0.3);" aria-hidden="true">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
        <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
      </svg>
    </div>
    <div>
      <h3 class="!mt-0 !mb-1 text-lg font-bold text-white">PGP Key (JuanU)</h3>
      <p class="!my-0 text-sm text-neutral-400">Identity: <code>JuanU (Fumoctl's personal pgp key) &lt;juanu@fumoctl.com&gt;</code></p>
    </div>
  </div>

  <div class="text-xs text-neutral-400 mt-2">
    <strong>Key Fingerprint:</strong>
  </div>
  <code class="pgp-fingerprint">5F3C 25D7 55D3 A432 1D03  FF71 35FA C098 F119 E8FA</code>

  <div class="text-xs text-neutral-400 mt-2">
    <strong>Fetch automatically via Web Key Directory (WKD):</strong>
  </div>
  <pre class="!my-1.5"><code class="language-bash">gpg --locate-keys juanu@fumoctl.com</code></pre>

  <div class="rss-actions !mt-3">
    <a href="/fumopgp.pub" download class="rss-btn-secondary">
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>
      Download fumopgp.pub
    </a>
    <a href="/.well-known/openpgpkey/hu/7cezh8u7c76p1a1r43w46xdfz68wkj7i" class="rss-btn-secondary">
      WKD Binary Key
    </a>
  </div>
</div>

---

## Connect & Socials

- **Website**: [fumoctl.com](https://fumoctl.com/)
- **Email**: [juanu@fumoctl.com](mailto:juanu@fumoctl.com)
- **RSS Feed**: [fumoctl.com/index.xml](https://fumoctl.com/index.xml)
- **PGP Key**: [fumopgp.pub](/fumopgp.pub) (`5F3C 25D7 55D3 A432 1D03  FF71 35FA C098 F119 E8FA`)
- **GitHub**: [@fumoctl](https://github.com/fumoctl)
- **YouTube**: [@Fumoctl](https://www.youtube.com/@Fumoctl)
- **X / Twitter**: [@Fumoctl](https://x.com/Fumoctl)
- **LinkedIn**: [in/fumoctl](https://www.linkedin.com/in/fumoctl)
