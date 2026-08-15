# launchguard

A simple macOS application that automatically prevents other applications from launching.

## about

launchguard monitors application launches and immediately terminates any with specific bundle identifiers. It was written to stop Apple Music from launching when using Bluetooth headphones (super annoying btw), but it can also be used to block other apps.

When [installed](#installation) it runs in the background as a macOS launch agent.

## requirements

- macOS (specific versions untested)
- Xcode Command Line Tools or Clang

## installation

Install with:

```sh
git clone https://github.com/tadmccorkle/launchguard.git
cd launchguard
./run.sh install
```

The following files are installed:

- **Binary:** `~/.local/bin/launchguard`
- **Configuration:** `~/.config/launchguard/launchguard.conf`
- **Launch agent plist:** `~/Library/LaunchAgents/local.launchguard.plist`

The launch agent ensures launchguard runs automatically at login.

Uninstall with:

```sh
./run.sh uninstall
```

## configuration

Edit the configuration file at `~/.config/launchguard/launchguard.conf` and add bundle identifiers for applications you want to block, one per line. Comments starting with `#` are ignored. Configuration changes take effect immediately.

**Example configuration:**

```conf
# Blocked applications
com.apple.Music
com.google.Chrome
```

## license

The code is available under the [MIT License](./LICENSE.txt).
