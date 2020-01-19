################################################################################
##
##  This file is part of the Poseidon Kernel, and is made available under
##  the terms of the MIT License.
##
##  Copyright (C) 2020 - The Poseidon Authors
##
################################################################################

ARCH ?= x86_64

# The current profile
export PROFILE ?= debug

# Build directory, exported for recursive make invocations
export TARGET_DIRECTORY := $(shell pwd)/build

BIN := $(TARGET_DIRECTORY)/poseidon.bin
ISO := $(TARGET_DIRECTORY)/poseidon.iso
TARGET_TRIPLE := $(ARCH)-unknown-none
KERNEL := $(TARGET_DIRECTORY)/kernel/x86_64-unknown-none/debug/libkernel.a

# Do not print "Entering directory ..."
MAKEFLAGS	+=	--no-print-directory

all:	$(BIN)

$(BIN): $(ARCH) kernel
		ld --nmagic -T kernel/arch/$(ARCH)/poseidon.ld $(TARGET_DIRECTORY)/boot/*.o $(KERNEL) -o $(BIN)

$(ARCH):
		$(MAKE) -C kernel/arch/$(ARCH)

kernel:
		cargo xbuild --manifest-path kernel/Cargo.toml --target-dir $(TARGET_DIRECTORY)/kernel --target kernel/targets/$(TARGET_TRIPLE).json

$(ISO):	all
		./scripts/gen-iso.sh -o $(ISO) $(BIN)

iso:	$(ISO)

qemu:	iso
		qemu-system-$(ARCH) -cdrom $(TARGET_DIRECTORY)/poseidon.iso

clean:
		$(RM) -r $(TARGET_DIRECTORY)
		$(RM) -r kernel/xbuild/

re:		clean all

.PHONY: kernel all clean re iso qemu
