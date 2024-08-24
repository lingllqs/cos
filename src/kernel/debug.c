#include <minios/debug.h>
#include <minios/stdarg.h>
#include <minios/printk.h>
#include <minios/stdio.h>


static char buf[1024];

void debugk(char *file, int line, const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    vsprintf(buf, fmt, args);
    printk("[%s] [%d] %s", file, line, buf);
}
