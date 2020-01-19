################################################################################
##
##  This file is part of the Poseidon Kernel, and is made available under
##  the terms of the MIT License.
##
##  Copyright (C) 2020 - The Poseidon Authors
##
################################################################################


SRCS = $(wildcard boot/*.asm)
OBJS = $(addprefix $(TARGET_DIRECTORY)/, $(SRCS:%.asm=%.o))

all: $(OBJS)

$(TARGET_DIRECTORY)/boot/%.o:	boot/%.asm
		@mkdir -p "$(TARGET_DIRECTORY)/boot"
		nasm -f elf64 $< -o $@

clean:
		$(RM) $(OBJS)

.PHONY:	all clean
