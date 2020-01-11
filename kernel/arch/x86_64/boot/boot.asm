bits 32

section .text

global start

start:
    mov DWORD [0xb8000], 0x024b024f
    hlt
