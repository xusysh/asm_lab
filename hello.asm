section text
bits 16

Start       dw      Begin
SegVal	    dw	    0
Version     dw      1
Signature   db      "xusysh",0,"           "


Begin:
      	mov ax,cs
	mov ds,ax
        mov si,prompt    ;不再需要加偏移量
PrintStr:
        cld
	lodsb
	test al,al
	jz PrintEnd
	mov ah,14
	int 10h
    	jmp PrintStr
PrintEnd:
        retf

prompt       db      "The program runs!",0dh,0ah,0
times  1022 -($-$$) db 0
db	55h,0aah