---
name: "aside-rtl"
description: "Add right-to-left support and a proper Persian/Arabic font (Vazirmatn) to Aside's own chat UI on macOS: side panel, full chat page, side chats, chat titles and the message box. Use when the user says Persian, Farsi, Arabic or Hebrew text in Aside looks left-aligned, scrambled or in the wrong font, asks for RTL in Aside, or wants to update, check or remove this patch."
---

# Aside RTL

Aside has no custom-CSS setting. Its chat UI is a built-in extension unpacked at
`~/Library/Application Support/Aside/AsideAgentManager/<version>/`, and edited files there load
after a page reload. This skill copies a small CSS + JS patch into every version folder, links it
from each page that loads Aside's stylesheet, and installs a LaunchAgent that re-applies it when
an Aside update adds a new version folder.

What it does:
- A text block becomes `dir="rtl"` when it has more Persian/Arabic/Hebrew letters than Latin ones
  (code, math and URLs don't count). Covers reply Markdown (`.streamdown`), the user's own
  bubbles, previews, chat titles (`.truncate`), the TipTap message box and text fields. An English
  block inside an RTL block gets `dir="ltr"`. A MutationObserver keeps streaming replies correct.
- Arabic-script letters render in Vazirmatn (bundled, SIL OFL 1.1) through extra `@font-face`
  rules under Aside's own family names with an Arabic-only `unicode-range`; Latin keeps Geist.
  Hebrew keeps the system font.
- RTL blocks get line-height 1.75, bold instead of italic, mirrored quotes and nested lists,
  right-aligned table cells; code, Mermaid and KaTeX stay left-to-right.
- The script only sets `dir` plus a `data-aside-rtl` marker, so it can undo its own changes.

## Install or update

```sh
zsh <this-skill-dir>/scripts/install.sh            # copy to ~/.aside-rtl, apply, add LaunchAgent com.aside-rtl
zsh <this-skill-dir>/scripts/install.sh --no-agent # apply once, no background job
```

Re-running is safe and also updates an existing install. Then check `~/.aside-rtl/apply.log`
lists every installed version as patched, and tell the user to close and reopen the side panel
(or reload chat pages); pages open before the install keep the old look. The LaunchAgent costs
about 0.1 s of CPU per run (login, folder change, every 10 minutes).

If install prints that an older `aside-ui-patch` is also injected, that is an earlier local
version of this patch. Ask before removing it:
`launchctl bootout gui/$(id -u)/com.aside-ui-patch; zsh ~/aside-ui-patch/apply.sh --remove`.

## Remove

```sh
zsh ~/.aside-rtl/uninstall.sh
```

It stops the LaunchAgent first (otherwise it re-applies at once), restores every page byte for
byte and deletes `~/.aside-rtl`.

## Changing it or fixing it after an Aside update

Edit `assets/patch/aside-rtl.css` or `.js` in this skill, run `install.sh` again, reopen the panel.
If an Aside update breaks it, the build probably renamed what the patch targets: `.streamdown` and
its `data-streamdown` attributes, `[data-agent-session-ui]`, `div.whitespace-pre-wrap`,
`.truncate`, the TipTap editor, and the font families "Geist Variable", "Aside Display" and
"Geist Mono Variable". To inspect a live chat page from the REPL:
`openTab('about:blank')`, then `page.goto('chrome-extension://fjdhphbdlfjogobdofoaagnlnkoibdge/main.html#/u/0/tasks/<sessionId>')`
and read the DOM with `page.evaluate`. Use CDP `Emulation.setDeviceMetricsOverride` at 420 px
for side-panel width. Search the extension's `assets/` with `rg -F -- <pattern> .` (some file
names start with a dash).

Known limits: a Persian paragraph that holds a long Latin path stays LTR (majority rule); a
Persian phrase inside an English paragraph is left alone; a Latin word glued to a Persian suffix
without a ZWNJ looks odd, which is normal bidi. macOS only. Windows Aside keeps its files
elsewhere and is not covered.
