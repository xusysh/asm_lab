SDISP   EQU  7c00h
section text
bits 16

Begin:
	mov ax,cs
	mov ss,ax
        mov sp,SDISP
        
        mov ds,ax
        mov si,SDISP + Begin
        push word 0060h
        pop es
        mov di,0
        cld
        mov cx,100h
        rep movsw

        push es
        push Begin2
        retf

Begin2:
        push cs
        pop ds
        ;
        mov dx,mess1
        call PutStr
        ;
        mov si,DiskAP
        mov dl,80h
        mov ah,42h
        int 13h
        jc Over
        ;
        mov ax,0
        mov es,ax
        mov ax,0aa55h
        cmp [es:SDISP+27FEH],ax
        jnz Over
        ;
        push word 0
        push word SDISP + 0
        retf

Over:
        mov dx,mess2
        call PutStr
        jmp $

PutStr:
        mov bh,0
        mov si,dx
Lab1:
        lodsb
        or al,al
        jz Lab2
        mov ah,14
        int 10h
        jmp Lab1
Lab2:
        ret

DiskAP:
    db  10h
    db  0
    dw  20
    dw  SDISP
    dw  0000h
    dd  10
    dd  0
;
mess1   db  "booting system..",0dh,0ah,0
mess2   db  "Error..",0
    ;
	times   510 - ($ - $$) db 0
	db	55h,0aah
