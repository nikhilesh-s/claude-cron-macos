# Claude Cron

Small native macOS SwiftUI utility for daily recurring Claude prompt submissions. It stores schedules in the user's existing crontab and preserves unrelated jobs.

## Build without Xcode

The included native AppKit fallback builds with the macOS Command Line Tools:

```bash
mkdir -p "build/Claude Cron.app/Contents/MacOS"
clang -fobjc-arc ClaudeCron/ClaudeCronFallback.m \
  -o "build/Claude Cron.app/Contents/MacOS/Claude Cron" \
  -framework Cocoa -framework ApplicationServices -mmacosx-version-min=13.0
```

Then add the `Info.plist` from the existing build bundle and run:

```bash
cp -R "build/Claude Cron.app" /Applications/
open -a "Claude Cron"
```

`ClaudeCron.xcodeproj` contains the SwiftUI source version for use on a machine with Xcode.

## Install and run

Copy the built `ClaudeCron.app` to `/Applications`, launch it, and grant Claude Cron access under **System Settings → Privacy & Security → Accessibility**. The app's scheduled cron entries launch the installed app with `--submit-now`; the app then activates Claude, waits one second, verifies Claude is frontmost, and presses Return.

The included `scripts/submit-claude.sh` is a standalone equivalent and can be installed with:

```bash
mkdir -p "$HOME/Library/Application Support/ClaudeCron"
cp scripts/submit-claude.sh "$HOME/Library/Application Support/ClaudeCron/submit-claude.sh"
chmod +x "$HOME/Library/Application Support/ClaudeCron/submit-claude.sh"
```

Schedules are daily and are read from crontab on every launch. Removing a schedule only removes Claude Cron entries; unrelated crontab lines remain intact.
