# Claude Cron

Native macOS SwiftUI utility that schedules recurring prompts for the Claude desktop app using cron. It stores schedules in your existing crontab and leaves unrelated jobs alone.

## How it works

Each schedule is a daily crontab line that launches the installed app with `--submit-now`. The app then activates Claude, waits one second, checks that Claude is frontmost, and presses Return.

Schedules are read from crontab on every launch. Removing a schedule removes only Claude Cron entries.

## Requirements

- macOS 13 or later
- Xcode (SwiftUI version) or the Command Line Tools (AppKit fallback)

## Build

SwiftUI version: open `ClaudeCron.xcodeproj` in Xcode and run, or archive and copy the app to `/Applications`.

AppKit fallback, no Xcode needed:

```bash
scripts/build-fallback.sh
cp -R "build/Claude Cron.app" /Applications/
open -a "Claude Cron"
```

## Permissions

Grant Claude Cron access under **System Settings > Privacy & Security > Accessibility**. Without it the app cannot press Return in Claude.

## Standalone script

`scripts/submit-claude.sh` runs the same `--submit-now` call without the window:

```bash
mkdir -p "$HOME/Library/Application Support/ClaudeCron"
cp scripts/submit-claude.sh "$HOME/Library/Application Support/ClaudeCron/submit-claude.sh"
chmod +x "$HOME/Library/Application Support/ClaudeCron/submit-claude.sh"
```

## Status

No screenshot yet. The SwiftUI project has not been built in this environment (no Xcode installed); the fallback source compiles with `clang`.

## License

MIT. See [LICENSE](LICENSE).
