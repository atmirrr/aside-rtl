---
name: "aside-rtl"
description: "Add right-to-left support and the Vazirmatn font to Aside's own chat UI on macOS: side panel, full chat page, side chats, chat titles and the message box. Use when right-to-left text in Aside looks left-aligned, scrambled or in the wrong font, when the user asks for RTL in Aside, or wants to update, check or remove this patch."
---

# Aside RTL

Aside has no custom-CSS setting. Its chat UI is a built-in extension, and edited files load after
a page reload. Where it lives depends on the build:
- older builds: `~/Library/Application Support/Aside/AsideAgentManager/<version>/`
- newer builds (browser 1.0.1022 and later): inside the app, at
  `/Applications/Aside.app/Contents/Frameworks/Aside Framework.framework/Versions/<app version>/Libraries/AsideAgentManager/`.
  The Application Support folder is then empty, and a copy placed there is deleted at the next launch.

This skill copies a small CSS + JS patch into each copy it finds, links it from each page that
loads Aside's stylesheet, and installs a LaunchAgent that re-applies it after Aside updates. Pages
inside the app are backed up to `~/.aside-rtl/bundle-backup/<app version>/` before the first edit.
Editing files inside the app breaks its code-signature seal (`codesign --verify` reports it);
Aside still launches and runs normally, and `uninstall.sh` puts the original pages back.

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
lists every copy as patched (app copies are logged as `app <version>`), and tell the user to close and reopen the side panel
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
byte (app pages from the backup) and deletes `~/.aside-rtl`. If Aside ever refuses to open after
a patch, this is the fix.

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
elsewhere and is not covered. If the app was installed by another user or an admin and is not
writable, the in-app copy is skipped (logged as `not writable`).
