<div align="center">

# ✉️ MailFlow for Omarchy

**Unread mail from your self-hosted [MailFlow.sh](https://mailflow.sh), right in the Omarchy bar.**<br>
An envelope with a count, and a click away from a per-account breakdown.

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Omarchy](https://img.shields.io/badge/Omarchy-plugin-8a2be2.svg)](https://omarchy.org)
[![Omarchy plugin marketplace](https://img.shields.io/badge/marketplace-verified-2ea44f.svg)](https://omarchyplugins.com/plugin.html?id=melkweg.mailflow)
[![MailFlow.sh](https://img.shields.io/badge/MailFlow.sh-3.4%2B-0a7cff.svg)](https://mailflow.sh)
[![Python](https://img.shields.io/badge/python-3-3776ab.svg?logo=python&logoColor=white)](scripts/mf-unread)

</div>

---

## ✨ Features

- 📬 **Unread at a glance**: a filled envelope with the number of unread messages, including mail your inbox rules sorted into folders
- 👥 **Per account**: click the envelope for the total and the count of every account
- 🔴 **Honest about faults**: the envelope turns red when you are not signed in, MailFlow is unreachable, or the counts are out of date
- 🔐 **Your own session**: signs in like the web app (password plus authenticator or email code); no extra server component, no database access
- 🌐 **One click to the web app**: the panel opens MailFlow in your browser
- 😴 **Wakes up fast**: after a suspend the count refreshes within seconds, not after the next interval

## 🚀 How it works

`scripts/mf-unread` polls `GET /api/mail/unread-counts` on your MailFlow every 30 seconds
with a MailFlow session, and prints one JSON line per reading. The bar widget only reads
those lines; it does no network I/O itself.

| State | Envelope |
| --- | --- |
| No unread mail | outlined, bar colour |
| Unread mail | filled, with the count, accent colour |
| Not signed in | outlined, red; the panel shows **Not signed in** and a **Sign in** tile |
| MailFlow unreachable | outlined, red; the panel shows **MailFlow unreachable** |
| Counts out of date | outlined, red; the panel shows **Counts out of date** |

The tooltip gives the same information in one line per account.

### What the number means

The number is unread mail in the INBOX of each account, plus unread mail in every other
folder, so messages that inbox rules move out of INBOX (into "Shop", "GitHub" and so on)
still count. Sent, Drafts, Trash, Junk/Spam, Archive and Notes never count: folders with an
IMAP special-use flag for those, or with one of those names. Unread stays unread wherever
it is, so a folder you leave unread keeps the envelope lit.

The panel shows the total per account. An account with unread mail outside INBOX says so
below its address (`▸ 3 folders`); click it, or pick it with ↑/↓ and press Enter, to fold
open a list of Inbox and those folders, most unread first. Nested folders show their path
(`Clients › Acme`), cut off on the left when too long. Past eight rows the list scrolls
inside the card, so many busy folders never stretch the panel. One account is open at a
time, and all are closed again when the panel opens.

The total in the bar covers the accounts in MailFlow's unified inbox; the panel lists
every account. Counts are as reported by the IMAP server.

An account whose count MailFlow could not refresh recently is marked out of date (red
stripe, `(out of date)` in the tooltip).

## 📋 Requirements

- A [MailFlow.sh](https://mailflow.sh) server, version **3.4.0 or newer**,
  reachable from your desktop.
- An account that signs in with a password, optionally with an authenticator (TOTP) or an
  email code as second factor. Accounts that only use single sign-on are not supported.
- `python3` (standard library only).

## 📦 Installation

Listed in the [Omarchy plugin marketplace](https://omarchyplugins.com/plugin.html?id=melkweg.mailflow),
where you can also copy the install command. From a terminal:

```bash
omarchy plugin add https://github.com/mvalkier/omarchy-mailflow-plugin.git --enable
```

Update later with:

```bash
omarchy plugin update melkweg.mailflow
```

### Removal

Sign out first, so the session ends on the server too, then remove the plugin and the
session directory:

```bash
~/.config/omarchy/plugins/melkweg.mailflow/scripts/mf-unread logout
omarchy plugin remove melkweg.mailflow
rm -rf ~/.config/mailflow-bar
```

## 🔑 Signing in

Right after installation the envelope is red: the plugin is not signed in yet.

1. **Click the envelope** and then **Sign in**. A floating terminal opens.
2. Enter your MailFlow URL (for example `mail.example.com`; `https://` is added), your
   username and password, and the authenticator or email code if MailFlow asks for one.
3. The bar picks up the new session within a few seconds.

From a terminal, the same:

```bash
~/.config/omarchy/plugins/melkweg.mailflow/scripts/mf-unread login
```

## 🛡️ Security

- Only the session cookie is stored, never your password: in
  `~/.config/mailflow-bar/session.json` (mode 600, directory mode 700), outside the plugin
  directory, so an update or reinstall does not lose it.
- It is a full MailFlow session, just like a signed-in browser tab. Treat the file
  accordingly.
- Every poll extends the session. The session stays valid for 7 days without use. A laptop that was suspended for a few days picks up where it left off; after 7 days or more you are asked to sign in again.
- Changing your MailFlow password ends all sessions, including this one.
- To sign out and remove the session:

  ```bash
  ~/.config/omarchy/plugins/melkweg.mailflow/scripts/mf-unread logout
  ```

MailFlow's auto-lock applies to the browser tab where it is enabled, not to the bar's
session.

## 🛠️ Development

From a working tree:

```bash
./install --restart
omarchy plugin enable melkweg.mailflow --section right
```

`install` copies the working tree to `~/.config/omarchy/plugins/melkweg.mailflow` and runs
`omarchy plugin validate`. It copies rather than symlinks, because validation rejects any
symlink in a plugin directory. If the plugin directory is a checkout made by
`omarchy plugin add`, `install` refuses unless given `--force`. `--restart` restarts the
shell: components such as `EnvelopeIcon.qml` stay cached until then.

A single reading, without the bar:

```bash
scripts/mf-unread --once
```

Control without clicking:

```bash
omarchy-shell melkweg.mailflow toggle    # open or close the panel
omarchy-shell melkweg.mailflow webmail   # open MailFlow in the browser
omarchy-shell melkweg.mailflow signIn    # open the sign-in terminal
```

<details>
<summary><b>Files</b></summary>

<br>

| File | Role |
| --- | --- |
| `BarWidget.qml` | The envelope and count in the bar; runs `mf-unread`, owns the IPC target and passes the readings to the panel. |
| `Panel.qml` | Total, counts per account, the sign-in tile and the web app tile. |
| `EnvelopeIcon.qml` | The envelope as a `Shape`, so its stroke matches the other bar icons. |
| `scripts/mf-unread` | All network I/O: polling, `login` and `logout`. Every reading is one JSON line on stdout. |
| `install` | Copies the plugin into Omarchy's plugin directory. |

</details>

<details>
<summary><b>The helper script</b></summary>

<br>

```bash
scripts/mf-unread           # keep polling, one JSON line per reading
scripts/mf-unread --once    # a single reading
scripts/mf-unread login     # sign in interactively
scripts/mf-unread logout    # end the session and forget it
```

A reading looks like this:

```json
{"ok": true, "url": "https://mail.example.com", "total": 3, "complete": true,
 "accounts": [{"email": "me@example.com", "unread": 3, "inbox": 1, "stale": false,
               "folders": [{"name": "Shop", "unread": 2, "stale": false}]}], "time": 1791561600}
{"ok": false, "url": "https://mail.example.com", "reason": "login"}
```

`reason` is `login` (no session, expired or locked) or `unreachable` (no connection or a
server error). After a failed connection the next attempt follows after about 5 seconds
instead of 30, so a laptop that just woke up recovers quickly once the network is back.

</details>

## ™️ Trademarks

Not affiliated with [MailFlow.sh](https://mailflow.sh) or its authors.

## 📄 License

[MIT](LICENSE) © 2026 Martijn Valkier
