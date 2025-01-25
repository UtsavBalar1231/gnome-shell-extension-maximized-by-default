#!/bin/sh

set -e

# Configuration
EXT_NAME="gnome-shell-extension-maximized-by-default"
SRC_DIR="src"
DIST_DIR="dist"
EXT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/gnome-shell/extensions"

# ANSI escape codes (compatible with POSIX)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Error handling
die() {
	printf "${RED}Error: ${NC}%s\n" "$1" >&2
	exit 1
}

# Check required commands
check_cmd() {
	for cmd in "$@"; do
		command -v "$cmd" >/dev/null 2>&1 || die "'$cmd' not found"
	done
}

# Extract UUID from metadata.json
get_uuid() {
	metadata="$1"
	uuid=$(grep '"uuid":' "$metadata" | sed -E 's/.*"uuid": "([^"]+)".*/\1/')
	[ -n "$uuid" ] && printf "%s" "$uuid" || die "Failed to extract UUID"
}

# Build extension package
build_extension() {
	check_cmd zip
	[ -d "$SRC_DIR" ] || die "Source directory $SRC_DIR not found"

	metadata="$SRC_DIR/metadata.json"
	[ -f "$metadata" ] || die "metadata.json not found"

	uuid=$(get_uuid "$metadata")
	output="$DIST_DIR/${EXT_NAME}.zip"

	printf "${YELLOW}Building %s...${NC}\n" "$output"
	mkdir -p "$DIST_DIR"

	# Create zip with POSIX-compliant options
	(
		cd "$SRC_DIR" && zip -qr "../$output" . \
			-x "*~" "*.sw[po]" "*.bak" "__pycache__" "*.py[co]" ".DS_Store"
	) || die "Failed to create zip archive"

	printf "${GREEN}Built: %s${NC}\n" "$output"
}

# Install extension
install_extension() {
	check_cmd unzip
	[ -d "$SRC_DIR" ] || die "Source directory $SRC_DIR not found"

	# Auto-build if dist doesn't exist
	if [ ! -f "$DIST_DIR/${EXT_NAME}.zip" ]; then
		printf "${YELLOW}Package not found, building...${NC}\n"
		build_extension
	fi

	# Extract UUID from built package
	temp_dir=$(mktemp -d)
	trap 'rm -rf "$temp_dir"' EXIT

	unzip -q "$DIST_DIR/${EXT_NAME}.zip" metadata.json -d "$temp_dir" ||
		die "Failed to extract metadata.json"

	uuid=$(get_uuid "$temp_dir/metadata.json")
	target_dir="$EXT_DIR/$uuid"

	[ -d "$target_dir" ] && die "Extension already installed. Uninstall first."

	# Install extension
	mkdir -p "$target_dir"
	unzip -q "$DIST_DIR/${EXT_NAME}.zip" -d "$target_dir" ||
		die "Failed to install extension"

	printf "${GREEN}Installed: %s${NC}\n" "$uuid"
	printf "Restart GNOME Shell (Alt+F2 → r) to enable\n"
}

# Uninstall extension
uninstall_extension() {
	[ -d "$SRC_DIR" ] || die "Source directory $SRC_DIR not found"
	metadata="$SRC_DIR/metadata.json"
	[ -f "$metadata" ] || die "metadata.json not found"

	uuid=$(get_uuid "$metadata")
	target_dir="$EXT_DIR/$uuid"

	[ -d "$target_dir" ] || die "Extension not installed"

	rm -rf "$target_dir"
	printf "${GREEN}Uninstalled: %s${NC}\n" "$uuid"
	printf "Restart GNOME Shell (Alt+F2 → r) to complete\n"
}

# Main entry point
main() {
	case "${1:-}" in
	install)
		install_extension
		;;
	uninstall)
		uninstall_extension
		;;
	*)
		printf "Usage: %s (install|uninstall)\n" "$0"
		exit 1
		;;
	esac
}

main "$@"
