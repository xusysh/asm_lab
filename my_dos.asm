DATA_OFFSET equ 7c00h
segment text
bits 16

Start:
      	mov ax,cs
	mov ds,ax
        mov sp,DATA_OFFSET
        mov si,prompt2
        add si,DATA_OFFSET
        call PrintStr
        call ReadSlim
Begin:
        xor ax,ax
        mov es,ax
        xor bx,bx
        xor cx,cx
        xor dx,dx
        cld
	mov si,prompt
        add si,DATA_OFFSET
        call PrintStr
        mov ah,03h
        int 10h
        mov [prompt_pos + DATA_OFFSET],dl
        mov word [operand_pos + DATA_OFFSET],0
        mov word [load_seg + DATA_OFFSET],1000h
        mov byte [sload_flag],0
        mov di,cmd
        add di,DATA_OFFSET
ScanKey:
        mov ah,1
        int 16h
        jz ScanKey
        
        mov ah,0
        int 16h
        cmp ah,1ch
        je key_enter
        cmp ah,0eh
        je key_bsp
        cmp ah,4bh
        je key_left
        cmp ah,1
        jz PowerOff
        jmp char
key_enter:
        mov ah,0eh
        int 10h
        mov al,0ah
        mov ah,0eh
        int 10h
        mov al,0
        stosb
        jmp CheckCmd
key_bsp:
        mov ah,03h
        int 10h
        cmp dl,[prompt_pos+DATA_OFFSET]
        jle key_bsp_end
        mov ah,0eh
        mov cx,1
        int 10h
        mov al,20h
        mov cx,1
        mov ah,0ah
        int 10h
        
        dec di
        xor al,al
        stosb
        dec di    
key_bsp_end:    
        jmp ScanKey
key_left:
        ;
        jmp ScanKey
key_right:
        mov ah,03h
        int 10h
        inc dl
        mov ah,02h
        int 10h
        jmp ScanKey
char:
        mov ah,0eh
        int 10h
        stosb
        jmp ScanKey

CheckCmd:
        mov si,cmd + DATA_OFFSET
        mov di,trimed_cmd + DATA_OFFSET
        call Trim
        mov si,trimed_cmd
        add si,DATA_OFFSET
        call SplitCmd
        mov bx,cmd_tab
        add bx,DATA_OFFSET
        mov cx,cmd_count
CheckCmd_loop1_start:
        mov si,trimed_cmd
        add si,DATA_OFFSET
        mov di,[bx]
        add di,DATA_OFFSET
        call StrCmp

        add bx,4                      ;2 bytes addr * 2
        test ax,ax
        jnz CheckCmd_succ
        loop CheckCmd_loop1_start
CheckCmd_loop1_end:
        call PrintStr
        mov si,cmd_error
        add si,DATA_OFFSET
        call PrintStr
        jmp CheckCmd_end
CheckCmd_succ:
        sub bx,2
        mov dx,[bx]             ;get command Program addr
        add dx,DATA_OFFSET
        call dx    
CheckCmd_end:
        jmp Begin

SplitCmd:
SplitCmd_loop_start:
        lodsb
        cmp al,20h              ;check space
        je SplitCmd_succ
        test al,al
        jz SplitCmd_loop_end
        jmp SplitCmd_loop_start
SplitCmd_loop_end:
        xor ax,ax
        jmp SplitCmd_end
SplitCmd_succ:
        dec si
        mov byte [si],0
        inc si
        mov word [operand_pos + DATA_OFFSET],si
        mov ax,1
SplitCmd_end:
        ret

StrCmp:
        push si
        push di
StrCmp_loop_start:
        lodsb
        test al,al
        jz str1_end        
        cmp byte [di],0
        jz StrCmp_failed
        cmp al,byte [di]
        jne StrCmp_failed
        inc di
        jmp StrCmp_loop_start
str1_end:
        cmp byte [di],0
        jne StrCmp_failed
StrCmp_loop_end:
        mov ax,1
        jmp StrCmp_end
StrCmp_failed:
        xor ax,ax
StrCmp_end:
        pop di
        pop si
        ret

PrintStr:
        cld
	lodsb
	test al,al
	jz PrintEnd
	mov ah,14
	int 10h
	jmp PrintStr
PrintEnd:
        ret

PowerOff:
	mov ax,5301h
	xor bx,bx
	int 15h
        ;
	mov ax,530eh
	mov cx,0102h
	int 15h
        ;	
	mov ax,5307h
	mov bl,01h
	mov cx,0003h
	int 15h
        ret

Echo:
        cmp word [operand_pos + DATA_OFFSET],0
        je Echo_end
        mov si,word [operand_pos + DATA_OFFSET]
        call PrintStr
        mov si,newline
        add si,DATA_OFFSET
        call PrintStr
Echo_end:
        ret

ReadSlim:
        mov si,DiskAP
        add si,DATA_OFFSET
        mov dword [DiskAP+DATA_OFFSET+8],1          ;slim表起始扇区
        mov word [DiskAP+DATA_OFFSET+2],9           ;slim表所占扇区
        mov word [DiskAP+DATA_OFFSET+4],Slim16 + DATA_OFFSET
        mov dl,80h
        mov ah,42h
        int 13h
        jc ReadSlim_error
        ;
        mov ax,0
        mov es,ax
        mov ax,0aa55h
        cmp [es:Slim16+DATA_OFFSET+11FEH],ax
        jnz ReadSlim_error
        jmp ReadSlim_end
ReadSlim_error:
        mov si,readslim_error
        add si,DATA_OFFSET
        call PrintStr
ReadSlim_end:
        ret

Load:
        pushf
        pop ax
        btr ax,8             ;设置TF=0
        push ax 
        popf                    ;设置flags

        mov di,Slim16
        add di,DATA_OFFSET
        mov cx,word [di]
        add di,2

        mov si,[operand_pos + DATA_OFFSET]
        push si
        call SplitCmd
        test ax,ax
        jnz Load_with_addr
Load_without_addr:
        mov word [load_seg + DATA_OFFSET],1000h
        pop si
        jmp CmpName
Load_with_addr:
        mov si,[operand_pos + DATA_OFFSET]
        call HexStr2Uint
        mov word [load_seg + DATA_OFFSET],ax

        pop si
CmpName:
        call StrCmp
        add di,24
        test ax,ax
        jnz Cmp_succ
        loop CmpName
Cmp_fail:
        call PrintStr
        mov si,cmd_error
        add si,DATA_OFFSET
        call PrintStr
        jmp Load_end
Load_fail:
        mov si,[operand_pos + DATA_OFFSET]
        call PrintStr
        mov si,load_error
        add si,DATA_OFFSET
        call PrintStr
        jmp Load_end
Cmp_succ:
        sub di,4
        mov si,DiskAP
        add si,7c00h
        mov dx,word [di]
        mov word [DiskAP+DATA_OFFSET+8],dx
        mov dx,word [di+2]
        mov word [DiskAP+DATA_OFFSET+2],dx      
        mov word [DiskAP+DATA_OFFSET+4],0
        mov ax, word [load_seg + DATA_OFFSET]
        mov word [DiskAP+DATA_OFFSET+6],ax
        mov dl,80h
        mov ah,42h
        int 13h
        jc Load_fail
        ;
        mov ax, word [load_seg + DATA_OFFSET]
        mov es,ax               ;给要加载的程序分配段地址
        mov [es:2],ax           ;为段间调用做准备

   ;     mov ax,0aa55h
    ;    shl dx,9
     ;
     ;   cmp [es:dx-2],ax
      ;  jnz Load_fail
        ;

        cmp byte [sload_flag+DATA_OFFSET],0
        je Load_call
        pushf                   ;保存全部标志到堆栈
        pop ax                  ;从堆栈中取出全部标志
        or ax,0100h             ;设置TF=1
        push ax 
        popf                    ;设置flags
Load_call:
        call far [es:0]        ;该地址指向4字节(偏移+段地址)
Load_end:
        ret

SLoad:
        pushf
        mov byte [sload_flag+DATA_OFFSET],1            
        call Load
SLoad_end:
        popf
        mov byte [sload_flag+DATA_OFFSET],0         
        ret


;setint hello.int 21
SetInt:
        mov di,Slim16
        add di,DATA_OFFSET
        mov cx,word [di]
        add di,2

        mov si,[operand_pos + DATA_OFFSET]
        push si
        call SplitCmd
SetInt_get_addr:
        mov si,[operand_pos + DATA_OFFSET]
        call HexStr2Uint
        mov [int_handler_type+DATA_OFFSET],ax
        pop si
SetInt_CmpName:
        call StrCmp
        add di,24
        test ax,ax
        jnz SetInt_Cmp_succ
        loop SetInt_CmpName
SetInt_Cmp_fail:
        call PrintStr
        mov si,cmd_error
        add si,DATA_OFFSET
        call PrintStr
        jmp SetInt_end
SetInt_Load_fail:
        mov si,[operand_pos + DATA_OFFSET]
        call PrintStr
        mov si,setint_error
        add si,DATA_OFFSET
        call PrintStr
        jmp SetInt_end
SetInt_Cmp_succ:
        sub di,4
        mov si,DiskAP
        add si,7c00h
        mov dx,word [di]
        mov word [DiskAP+DATA_OFFSET+8],dx
        mov dx,word [di+2]
        mov word [DiskAP+DATA_OFFSET+2],dx      
        mov word [DiskAP+DATA_OFFSET+4],0
        mov ax, word [int_seg + DATA_OFFSET]
        mov word [DiskAP+DATA_OFFSET+6],ax
        mov dl,80h
        mov ah,42h
        int 13h
        jc SetInt_Load_fail
        ;
        mov ax, word [int_seg + DATA_OFFSET]
        mov es,ax               ;给要加载的程序分配段地址
        mov ax,[es:0]

        mov bx,[int_handler_type+DATA_OFFSET]
        shl bx,2
        mov word [bx],ax
        mov ax,[int_seg+DATA_OFFSET]
        mov word [bx+2],ax
        add word [int_seg+DATA_OFFSET],8
        
SetInt_end:
        ret

InitInt:
        mov si,prompt3
        call PrintStr
InitInt_end:
        ret        

HexStr2Uint:
        xor ax,ax
        xor dx,dx
HexStr2Uint_loop_start:
        lodsb
        test al,al
        jz HexStr2Uint_loop_end
        sub al,30h
        cmp al,9
        jle HexStr2Uint_not_char
        sub al,7
HexStr2Uint_not_char:
        shl dx,4
        add dx,ax
        jmp HexStr2Uint_loop_start
HexStr2Uint_loop_end:
        mov ax,dx
        ret

DecStr2Uint:
        xor ax,ax
        xor dx,dx
        mov cl,10
DecStr2Uint_loop_start:
        mov dl,[si]
        inc si
        test dl,dl
        jz DecStr2Uint_loop_end
        mul cl
        sub dl,30h
        add ax,dx
        jmp DecStr2Uint_loop_start
DecStr2Uint_loop_end:
        ret

Trim:
        xor cx,cx       ;空格计数
Trim_loop_start:
        lodsb
        test al,al
        jz Trim_loop_end
        cmp al,20h
        jne Trim_not_space
Trim_space_detected:
        test cx,cx
        jz Trim_first_space
        jmp Trim_loop_start
Trim_first_space:
        inc cx
        stosb
        jmp Trim_loop_start
Trim_not_space:
        xor cx,cx
        stosb
        jmp Trim_loop_start
Trim_loop_end:
        mov al,0
        stosb
        ret

Ls:
        mov si,Slim16 + DATA_OFFSET
        mov cx,word [si]
        add si,2
Ls_loop_start:
        push si
        call PrintStr
        mov si,tab
        add si,7c00h
        call PrintStr
        pop si
        add si,24
        loop Ls_loop_start
Ls_loop_end:
        mov si,newline
        add si,7c00h
        call PrintStr
        ret

Roll:
        cmp word [operand_pos + DATA_OFFSET],0
        jne Roll_with_operand
Roll_without_operand:
        mov cx,101
        jmp get_random_byte
Roll_with_operand:
        mov si,word [operand_pos + DATA_OFFSET]
        call DecStr2Uint
        inc ax
        mov cx,ax
get_random_byte:

        mov ah,1
        int 21h

        and ah,3
        div cl
        mov al,ah
        xor ah,ah
        ;
        mov bx,roll_byte_str
        add bx,DATA_OFFSET
        call uint2str
        ;
        lea si,[roll_byte_str+DATA_OFFSET]
        call PrintStr
        lea si,[newline+DATA_OFFSET]
        call PrintStr
Roll_end:
        ret

uint2str:  
        mov cx,10       
        xor si,si
        test ax,ax
        jnz uint2str_loop_start
        mov word [bx],0030h
        jmp reverse_str_loop_end
uint2str_loop_start:  
        xor dx,dx
        test ax,ax
        jz uint2str_loop_end
get_ch:
        div cx              
        add dl,30h
        mov [bx+si],dl    
        push dx
        inc si   
        jmp uint2str_loop_start
uint2str_loop_end:
        mov byte [bx+si],0
reverse_str:
        xor si,si
reverse_str_loop_start:
        cmp byte [bx+si],0
        jz reverse_str_loop_end
        pop dx 
        mov byte [bx + si], dl
        inc si
        jmp reverse_str_loop_start
reverse_str_loop_end:
        ret


prompt	        db	"xusysh@my_dos> ",0
prompt2         db      "Reading Slim16 TAB...",0dh,0ah,0
prompt3         db      "Initializing interrupt table",0dh,0ah,0
prompt_pos      db      0                 ;记录提示信息结尾位置
newline         db      0dh,0ah,0
tab             db      "    ",0
cmd_error	db	" : Can't Find Command or Program!",0dh,0ah,0
readslim_error	db	0dh,0ah,"Can't Read Slim16!",0dh,0ah,0
load_error      db      " : Can't Load Program!",0dh,0ah,0
setint_error    db      "Setiing Interrupt table failed!",0dh,0ah,0
roll_byte_str   db      0,0,0,0,0,0
cmd             db      "                                               ",0
trimed_cmd      db      "                                               ",0
operand_pos     dw      0
load_seg        dw      0
int_seg         dw      500h
int_handler_type         dw      0
sload_flag      db      0
cmd_len         equ     15
cmd1            db      "poweroff",0,"      "
cmd2            db      "echo",0,"          "
cmd3            db      "load",0,"          "
cmd4            db      "ls",0,"            "
cmd5            db      "roll",0,"          "
cmd6            db      "setint",0,"        "
cmd7            db      "sload",0,"         "
cmd_count       equ     ($-cmd1)/cmd_len
cmd_tab         dw      cmd1,PowerOff,cmd2,Echo,cmd3,Load
                dw      cmd4,Ls,cmd5,Roll,cmd6,SetInt
                dw      cmd7,SLoad
        ;
DiskAP:
    db  10h             ;DAP尺寸
    db  0               ;保留
    dw  0               ;所占扇区数
    dw  0               ;缓冲区偏移
    dw  0               ;缓冲区段值
    dd  0               ;起始扇区号低4字节
    dd  0               ;起始扇区号高4字节

Slim16:
    times 4608 db 0          ;预留9个扇区大小的内存空间

	times   10238 -($-$$) db 0
	db	55h,0aah
