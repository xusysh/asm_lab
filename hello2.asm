section text
bits 16

Start       dw      Begin
SegVal	    dw	    0
Version     dw      1
Signature   db      "xusysh",0,"           "


Begin:
      	mov ax,cs
	mov ds,ax
	xor cx,cx
	dec cx
	mov si,prompt
        call PrintStr
        retf


PrintStr:
        cld
        lodsb
    	test al,al
	jz PrintEnd
    	mov ah,14
	int 10h
    	loop PrintStr
PrintEnd:
        ret 

prompt       db      "The Program Runs!",0dh,0ah,0
times  510 -($-$$) db 0
db	55h,0aah