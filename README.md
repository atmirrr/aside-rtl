# aside-rtl

An [Aside](https://asidehq.com) skill that adds right-to-left support and the Vazirmatn font to
Aside's own chat UI on macOS. Replies, your messages, chat titles and the message box follow the direction of the text,
and code stays left-to-right. The patch is re-applied automatically after Aside updates.

Newer Aside builds keep the chat UI inside `Aside.app`. On those, the patch edits files in the app
(originals are backed up first), which breaks the app's code-signature seal; Aside keeps working,
and the uninstall script restores the original pages.

## Install

As a skill (your Aside agent can then install, update or remove it for you):

```sh
git clone https://github.com/atmirrr/aside-rtl ~/.aside/u/0/skills/user/aside-rtl
```

Or run it directly:

```sh
zsh scripts/install.sh            # apply + LaunchAgent com.aside-rtl
zsh ~/.aside-rtl/uninstall.sh     # remove, pages restored byte for byte
```

Close and reopen the Aside side panel afterwards. See [SKILL.md](SKILL.md) for details and limits.
