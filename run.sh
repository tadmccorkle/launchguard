#!/bin/sh
set -e

LG_DIR="$(dirname $0)"
LG_MAIN="$LG_DIR/main.m"
LG_BUILD_DIR="$LG_DIR/bin"
LG_CFG_SRC="$LG_DIR/launchguard.conf"

LG_BINARY_NAME="launchguard"
LG_LABEL="local.launchguard"

LG_LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
LG_INSTALL_DIR="$HOME/.local/bin"
LG_CFG_DIR="$HOME/.config/launchguard"

LG_INSTALL_PATH="$LG_INSTALL_DIR/$LG_BINARY_NAME"
LG_CFG_PATH="$LG_CFG_DIR/launchguard.conf"
LG_PLIST_PATH="$LG_LAUNCH_AGENTS_DIR/$LG_LABEL.plist"

usage() {
	echo "Usage: $0 <command>"
	echo ""
	echo "Commands:"
	echo "  build       Compile launchguard"
	echo "  install     Compile and install launchguard"
	echo "  uninstall   Remove launchguard and its launch agent"
	echo "  help        Display detailed help information"
	echo ""
}

build() {
	mkdir -p "$LG_BUILD_DIR"
	clang "$LG_MAIN" -fobjc-arc -framework Cocoa -o "$LG_BUILD_DIR/$LG_BINARY_NAME" "$@"
}

install() {
	if [ ! -f "$LG_MAIN" ]; then
		echo "Error: Source file not found: $LG_MAIN"
		exit 1
	fi

	echo "Installing launchguard..."

	build
	mkdir -p "$LG_INSTALL_DIR"
	cp "$LG_BUILD_DIR/$LG_BINARY_NAME" "$LG_INSTALL_PATH"
	echo "  Binary installed: $LG_INSTALL_PATH"

	if [ ! -f "$LG_CFG_PATH" ]; then
		mkdir -p "$LG_CFG_DIR"
		if [ ! -f "$LG_CFG_SRC" ]; then
			touch "$LG_CFG_PATH"
			echo "  Empty config installed: $LG_CFG_PATH"
		else
			cp "$LG_CFG_SRC" "$LG_CFG_PATH"
			echo "  Config installed: $LG_CFG_PATH"
		fi
	else
		echo "  Found existing config: $LG_CFG_PATH"
	fi

	mkdir -p "$LG_LAUNCH_AGENTS_DIR"
	cat > "$LG_PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LG_LABEL</string>

    <key>ProgramArguments</key>
    <array>
        <string>$LG_INSTALL_PATH</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF
	echo "  Launch agent created: $LG_PLIST_PATH"

	launchctl bootout "gui/$UID/$LG_LABEL" 2>/dev/null || true
	launchctl bootstrap "gui/$UID" "$LG_PLIST_PATH"
	echo "  Launch agent loaded"

	echo ""
	echo "Installation complete!"
	echo ""
	echo "  Installation path: $LG_INSTALL_PATH"
	echo "  Launch agent label: $LG_LABEL"
	echo ""
	echo "To customize blocked applications, edit: $LG_CFG_PATH"
}

uninstall() {
	echo "Uninstalling launchguard..."

	if launchctl print "gui/$UID/$LG_LABEL" > /dev/null 2>&1; then
		launchctl bootout "gui/$UID/$LG_LABEL" > /dev/null 2>&1 || true
		echo "  Launch agent unloaded"
	fi

	if pkill "$LG_BINARY_NAME" 2>/dev/null; then
		echo "  Process terminated"
	fi

	if [ -f "$LG_PLIST_PATH" ]; then
		rm "$LG_PLIST_PATH"
		echo "  Removed: $LG_PLIST_PATH"
	fi

	if [ -f "$LG_INSTALL_PATH" ]; then
		rm "$LG_INSTALL_PATH"
		echo "  Removed: $LG_INSTALL_PATH"
	fi

	echo ""
	echo "Uninstallation complete!"
}

help() {
	cat <<EOF
launchguard - Automatically prevent applications from launching

COMMANDS:
    build
        Compile launchguard from source.

    install
        Compile launchguard from source and install it.

    uninstall
        Remove launchguard binary and its launch agent.

    help
        Display this help message.

CONFIGURATION:
    Edit $LG_CFG_PATH and add bundle identifiers of blocked applications, one per line.
    Comment lines starting with '#' are ignored.

    Example:
        # blocked apps:
        com.apple.Music
        com.google.Chrome

FILES:
    - Binary: $LG_INSTALL_PATH
    - Config: $LG_CFG_PATH
    - Launch Agent: $LG_PLIST_PATH

EOF
}

if [ "$#" -eq 0 ]; then usage && exit 1; else "$@"; fi
