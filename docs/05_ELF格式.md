## ELF 文件格式

代码段: .text
数据段:
    1. .data 初始化数据
    2. .bss 未初始化 (Block Started by Symbol) objcopy -O binary 将bss段展开到文件中

## 源代码示例

```c++
#include <minios/minios.h>

int magic = MINIOS_MAGIC;
char message[] = "Hello Rust";
char buf[1024];

void kernel()
{
    char *video = (char *)0xb8000;
    for (int i = 0; i < sizeof(message); i++)
    {
        video[i * 2] = message[i];
    }
}
```

## 预处理

gcc -m32 -E main.c -o test.i
```c++
# 0 "main.c"
# 0 "<built-in>"
# 0 "<命令行>"
# 1 "/usr/include/stdc-predef.h" 1 3 4
# 0 "<命令行>" 2
# 1 "main.c"
# 1 "/usr/include/minios/minios.h" 1 3 4
# 2 "main.c" 2

int magic = 
# 3 "main.c" 3 4
           1700310115
# 3 "main.c"
                       ;
char message[] = "Hello Rust";
char buf[1024];

void kernel()
{
    char *video = (char *)0xb8000;
    for (int i = 0; i < sizeof(message); i++)
    {
        video[i * 2] = message[i];
    }
}
```

## 编译

gcc -m32 -S main.c -o test.s
```c++
	.file	"main.c"
	.text
	.globl	magic
	.data
	.align 4
	.type	magic, @object
	.size	magic, 4
magic:
	.long	1700310115
	.globl	message
	.align 4
	.type	message, @object
	.size	message, 11
message:
	.string	"Hello Rust"
	.globl	buf
	.bss
	.align 32
	.type	buf, @object
	.size	buf, 1024
buf:
	.zero	1024
	.text
	.globl	kernel
	.type	kernel, @function
kernel:
.LFB0:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$16, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	$753664, -8(%ebp)
	movl	$0, -12(%ebp)
	jmp	.L2
.L3:
	movl	-12(%ebp), %edx
	addl	%edx, %edx
	movl	%edx, %ecx
	movl	-8(%ebp), %edx
	addl	%edx, %ecx
	leal	message@GOTOFF(%eax), %ebx
	movl	-12(%ebp), %edx
	addl	%ebx, %edx
	movzbl	(%edx), %edx
	movb	%dl, (%ecx)
	addl	$1, -12(%ebp)
.L2:
	movl	-12(%ebp), %edx
	cmpl	$10, %edx
	jbe	.L3
	nop
	nop
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE0:
	.size	kernel, .-kernel
	.section	.text.__x86.get_pc_thunk.ax,"axG",@progbits,__x86.get_pc_thunk.ax,comdat
	.globl	__x86.get_pc_thunk.ax
	.hidden	__x86.get_pc_thunk.ax
	.type	__x86.get_pc_thunk.ax, @function
__x86.get_pc_thunk.ax:
.LFB1:
	.cfi_startproc
	movl	(%esp), %eax
	ret
	.cfi_endproc
.LFE1:
	.ident	"GCC: (GNU) 14.2.1 20240805"
	.section	.note.GNU-stack,"",@progbits

```

## 汇编

as -32 test.s -o test.o
readelf -e test.o
```c++
ELF 头：
  Magic：  7f 45 4c 46 01 01 01 00 00 00 00 00 00 00 00 00
  类别:                              ELF32
  数据:                              2 补码，小端序 (little endian)
  Version:                           1 (current)
  OS/ABI:                            UNIX - System V
  ABI 版本:                          0
  类型:                              REL (可重定位文件)
  系统架构:                          Intel 80386
  版本:                              0x1
  入口点地址：              0x0
  程序头起点：              0 (bytes into file)
  Start of section headers:          736 (bytes into file)
  标志：             0x0
  Size of this header:               52 (bytes)
  Size of program headers:           0 (bytes)
  Number of program headers:         0
  Size of section headers:           40 (bytes)
  Number of section headers:         15
  Section header string table index: 14

节头：
  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            00000000 000000 000000 00      0   0  0
  [ 1] .group            GROUP           00000000 000034 000008 04     12   8  4
  [ 2] .text             PROGBITS        00000000 00003c 000050 00  AX  0   0  1
  [ 3] .rel.text         REL             00000000 000228 000018 08   I 12   2  4
  [ 4] .data             PROGBITS        00000000 00008c 00000f 00  WA  0   0  4
  [ 5] .bss              NOBITS          00000000 0000a0 000400 00  WA  0   0 32
  [ 6] .text.__x86.[...] PROGBITS        00000000 0000a0 000004 00 AXG  0   0  1
  [ 7] .comment          PROGBITS        00000000 0000a4 00001c 01  MS  0   0  1
  [ 8] .note.GNU-stack   PROGBITS        00000000 0000c0 000000 00      0   0  1
  [ 9] .note.gnu.pr[...] NOTE            00000000 0000c0 000028 00   A  0   0  4
  [10] .eh_frame         PROGBITS        00000000 0000e8 000050 00   A  0   0  4
  [11] .rel.eh_frame     REL             00000000 000240 000010 08   I 12  10  4
  [12] .symtab           SYMTAB          00000000 000138 0000a0 10     13   4  4
  [13] .strtab           STRTAB          00000000 0001d8 00004d 00      0   0  1
  [14] .shstrtab         STRTAB          00000000 000250 00008d 00      0   0  1
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  L (link order), O (extra OS processing required), G (group), T (TLS),
  C (compressed), x (unknown), o (OS specific), E (exclude),
  D (mbind), p (processor specific)

本文件中没有程序头。
```

## 链接

ld -m elf_i386 -static test.o -o test.out -e kernel
