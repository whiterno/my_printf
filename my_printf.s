section .bss

    printf_buf          resb PRINTF_BUFF_SIZE
    num_to_askii_buff   resb NUM_BUFF_SIZE

section .data

    error_msg       db "%% : Unknown specificator has occured", 0xa
    error_msg_len   dq $ - error_msg

    STD_OUT             equ 1

    TO_LETTER_SHIFT     equ 27h
    NUM_TOP_BORDER      equ 3ah

    SEVENTH_ARG_SHIFT   equ 72
    RBP_SHIFT           equ 56

    CASE_AMOUNT         equ 23

    PRINTF_BUFF_SIZE    equ 10
    NUM_BUFF_SIZE       equ 64

section .rodata

func_table:
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

    add rdx, '0'         ; rdx += 30h
%endmacro

%macro PRINT_CHAR_TO_BUFFER 0
    mov byte [rdi], dl  ; [rdi] = rdx
    inc rdi             ; rdi++
%endmacro

%macro COPY_FROM_NUM_BUFF_TO_PRINTF_BUFF 0
%%DigitLoop:
    dec rsi             ; rsi--
    movsb               ; *(rdi++) = *(rsi++)
    dec rsi             ; rsi--

    FLUSH_IF_OVERFLOW

    cmp rsi, num_to_askii_buff      ; if (rsi == &num_to_askii_buff)
    jne %%DigitLoop
%endmacro

%macro CHECK_FOR_NULL_CHAR 0
    mov bl, byte [rsi]     ; bl = [rsi]
    cmp bl, 0              ; if (bl == 0)
%endmacro

%macro FLUSH 0
    push rax            ;
    push rdx            ; save reqisters
    push rsi            ;

    mov rdx, printf_buf ; rdx = &printf_buf
    sub rdx, rdi        ; rdx -= rdi
    neg rdx             ; rdx = -rdx

    mov rsi, rdi        ; rsi = rdi
    sub rsi, rdx        ; rsi -= rdx

    mov rdi, STD_OUT    ; rdi = STD_OUT

    mov rax, 1          ; rax = 1 (sys_write)
    syscall

    mov rdi, printf_buf ; rdi = printf_buf

    pop rsi             ;
    pop rdx             ; revive registers
    pop rax             ;
%endmacro

%macro FLUSH_IF_OVERFLOW 0
    mov rax, rdi                ; rax = rdi
    sub rax, printf_buf         ; rax -= printf_buf

    cmp rax, PRINTF_BUFF_SIZE   ; if (rax == PRINTF_BUFF_SIZE)
    jne %%Done

    FLUSH

%%Done:
%endmacro

global myPrintf

;--------------------------------------------------------------------
;---------------------------MAIN-------------------------------------
;-------------------------FUNCTION-----------------------------------
;--------------------------------------------------------------------
myPrintf:
    push rbp                ; create stack frame
    mov rbp, rsp            ;

    push r9                 ;
    push r8                 ;
    push rcx                ; save args to stack
    push rdx                ;
    push rsi                ;
    push rdi                ;

    pop rsi                 ; rsi = format string
    mov rdi, printf_buf     ; rsi = printf buffer
    mov r10, 16             ; address shift for arg

    call asmPrintf

    add rsp, 40             ; clear stack

    pop rbp                 ; revive old rbp

    ret

;--------------------------------------------------------------------
;Standart printf
;Entry: RSI - format string address
;       RDI - printf buffer address
;       Stack - args for printf
;Exit:  None
;Destr: RAX, RBX, RDX, RDI, RSI, R10
;--------------------------------------------------------------------
asmPrintf:
.Loop:
    mov rbx, SEVENTH_ARG_SHIFT          ; rbx = SEVENTH_ARG_SHIFT
    cmp r10, RBP_SHIFT                  ; if (r10 == RBP_SHIFT)
    cmove r10, rbx                      ;       r10 = rbx

    CHECK_FOR_NULL_CHAR
    je .Done

    cmp bl, '%'                         ; if (bl == '%')
    je .SpecificatorCheck

    movsb                               ; *(rdi++) = *(rsi++)

    FLUSH_IF_OVERFLOW

    jmp .Loop

.SpecificatorCheck:
    inc rsi                             ; rsi++
    movzx rbx, byte [rsi]               ; rbx = *(rsi)

    cmp rbx, '%'                        ; if (rbx == '%')
    je .Percent

    sub rbx, 'b'                        ; rbx -= 'b'
    cmp rbx, CASE_AMOUNT                ; if (rbx == CASE_AMOUNT)
    ja .Error

    push rsi                            ; save rsi
    mov rsi, rsp                        ; rsi = rsp
    add rsi, r10                        ; rsi += r10

    call [func_table + rbx * 8]         ; call specificator handler

    pop rsi                             ; revive rsi
    inc rsi                             ; rsi++
    jmp .Loop

.Percent:
    movsb                               ; *(rdi++) = *(rsi)

    FLUSH_IF_OVERFLOW

    jmp .Loop

.Error:

    call noSuchSpecificator
    inc rsi                             ; rsi++

    jmp .Loop

.Done:
    FLUSH
    ret

;--------------------------------------------------------------------
;%c
;Entry: RSI - char address
;       RDI - printf buffer address (0 if for check)
;Exit:  RSI + 1, RDI + 1, R10 + 8
;Destr: RSI, RDI
;--------------------------------------------------------------------
printCharToBuffer:
    add r10, 8              ; r10 += 8

    movsb                   ; *(rdi++) = *(rsi++)

    FLUSH_IF_OVERFLOW

    ret

;--------------------------------------------------------------------
;%d
;Entry: RSI - decimal address
;       RDI - printf buffer address (0 if for check)
;Exit:  None
;Destr: RSI, RDI
;--------------------------------------------------------------------
printDecToBuffer:
    add r10, 8                  ; r10 += 8

    push rdi                    ; save rdi
    mov rdi, num_to_askii_buff  ; rdi = &num_to_askii_buff

    call convertDecToASKII

    mov rsi, rdi                ; rsi = rdi
    pop rdi                     ; revive rdi

    COPY_FROM_NUM_BUFF_TO_PRINTF_BUFF

    ret

;--------------------------------------------------------------------
;%x
;Entry: RSI - heximal address
;       RDI - printf buffer address (0 if for check)
;Exit:  None
;Destr: RSI, RDI
;--------------------------------------------------------------------
printHexToBuffer:
    add r10, 8                  ; r10 += 8

    push rdi                    ; save rdi
    mov rdi, num_to_askii_buff  ; rdi = &num_to_askii_buff

    call convertHexToASKII

    mov rsi, rdi                ; rsi = rdi
    pop rdi                     ; revive rdi

    COPY_FROM_NUM_BUFF_TO_PRINTF_BUFF

    ret

;--------------------------------------------------------------------
;%o
;Entry: RSI - octal address
;       RDI - printf buffer address (0 if for check)
;Exit:  None
;Destr: RSI, RDI
;--------------------------------------------------------------------
printOctToBuffer:
    add r10, 8                  ; r10 += 8

    push rdi                    ; save rdi
    mov rdi, num_to_askii_buff  ; rdi = &num_to_askii_buff

    call convertOctToASKII

    mov rsi, rdi                ; rsi = rdi
    pop rdi                     ; revive rdi

    COPY_FROM_NUM_BUFF_TO_PRINTF_BUFF

    ret

;--------------------------------------------------------------------
;%b
;Entry: RSI - binary address
;       RDI - printf buffer address (0 if for check)
;Exit:  None
;Destr: RSI, RDI
;--------------------------------------------------------------------
printBinToBuffer:
    add r10, 8                  ; r10 += 8

    push rdi                    ; save rdi
    mov rdi, num_to_askii_buff  ; rdi = &num_to_askii_buff

    call convertBinToASKII

    mov rsi, rdi                ; rsi = rdi
    pop rdi                     ; revive rdi

    COPY_FROM_NUM_BUFF_TO_PRINTF_BUFF

    ret

;--------------------------------------------------------------------
;%s
;Entry: RSI - string pointer address
;       RDI - printf buffer address (0 if for check)
;Exit:  None
;Destr: RAX, RBX, RDX, RSI, RDI
;--------------------------------------------------------------------
printStringToBuffer:
    add r10, 8                  ; r10 += 8

    push rsi                    ; save rsi
    mov rsi, [rsi]              ; rsi = *(rsi)

    mov rbx, -1
    mov rax, rsi                ; save string beginning address
    dec rsi                     ; rsi--
.CountChars:
    inc rsi                     ; rsi++
    cmp byte [rsi], 0           ; if (*(rsi) == 0)
    jne .CountChars

    mov rbx, rsi                ; rbx = rsi
    sub rbx, rax                ; rbx -= rax
    inc rbx                     ; rbx++

    mov rsi, rax                ; rsi = rax

    mov rax, PRINTF_BUFF_SIZE   ; rax = PRINTF_BUFF_SIZE
    sub rax, printf_buf         ; rax -= &printf_buf
    add rax, rdi                ; rax += rdi

    cmp rbx, rax                ; if (rbx > rax)
    ja .ManualSyscall

    CHECK_FOR_NULL_CHAR
    je .Done

.CharacterLoop:
    movsb                       ; *(rdi) = *(rsi)

    FLUSH_IF_OVERFLOW

    CHECK_FOR_NULL_CHAR
    jne .CharacterLoop

.ManualSyscall:
    FLUSH

    push rdi                    ; save rdi

    mov rdx, rbx                ; rdx = rbx
    mov rdi, STD_OUT            ; rdi = STD_OUT
    mov rax, 1                  ; rax = 1 (sys_write)
    syscall

    pop rdi                     ; revive rdi

.Done:
    pop rsi                     ; revive rsi
    ret

;--------------------------------------------------------------------
;Entry: RSI - decimal address
;       RDI - number to askii buffer address
;Exit:  RDI - number address end
;Destr: RAX, RBX, RCX, RDX, RSI, RDI
;--------------------------------------------------------------------
convertDecToASKII:
    mov rax, [rsi]              ; rax = *(rsi)
    mov rbx, 10                 ; bl = 10;
    xor rcx, rcx                ; rcx = 0

    ; check if num is negative
    cmp rax, 0                  ; if rax >= 0
    jge .DigitLoop

    mov rcx, -1                 ; rcx = -1
    neg rax                     ; rax = -rax

.DigitLoop:
    cqo                         ; rdx = 0

    div rbx                     ; rdx:rax / 10 = rax * 10 + rdx

    add dl, '0'                 ; dl += '0'

    PRINT_CHAR_TO_BUFFER

    cmp rax, 0                  ; if (rax != 0)
    jne .DigitLoop              ;

    ; print '-' to buffer if num is negative
    cmp rcx, -1                 ; if (rcx == -1)
    jne .Positive               ;

    mov byte [rdi], '-'         ; *(rdi) = '-'
    inc rdi                     ; rdi++

.Positive:

    ret

;--------------------------------------------------------------------
;Entry: RSI - hexadecimal address
;       RDI - number to askii buffer address
;Exit:  RDI - number address end
;Destr: RAX, RBX, RDX, RSI, RDI
;--------------------------------------------------------------------
convertHexToASKII:
    mov rax, [rsi]                      ; rax = *(rsi)

.DigitLoop:
    GET_NUM_CHAR 4

    ; check whether it is 0..9 or a..f
    mov rbx, rdx                        ; rbx = rdx
    add rbx, TO_LETTER_SHIFT            ; rbx += 27h

    cmp rdx, NUM_TOP_BORDER             ; if (rdx >= 3ah)
    cmovge rdx, rbx                     ;     rdx = rbx

    PRINT_CHAR_TO_BUFFER

    cmp rax, 0                          ; if (rax != 0)
    jne .DigitLoop                      ;

    ret

;--------------------------------------------------------------------
;Entry: RSI - octal address
;       RDI - number to askii buffer address
;Exit:  RDI - number address end
;Destr: RAX, RDX, RSI, RDI
;--------------------------------------------------------------------
convertOctToASKII:
    mov rax, [rsi]      ; rax = *(rsi)

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
    mov rax, [rsi]      ; rax = *(rsi)

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
    push rsi                        ; save registers
    push rdi                        ;

    add rbx, 'b'                    ; rbx += 'b' (unknown spec letter)
    mov byte 1[error_msg], bl       ; *(error_msg + 1) = bl

    mov rax, 1                      ; rax = 1 (sys_write)
    mov rdi, STD_OUT                ; rdi = STD_OUT
    mov rsi, error_msg              ; rsi = &error_msg
    mov rdx, [error_msg_len]        ; rdx = *(error_msg_len)
    syscall

    pop rdi                         ; revive registers
    pop rsi                         ;

    ret
