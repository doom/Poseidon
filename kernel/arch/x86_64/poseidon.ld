ENTRY(start)

/* Place the kernel at 1M, the conventional address to load a kernel */
KERNEL_OFFSET = 1M;

SECTIONS
{
    . = KERNEL_OFFSET;

    .boot :
    {
        /* ensure that the multiboot header is at the beginning */
        KEEP(*(.multiboot_header))
    }

    .text :
    {
        *(.text)
    }
}
