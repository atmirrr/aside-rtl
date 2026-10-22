# aside-rtl

An [Aside](https://asidehq.com) skill that adds right-to-left support and the Vazirmatn font to
Aside's own chat UI on macOS. Persian, Arabic and Hebrew replies, your messages, chat titles and
the message box are aligned right-to-left, and code stays left-to-right. The patch is
re-applied automatically after Aside updates.

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
