[BITS 16]
[ORG 0x7C00]        ; BIOS loads us at 0000:0x7c00 and INT 19h,
                    ; so we make NASM take this into account in the flat bin
                    ; TODO: check -boot-load-seg

; Some symbolic values to make things a little bit clearer

BIOS_TELETYPE_OUTPUT            equ     0Eh
BIOS_SET_CURSOR                 equ     2h
BIOS_SCROLL                     equ     6h

MAIN_OFFSET                     equ     0000h
MAIN_SEGMENT                    equ     1000h

PM_MAIN                         equ     MAIN_SEGMENT * 16

PM_STACK_SEGMENT                equ     60000h

; TODO: Optimally, I should use BIOS functions to get these values
; dynamically... like the BIOS did to launch us.

VDISK_LBA                       equ     1Bh
MAIN_LBA                        equ     VDISK_LBA + 1

; Code

_main:

    ; set up a quick ds and ss
    mov     ax, cs
    mov     ds, ax
    mov     sp, stacktop

    call    load_main

    ; RM to PM preparation -> Intel 3a - 9.9.1

    ; disable software interrupts
    cli

    ; disable NMI
    mov     al, 70h
    out     80h, al

    ; mask all PIC interrupts
    mov     al, 0FFh
    out     0A1h, al
    mov     al, 0FBh
    out     21h, al

    ; enable the A20 line the fast way
    in      al, 92h
	or      al, 2h
	out     92h, al

    ; load the GDT
	xor     ax, ax
	mov     ds, ax
	lgdt    [ds:gdt]

    ; set cr0.PE
	mov     eax, cr0
	or      eax, 1
	mov     cr0, eax

    ; reload cs
	jmp     0008h:reload_seg_regs

[BITS 32]       ; no more mistakes allowed now

reload_seg_regs:

    ; reload data segment registers
    mov     ax, 10h
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax
    mov     ss, ax

    ; define the new stack
    mov esp, PM_STACK_SEGMENT

    ; transfer control to 32-bit code
    jmp     PM_MAIN
 
[BITS 16]

load_main:

    call    reset_drive
    jc      _die

    call    read_sector
    jc      _die
    cld
    mov     si, main_success
    call    print_string

    ret

    _die:
        call    die
    
die:        ; print error msg and halt execution
    mov     si, drive_error
    call    print_string
    jmp     $

read_sector:
    mov     ax, cs
    mov     ds, ax
    mov     si, DAP
    xor     ax, ax
    mov     ah, 42h
    int     13h
    ret

reset_drive:
    xor     ax, ax
    int     13h
    jc      die

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                        ;;
;;;                         DATA                           ;;
;;;                                                        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

align 8
gdt_base:

    ; NULL SEGMENT
	dq 0x0000000000000000

    ; CODE SEGMENT DPL = 0
        ;segment_limit   dw  FFFF
        ;base_address    dw  0000
        ;base2316        db  00
        ;p_dpl_type      db  9Ah ; 0b10011010
        ;g_d_0_avl       db  CFh ; 0b11001111
        ;base3124        db  00 

	dq 0x00CF9A000000FFFF

    ; DATA SEGMENT DPL = 0
        ;segment_limit   dw  FFFF
        ;base_address    dw  0000
        ;base2316        db  00
        ;p_dpl_type      db  96h ; 0b10010010
        ;g_b_0_avl       db  CFh ; 0b11001111
        ;base3124        db  00 

	dq 0x00CF92000000FFFF

gdt:
	dw (gdt - gdt_base) - 1
	dd gdt_base

; (C x TH x TS) + (H x TS) + (S - 1) = LBA
; DAP : Disk Address Packet
DAP:
    dap_size:   db   10h
    unused:     db   00h
    sec2read:   dw   01h
    buffer:     dw   MAIN_OFFSET, MAIN_SEGMENT
    lba:        dq   MAIN_LBA

main_success    db  "[STAGE0] Loaded main successfully", 13, 10, 0
drive_error     db  "[STAGE0] Something went wrong with a disk op :(", 13, 10, 0

stackbottom:
    align   2
    TIMES   64 dw 0
stacktop:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                        ;;
;;;                 FILL AND SIGNATURE                     ;;
;;;                                                        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


TIMES 510-($-$$) db 0   ; NASM doc 12.1.4 ($ is an offset not a pure number,
                        ; so is $$, ($-$$) makes a pure number

db 0x55, 0xAA           ; Bootable partition signature
