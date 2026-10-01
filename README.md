# ✿ comfy terminal for Windows ✿

A cozy makeover (with a little potted plant that has a face) for Windows Terminal + PowerShell 7, with a few Claude Code helpers.
Inspired by marinasofia/sakura-terminal (Mac/Ghostty).

## Install

Needs Windows Terminal, PowerShell 7 (`winget install Microsoft.PowerShell`), and Claude Code for the Claude bits.
In PowerShell 7, from this folder:

```powershell
Get-ChildItem -Recurse | Unblock-File   # only needed if you downloaded it as a zip
./install.ps1
```

It lists every change and waits for `y`. Then reopen Windows Terminal and pick the **Comfy** profile
(make it the default under Settings > Startup > Default profile).

`./install.ps1 -SkipStatusLine` leaves Claude Code's status line alone. `./uninstall.ps1` puts everything back.

## What you get

| type or press | what happens |
| :--- | :--- |
| new tab | the plant greeting (it wiggles and blinks): current folder + branch, your last Claude chat, the moon |
| **ctrl + /** or `menu` | searchable menu of everything |
| **alt + w** | type a command, press alt+w instead of enter, and Claude explains it and rates it SAFE / CAREFUL / RISKY. The command stays on your line |
| `who` | mini game: who's that pokémon? Read a description, guess the name (3 tries each) |
| `ask` | one or two line answer from Claude |
| `cl`, `cl -c` | start Claude Code (or continue the last chat in this folder). In Windows Terminal the plant stays pinned in a pane on top and Claude opens below it |
| `bloom` | show the greeting again |
| `comfy-config` | change your name, turn the greeting or prompt off, or change the model alt+w/`ask` use |

Claude Code also gets a pink theme (pick it any time in `/theme` as **Comfy**) and a pink status line: model, how full the chat is (🌸 plenty of room, 🍵 halfway, 🌙 time to wrap up), time, lines changed, folder and branch.
When Claude finishes or needs you, the terminal's taskbar button flashes until you click back in (nothing happens if the window is already in front).

## VS Code

The prompt, keys, greeting and commands load in VS Code too (both the plain pwsh terminal and the
PowerShell extension's terminal). Set PowerShell 7 as the default terminal, and for the pink colors
add this to your VS Code `settings.json` (Ctrl+Shift+P > Preferences: Open User Settings (JSON)):

```json
"terminal.integrated.defaultProfile.windows": "PowerShell",
"terminal.integrated.fontFamily": "Cascadia Mono",
"workbench.colorCustomizations": {
  "terminal.background": "#24273A", "terminal.foreground": "#FCE4EE",
  "terminalCursor.foreground": "#F7B6CC", "terminal.selectionBackground": "#5B6078",
  "terminal.ansiBlack": "#494D64", "terminal.ansiRed": "#F2798F", "terminal.ansiGreen": "#A8D8B9",
  "terminal.ansiYellow": "#F6D38B", "terminal.ansiBlue": "#B9A6F0", "terminal.ansiMagenta": "#E39BD6",
  "terminal.ansiCyan": "#9ED9DF", "terminal.ansiWhite": "#FCE4EE",
  "terminal.ansiBrightBlack": "#9C7A8E", "terminal.ansiBrightRed": "#FF9DB0",
  "terminal.ansiBrightGreen": "#C4EBD1", "terminal.ansiBrightYellow": "#FBE3AE",
  "terminal.ansiBrightBlue": "#D2C5F7", "terminal.ansiBrightMagenta": "#F2BDE6",
  "terminal.ansiBrightCyan": "#C0EBEF", "terminal.ansiBrightWhite": "#FFF5F9"
}
```

## Notes

- alt+w and `ask` run `claude -p` with the Haiku model from `~/.comfy/scratch`, so they cost a little and stay out of your chat history and the greeting.
- alt+w is safe for commands with `|` or `;` in them, since nothing on the line runs.
- `cl` shadows the MSVC compiler `cl.exe` inside Visual Studio developer shells. Delete `function cl` from `~/.comfy/comfy.ps1` if you need it.
- Settings live in `~/.comfy/config.json`. Reinstalling never overwrites them.
