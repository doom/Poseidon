;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  This file is part of the Poseidon Kernel, and is made available under
;;  the terms of the MIT License.
;;
;;  Copyright (C) 2020 - The Poseidon Authors
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bits 32

section .text

global start

start:
    mov DWORD [0xb8000], 0x024b024f
    hlt
