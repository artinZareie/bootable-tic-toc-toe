; By: Artin Zarei, Mohammad Mohsen Mirazei
; This is the entry point for grub to locate our OS and bring it up.

MBALIGN		EQU		1 << 0
MEMINFO		EQU		1 << 1
MBFLAGS		EQU		MBALIGN | MEMINFO
MAGIC		EQU		0x1BADB002
CHECKSUM	EQU		-(MAGIC + MBFLAGS)

SECTION .multiboot
ALIGN	16
	DD	MAGIC
	DD	MBFLAGS
	DD	CHECKSUM

SECTION .bss
ALIGN	16
stack_bottom:
	RESB 16384		; Reserve 16KiB
stack_top:

SECTION .text

	GLOBAL _start:function (_start.end - _start)

_start:
	mov esp, stack_top
	mov ebp, esp

	EXTERN _main
	call _main
	cli

.hang:
	hlt
	jmp .hang

.end:
