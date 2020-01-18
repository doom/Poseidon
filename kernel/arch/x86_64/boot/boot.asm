;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  This file is part of the Poseidon Kernel, and is made available under
;;  the terms of the MIT License.
;;
;;  Copyright (C) 2020 - The Poseidon Authors
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;
;;; References:
;;;
;;; Intel Architecture Software Manual, volume 3A: System Programming Guide, Part 1
;;;   https://software.intel.com/sites/default/files/managed/7c/f1/253668-sdm-vol-3a.pdf
;;;
;;; The Multiboot2 Specification version 2.0:
;;;   https://www.gnu.org/software/grub/manual/multiboot2/multiboot.pdf
;;;

bits 32

section .text

;;;
;;; Kernel starting point.
;;;
;;; The bootloader drops us here according to the multiboot's specification.
;;;
;;; The eax register should contain the multiboot2 bootloader's magic value, and
;;; we should crash if it's not the case.
;;; The ebx register should contain a pointer to the multiboot2 structure, which
;;; we'll save for later use.
;;;
;;; At this stage, the CPU is in 32-bit protected mode and paging is disabled.
;;; We must enable paging and go to long mode before executing any Rust code.
;;;
;;; NOTE: The BSS section is already cleaned by the bootloader (according to the
;;; the multiboot specification, see the note at the end of section 3.1.5)
;;;
[global start]
start:
    cli                             ;; Clear interrupt flag
    mov esp, bsp_kernel_stack_top   ;; Set-up kernel stack

    call detect_cpuid               ;; Ensure CPUID is available, panics overwise
    call detect_ia_32e              ;; Ensure IA-32e mode is available.

    call setup_paging               ;; Set up paging without enabling it
    call enable_paging              ;; Enable long-mode and paging, leaving
                                    ;; the CPU in a 32-bit compatiblity mode.

    lgdt [boot_gdt64.fatptr]        ;; Load the 64-bit GDT

    ;; Transition to 64-bit by reloading the code segment register
    ;; with the new 64-bit code segment selector
    jmp boot_gdt64.kernel_code:start64

bits 64
start64:

    ;; Reload all data segment registers with the new 64-bit data segment selector
    mov ax, boot_gdt64.kernel_data
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ;; Clear the screen
    mov rdi, 0xB8000
    mov rax, 0x0F200F200F200F20
    mov rcx, 500
    rep stosq

    ;; Write 'OK'
    mov dword [0xB8000], 0x024b024f
    hlt

bits 32

;;;
;;; Detect if the CPUID instruction is available.
;;; Panic if it is not.
;;;
detect_cpuid:
    pushfd                          ;; Mov EFLAGS to EAX through the stack
    pop eax

    mov ecx, eax                    ;; Save EFLAGS

    xor eax, 1 << 21                ;; Flip the ID bit

    push eax                        ;; Copy eax to EFLAGS
    popfd

    pushfd                          ;; Copy EFLAGS back to EAX (with the ID bit
    pop eax                         ;; flipped if CPUID is supported)

    push ecx                        ;; Restore the EFLAGS we saved earlier
    popfd

    cmp eax, ecx                    ;; Test if the bit flip was reverted by the CPU,
                                    ;; indicating that the CPUID instruction is supported

    je .panic                       ;; If CPUID isn't supported, panic
    ret

.panic:
    mov edi, boot_panic_no_cpuid
    call boot_panic                 ;; boot_panic never returns

;;;
;;; Detect if long-mode is available.
;;; Panic if it is not.
;;;
detect_ia_32e:
    mov eax, 0x80000000             ;; Retrieve the highest CPUID function supported
    cpuid
    cmp eax, 0x80000001             ;; Test if the extended processor information
    jb .no_ia_32e                   ;; can be retrieved

    mov eax, 0x80000001             ;; Retrieve the extended processor information
    cpuid
    test edx, 1 << 29               ;; Test if the "Long Mode" bit is set
    jz .no_ia_32e

    ret

.no_ia_32e:
    mov edi, boot_panic_no_ia_32e
    call boot_panic


;;;
;;; Set up paging without enabling it
;;;
;;; This function sets up a 4-level paging using 512 2MB pages, therefore
;;; mapping the first GB of virtual memory on its physical counterpart.
;;;
setup_paging:
    mov eax, boot_pdpt
    or eax, 000000000011b           ;; Present + Writable
    mov [boot_pml4], eax

    mov eax, boot_pd
    or eax, 000000000011b           ;; Present + Writable
    mov [boot_pdpt], eax

    ;; Iterate over all 512 entries of the PD, and map them using 2MB pages.
    mov ecx, 0
.map_pd:
    mov eax, 0x200000               ;; 2MB
    mul ecx                         ;; eax *= ecx
    or eax, 000010000011b           ;; Present + Writable + 2MB Page
    mov [boot_pd + ecx * 8], eax    ;; Map the entry

    inc ecx
    cmp ecx, 512
    jne .map_pd

    ret


;;;
;;; Enable paging and long mode.
;;;
;;; NOTE: The CPU is in compatibility mode when leaving this function.
;;; A 64-bit code segment must be loaded to fully transition into 64-bit.
;;;
enable_paging:
    mov ecx, 0xC0000080
    rdmsr                           ;; Read the EFER MSR
    or eax, 1 << 8                  ;; Set the LM-bit
    wrmsr                           ;; Update the EFER MSR

    mov eax, cr4
    or eax, 1 << 5                  ;; Set the PAE bit
    mov cr4, eax

    mov eax, boot_pml4              ;; Load the address of the PML4 into CR3
    mov cr3, eax

    mov eax, cr0
    or eax, 1 << 31                 ;; Enable paging
    mov cr0, eax

    ret


;;;
;;; Print an error message to the user using the VGA display.
;;; This function never returns.
;;;
;;; This is so early in the boot process that we can't rely on the
;;; usual panic utilities nor the usual logging drivers.
;;;
;;; It expects a pointer to a zero-terminated string in edi.
;;;
boot_panic:
    mov eax, 0xB8000                ;; Cursor
    mov bh, 0x07                    ;; Set the formatting

.loop:
    cmp byte [edi], 0               ;; Test if it is the end of the string
    je .endloop

    mov bl, byte [edi]
    mov word [eax], bx              ;; Print a char
    add eax, 2

    inc edi                         ;; Increment the string pointer and start again
    jmp .loop

.endloop:
    cli
    hlt
    jmp boot_panic


section .bss

;;;
;;; Bootstrap processor's kernel stack
;;;
align 4096
bsp_kernel_stack_bot:
    resb 4096 * 16                  ;; TODO FIXME: Set this as a kernel configuration option
bsp_kernel_stack_top:

;;;
;;; Boot PML4, used to transition into long mode, before paging is properly initialized
;;;
align 4096
boot_pml4:
    resb 512 * 8

;;;
;;; Boot PDPT, used to transition into long mode, before paging is properly initialized
;;;
align 4096
boot_pdpt:
    resb 512 * 8

;;;
;;; Boot PD, used to transition into long mode, before paging is properly initialized
;;;
align 4096
boot_pd:
    resb 512 * 8


section .rodata

;;;
;;; Error messages displayed on boot, before any drivers are available
;;;
boot_panic_no_cpuid     db "The CPUID instruction isn't available.", 0
boot_panic_no_ia_32e    db "The CPU doesn't support 64-bit instructions.", 0

;;;
;;; A 64-bit GDT used during boot-time.
;;;
;;; It is replaced for a dynamic GDT by the Bootstrap processor
;;; in the middle of the boot process.
;;;
;;; TODO FIXME XXX: Replace this with a Rust structure, using strong typing
;;; and self-explanatory fields.
;;;
align 16
boot_gdt64:

    ;; Null descriptor
    .null: equ $ - boot_gdt64
    dw 0                        ;; Limit (low)
    dw 0                        ;; Base (low)
    db 0                        ;; Base (middle)
    db 0                        ;; Access
    db 0                        ;; Granularity
    db 0                        ;; Base (high)

    ;; Kernel code descriptor
    .kernel_code: equ $ - boot_gdt64
    dw 0                        ;; Limit (low)
    dw 0                        ;; Base (low)
    db 0                        ;; Base (middle)
    db 10011010b                ;; Access (exec/read)
    db 10101111b                ;; Granularity, 64-bit flag, limit (high)
    db 0                        ;; Base (high)

    ;; Kernel data descriptor
    .kernel_data: equ $ - boot_gdt64
    dw 0                        ;; Limit (low)
    dw 0                        ;; Base (low)
    db 0                        ;; Base (middle)
    db 10010010b                ;; Access (read/write)
    db 00000000b                ;; Granularity
    db 0                        ;; Base (high)

    ;; The GDT Fat Pointer
    .fatptr:
    dw $ - boot_gdt64 - 1       ;; Size
    dq boot_gdt64               ;; Address
