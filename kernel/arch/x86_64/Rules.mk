################################################################################
##
##  This file is part of the Poseidon Kernel, and is made available under
##  the terms of the MIT License.
##
##  Copyright (C) 2020 - The Poseidon Authors
##
################################################################################


ARCH_SRCS := $(wildcard kernel/arch/$(ARCH)/boot/*.asm)
ARCH_OBJECTS := $(addprefix $(TARGET_DIRECTORY)/, $(ARCH_SRCS:kernel/arch/$(ARCH)/%.asm=%.o))

$(TARGET_DIRECTORY)/boot/%.o:	kernel/arch/$(ARCH)/boot/%.asm
		@mkdir -p "$(TARGET_DIRECTORY)/boot"
		nasm -f elf64 $< -o $@
