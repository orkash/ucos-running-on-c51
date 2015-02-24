#ifdef  OS_CPU_GLOBALS
#define OS_CPU_EXT
#else   
#define OS_CPU_EXT extern
#endif

#include <reg51.h>

/*
**************************************************************************************
                        Datatype
									Related with compiler
**************************************************************************************
*/

typedef unsigned char BOOLEAN;
typedef unsigned char INT8U;    // Unsigned 8-bit integer.
typedef signed char INT8S;      // Signed 8-bit integer.
typedef unsigned char INT16U;   // Unsigned 16-bit integer.
typedef signed char INT16S;     // Signed 16-bit integer.
typedef unsigned long INT32U;   // Unsigned 32-bit integer.
typedef signed long INT32S;     // Signed 32-bit integer.
typedef float FP32;             // Single-precision float.
typedef double FP64;            // Double-precison float.
typedef unsigned char OS_STK;   // 8-bit stack entry

/*
**************************************************************************************
                    Related with CPU
**************************************************************************************
*/

#define OS_ENTER_CRITICAL() EA = 0   // Interrupt disabled.
#define OS_EXIT_CRITICAL() EA = 1    // Interrupt enabled.
#define OS_STK_GROWTH() 0            // Descending or Ascending stack.
#define OS_TASK_SW() OSCtxSw()