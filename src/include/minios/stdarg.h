#ifndef MINIOS_STDARG_H
#define MINIOS_STDARG_H

typedef char* va_list;

// ap 指向下一个参数地址，第一个参数是参数个数，下一个是实际参数
#define va_start(ap, v) (ap = (va_list)&v + sizeof(char *))

// ap 指向下一个参数，va_arg 宏的结果为当前参数
#define va_arg(ap, t) (*(t *)((ap += sizeof(char *)) - sizeof(char *)))

// 将 ap 指向 NULL
#define va_end(ap) (ap = (va_list)0)

#endif // !MINIOS_STDARG_H
