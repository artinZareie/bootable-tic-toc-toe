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

terminal_color db 0

terminal_cursor_pos:
terminal_row db 0
terminal_column db 0

; Game data
title db "Tic Tac Toe", 0
row_format  db	"| | | |", 0
row_sep	    db	"-------", 0
game_state times 9 db 0		; 0 is empty, 1 is X and 2 is O
current_player db 1

global _main

;--------------------------Kernel Main starts--------------------------
_main:
    mov dl, VGA_COLOR_BLUE
    mov dh, VGA_COLOR_WHITE
    call terminal_set_color
    
    ; Fill the screen with chosen color.
    call terminal_clear
    
    ; Print game title
    mov byte [terminal_row], 3     ; Row 3
    mov byte [terminal_column], 34 ; (80-11)/2=34.5≈34
    mov esi, title
    call terminal_write_string
    
    ; Initialize test game state (X in corners, O in center)
    mov byte [game_state], 1
    mov byte [game_state + 4], 2
    mov byte [game_state + 8], 1
     
    ; Draw the game board
    call draw_board

    mov esi, title
    call terminal_write_string

    cli

.hang:
    hlt
    jmp		.hang
    jmp		_main
;--------------------------Kernel Main ends--------------------------

;--------------------------draw_board starts--------------------------
draw_board:
    pusha
    mov ebp, esp

    mov byte [terminal_row], 4
    mov byte [terminal_column], 36 ; (80-7)/2=36.5≈36
    mov esi, row_sep
    call terminal_write_string

    mov ecx, 3
    mov al, 5

.write_format_loop:
    mov byte [terminal_row], al
    mov byte [terminal_column], 36 ; (80-7)/2=36.5≈36
    mov esi, row_format
    call terminal_write_string
    inc eax

    mov byte [terminal_row], al
    mov byte [terminal_column], 36 ; (80-7)/2=36.5≈36
    mov esi, row_sep
    call terminal_write_string
    inc eax

    LOOP .write_format_loop

    mov ecx, 9

.fill_screen:
    lea eax, [ecx - 1]
    xor edx, edx
    mov bx, 3
    div bx		    ; eax = row, edx = column

    mov bl, BYTE game_state[ecx - 1] ; Load the character to bl

    test bl, bl		    ; Check if bl == 0
    je  .no_state

    lea eax, [2 * eax + 5]
    lea edx, [2 * edx + 37]

    mov dh, dl            ; dh = column (from edx's lower byte)
    mov dl, al            ; dl = row (from eax's lower byte)

    cmp bl, 1
    je  .x_state

.o_state:
    mov al, 'O'
    jmp .write_entry

.x_state:
    mov al, 'X'

.write_entry:
    call terminal_putentryat

.no_state:
    dec ecx
    test ecx, ecx
    jnz .fill_screen

    mov WORD [terminal_cursor_pos], 0xB	    ; Move cursor to the 11th line.

    popa
    ret
;--------------------------draw_board ends--------------------------
	
; The following parts are copied from https://wiki.osdev.org/Bare_Bones_with_NASM
; So the credits go to collobarators of OSDev.

	
; IN = dl: y, dh: x
; OUT = dx: Index with offset 0xB8000 at VGA buffer
; Other registers preserved
; --------------------------terminal_getidx starts--------------------------
terminal_getidx:
    push eax
    push ebx

    mov ax, VGA_WIDTH
    mul dl
    movzx bx, dh
    add ax, bx
    shl ax, 1
    mov dx, ax

    pop ebx
    pop eax
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

    cmp dl, VGA_HEIGHT
    jne .not_out_of_screen

    call terminal_clear

.not_out_of_screen:

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

; IN = Nothing
; OUT = sets dx to 0
;--------------------------terminal_clear starts--------------------------
terminal_clear:
    pusha

    mov edi, 0xB8000
    mov ecx, VGA_WIDTH * VGA_HEIGHT
    mov al, 0x20
    mov ah, [terminal_color]

.loop:
    mov [edi], ax
    add edi, 2
    loop .loop

    mov word [terminal_cursor_pos], 0

    popa

    mov dx, 0

    ret
;--------------------------terminal_clear ends--------------------------
