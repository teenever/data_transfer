#!/usr/bin/env bash

# SplitMergeTransferMac.sh - Simple file split, merge, and transfer tool for macOS.
# Usage examples:
#   ./SplitMergeTransferMac.sh split 10m large.iso part_
#   ./SplitMergeTransferMac.sh merge part_a part_b merged.iso
#   ./SplitMergeTransferMac.sh scp user@host:file ./
#   ./SplitMergeTransferMac.sh ftp ftp.example.com

set -euo pipefail

print_usage() {
    cat <<USAGE
Usage: $0 <command> [arguments]
Commands:
  split <size> <file> <prefix>
  merge <part1> <part2> ... <outfile>
  scp   [scp arguments]
  sftp  [sftp arguments]
  ftp   [ftp arguments]
USAGE
}

# Split file into chunks using BSD split
cmd_split() {
    local size="$1" file="$2" prefix="$3"
    /usr/bin/split -b "$size" "$file" "$prefix"
}

# Merge parts into one file
cmd_merge() {
    local outfile="${@: -1}"               # last argument
    local parts=("${@:1:$#-1}")             # all but last
    /bin/cat "${parts[@]}" > "$outfile"
}

# Pass-through to scp
cmd_scp() { /usr/bin/scp "$@"; }

# Pass-through to sftp
cmd_sftp() { /usr/bin/sftp "$@"; }

# Invoke ftp from inetutils if available
cmd_ftp() {
    if [[ -x /usr/local/bin/ftp ]]; then
        /usr/local/bin/ftp "$@"
    else
        echo "Error: /usr/local/bin/ftp not found. Install inetutils via brew." >&2
        exit 1
    fi
}

main() {
    local cmd="${1:-}"
    shift || true
    case "$cmd" in
        split) cmd_split "$@" ;;
        merge) cmd_merge "$@" ;;
        scp)   cmd_scp "$@" ;;
        sftp)  cmd_sftp "$@" ;;
        ftp)   cmd_ftp "$@" ;;
        *) print_usage; exit 1 ;;
    esac
}

main "$@"


