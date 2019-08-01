    ;演示程序（工作程序）dp84.asm
    ;演示键盘中断处理程序（采用虚拟机可加载格式）
    PORT_KEY_DAT   EQU   0x60
    PORT_KEY_STA   EQU   0x64
    ;
        section   text
        bits   16
    ;可加载工作程序头部特征信息
Start       dw      Begin
SegVal	    dw	    0
Version     dw      1
Signature   db      "xusysh",0,"           "
    ;-------------------------------
    Begin:                              ;演示程序的初始化
        MOV   AX, 0                     ;准备设置中断向量
        MOV   DS, AX
        CLI
        MOV   WORD [9*4], int09h_handler
        MOV   [9*4+2], CS               ;启用新的键盘中断处理程序
        mov ax,cs
	mov es,ax
        STI
        ;
    Next:                               ;演示程序的演示处理
        MOV   AH, 0                     ;调用键盘I/O程序
        INT   16H                       ;获取用户按键
        ;
        CMP   AL, 0DH                   ;回车键吗？
        JNZ   Next                      ;否则继续
        ;
        MOV   AH, 14                    ;为了演示效果
        MOV   AL, 0AH                   ;显示一个换行
        INT   10H
        ;
        RETF                            ;结束（返回到加载器）
    ;-----------------------------------
    int09h_handler:                     ;新的9号键盘中断处理程序
        PUSHA                           ;保护通用寄存器
        ;
        MOV   AL, 0ADH
        OUT   PORT_KEY_STA, AL          ;禁止键盘发送数据到接口
        ;
        IN    AL, PORT_KEY_DAT          ;从键盘接口读取按键扫描码
        ;
        STI                             ;开中断
        CALL  Int09hfun                 ;完成相关功能
        ;
        CLI                             ;关中断
        MOV   AL, 0AEH
        OUT   PORT_KEY_STA, AL          ;允许键盘发送数据到接口
        ;
        MOV   AL, 20H                   ;通知中断控制器8259A
        OUT   20H, AL                   ;当前中断处理已经结束
        ;
        POPA                            ;恢复通用寄存器
        ;
        IRET                            ;中断返回
    ;-----------------------------------
    Int09hfun:                          ;演示9H号中断处理程序的具体功能
        CMP   AL, 1CH                   ;判断回车键的扫描码
        JNZ   .LAB1                     ;非回车键，转
        MOV   AH, AL                    ;回车键，保存扫描码
        MOV   AL, 0DH                   ;回车键ASCII码
        CALL  Enqueue                   ;;保存到键盘缓冲区
        JMP   SHORT .LAB3
     .LAB1:                              ;仅识别处理QWERTYUIOP十个键
        CMP   AL, 10H                   ;判断字母Q键扫描码
        jl    .LAB3                     ;低于，则直接丢弃
        CMP   AL, 19H                   ;判断字母P键扫描码
        jg    .LAB3                     ;高于，则直接丢弃

        push ax

        MOV   AH, AL                    ;保存扫描码
        ADD   AL, 31H                   ;按演示方案转成对应的ASCII码
        .LAB2:
        CALL  Enqueue                   ;;保存到键盘缓冲区

        pop   ax
        MOV   si,prompt0
        xor   ah,ah
        sub   ax,10h
        shl   ax,5
        add   si,ax       
        call PrintStr
        .LAB3:
        RET                             ;返回
    ;-----------------------------------
    Enqueue:                            ;把扫描码和ASCII码存入键盘缓冲区
        PUSH  DS                        ;保护DS
        MOV   BX, 40H
        MOV   DS, BX                    ;DS=0040H
        MOV   BX, [001CH]               ;取队列的尾指针
        MOV   SI, BX                    ;SI=队列尾指针
        ADD   SI, 2                     ;SI=下一个可能位置
        CMP   SI, 003EH                 ;越出缓冲区界吗？
        JB    .LAB1                     ;没有，转
        MOV   SI, 001EH                 ;是的，循环到缓冲区头部
    .LAB1:
        CMP   SI, [001AH]               ;与队列头指针比较
        JZ    .LAB2                     ;相等表示，队列已经满
        MOV   [BX], AX                  ;把扫描码和ASCII码填入队列
        MOV    [001CH], SI              ;保存队列尾指针
    .LAB2:
        POP   DS                        ;恢复DS
        RET                             ;返回
    end_of_text:                        ;结束位置

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

prompt0       db      "    MOV AX,CS                ",0dh,0ah,0
prompt1       db      "    CALL .FUNC40             ",0dh,0ah,0
prompt2       db      "    LEA BX,[BX+SI+7C00H]     ",0dh,0ah,0
prompt3       db      ".LAB30:                      ",0dh,0ah,0
prompt4       db      "    PUSH DX                  ",0dh,0ah,0
prompt5       db      "    CALL FAR[ES:123H]        ",0dh,0ah,0
prompt6       db      "    MOV ES,AX                ",0dh,0ah,0
prompt7       db      "    REPNZ MOVSB              ",0dh,0ah,0
prompt8       db      "    LOOP .LAB50              ",0dh,0ah,0
prompt9       db      "    rdtsc                    ",0dh,0ah,0
times  510 -($-$$) db 0
db	55h,0aah