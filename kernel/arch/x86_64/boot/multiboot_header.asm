section .multiboot_header

; Multiboot 2 compliant header
; See https://www.gnu.org/software/grub/manual/multiboot2/multiboot.pdf

%define MULTIBOOT_MAGIC         0xE85250D6      ; magic number for MultiBoot 2
%define ARCHITECTURE            0               ; 0 => i386

multiboot_header_start:
    dd MULTIBOOT_MAGIC
    dd ARCHITECTURE
    dd multiboot_header_end - multiboot_header_start

    ; Checksum
    dd 0x100000000 - (MULTIBOOT_MAGIC + ARCHITECTURE + (multiboot_header_end - multiboot_header_start))

    ; The header contains a list of tags
    ; Those tags can be used to provide or request information to/from the bootloader

    ; Empty tag, marking the end of the tag list
    dw 0            ; type
    dw 0            ; flags
    dd 8            ; size
multiboot_header_end:
