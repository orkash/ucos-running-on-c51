$NOMOD51
EA	BIT	0A8H.7
SP	DATA	081H
B	DATA	0F0H
ACC	DATA	0E0H
DPH	DATA	083H
DPL	DATA	082H
PSW	DATA	0D0H
TR0	BIT	088H.4
TH0	DATA	08CH
TL0	DATA	08AH

NAME OS_CPU_A    ;模块名


; 定义重定位段
?PR?OSStartHighRdy?OS_CPU_A SEGMENT CODE
?PR?OSCtxSw?OS_CPU_A SEGMENT CODE
?PR?OSIntCtxSw?OS_CPU_A SEGMENT CODE
?PR?OSTickISR?OS_CPU_A SEGMENT CODE

; 声明引用全局变量和外部子程序
          EXTRN IDATA(?C_XBP)   ; 仿真堆栈指针用于重入局部变量保存
		  EXTRN IDATA(OSTCBCur)
		  EXTRN IDATA(OSTCBHighRdy)
		  EXTRN IDATA(OSRunning)
		  EXTRN IDATA(OSPrioCur)
		  EXTRN IDATA(OSPrioHighRdy)
		  EXTRN CODE (_?OSTaskSwHook)
		  EXTRN CODE (_?OSIntEnter)
		  EXTRN CODE (_?OSIntExit)
		  EXTRN CODE (_?OSTimeTick)

; 对外声明4个不可重入函数
          PUBLIC OSStartHighRdy
		  PUBLIC OSCtxSw
		  PUBLIC OSIntCtxSw
		  PUBLIC OSTickISR
		  
; 分配堆栈空间。只关心大小，堆栈起点由keil决定，通过标号可以获得keil分配的SP起点。
?STACK SEGMENT IDATA
       RSEG ?STACK
OSStack:
       DS 40H
OSStkStart IDATA OSStack-1

; 定义压栈宏
PUSHALL MACRO
       PUSH PSW
	   PUSH ACC
	   PUSH B
	   PUSH DPL
	   PUSH DPH
	   MOV  A,R0     ; R0-R7入栈
	   PUSH ACC
	   MOV  A,R1
	   PUSH ACC
	   MOV  A,R2
	   PUSH ACC
	   MOV  A,R3
	   PUSH ACC
	   MOV  A,R4
	   PUSH ACC
	   MOV  A,R5
	   PUSH ACC
	   MOV  A,R6
	   PUSH ACC
	   MOV  A,R7
	   PUSH ACC
	   ; PUSH SP      ; 不比保存SP，任务切换时由相应程序调整
	   ENDM

; 定义出栈宏
POPALL MACRO
       ;POP SP        ; 不必保存SP，任务切换时由相应程序调整
	   POP ACC       ; R0-R7出栈
	   MOV R7,A
	   POP ACC
	   MOV R6,A
	   POP ACC
	   MOV R5,A
	   POP ACC
	   MOV R4,A
	   POP ACC
	   MOV R3,A
	   POP ACC
	   MOV R2,A
	   POP ACC
	   MOV R1,A
	   POP ACC
	   MOV R0,A
	   POP DPH
	   POP DPL
	   POP B
	   POP ACC
	   POP PSW
	   ENDM
	   
; 子程序
       RSEG ?PR?OSStartRdy?OS_CPU_A
OSStartHighRdy:
       USING 0               ; 使用寄存器第0组。上电后51自动关中断，此处不必CLR EA指令，因为到此处还未中断，本程序退出后开中断
	   LCALL _?OSTackSwHook
OSCtxSw_in:
       ;OSTCBCur ===> DPTR   ; 获得当前TCB指针
	   MOV  R0,#LOW(OSTCBCur); 获得OSTCBCur指针低地址，指针占3字节。+0类型+1高8位数据+2低8位数据
	   INC  R0
	   MOV  DPH, @R0
	   INC  R0
	   MOV  DPL, @R0
	   ;OSTCBCur->OSTCBStkPtr===>DPTR  ;获得用户堆栈指针
	   INC  DPTR
	   MOVX A, @DPTR         ; OSTCBStkPtr是void指针
	   MOV  R0,A
	   INC  DPTR
	   MOVX A, @DPTR
	   MOV  R1,A
	   MOV  DPH, R0
	   MOV  DPL, R1
	   ;*UserStrPtr ===> R5  ; 用户堆栈起始地址内容（即用户堆栈长度放在此处）
	   MOVX A, @DPTR
	   MOV  R5, A            ; R5 = 用户堆栈长度
	   ; 恢复现场堆栈内容
	   MOV  R0, #OSStkStart
restore_stack:
       INC  DPTR
	   INC  R0
	   MOVX A, @DPTR
	   MOV  @R0, A
	   DJNZ R5, restore_stack
	   ; 恢复堆栈指针SP
	   MOV  SP,R0
	   ; 恢复仿真堆栈指针?C_XBP
	   INC  DPTR
	   MOVX A, @DPTR
	   MOV  ?C_XBP, A        ; ?C_XBP仿真堆栈指针高8位
	   INC  DPTR
	   MOVX A, @DPTR
	   MOV  ?C_XBP+1, A      ; ?C_XBP仿真堆栈指针低8位
	   ;OSRunning=TRUE
	   MOV  R0, #LOW(OSRunning)
	   MOV  @R0, #01
	   POPALL
	   SETB EA
	   RETI
	   
;----------------------------------------------------------------------
       RSEG ?PR?OSCtxSw?OS_CPU_A
OSCtxSw:
       PUSHALL
OSIntCtxSw_in:
       ; 获得堆栈长度和起始地址
	   MOV  A, SP
	   CLR  C
	   SUBB A, #OSStkStart
	   MOV  R5, A            ; 获得堆栈长度
	   ;OSTCBCur===>DPTR     ; 获得当前TCB指针
	   MOV  R0, #LOW(OSTCBCur)
	   ; 获得OSTCBCur指针低地址，指针占3字节。+0类型+1高八位数据+2低八位数据
	   INC  R0
	   MOV  DPH, @R0
	   INC  R0
	   MOV  DPL, @R0
	   ;OSTCBCur->OSTCBStkPtr===>DPTR    ; 获得用户堆栈指针
	   INC  DPTR
	   MOVX A, @DPTR         ; OSTCBStkPtr是void指针
	   MOV  R0, A
	   INC  DPTR
	   MOVX A, @DPTR
	   MOV  R1, A
	   MOV  DPH, R0
	   MOV  DPL, R1
	   ; 保存堆栈长度
	   MOV  A, R5
	   MOVX @DPTR, A
	   MOV  R0, #OSStkStart  ; 获得堆栈指针
save_stack:
       INC  DPTR
	   INC  R0
	   MOV  A, @R0
	   MOVX @DPTR, A
	   DJNZ R5, sava_stack
	   ; 保存仿真堆栈指针?C_XBP
	   INC  DPTR
	   MOV  A, ?C_XBP        ; C_XBP仿真堆栈指针高8位
	   MOVX @DPTR, A
	   INC  DPTR
	   MOV  A, ?C_XBP+1      ; C_XBP仿真堆栈指针低8位
	   MOVX @DPTR, A
	   ; 调用用户程序
	   LCALL _?OSTaskSwHook
	   ;OSTCBCur=OSTCBHighRdy
	   MOV  R0, #OSTCBCur
	   MOV  R1, #OSTCBHighRdy
	   MOV  A, @R1
	   MOV  @R0, A
	   INC  R0
	   INC  R1
	   MOV  A, @R1
	   MOV  @R0, A
	   ;OSPrioCur=OSPrioHighRdy   ; 使用这两个变量主要目的是为了使指针比较变为字节比较，以便节省空间
	   MOV  R0, #OSPrioCur
	   MOV  R1, #OSPrioHighRdy
	   MOV  A, @R1
	   MOV  @R0, A
	   LJMP OSCtxSw_in
	   
;-----------------------------------------------------------------------
       RSEG ?PR?OSIntCtxSw?OS_CPU_A
OSIntCtxSw:
       ; 调整sp指针去掉在调用OSIntExit(),OSIntCtxSw()过程中压入栈的多余内容
	   ;SP=SP-4
	   MOV  A, SP
	   CLR  C
	   SUBB A, #4
	   MOV  SP, A
	   LJMP OSIntCtXSw_in

;-----------------------------------------------------------------------
       CSEG AT 000BH      ;OSTickISR
	   LJMP OSTickISR
	   RSEG ?PR?OSTickISR?OS_CPU_A
OSTickISR:
       USING 0
	   PUSHALL
	   CLR   TR0
	   MOV   TH0, #0B1H
	   MOV   TL0, #0E0H
	   SETB  TR0
	   LCALL _?OSIntEnter
	   LCALL _?OSTimeTick
	   LCALL _?OSIntExit
	   POPALL
	   RETI
	   
END 