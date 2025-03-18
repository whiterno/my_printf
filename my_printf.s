section .bss

    printf_buf          resb 128
    num_to_askii_buff   resb 64

section .data

    format          db "Hello, I have %d children", 0xa, 0x0
    error_msg       db "Unknown specificator has occured", 0xa
    error_msg_len   dq $ - error_msg

section .rodata

.FuncTable:
    dq printBinToBuffer      ; %b
    dq printCharToBuffer     ; %c
    dq printDecToBuffer      ; %d

    dq noSuchSpecificator    ; %e
    dq noSuchSpecificator    ; %f
    dq noSuchSpecificator    ; %g
    dq noSuchSpecificator    ; %h
    dq noSuchSpecificator    ; %i
    dq noSuchSpecificator    ; %j
    dq noSuchSpecificator    ; %k
    dq noSuchSpecificator    ; %l
    dq noSuchSpecificator    ; %m
    dq noSuchSpecificator    ; %n
    dq noSuchSpecificator    ; %o
    dq noSuchSpecificator    ; %p
    dq noSuchSpecificator    ; %q
    dq noSuchSpecificator    ; %r

    dq printStringToBuffer   ; %s

    dq noSuchSpecificator    ; %t
    dq noSuchSpecificator    ; %u
    dq noSuchSpecificator    ; %v
    dq noSuchSpecificator    ; %w

    dq printHexToBuffer      ; %x

section .text

%macro GET_NUM_CHAR 1
    mov edx, 1           ; rdx = 1
    shl rdx, %1          ; rdx << %1
    dec rdx              ; rdx--

    and rdx, rax         ; rdx &= rax
    shr rax, %1          ; rax >> %1

    add rdx, 30h         ; rdx += 30h
%endmacro

%macro PRINT_CHAR_TO_BUFFER 0
    mov byte [rdi], dl  ; [rdi] = rdx
    inc rdi             ; rdi++
%endmacro

%macro COPY_FROM_NUM_BUFF_TO_PRINTF_BUFF 0
%%DigitLoop:
    dec rsi
    movsb
    dec rsi

    cmp rsi, num_to_askii_buff
    jne %%DigitLoop
%endmacro

%macro CHECK_FOR_NULL_CHAR 0
    movzx rax, byte [rsi]   ; rax = [rsi]
    cmp rax, 0              ; if (rax == 0)
%endmacro

%macro FLUSH 0
    push rax
    push rdx
    push rsi

    mov rdx, printf_buf ; rdx = &printf_buf
    sub rdx, rdi        ; rdx -= rdi
    neg rdx             ; rdx = -rdx

    mov rsi, rdi    ; rsi = rdi
    sub rsi, rdx    ; rsi -= rdx

    mov rdi, 1      ; rdi = STD_OUT

    mov rax, 1      ; rax = 1 (sys_write)
    syscall

    mov rdi, printf_buf ; rdi = printf_buf

    pop rsi
    pop rdx
    pop rax
%endmacro

global _start

;--------------------------------------------------------------------
;---------------------------MAIN-------------------------------------
;-------------------------FUNCTION-----------------------------------
;--------------------------------------------------------------------
_start:
    mov rdi, format

    push rbp
    mov rbp, rsp

    push r9
    push r8
    push rcx
    push rdx
    push 10     ; rsi needed!
    push rdi

    pop rsi
    mov rdi, printf_buf
    mov r10, 0

    ; call checkFormat
    call asmPrintf

    add rsp, 48

    pop rbp

.Exit:
    mov rax, 60
    syscall

;--------------------------------------------------------------------
;Standart printf
;Entry: RSI - format string address
;       RDI - printf buffer address
;       Stack - args for printf
;Exit:  None
;Destr:
;--------------------------------------------------------------------
asmPrintf:
    CHECK_FOR_NULL_CHAR
    je .Done

.Done:
    ret

;--------------------------------------------------------------------
;%c
;Entry: RSI - char address
;       RDI - printf buffer address
;Exit:  RSI + 1, RDI + 1
;Destr: RSI, RDI
;--------------------------------------------------------------------
printCharToBuffer:

    movsb               ; [rdi++] = [rsi++]

    ret

;--------------------------------------------------------------------
;%d
;Entry: RSI - decimal address
;       RDI - printf buffer address
;Exit:  None
;Destr: RSI, RDI
;--------------------------------------------------------------------
printDecToBuffer:

    push rdi                    ; save rdi
    mov rdi, num_to_askii_buff

    call convertDecToASKII

    mov rsi, rdi            ; rsi = rdi
    pop rdi                 ; revive rdi

    COPY_FROM_NUM_BUFF_TO_PRINTF_BUFF

    ret

;--------------------------------------------------------------------
;%x
;Entry: RSI - heximal address
;       RDI - printf buffer address
;Exit:  None
;Destr: RSI, RDI
;--------------------------------------------------------------------
printHexToBuffer:

    push rdi                    ; save rdi
    mov rdi, num_to_askii_buff

    call convertHexToASKII

    mov rsi, rdi            ; rsi = rdi
    pop rdi                 ; revive rdi

    COPY_FROM_NUM_BUFF_TO_PRINTF_BUFF

    ret

;--------------------------------------------------------------------
;%o
;Entry: RSI - octal address
;       RDI - printf buffer address
;Exit:  None
;Destr: RSI, RDI
;--------------------------------------------------------------------
printOctToBuffer:

    push rdi                    ; save rdi
    mov rdi, num_to_askii_buff

    call convertOctToASKII

    mov rsi, rdi            ; rsi = rdi
    pop rdi                 ; revive rdi

    COPY_FROM_NUM_BUFF_TO_PRINTF_BUFF

    ret

;--------------------------------------------------------------------
;%b
;Entry: RSI - binary address
;       RDI - printf buffer address
;Exit:  None
;Destr: RSI, RDI
;--------------------------------------------------------------------
printBinToBuffer:

    push rdi                    ; save rdi
    mov rdi, num_to_askii_buff

    call convertBinToASKII

    mov rsi, rdi            ; rsi = rdi
    pop rdi                 ; revive rdi

    COPY_FROM_NUM_BUFF_TO_PRINTF_BUFF

    ret

;--------------------------------------------------------------------
;%s
;Entry: RSI - string address
;       RDI - printf buffer address
;Exit:  None
;Destr: RAX, RSI, RDI
;--------------------------------------------------------------------
printStringToBuffer:

    CHECK_FOR_NULL_CHAR
    je .Done

.CharacterLoop:
    movsb

    CHECK_FOR_NULL_CHAR
    jne .CharacterLoop

.Done:
    ret

;--------------------------------------------------------------------
;Entry: RSI - decimal address
;       RDI - number to askii buffer address
;Exit:  RDI - number address end
;Destr: RAX, RBX, RCX, RDX, RSI, RDI
;--------------------------------------------------------------------
convertDecToASKII:
    mov rax, [rsi]      ; rax = [rsi]
    mov rbx, 10         ; bl = 10;
    xor rcx, rcx        ; rcx = 0

    ; check if num is negative
    cmp rax, 0          ; if rax >= 0
    jge .DigitLoop

    mov rcx, -1
    neg rax             ; rax = -rax

.DigitLoop:
    cqo                 ; rdx = 0

    div rbx             ; rdx:rax / 10 = rax * 10 + rdx

    add dl, 30h         ; dl += 30h

    PRINT_CHAR_TO_BUFFER

    cmp rax, 0          ; if (rax != 0)
    jne .DigitLoop      ;

    ; print '-' to buffer if num is negative
    cmp rcx, -1         ; if (rcx == -1)
    jne .Positive       ;

    mov byte [rdi], '-' ; [rdi] = '-'
    inc rdi             ; rdi++

.Positive:

    ret

;--------------------------------------------------------------------
;Entry: RSI - hexadecimal address
;       RDI - number to askii buffer address
;Exit:  RDI - number address end
;Destr: RAX, RBX, RDX, RSI, RDI
;--------------------------------------------------------------------
convertHexToASKII:
    mov rax, [rsi]      ; rax = [rsi]

.DigitLoop:
    GET_NUM_CHAR 4

    ; check whether it is 0..9 or a..f
    mov rbx, rdx        ; rbx = rdx
    add rbx, 27h        ; rbx += 27h

    cmp rdx, 3ah        ; if (rdx >= 3ah)
    cmovge rdx, rbx     ;     rdx = rbx

    PRINT_CHAR_TO_BUFFER

    cmp rax, 0          ; if (rax != 0)
    jne .DigitLoop      ;

    ret

;--------------------------------------------------------------------
;Entry: RSI - octal address
;       RDI - number to askii buffer address
;Exit:  RDI - number address end
;Destr: RAX, RDX, RSI, RDI
;--------------------------------------------------------------------
convertOctToASKII:
    mov rax, [rsi]      ; rax = [rsi]

.DigitLoop:
    GET_NUM_CHAR 3

    PRINT_CHAR_TO_BUFFER

    cmp rax, 0          ; if (rax != 0)
    jne .DigitLoop      ;

    ret

;--------------------------------------------------------------------
;Entry: RSI - binary address
;       RDI - number to askii buffer address
;Exit:  RDI - number address end
;Destr: RAX, RDX, RSI, RDI
;--------------------------------------------------------------------
convertBinToASKII:
    mov rax, [rsi]      ; rax = [rsi]

.DigitLoop:
    GET_NUM_CHAR 1

    PRINT_CHAR_TO_BUFFER

    cmp rax, 0          ; if (rax != 0)
    jne .DigitLoop      ;

    ret

;--------------------------------------------------------------------
;Error handler that runs when unknown specificator is occured
;Entry: None
;Exit:  None
;Destr: None
;--------------------------------------------------------------------
noSuchSpecificator:
    mov rax, 1
    mov rdi, 1
    mov rsi, error_msg
    mov rdx, [error_msg_len]
    syscall

    mov rax, 60
    mov rdi, -1
    syscall
