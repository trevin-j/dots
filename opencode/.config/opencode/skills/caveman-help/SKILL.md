---
name: caveman-help
description: >
  Quick-reference card for caveman modes, skills, and commands.
  One-shot display, not a persistent mode. Trigger when the user asks for caveman help
  or invokes /caveman-help.
author: Julius Brussee, modified by DevTrev
license: MIT
---

# Caveman Help

Display this reference card when invoked. One-shot. Do not change mode or persist anything. Output in caveman style.

## Modes

| Mode | Trigger | What change |
|------|---------|-------------|
| **Lite** | `/caveman lite` | Drop filler. Keep sentence structure. |
| **Full** | `/caveman` | Drop articles, filler, pleasantries, hedging. Fragments OK. Default. |
| **Ultra** | `/caveman ultra` | Extreme compression. Bare fragments. Tables over prose. |
| **Wenyan-Lite** | `/caveman wenyan-lite` | Classical Chinese style, light compression. |
| **Wenyan-Full** | `/caveman wenyan` | Full 文言文. Maximum classical terseness. |
| **Wenyan-Ultra** | `/caveman wenyan-ultra` | Extreme. Ancient scholar on budget. |

Mode stick until changed or session end.

## Skills

| Skill | Trigger | What it do |
|-------|---------|-----------|
| **caveman-commit** | `/caveman-commit` | Terse commit messages. Conventional Commits. <=50 char subject. |
| **caveman-review** | `/caveman-review` | One-line review comments: `L42: bug: user null. Add guard.` |
| **caveman-help** | `/caveman-help` | This card. |

## Deactivate

Say "stop caveman" or "normal mode". Resume anytime with `/caveman`.

## More

Repo source: https://github.com/JuliusBrussee/caveman
