# ✿ sakura terminal for Windows ✿

A cherry blossom makeover for Windows Terminal + PowerShell 7, with a few Claude Code helpers.
Inspired by marinasofia/sakura-terminal (Mac/Ghostty).

## Install

Needs Windows Terminal, PowerShell 7 (`winget install Microsoft.PowerShell`), and Claude Code for the Claude bits.
In PowerShell 7, from this folder:

```powershell
Get-ChildItem -Recurse | Unblock-File   # only needed if you downloaded it as a zip
./install.ps1
```

It lists every change and waits for `y`. Then reopen Windows Terminal and pick the **Sakura** profile
(make it the default under Settings > Startup > Default profile).

`./install.ps1 -SkipStatusLine` leaves Claude Code's status line alone. `./uninstall.ps1` puts everything back.

## What you get

| type or press | what happens |
| :--- | :--- |
| new tab | the blossom greeting: next todo, current folder + branch, your last Claude chat, the moon |
| **ctrl + /** or `menu` | searchable menu of everything |
| **alt + w** | type a command, press alt+w instead of enter, and Claude explains it and rates it SAFE / CAREFUL / RISKY. The command stays on your line |
| `what` | same thing, paste a command at the prompt |
| `ask` | one or two line answer from Claude |
| `todo`, `todo add`, `todo done 2`, `todo edit` | tiny todo list (`todo buy milk` also adds) |
| `cl`, `cl -c` | start Claude Code, or continue the last chat in this folder |
| `bloom` | show the greeting again |
| `sakura-config` | change your name, turn the greeting or prompt off, or change the model `what`/`ask` use |

Claude Code also gets a pink status line: model, how full the chat is (with a nudge past 70%), cost, time, lines changed, folder and branch.

## Notes

- `what` and `ask` run `claude -p` with the Haiku model from `~/.sakura/scratch`, so they cost a little and stay out of your chat history and the greeting.
- Always use alt+w or the `what` paste prompt for commands with `|` or `;` in them. Typing `what a | b` directly lets PowerShell run the `| b` part.
- `cl` shadows the MSVC compiler `cl.exe` inside Visual Studio developer shells. Delete `function cl` from `~/.sakura/sakura.ps1` if you need it.
- Your todos live in `~/.sakura/todo.txt`, settings in `~/.sakura/config.json`. Reinstalling never overwrites them.
