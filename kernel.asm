BITS 32
VGA_WIDTH	EQU		80
VGA_HEIGHT	EQU		25

VGA_COLOR_BLACK			EQU		0
VGA_COLOR_BLUE			EQU		1
VGA_COLOR_GREEN			EQU		2
VGA_COLOR_CYAN			EQU		3
VGA_COLOR_RED			EQU		4
VGA_COLOR_MAGENTA		EQU		5
VGA_COLOR_BROWN			EQU		6
VGA_COLOR_LIGHT_GREY		EQU		7
VGA_COLOR_DARK_GREY		EQU		8
VGA_COLOR_LIGHT_BLUE		EQU		9
VGA_COLOR_LIGHT_GREEN		EQU		10
VGA_COLOR_LIGHT_CYAN		EQU		11
VGA_COLOR_LIGHT_RED		EQU		12
VGA_COLOR_LIGHT_MAGENTA		EQU		13
VGA_COLOR_LIGHT_BROWN		EQU		14
VGA_COLOR_WHITE			EQU		15

hello_string db "Hello, kernel World!", 0xA, 0 ; 0xA = line feed

terminal_color db 0

terminal_cursor_pos:
terminal_column db 0
terminal_row db 0

global _main

;--------------------------Kernel Main starts--------------------------
_main:
	mov		dh, VGA_COLOR_LIGHT_GREY
    mov		dl, VGA_COLOR_BLACK
    call	terminal_set_color
    mov		esi, hello_string
    call	terminal_write_string
    call	terminal_write_string

    cli

.hang:
    hlt
    jmp		.hang
    jmp		_main
;--------------------------Kernel Main ends--------------------------
	
; The following parts are copied from https://wiki.osdev.org/Bare_Bones_with_NASM
; So the credits go to collobarators of OSDev.

	
; IN = dl: y, dh: x
; OUT = dx: Index with offset 0xB8000 at VGA buffer
; Other registers preserved
; --------------------------terminal_getidx starts--------------------------
terminal_getidx:
    push ax; preserve registers

    shl dh, 1 ; multiply by two because every entry is a word that takes up 2 bytes

    mov al, VGA_WIDTH
    mul dl
    mov dl, al

    shl dl, 1 ; same
    add dl, dh
    mov dh, 0

    pop ax
    ret
;--------------------------terminal_getidx ends--------------------------


; IN = dl: bg color, dh: fg color
; OUT = none
;--------------------------terminal_set_color starts--------------------------
terminal_set_color:
    shl dl, 4

    or dl, dh
    mov [terminal_color], dl


    ret
;--------------------------terminal_set_color ends--------------------------

;--------------------------terminal_putentryat starts--------------------------
; IN = dl: y, dh: x, al: ASCII char
; OUT = none
terminal_putentryat:
    pusha
    call terminal_getidx
    mov ebx, edx

    mov dl, [terminal_color]
    mov byte [0xB8000 + ebx], al
    mov byte [0xB8001 + ebx], dl

    popa
    ret
;--------------------------terminal_putentryat ends--------------------------


; IN = al: ASCII char
; OUT = dx: New position
;--------------------------terminal_putchar starts--------------------------
terminal_putchar:
    mov dx, [terminal_cursor_pos] ; This loads terminal_column at DH, and terminal_row at DL

	cmp al, 0xA
    jne .nlf

	mov dh, 0
	inc dl
	jmp .cursor_moved

.nlf:
    call terminal_putentryat
    
    inc dh
    cmp dh, VGA_WIDTH
    jne .cursor_moved

    mov dh, 0
    inc dl

    cmp dl, VGA_HEIGHT
    jne .cursor_moved

    mov dl, 0


.cursor_moved:
    ; Store new cursor position 
    mov [terminal_cursor_pos], dx

    ret
;--------------------------terminal_putchar ends--------------------------

; IN = cx: length of string, ESI: string location
; OUT = none
;--------------------------terminal_write starts--------------------------
terminal_write:
    pusha
.loopy:

    mov al, [esi]
    call terminal_putchar

    dec cx
    cmp cx, 0
    je .done

    inc esi
    jmp .loopy


.done:
    popa
    ret
;--------------------------terminal_write ends--------------------------

; IN = ESI: zero delimited string location
; OUT = ECX: length of string
;--------------------------terminal_strlen starts--------------------------
terminal_strlen:
    push eax
    push esi
    mov ecx, 0
.loopy:
    mov al, [esi]
    cmp al, 0
    je .done

    inc esi
    inc ecx

    jmp .loopy


.done:
    pop esi
    pop eax
    ret
;--------------------------terminal_strlen ends--------------------------

; IN = ESI: string location
; OUT = none
;--------------------------terminal_write_string starts--------------------------
terminal_write_string:
    pusha
    call terminal_strlen
    call terminal_write
    popa
    ret
;--------------------------terminal_write_string ends--------------------------

; TODO: Change because in protected mode 0x10 interrupts are not allowed.
; IN = Nothing
; OUT = Nothing
;--------------------------terminal_clear starts--------------------------
terminal_clear:
	pusha

	mov ah, 0x06
	mov al, 0
	mov bh, 0x07
	mov ch, 0
	mov cl, 0
	mov dh, VGA_HEIGHT - 1
	mov dl, VGA_WIDTH - 1
	int 0x10

	popa
	ret
;--------------------------terminal_clear ends--------------------------
