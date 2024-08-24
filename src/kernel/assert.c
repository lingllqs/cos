#include <minios/printk.h>
#include <minios/types.h>
#include <minios/stdarg.h>
#include <minios/assert.h>
#include <minios/stdio.h>

static u8 buf[1024];

static void spin(char *name)
{
    printk("spinning in %s ...\n", name);
    while (true)
        ;
}
void assertion_failure(char *exp, char *file, char *base, int line)
{
    printk("\n--> assert(%s) failed!!!\n"
           "--> file: %s\n"
           "--> base: %s\n"
           "--> line: %d\n",
           exp, file, base, line);

    spin("assertion_failure()");

    asm volatile("ud2");
}

void panic(const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    int i = vsprintf((char *)buf, fmt, args);
    va_end(args);

    printk("!!! panic !!!\n%s --> ", buf);
    spin("panic()");

    asm volatile("ud2");
}
