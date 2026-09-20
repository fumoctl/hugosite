---
title: "Using sing-box Tun Mode to Implement a Transparent Proxy for V2rayU"
date: 2025-11-09T14:30:00+00:00
draft: false
tags: ["MacOS", "Sing-Box", "V2rayU", "TUN", "Transparent Proxy", "Gemini CLI", "Troubleshooting"]
categories: ["Networking", "Guides"]
summary: "This post documents the troubleshooting process for a gemini-cli OAuth login failure on macOS. Since V2rayU lacks a native Tun mode, it cannot proxy the gemini-cli's random port callback. This article introduces a clever solution: using sing-box to enable Tun mode for transparent proxying, intercepting all system traffic, and forwarding it back to V2rayU's SOCKS port, perfectly solving the proxy challenge for CLI tools."
showSummary: true
---

This post documents the troubleshooting process for a gemini-cli OAuth login failure on macOS. Since V2rayU lacks a native Tun mode, it cannot proxy the gemini-cli's random port callback. This article introduces a clever solution: using sing-box to enable Tun mode for transparent proxying, intercepting all system traffic, and forwarding it back to V2rayU's SOCKS port, perfectly solving the proxy challenge for CLI tools.

## The Problem

CLI developer tools frequently initiate ephemeral local listeners for OAuth handshakes. When your proxy client operates solely at the HTTP/SOCKS application layer without system-level TUN interception:

1. Requests sent to `127.0.0.1` bypass system proxies.
2. CLI network drivers ignore environment variables like `http_proxy`.
3. Handshake timeouts disrupt command line workflows.

## The Solution: sing-box TUN

By using `sing-box` with a virtual TUN interface, we capture all layer-3 IP packets before macOS routing decisions occur:

```json
{
  "inbounds": [
    {
      "type": "tun",
      "interface_name": "utun99",
      "inet4_address": "172.19.0.1/30",
      "auto_route": true,
      "strict_route": true
    }
  ],
  "outbounds": [
    {
      "type": "socks",
      "tag": "v2rayu-socks",
      "server": "127.0.0.1",
      "server_port": 10808
    }
  ]
}
```

Once running, every CLI tool functions seamlessly without manual proxy configuration.
