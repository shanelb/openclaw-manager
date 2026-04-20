---
name: hhmail
description: Manage and triage my custom emails.
metadata: { "openclaw": { "emoji": "✉️" } }
---

# HHMail — Himalaya for Hostinger

> This skill is **agent-driven**. The agent handles configuration and all email operations. The user does not need to run any terminal commands.

## Agent: How to Use This Skill

Read this section fully before acting. Follow the decision trees in order.

---

### Setup Flow

Run this flow whenever the user asks to set up email, or when email commands fail because no config exists.

**Step 1 — Check config**

```bash
test -f ~/.config/himalaya/config.toml && echo "exists" || echo "missing"
```

- If missing → go to Step 2.
- If exists → run `himalaya folder list` to test it.
  - If it succeeds → config is valid. Skip to email operations.
  - If it fails → tell the user the config may have wrong credentials. Ask if they want to reconfigure. If yes → go to Step 2.

**Step 2 — Check the user has a Hostinger email account**

Before asking for credentials, confirm the user already has a Hostinger email address and password. If they don't (e.g. they haven't created an email account yet, or they don't know their password), tell them:

> "You'll need to create a Hostinger email account first. Log in to your Hostinger control panel (hPanel), go to **Emails → Email Accounts**, and create a new email address. Once you have your email address and password, come back and I'll finish the setup."

Do not proceed until the user confirms they have both an email address and a password.

**Step 3 — Gather credentials from the user**

Ask in a single message (do not send separate messages for each field):

> "To set up your Hostinger email, I need:
> 1. Your email address (e.g. `you@yourdomain.com`)
> 2. Your display name (shown in the From field)
> 3. Your email password"

**Step 4 — Write config**

Derive the account name: strip everything up to and including `@`, then strip the last `.xxx` TLD.
- `you@company.com` → `company`
- `you@my-brand.net` → `my-brand`

Write `~/.config/himalaya/config.toml` directly with the following content (substituting the collected values):

```toml
[accounts.ACCOUNT_NAME]
default = true
email = "EMAIL"
display-name = "DISPLAY_NAME"
downloads-dir = "~/Downloads"

backend.type = "imap"
backend.host = "imap.hostinger.com"
backend.port = 993
backend.login = "EMAIL"
backend.encryption.type = "tls"
backend.auth.type = "password"
backend.auth.raw = "PASSWORD"

message.send.backend.type = "smtp"
message.send.backend.host = "smtp.hostinger.com"
message.send.backend.port = 465
message.send.backend.login = "EMAIL"
message.send.backend.encryption.type = "tls"
message.send.backend.auth.type = "password"
message.send.backend.auth.raw = "PASSWORD"

[accounts.ACCOUNT_NAME.folder.aliases]
inbox = "INBOX"
sent = "INBOX.Sent"
drafts = "INBOX.Drafts"
trash = "INBOX.Trash"
junk = "INBOX.Junk"
```

Set file permissions to owner-only after writing:
```bash
chmod 600 ~/.config/himalaya/config.toml
```

**Step 5 — Confirm and report**

```bash
himalaya --account ACCOUNT_NAME folder list
```

If it succeeds, tell the user their email is set up and ready. Give them examples of what they can ask for (check inbox, send an email, etc.).

---

### Reading Email

When the user asks to check, read, or open emails:

```bash
# Show inbox (default)
himalaya envelope list

# More results
himalaya envelope list --page-size 50

# Show a specific folder
himalaya envelope list --folder sent
himalaya envelope list --folder "INBOX.Sent"

# Read a specific email (ID from the envelope list)
himalaya message read ID

# Download attachments
himalaya attachment download ID
```

Present the results in a readable summary. For email body output, summarise the content rather than dumping raw text unless the user asks for the full message.

**Hostinger folder names** (both aliases and full paths work):

| Say | Command uses |
|-----|-------------|
| inbox | `INBOX` |
| sent | `INBOX.Sent` |
| drafts | `INBOX.Drafts` |
| trash | `INBOX.Trash` |
| junk | `INBOX.Junk` |

---

### Sending Email

**Never use `himalaya message write` without flags** — it opens `$EDITOR` interactively and blocks.

For short messages (single-line body):

```bash
himalaya message write \
  -H "To:RECIPIENT" \
  -H "Subject:SUBJECT" \
  "BODY"
```

For multi-line or formatted messages:

```bash
printf "From: FROM_EMAIL\nTo: TO_EMAIL\nSubject: SUBJECT\n\nBODY" \
  | himalaya template send
```

For messages with file attachments (MML syntax):

```bash
printf "From: FROM\nTo: TO\nSubject: SUBJECT\n\nSee attached.\n\n<#part filename=/path/to/file.pdf><#/part>" \
  | himalaya template send
```

Confirm the send to the user. If the command errors, show the error and ask if they want to retry.

---

### Replying to Email

First read the email to show the user what they are replying to:

```bash
himalaya message read ID
```

Then send the reply non-interactively using the original message ID:

```bash
# Get the message-id header
MSG_ID=$(himalaya message read ID --output json | python3 -c "import sys,json; print(json.load(sys.stdin).get('message-id',''))")

# Send reply
printf "From: FROM\nTo: ORIGINAL_SENDER\nIn-Reply-To: ${MSG_ID}\nSubject: Re: ORIGINAL_SUBJECT\n\nREPLY_BODY" \
  | himalaya template send
```

If `python3` is unavailable, skip the `In-Reply-To` header — the reply will still send, just without threading.

---

### Searching Email

```bash
# By sender
himalaya envelope list from sender@example.com

# By subject keyword
himalaya envelope list subject keyword

# Both
himalaya envelope list from sender@example.com subject meeting

# In a specific folder
himalaya envelope list --folder sent from someone@example.com
```

Show matching results to the user in a readable list.

---

### Multiple Accounts

```bash
# List all configured accounts
himalaya account list

# Use a specific account for any command
himalaya --account ACCOUNT_NAME envelope list
himalaya --account ACCOUNT_NAME message read ID
```

When the user has multiple accounts, always confirm which account to use before acting.
