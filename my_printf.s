section .bss

    printf_buf          resb 128
    num_to_askii_buff   resb 128

section .data

    decimal dq 321

section .text

global _start

_start:

    mov rsi, decimal
    mov rdi, printf_buf

    call printDecToBuffer

    mov rdx, printf_buf
    sub rdx, rdi
    neg rdx

    mov rsi, rdi
    mov rdi, 1

    mov rax, 1
    syscall

.exit:
    mov rax, 60
    syscall


;--------------------------------------------------------------------
;Entry: RSI - char address
;       RDI - buffer address
;Exit:  RSI + 1, RDI + 1
;Destr: RSI, RDI
;--------------------------------------------------------------------
printCharToBuffer:

    movsb               ; [rdi++] = [rsi++]

    ret


;--------------------------------------------------------------------
;Entry: RSI - decimal address
;       RDI - buffer address
;Exit:  None
;Destr:
;--------------------------------------------------------------------
printDecToBuffer:

    push rdi                ; save rdi

    call convertDecToASKII

    mov rsi, rdi            ; rsi = rdi
    pop rdi                 ; revive rdi

.DigitLoop:
    dec rsi
    movsb
    dec rsi

    cmp rsi, num_to_askii_buff
    jne .DigitLoop

    ret

;--------------------------------------------------------------------
;Entry: RSI - decimal address
;       RDI - decimal to askii buffer address
;Exit:  RDI - decimal address end
;Destr: RAX, BL RCX, RDX, RSI, RDI
;--------------------------------------------------------------------
convertDecToASKII:
    mov rax, [rsi]      ; rax = [rsi]
    mov rbx, 10          ; bl = 10;
    xor rcx, rcx

    cmp rax, 0          ; if rax >= 0
    jge .DigitLoop

    mov rcx, -1
    neg rax             ; rax = -rax

.DigitLoop:
    cqo                 ; rdx = 0

    div rbx             ; rdx:rax / 10 = rax * 10 + rdx

    add dl, 30          ; dl += 30

    mov byte [rdi], dl  ; [rdi] = rdx
    inc rdi             ; rdi++

    cmp rax, 0
    jne .DigitLoop

    cmp rcx, -1
    jne .Positive

    mov byte [rdi], '-'
    inc rdi

.Positive:

    ret
