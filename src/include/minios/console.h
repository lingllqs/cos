#ifndef MINIOS_CONSOLE_H
#define MINIOS_CONSOLE_H

#include <minios/types.h>

#define CRT_ADDR_REG 0x3d4
#define CRT_DATA_REG 0x3d5

#define CRT_START_ADDR_H 0xc // 显存起始位置高位
#define CRT_START_ADDR_L 0xd // 显存起始位置低位
#define CRT_CURSOR_H 0xe     // 光标位置高位
#define CRT_CURSOR_L 0xf     // 光标位置低位

#define MEM_BASE 0xb8000              // 显卡内存起始位置
#define MEM_SIZE 0x4000               // 显卡内存大小 16k
#define MEM_END (MEM_BASE + MEM_SIZE) // 显卡内存结束位置
#define WIDTH 80                      // 文本列数
#define HEIGHT 25                     // 文本行数
#define ROW_SIZE (WIDTH * 2)          // 屏幕每行字节数
#define SCR_SIZE (ROW_SIZE * HEIGHT)  // 屏幕字节数

#define ASCII_NUL 0x00
#define ASCII_ENQ 0x05 // 传送应答消息
#define ASCII_BEL 0x07 // \a
#define ASCII_BS 0x08  // \b
#define ASCII_HT 0x09  // \t
#define ASCII_LF 0x0a  // \n
#define ASCII_VT 0x0b  // \v
#define ASCII_FF 0x0c  // \f
#define ASCII_CR 0x0d  // \r
#define ASCII_DEL 0x7f

void console_init();
void console_clear();
void console_write(char *buf, u32 count);

#endif // !MINIOS_CONSOLE_H
