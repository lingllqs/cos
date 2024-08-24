#ifndef MINIOS_STDIO_H
#define MINIOS_STDIO_H

#include <minios/stdarg.h>

int vsprintf(char *buf, const char *fmt, va_list args);
int sprintf(char *buf, const char *fmt, ...);

#endif // !MINIOS_STDIO_H
