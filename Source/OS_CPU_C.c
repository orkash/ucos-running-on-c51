#define OS_CPU_GLOBALS
#include "includes.h"

/*
*********************************************************************************************************
                              初始化任务堆栈
*********************************************************************************************************
*/
void *OSTaskStkInit(void (*task)(void *pd), void *ppdata, void *ptos, INT16U opt) reentrant
{
	OS_STK *stk;
	ppdata = ppdata;
	opt = opt;                 //OPT没被用到，保留此语句防止警告产生
	stk = (OS_STK*)ptos;       //用户堆栈最底有效地址
	*stk++ = 15;               //用户堆栈长度
	*stk++ = (INT16U)task & 0xff;      //任务地址低8位
	*stk++ = (INT16U)task >> 8;        //任务地址高8位
	*stk++ = 0x00;                     //PSW
	*stk++ = 0x0A;                     //ACC
	*stk++ = 0x0B;                     //B
	*stk++ = 0x00;                     //DPL
	*stk++ = 0x00;                     //DPH
	*stk++ = 0x00;                     //R0
	*stk++ = 0x01;                     //R1
	*stk++ = 0x02;                     //R2
	*stk++ = 0x03;                     //R3
	*stk++ = 0x04;                     //R4
	*stk++ = 0x05;                     //R5
	*stk++ = 0x06;                     //R6
	*stk++ = 0x07;                     //R7
	//不保存SP，任务切换时根据用户堆栈长度计算得出
	*stk++ = (INT16U)(ptos+MaxStkSize) >> 8;      //?C_XBP仿真堆栈指针高8位
	*stk++ = (INT16U)(ptos+MaxStkSize) & 0xff;    //?C_XBP仿真堆栈指针低8位
	return ((void*)ptos);
}

#if OS_CPU_HOOKS_EN
/*
**************************************************************************************
*                          任务创建钩挂函数
**************************************************************************************
*/
void OSTackCreateHook(OS_TCB *ptcb) reentrant
{
	ptcb = ptcb;
}

/*
**************************************************************************************
*                          任务删除钩挂函数
**************************************************************************************
*/
void OSTackDelHook(OS_TCB *ptcb) reentrant
{
	ptcb = ptcb;
}

/*
**************************************************************************************
*                          任务切换钩挂函数
**************************************************************************************
*/
void OSTaskSwHook(void) reentrant
{
}

/*
**************************************************************************************
*                          统计任务钩挂函数
**************************************************************************************
*/
void OSTaskStatHook(void) reentrant
{
}

/*
**************************************************************************************
*                          定时钩挂函数
**************************************************************************************
*/
void OSTimeTickHook(void) reentrant
{
}
#endif
//初始化定时器0
void InitTimer0(void) reentrant
{
	TMOD = TMOD & 0x00;
	TMOD = TMOD | 0x01;         //方式1（16位定时器），仅受TR0控制
	TH0 = 0xB1;                 //定义Tick=50次/秒（即0.02秒/次）
	TL0 = 0xE0;
	ET0 = 1;                    //允许T0中断
	TR0 = 1;
}