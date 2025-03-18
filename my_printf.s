section .bss

    printf_buf          resb 128
    num_to_askii_buff   resb 128

section .text

global _start

_start:

.exit:
    mov rax, 60
    syscall


;--------------------------------------------------------------------
;Entry: RSI - char address
;       RDI - buffer address
;Exit:  RSI + 1, RDI + 1
;--------------------------------------------------------------------
printCharToBuffer:

    movsb               ; [rdi++] = [rsi++]

    ret

;--------------------------------------------------------------------
;Entry: RSI - decimal address
;       RDI - buffer address
;Exit:
;--------------------------------------------------------------------
convertDecToASKII:
    mov rax, [rsi]      ; rax = [rsi]
    mov bl, 10          ; bl = 10;
    xor rcx, rcx

    cmp rax, 0          ; if rax >= 0
    jge .DigitLoop

    mov ecx, 100
    neg rax             ; rax = -rax

.DigitLoop:
    xor rdx, rdx        ; rdx = 0

    div bl              ; rdx:rax / 10 = rax * 10 + rdx

    add dl, 30          ; dl += 30

    mov byte [rdi], dl  ; [rdi] = rdx
    inc rdi             ; rdi++
    inc rcx             ; rcx++

    cmp rax, 0
    jne .DigitLoop

    cmp rcx, 100
    jge .Positive

    mov byte [rdi], '-'

.Positive:

