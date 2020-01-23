################################################################################
##
##  This file is part of the Poseidon Kernel, and is made available under
##  the terms of the MIT License.
##
##  Copyright (C) 2020 - The Poseidon Authors
##
################################################################################

ARCH ?= x86_64

# Current profile
PROFILE ?= debug

# Build directory
TARGET_DIRECTORY := $(shell pwd)/build

BIN := $(TARGET_DIRECTORY)/poseidon.elf
ISO := $(TARGET_DIRECTORY)/poseidon.iso
TARGET_TRIPLE := $(ARCH)-unknown-none
KERNEL := $(TARGET_DIRECTORY)/kernel/$(TARGET_TRIPLE)/$(PROFILE)/libkernel.a

CARGO_FLAGS := --target kernel/targets/$(TARGET_TRIPLE).json
LDFLAGS := --nmagic

ifeq ($(PROFILE),release)
CARGO_FLAGS += --release
endif

include kernel/arch/$(ARCH)/Rules.mk

all:		$(ARCH_OBJECTS)
			cargo xbuild --manifest-path kernel/Cargo.toml --target-dir $(TARGET_DIRECTORY)/kernel $(CARGO_FLAGS)
			ld $(LDFLAGS) -T kernel/arch/$(ARCH)/poseidon.ld $(ARCH_OBJECTS) $(KERNEL) -o $(BIN)

$(ISO):		all
			./scripts/gen-iso.sh -o $(ISO) $(BIN)

iso:		$(ISO)

qemu:		iso
			qemu-system-$(ARCH) -cdrom $(TARGET_DIRECTORY)/poseidon.iso -m 512M

qemu-kvm:	iso
			qemu-system-$(ARCH) -cdrom $(TARGET_DIRECTORY)/poseidon.iso -m 512M --enable-kvm

clean:
			$(RM) -r $(TARGET_DIRECTORY)

fclean:		clean
			$(RM) -r kernel/xbuild/

re:			clean all

.PHONY: 	all clean fclean re iso qemu qemu-kvm
