#!/bin/bash

set -eu

function usage() {
    echo "Usage: $0 [-o OUTPUT_FILE] KERNEL_BINARY"
    exit 1
}

declare output_file="poseidon.iso"

while getopts "o:" FLAG; do
    case $FLAG in
        o)
            output_file="$OPTARG"
            ;;
        *)
            echo "Unknown option: $FLAG"
            usage
    esac
done

shift $((OPTIND - 1))

if [[ $# -ne 1 ]]; then
    usage
fi

declare kernel_path="$1"
declare kernel_basename=$(basename "$kernel_path")

declare temp_dir=$(mktemp -d)

mkdir -p "$temp_dir/boot/grub"
cp "$kernel_path" "$temp_dir/boot/$kernel_basename"

cat > "$temp_dir/boot/grub/grub.cfg" << EOF
set timeout=0

menuentry "Poseidon" {
    multiboot2 /boot/$kernel_basename
}
EOF

grub-mkrescue -o "$output_file" "$temp_dir"

rm -rf "$temp_dir"
