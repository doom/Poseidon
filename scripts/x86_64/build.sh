#!/bin/bash

set -eu

mkdir -p "${BUILD_DIR}/boot"
nasm -f elf64 "kernel/arch/${ARCH}/boot/multiboot2_header.asm" -o "${BUILD_DIR}/boot/multiboot2_header.o"
nasm -f elf64 "kernel/arch/${ARCH}/boot/boot.asm" -o "${BUILD_DIR}/boot/boot.o"
