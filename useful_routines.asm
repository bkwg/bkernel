; This file contains some useful routines that can help when debugging, etc

[BITS 32]

video_memory                equ 0B8140h     ; + A0 to get to the next line

; _In_ esp --> len
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

[BITS 16]

cls:
    mov     al, 0
    mov     bh, 7
    mov     ch, 0
    mov     cl, 0
    mov     dh, 24
    mov     dl, 79
    mov     ah, BIOS_SCROLL
    int     10h

    mov     bh, 0   ; page 0
    xor     dx, dx  ; (dh)row = 0, (dl)column = 0
    mov     ah, BIOS_SET_CURSOR
    int     10h

    ret

; _In_ si --> string to print
print_string:
    lodsb
    test    al, al
    jz      _done
    mov     ah, BIOS_TELETYPE_OUTPUT
    int     10h
    jmp     print_string

    _done:
        ret

; _In_ ax --> byte to convert
print_byte_in_hex:
    push    cx
    push    dx

    mov     cx, 2
    mov     dl, 16
    
    _div:
        div     dl

    _s2:
        push    ax
        cmp     al, 10
        jb      _add48

        _add55:
            add     al, 55
            jmp     _print

        _add48:
            add     al, 48

    _print:
        mov     ah, 0Eh
        int     10h

    pop     ax
    shr     ax, 8
    dec     cx
    test    cx, cx
    jnz     _s2

    pop     dx
    pop     cx

    ret
