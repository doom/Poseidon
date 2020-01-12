/******************************************************************************\
**
**  This file is part of the Poseidon Kernel, and is made available under
**  the terms of the MIT License.
**
**  Copyright (C) 2020 - The Poseidon Authors
**
\******************************************************************************/

ENTRY(start)

/* Place the kernel at 1M, the conventional address to load a kernel */
KERNEL_OFFSET = 1M;

SECTIONS
{
    . = KERNEL_OFFSET;

    .boot :
    {
        /* ensure that the multiboot header is at the beginning */
        KEEP(*(.multiboot2_header))
    }

    .text :
    {
        *(.text)
    }
}
