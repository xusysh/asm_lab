section text
bits 16

Start       dw      Begin
SegVal	    dw	    0
Version     dw      1
Signature   db      "xusysh",0,"           "


Begin:
        sti
        push ds
        movzx si,ah
        shl si,1
        mov ax,cs
	mov ds,ax
        mov bx,func_tab
        call [bx+si]

        pop ds
        iret

Func1:
        mov si,dx
PrintStr:
        cld
	mov al,[es:si]
        inc si
    	test al,al
	jz PrintEnd
	mov ah,14
	int 10h
    	jmp PrintStr
PrintEnd:
        ret 

Func2:
        mov al,2
        out 70h,al
        in al,71h       ;读时钟秒数
        push ax

        mov al,0
        out 70h,al
        in al,71h       ;读时钟秒数
        pop dx
        add ax,dx

        rdtsc           ;读取时钟(x86指令)

        mul dx
        add al,ah
        rol ax,4

        ret

func_tab     dw      Func1,Func2         ;中断调用的功能表
times  510 -($-$$) db 0
db	55h,0aah