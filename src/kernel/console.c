#include <minios/console.h>
#include <minios/io.h>
#include <minios/string.h>

static u32 screen; // 屏幕在内存中位置

// |        | 0xba000
// | ______ |
// ||      ||
// ||screen||
// ||______||
// |        |
// |        |
// |        |
// |        |
// |        |
// |________| 0xb8000

static u32 pos; // 光标在内存中位置

static u32 x, y; // 光标在显示器上的坐标,x 为列，y 为行

static u8 attr = 0x07;     // 字符默认属性
static u16 erase = 0x0720; // 07 位黑底白字，20 为空格字符

// 获取屏幕在内存中的位置
static void get_screen()
{
    // 获得屏幕在显示屏上第几个字符
    outb(CRT_ADDR_REG, CRT_START_ADDR_H);
    screen = inb(CRT_DATA_REG) << 8;
    outb(CRT_ADDR_REG, CRT_START_ADDR_L);
    screen |= inb(CRT_DATA_REG);

    // 获得屏幕起始位置在内存中的位置
    screen <<= 1; // 一个字符两个字节(字符本身和字符属性)
    screen += MEM_BASE;
}

// 设置屏幕显示的起始位置
static void set_screen()
{
    outb(CRT_ADDR_REG, CRT_START_ADDR_H);
    outb(CRT_DATA_REG, ((screen - MEM_BASE) >> 9) & 0xff);
    outb(CRT_ADDR_REG, CRT_START_ADDR_L);
    outb(CRT_DATA_REG, ((screen - MEM_BASE) >> 1) & 0xff);
}

static void get_cursor()
{
    outb(CRT_ADDR_REG, CRT_CURSOR_H);
    pos = inb(CRT_DATA_REG) << 8;
    outb(CRT_ADDR_REG, CRT_CURSOR_L);
    pos |= inb(CRT_DATA_REG);

    get_screen();

    // 获得光标在内存中的位置
    pos <<= 1; // 一个字符大小为两个字节
    pos += MEM_BASE;

    u32 delta = (pos - screen) >> 1; // delta 为光标在屏幕上第几个字符
    x = delta % WIDTH;               // 得到光标相对屏幕显示起始位置所在列
    y = delta / WIDTH;               // 得到光标所在行
}

static void set_cursor()
{
    outb(CRT_ADDR_REG, CRT_CURSOR_H);
    outb(CRT_DATA_REG, ((pos - MEM_BASE) >> 9) & 0xff);
    outb(CRT_ADDR_REG, CRT_CURSOR_L);
    outb(CRT_DATA_REG, ((pos - MEM_BASE) >> 1) & 0xff);
}

void console_init()
{
    console_clear();
}

void console_clear()
{
    screen = MEM_BASE;
    pos = MEM_BASE;
    x = y = 0;
    set_screen();
    set_cursor();

    u16 *ptr = (u16 *)MEM_BASE;
    while (ptr < (u16 *)MEM_END)
    {
        *ptr++ = erase;
    }
}

static void command_cr()
{
    pos -= (x << 1);
    x = 0;
}

static void scroll_up()
{
    if (screen + SCR_SIZE + ROW_SIZE < MEM_BASE)
    {
        u32 *ptr = (u32 *)(screen + SCR_SIZE);
        for (size_t i = 0; i < WIDTH; ++i)
        {
            *ptr++ = erase;
        }
        screen += ROW_SIZE;
        pos += ROW_SIZE;
    }
    else
    {
        memcpy((void *)MEM_BASE, (void *)screen, SCR_SIZE);
        pos -= (screen - MEM_BASE);
        screen = MEM_BASE;
    }

    set_screen();
}

static void command_lf()
{
    if (y + 1 < HEIGHT)
    {
        y++;
        pos += ROW_SIZE;
        return;
    }
    scroll_up();
}

static void command_bs()
{
    if (x)
    {
        x--;
        pos -= 2;
        *(u16 *)pos = erase;
    }
}

static void command_del()
{
    *(u16 *)pos = erase;
}

void console_write(char *buf, u32 count)
{
    char ch;
    while (count--)
    {
        ch = *buf++;
        switch (ch)
        {
        case ASCII_NUL:
            break;
        case ASCII_BEL:
            break;
        case ASCII_BS:
            command_bs();
            break;
        case ASCII_HT:
            break;
        case ASCII_LF:
            command_cr();
            command_lf();
            break;
        case ASCII_VT:
            break;
        case ASCII_FF:
            command_lf();
            break;
        case ASCII_CR:
            command_cr();
            break;
        case ASCII_DEL:
            command_del();
            break;
        default:
            if (x >= WIDTH)
            {
                x -= WIDTH;
                pos -= ROW_SIZE;
                command_lf();
            }

            *((char *)pos) = ch;
            pos++;
            *((char *)pos) = attr;
            pos++;

            x++;

            break;
        }
    }
    set_cursor();
}
