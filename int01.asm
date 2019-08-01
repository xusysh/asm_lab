section text
bits 16

Start       dw      Begin
SegVal	    dw	    0
Version     dw      1
Signature   db      "xusysh",0,"           "


Begin:
        cli
        mov bp,sp
        push ds
        pusha

        mov ax,cs
	mov ds,ax

        mov ax,0
        mov es,ax
        jmp SingleStep

Step_end:

        popa
        pop ds
        iret

;
SingleStep:
        mov si,msg
        call PrintStr
        
GetNextAddr:
        ;获取栈中的CS
        mov dx,word [bp+2]
        call Uint2StrAddr
        mov al,':'
        call PrintCh
        ;
        ;获取栈中的偏移地址(ip即下一条指令)
        mov dx,word[bp]
        call Uint2StrAddr
        mov si,newline
        call PrintStr
        ;
ScanKey_start:
        mov si,prompt
        call PrintStr
        mov ah,0
        int 16h
        mov ah,0eh
        int 10h
        mov si,newline
        call PrintStr
        cmp al,74h
        je key_t
        cmp al,72h
        je key_r
        cmp al,71h
        je key_q
        cmp al,73h
        je key_s
        mov si,newline
        call PrintStr
        jmp ScanKey_start
ScanKey_end:
        jmp Step_end

key_t:
        jmp ScanKey_end

key_r:
        popa                   ;获取dx的原值
        pusha                  ;保存回堆栈
        mov si,show_ax
        call PrintStr
        mov dx,ax
        call Uint2StrAddr
        mov si,tab
        call PrintStr
        ;
        mov si,show_bx
        call PrintStr
        mov dx,bx
        call Uint2StrAddr
        mov si,tab
        call PrintStr
        ;
        popa                 ;重新获取cx的原值
        pusha                ;重新保存cx
        mov si,show_cx
        call PrintStr
        mov dx,cx
        call Uint2StrAddr
        mov si,tab
        call PrintStr
        ;
        popa                 ;重新获取dx的原值
        pusha                ;重新保存dx
        mov si,show_dx
        call PrintStr
        mov dx,bx
        call Uint2StrAddr
        mov si,tab
        call PrintStr
        ;
        mov si,show_si
        call PrintStr
        popa                 ;重新获取si的原值
        pusha                ;重新保存si
        mov dx,si
        call Uint2StrAddr
        mov si,tab
        call PrintStr
        ;
        mov si,show_di
        call PrintStr
        mov dx,di
        call Uint2StrAddr
        mov si,tab
        call PrintStr
        ;
        mov si,newline
        call PrintStr
key_r_end:     
        jmp ScanKey_start

key_q:
        pushf
        pop ax
        xor ax,0100h             ;设置TF=0
        push ax 
        popf                    ;设置flags
        ;
key_q_end:     
        jmp ScanKey_end

key_s:
        mov si,show_cs
        call PrintStr
        mov dx,[bp+2]
        call Uint2StrAddr
        mov si,tab
        call PrintStr

        mov si,show_ds
        call PrintStr
        popa
        pop ds
        push ds
        pusha
        mov dx,ds
        call Uint2StrAddr
        mov ax,cs
        mov ds,ax               ;恢复ds
        mov si,tab
        call PrintStr


        mov si,show_es
        call PrintStr
        mov dx,es
        call Uint2StrAddr
        mov si,tab
        call PrintStr

        mov si,show_ss
        call PrintStr
        mov dx,ss
        call Uint2StrAddr
        mov si,newline
        call PrintStr

        mov si,show_stack
        call PrintStr
        xor si,si
key_s_loop1_start:
        mov dx,[bp+si]
        call Uint2StrWord
        add si,2
        push si
        mov si,newline
        call PrintStr
        pop si
        cmp si,20
        je key_s_loop1_end
        loop key_s_loop1_start
key_s_loop1_end:
        mov si,newline
        call PrintStr

key_s_end:
        jmp ScanKey_start
        

PrintStr:
        cld
        push ax
        push dx
PrintStr_start:
        lodsb
    	test al,al
	jz PrintEnd
	mov ah,14
	int 10h
    	jmp PrintStr_start
PrintEnd:
        pop dx
        pop ax
        ret 

PrintCh:
	mov ah,14
	int 10h
        ret

Uint2StrWord:
        pusha
        call Uint2StrByte
        mov al,' '
        call PrintCh
        mov dl,dh
        call Uint2StrByte
Uint2StrWord_end:
        popa
        ret

Uint2StrAddr:
        rol dx,8
        call Uint2StrByte
        mov al,' '
        call PrintCh
        mov dl,dh
        call Uint2StrByte
Uint2StrAddr_end:
        ret

Uint2StrByte:  
        mov cx,2
Uint2StrByte_loop_start:
        rol dl,4
        mov al,dl
        xor ah,ah
        and al,0fh
        add al,30h
        cmp al,'9'
        jle Uint2StrByte_if_end
        add al,7
Uint2StrByte_if_end:
        call PrintCh
        loop Uint2StrByte_loop_start
Uint2StrByte_end:
        ret


msg          db      0dh,0ah,"Next step:",0dh,0ah,0
newline      db      0dh,0ah,0
tab          db      "    ",0
prompt       db      "(debug)> ",0 
show_ax      db      "AX:",0
show_bx      db      "BX:",0 
show_cx      db      "CX:",0 
show_dx      db      "DX:",0 
show_si      db      "SI:",0
show_di      db      "DI:",0 
show_sp      db      "DX:",0 
show_bp      db      "SI:",0

show_cs      db      "CS:",0
show_ds      db      "DS:",0
show_es      db      "ES:",0 
show_ss      db      "SS:",0 
show_stack   db      "Stack dump:",0dh,0ah,0 

times  1022 -($-$$) db 0
db	55h,0aah