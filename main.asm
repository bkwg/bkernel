[BITS 32]
[ORG 10000h]                    ; Main load offset

video_memory    equ 0B8000h     ; + A0 to get to the next line

PML4            equ 1000h
PDPT            equ PML4 + 1000h
PD              equ PDPT + 1000h
PT              equ PD + 1000h

e_entry_offset  equ 16 + 2 + 2 + 4
e_entry         equ elf64_image + e_entry_offset

; Code

_main:

    mov     ax, cs
    mov     ds, ax

    call    cls
    mov     esi, main_success
    call    print_string32

    call    transition_to_64bit
    jmp     $

transition_to_64bit:

    ; is long mode supported ?
    mov     eax, 0x80000000
    cpuid
    test    edx, (1 << 29)
    jz      no_lm

    jmp     init_paging

[bits 32]
    no_lm:
        mov     esi, no_long_mode
        call    die

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

cls:
    xor     ecx, ecx
    _cls:
        mov     BYTE [video_memory + ecx], 20h  ; space
        add     ecx, 2
        cmp     ecx, 0C80h                      ; A0 (160 = 80 (nb of col) * 2 (attributes) * 20
        jne     _cls

        ret

die:
    call    print_string32
    jmp     $


init_paging:
    ; See Intel 3A 9.8.5 Initializing IA-32e Mode

    ; Set PAE
    mov     eax, cr4
    or      eax, (1 << 5)
    mov     cr4, eax

    ; Clearing paging structures addresses
    mov ecx, 4
    xor eax, eax
    mov edi, PML4
    cl_pg:
        push ecx
        mov ecx, 1000h
        rep
        stosb
        add edi, 1000h
        pop ecx
        loop cl_pg

    ; Then PML4 -> PDPT -> PD -> PT -> pages frames
    mov     edi, 1000h
    mov     DWORD [edi], 00002003h
    add     edi, 1000h
    mov     DWORD [edi], 00003003h
    add     edi, 1000h
    mov     DWORD [edi], 00004003h
    add     edi, 1000h

    ; Now we map all page frames (4 KB --> 1000h)
    mov     eax, 00000003h
    mov     ecx, 512
    map_all_page_frames:
        mov     DWORD [edi], eax
        add     eax, 1000h
        add     edi, 8
        loop    map_all_page_frames

    ; We set CR3 with PML4 physical address
    mov     eax, 1000h
    mov     cr3, eax

    ; Setting IA32_EFER.LME
    mov     ecx, 0xC0000080
    rdmsr
    or      eax, (1 << 8)
    wrmsr

    ; Enabling paging
    mov     eax, cr0
    or      eax, (1 << 31)
    mov     cr0, eax

	lgdt    [gdt.pointer]
    jmp     0008h:welcome_to_64

[bits 64]
    welcome_to_64:
        mov     ax, 10h
        mov     ds, ax
        mov     es, ax
        mov     fs, ax
        mov     gs, ax
        mov     ss, ax
 
        mov     rax, QWORD [e_entry]
        add     rax, elf64_image

        ; Jump to C code
        jmp     rax

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;                                                        ;;;
;;;                         DATA                           ;;;
;;;                                                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

main_success    db "[MAIN] We are running successfully :)", 13, 10, 0
no_long_mode    db "[MAIN] LONG MODE NOT SUPPORTED", 13, 10, 0

; See AMD 4.8 Long-Mode Segment Descriptors
gdt:
.null:
    dq 0x0000000000000000

.code:
    ;p_dpl_1_type   9Ah ; 0b10011010
    ;g_d_l_avl      2h  ; 0b0010
    dq 0x00209A0000000000

.data
    ;p_dpl_1_type   92h ; 0b10010010
    ;g_b_l_avl      2h  ; 0b0010
    dq 0x0020920000000000
 
ALIGN 4
 
.pointer:
    dw $ - gdt - 1
    dd gdt

elf64_image:
incbin "kernel"
