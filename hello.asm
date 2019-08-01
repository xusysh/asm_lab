section text
bits 16

Start       dw      Begin
SegVal	    dw	    0
Version     dw      1
Signature   db      "xusysh",0,"           "


Begin:
      	mov ax,cs
		mov ds,ax
		mov es,ax
		mov si,prompt
		call PrintStr
        retf

prompt       db      "The Program Runs!",0dh,0ah,0
times  1022 -($-$$) db 0
db	55h,0aah