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
ask_character_string db "Please choose X or O: ", 0
ask_repeat_string db "Please only choose one of X or O, and not any other letters: ", 0
ask_place_string db "Enter row (1-3) and column (1-3): ", 0
ask_repeat_place_string db "Invalid move! Enter row (1-3) and column (1-3): ", 0
row_format  db	"| | | |", 0
row_sep	    db	"-------", 0
player_wins_string db "Player wins!", 0
computer_wins_string db "Computer wins!", 0
tie_string db "It's a tie!", 0
game_state times 9 db 0		; 0 is empty, 1 is X and 2 is O
player_choice db -1

; Array of win conditions
win_conds   db 0, 1, 2
	    db 3, 4, 5
	    db 6, 7, 8
	    db 0, 3, 6
	    db 1, 4, 7
	    db 2, 5, 8
	    db 0, 4, 8
	    db 2, 4, 6

; PS2 set1 to ASCII
scancode_table:							; Used to convert read codes to ASCII codes.
    db 0, 27, '1234567890-=', 8, 0, 'qwertyuiop[]', 10
    db 0, 'asdfghjkl;', 0, 0, 0, 0, 'zxcvbnm,./', 0, '*'
    db 0, ' ', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db '-', 0, 0, 0, '+', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

global _main

;--------------------------Kernel Main starts--------------------------
_main:
    mov dl, VGA_COLOR_BLUE
    mov dh, VGA_COLOR_WHITE
    call terminal_set_color
    
    ; Fill the screen with chosen color.
    call terminal_clear
    
    ; Draw the game board
    call draw_board
    call ask_character

    call play

    cli

.hang:
    hlt
    jmp		.hang
    jmp		_main
;--------------------------Kernel Main ends--------------------------

;--------------------------ask_character starts--------------------------
ask_character:
    pusha
    mov ebp, esp

    mov esi, ask_character_string
    call terminal_write_string

.read_and_check:

    call read_char
    call terminal_putchar

    cmp al, 'x'
    jne .case_o

    mov byte [player_choice], 0

    jmp .done

.case_o:
    cmp al, 'o'
    jne .loop

    mov byte [player_choice], 1

    jmp .done

.loop:
    call terminal_clear
    call draw_board

    mov esi, ask_repeat_string
    call terminal_write_string

    jmp .read_and_check

.done:
    call terminal_clear
    call draw_board

    popa
    ret
;--------------------------ask_character ends--------------------------

;--------------------------draw_board starts--------------------------
draw_board:
    pusha
    mov ebp, esp

    ; Print game title
    mov byte [terminal_row], 3     ; Row 3
    mov byte [terminal_column], 34 ; (80-11)/2=34.5≈34
    mov esi, title
    call terminal_write_string

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

;--------------------------valid_cell starts--------------------------
; IN = eax (cell number)
; OUT = al (bool|is the cell valid and empty?)
valid_cell:
    cmp eax, 0
    jl .ret_false

    cmp eax, 8
    jg .ret_false

    cmp BYTE [game_state + eax], 0
    jne .ret_false

    mov al, 1
    ret

.ret_false:
    mov al, 0
    ret
;--------------------------valid_cell ends--------------------------

;--------------------------game_status starts--------------------------
; IN = NOTHING
; OUT = eax (int|0 is ongoing, 1 is X's win, 2 is O's win, 3 is tie)
game_status:
    push ecx
    push esi
    push ebx
    push edx

    mov ecx, 0

.win_check_loop:
    cmp ecx, 8
    jge .check_draw

    mov esi, ecx
    imul esi, 3
    movzx eax, BYTE [win_conds + esi]
    movzx ebx, BYTE [win_conds + esi + 1]
    movzx edx, BYTE [win_conds + esi + 2]

    mov al, BYTE [game_state + eax]
    test al, al
    jz .next_win_check

    cmp al, BYTE [game_state + ebx]
    jne .next_win_check

    cmp al, BYTE [game_state + edx]
    jne .next_win_check

    movzx eax, al
    jmp .return

.next_win_check:
    inc ecx
    jmp .win_check_loop

.check_draw:
    mov ecx, 0

.draw_loop:
    cmp ecx, 9
    jge .return_3

    mov al, BYTE [game_state + ecx]
    test al, al
    jz .return_0

    inc ecx
    jmp .draw_loop

.return_0:
    xor eax, eax
    jmp .return

.return_3:
    mov eax, 3

.return:
    pop edx
    pop ebx
    pop esi
    pop ecx
    ret
;--------------------------game_status ends--------------------------

;--------------------------compute_cell starts--------------------------
;IN=eax(int|y), edx(int|x)
;OUT=eax(int|cell number) = 3 * (y - 1) + x - 1
compute_cell:
    dec eax
    lea eax, [eax + 2 * eax]
    lea eax, [eax + edx - 1]
    ret
;--------------------------compute_cell ends--------------------------

;--------------------------ask_player starts--------------------------
; IN = NOTHING
; OUT = eax (int|cell)
ask_player:
    push ebp
    mov ebp, esp
    sub esp, 12

    push esi
    push edi
    push ebx

    mov esi, ask_place_string
    call terminal_write_string

    call read_xy
    mov [ebp - 4], eax
    mov [ebp - 8], edx

    call compute_cell
    mov [ebp - 12], eax
    jmp .loop_cond

.ask_loop:
    call terminal_clear
    call draw_board
    mov esi, ask_repeat_place_string
    call terminal_write_string

    call read_xy
    mov [ebp - 4], eax
    mov [ebp - 8], edx

    call compute_cell
    mov [ebp - 12], eax

.loop_cond
    mov eax, [ebp - 4]
    cmp eax, 1
    jl .ask_loop
    cmp eax, 3
    jg .ask_loop

    mov eax, [ebp - 8]
    cmp eax, 1
    jl .ask_loop
    cmp eax, 3
    jg .ask_loop

    mov eax, [ebp - 12]
    call valid_cell
    test al, al
    jz .ask_loop

    mov eax, [ebp - 12]

    pop ebx
    pop edi
    pop esi
    add esp, 12
    mov esp, ebp
    pop ebp
    ret
;--------------------------ask_player ends--------------------------

;--------------------------player_play ends--------------------------
;IN=Nothing
;OUT=Nothing
player_play:
    push eax
    push ebx

    call ask_player	; Now eax is cell
    movzx ebx, BYTE [player_choice]
    inc ebx

    mov BYTE game_state[eax], bl
    
    pop ebx
    pop eax
    ret
;--------------------------player_play ends--------------------------

;--------------------------backtrack starts--------------------------
; IN = (bool is_ai_turn) pushed on stack
; OUT = eax (int | score) (Because it was recursive, using stack was easier.)
backtrack:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    call game_status
    push eax            ; push game_status result

    ; Gameover conditions
    mov eax, 2
    movzx ebx, BYTE [player_choice]
    sub eax, ebx        ; eax = 2 - player_choice 
    cmp eax, [esp]
    je .return_1

    movzx eax, BYTE [player_choice]
    add eax, 1          ; eax = player_choice + 1 (player's symbol)
    cmp eax, [esp]
    je .return_m1

    mov eax, 3
    cmp eax, [esp]
    je .return_0

    mov eax, [ebp + 8]  ; Load is_ai_turn
    test eax, eax
    jz .set_max         ; If player's turn, minimize

    mov ebx, 0x80000000 ; INT_MIN (maximizing)
    jmp .loop_start

.set_max:
    mov ebx, 0x7FFFFFFF ; INT_MAX (minimizing)

.loop_start:
    mov esi, 0          ; i = 0

.loop:
    cmp esi, 9
    jge .return_best

    mov eax, esi
    call valid_cell
    test al, al
    jz .next_iteration

    ; Set cell to player's symbol
    mov eax, [ebp + 8]
    test eax, eax
    jz .set_player
    mov eax, 2
    sub eax, [player_choice]
    jmp .store_cell

.set_player:
    movzx eax, BYTE [player_choice]
    add eax, 1

.store_cell:
    mov BYTE [game_state + esi], al

    ; Recursive call with flipped is_ai_turn
    mov eax, [ebp + 8]
    xor eax, 1
    push eax
    call backtrack
    add esp, 4

    ; Restore cell
    mov BYTE [game_state + esi], 0

    ; Update best_score
    mov edx, [ebp + 8]
    test edx, edx
    jz .minimize

    ; Maximize
    cmp eax, ebx
    jle .next_iteration
    mov ebx, eax
    jmp .next_iteration

.minimize:
    ; Minimize
    cmp eax, ebx
    jge .next_iteration
    mov ebx, eax

.next_iteration:
    inc esi
    jmp .loop

.return_best:
    mov eax, ebx
    jmp .done

.return_0:
    mov eax, 0
    jmp .done

.return_m1:
    mov eax, -1
    jmp .done

.return_1:
    mov eax, 1

.done:
    add esp, 4
    pop edi
    pop esi
    pop ebx
    pop ebp
    ret
;--------------------------backtrack ends--------------------------

;--------------------------computer_play starts--------------------------
computer_play:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    mov ecx, -1           ; best_move = -1
    mov ebx, 0x80000000   ; best_score = INT_MIN

    mov esi, 0            ; i = 0

.loop:
    cmp esi, 9
    jge .check_best_move

    mov eax, esi
    call valid_cell
    test al, al
    jz .next_iteration

    ; Set cell to AI's symbol
    mov eax, 2
    sub eax, [player_choice]
    mov BYTE [game_state + esi], al

    ; Call backtrack(false)
    push DWORD 0
    call backtrack
    add esp, 4

    ; Restore cell
    mov BYTE [game_state + esi], 0

    ; Update best_score and best_move
    cmp eax, ebx
    jle .next_iteration
    mov ebx, eax
    mov ecx, esi

.next_iteration:
    inc esi
    jmp .loop

.check_best_move:
    cmp ecx, -1
    je .done

    ; Apply best_move
    mov eax, 2
    sub eax, [player_choice]
    mov BYTE [game_state + ecx], al

.done:
    pop edi
    pop esi
    pop ebx
    pop ebp
    ret
;--------------------------computer_play ends--------------------------

;--------------------------play starts--------------------------
; IN = NOTHING
; OUT = NOTHING
play:
    pusha

.game_loop:
    call game_status
    cmp eax, 0
    jne .game_over

    mov al, [player_choice]
    cmp al, 0
    jne .computer_first

.player_first:
    call terminal_clear
    call draw_board
    call player_play

    call game_status
    cmp eax, 0
    jne .game_over

    call computer_play
    jmp .game_loop

.computer_first:
    call computer_play

    call terminal_clear
    call draw_board

    call game_status
    cmp eax, 0
    jne .game_over

    call player_play
    jmp .game_loop

.game_over:
    call terminal_clear
    call draw_board

    movzx ebx, BYTE [player_choice]
    inc ebx
    call game_status
    cmp eax, 3
    je .tie
    cmp eax, ebx
    je .player_wins
    jne .computer_wins

.player_wins:
    ; Print "Player wins!"
    mov esi, player_wins_string
    call terminal_write_string
    jmp .end

.computer_wins:
    ; Print "Computer wins!"
    mov esi, computer_wins_string
    call terminal_write_string
    jmp .end

.tie:
    ; Print "It's a tie!"
    mov esi, tie_string
    call terminal_write_string

.end:
    popa
    ret
;--------------------------play ends--------------------------
	
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

;--------------------------read_char starts--------------------------
; OUT = AL: ASCII character. Everything will be lower-case.
read_char:
    push edx
    push ecx
.wait_for_key:
    ; Check if keyboard has data
    in al, 0x64
    test al, 1
    jz .wait_for_key

    ; Read scancode
    in al, 0x60

    ; Check if key is released (ignore)
    test al, 0x80
    jnz .wait_for_key

    ; Convert scancode to ASCII
    movzx eax, al
    mov al, [scancode_table + eax]

    test al, al      ; Ignore unmapped keys
    jz .wait_for_key

.done:
    pop ecx
    pop edx
    ret
;--------------------------read_char ends--------------------------

;--------------------------read_xy starts--------------------------
; OUT = EAX (int | x), EDX (int | y)
read_xy:
.read_x:
    call read_char
    sub al, '0'
    cmp al, 9
    ja .read_x
    movzx edx, al

.read_y:
    call read_char
    sub al, '0'
    cmp al, 9
    ja .read_y
    movzx eax, al

    ret
;--------------------------read_xy ends--------------------------
