[BITS 32]
[ORG 10000h]    ; Main load offset


video_memory    equ 0B8140h     ; + A0 to get to the next line

; Code

_main:

    mov     ax, cs
    mov     ds, ax
    mov     esi, main_success
    call    print_string32
    jmp     $

; _In_ esi --> string to print
print_string32:
    xor     ecx, ecx

    _print32:
        lodsb 
        cmp     al, 13                              ; compare against '\n'
        jz      _done_printing
        mov     BYTE [video_memory + ecx], al
        inc     ecx
        ;mov     BYTE [video_memory + ecx], 0FFh    ; attributes (colors)
        inc     ecx
        jmp     _print32

    _done_printing:
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                        ;;
;;;                         DATA                           ;;
;;;                                                        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

main_success    db "[MAIN] We are running successfully :)", 13, 10, 0
