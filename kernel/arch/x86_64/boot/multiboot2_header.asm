section .multiboot2_header

; Multiboot 2 compliant header
; See https://www.gnu.org/software/grub/manual/multiboot2/multiboot.pdf

%define MULTIBOOT2_MAGIC        0xE85250D6      ; magic number for MultiBoot 2
%define ARCHITECTURE            0               ; 0 => i386

multiboot2_header_start:
    dd MULTIBOOT2_MAGIC
    dd ARCHITECTURE
    dd multiboot2_header_end - multiboot2_header_start

    ; Checksum
    dd 0x100000000 - (MULTIBOOT2_MAGIC + ARCHITECTURE + (multiboot2_header_end - multiboot2_header_start))

    ; The header contains a list of tags
    ; Those tags can be used to provide or request information to/from the bootloader

    ; Empty tag, marking the end of the tag list
    dw 0            ; type
    dw 0            ; flags
    dd 8            ; size
multiboot2_header_end:
