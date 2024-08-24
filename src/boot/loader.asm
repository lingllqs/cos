    [org 0x1000]

    dw 0x55aa ; 魔数，用于错误检测

    mov si, str_loading
    call print

    ;xchg bx, bx ; bochs 魔术断点

detect_memory:
    xor ebx, ebx ; ebx 置为 0, 每次中断返回 BIOS 会更新此值

    mov ax, 0
    mov es, ax
    mov edi, ards_buffer ; BIOS 将内存信息写入到 es:di 指向内存位置

    mov edx, 0x534d4150 ; 该16进制数字为 SMAP ascii 码

.next:
    mov eax, 0xe820 ; 0x15 BIOS 中断的检测内存的功能号为 0xe820
    mov ecx, 0x14 ; ARDS 结构的大小(Byte)
    int 0x15

    jc error ; 检测 CF 标志位，置位则表示出错

    add di, cx ; 指向下一个结构体

    inc word [ards_count] ; 将结构体数量加一

    cmp ebx, 0 ; 为 0 表示最后一个结构体
    jnz .next

    mov si, str_detecting
    call print
    

    ; 内存检测完成后进入保护模式阶段
    jmp prepare_protected_mode

    ;xchg bx, bx

    ;mov cx, [ards_count]
    ;mov si, 0

    ; 简单的查看
;.show:
;    ; ards_buffer 存放各段内存信息
;    mov eax, [ards_buffer + si]      ; 基地址
;    mov ebx, [ards_buffer + si + 8]  ; 内存长度
;    mov edx, [ards_buffer + si + 16] ; 内存类型，1 表示操作系统可用，2 表示操作系统不可用
;    add si, 20
;
;    xchg bx, bx ; bochs 魔术断点
;
;    loop .show
;
;jmp $
    ;

prepare_protected_mode:
    cli ; 关中断

    ; 打开A20地址线
    in al, 0x92
    or al, 0b10
    out 0x92, al

    ; 加载gdt表
    lgdt [gdt_ptr]

    ; 启动保护模式
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; 使用一个跳转指令来刷新缓存，真正进入保护模式
    jmp dword code_selector:protect_mode


print:
    mov ah, 0x0e
.next:
    mov al, [si]
    cmp al, 0x00
    jz .done
    int 0x10
    inc si
    jmp .next

.done:
    ret


str_loading:
    db "Loading minios...", 0x0a, 0x0d, 0x00

str_detecting:
    db "Decting Menory success...", 0x0a, 0x0d, 0x00

error:
    mov si, .msg
    call print
    hlt ; 停止 CPU
    jmp $
    .msg db "Loading error...", 0x0a, 0x0d, 0x00



[bits 32] ; 32位代码标志
protect_mode:
    ; 将非代码段寄存器初始化为数据段起始地址
    mov ax, data_selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov esp, 0x10000

    mov edi, 0x10000 ; 将硬盘数据读取到内存 0x10000 位置开始
    mov ecx, 10      ; 起始扇区号
    mov bl, 200      ; 读取扇区数量
    call read_disk

    jmp dword code_selector:0x10000

    ud2 ; 出错

jmp $

read_disk:
    ; 设置读取参数
    mov dx, 0x1f2
    mov al, bl
    out dx, al

    inc dx ; 0x1f3
    mov al, cl ; 0~7 位
    out dx, al

    inc dx ; 0x1f4
    shr ecx, 8
    mov al, cl
    out dx, al

    inc dx ; 0x1f5
    shr ecx, 8
    mov al, cl
    out dx, al

    inc dx ; 0x1f6
    shr cx, 8
    and cl, 0b1111      ; 扇区号高 4 位保存在 cl 寄存器低四位
    mov al, 0b1110_0000 ; 第4位0表示主盘，第6位1表示LBA方式，第5、7位固定为1
    or al, cl
    out dx, al

    inc dx ; 0x1f7
    mov al, 0x20 ; 0x20 为读硬盘，0x30 为写硬盘
    out dx, al

    ; 参数设置完毕，准备读取
    xor ecx, ecx ; 清空 ecx 寄存器
    mov cl, bl ; 保存读取扇区数量到 cl 寄存器(cx 寄存器用于循环计数)

.read:
    push cx                 ; 读取一个扇区时修改了 cx 寄存器，需要保存之前的 cx 数据
    call .wait_disk_leisure ; 等待硬盘空闲
    call .read_sec          ; 读取扇区
    pop cx                  ; 回复 cx 数据
    loop .read              ; 循环读取cl个扇区数

    ret

.wait_disk_leisure:
    mov dx, 0x1f7
.check:
    in al, dx           ; 读取端口数据以判断硬盘状态
    jmp $+2             ; 跳转下一行，延迟
    jmp $+2             ; 跳转下一行，延迟
    jmp $+2             ; 跳转下一行，延迟
    and al, 0b1000_1000 ; 保留第3位(DRQ)和第7位(BSY)
    cmp al, 0b0000_1000 ; al数据和‘硬盘数据准备完毕且硬盘空闲'状态比较
    jnz .check          ; 硬盘繁忙则继续检测

    ret

    ; 读取一个扇区数据
.read_sec:
    mov dx, 0x1f0 ; 主盘数据端口 0x1f0
    mov cx, 256   ; 一次读取一个字，读取256次
.read_word:
    in ax, dx ; 从端口中读取一个字数据到ax寄存器
    jmp $+2
    jmp $+2
    jmp $+2
    mov [edi], ax ; 数据保存到0x10000
    add edi, 2    ; 读取下一个字
    loop .read_word

    ret


; RPL(Request Privilege Level) 2 bit, TI 1 bit GDT index 索引 13 bit
; 代码段在gdt的第1个表中,第0个是NULL, TI 为0表示GDT，TI 为1表示LDT
code_selector equ (1 << 3)

; 数据段在gdt的第2个表中,RPL 和 TI 都为0 所以只需左移3位
data_selector equ (2 << 3)

memory_base equ 0                                            ; 内存起始位置: 基地址
memory_limit equ ((1024 * 1024 * 1024 * 4) / (1024 * 4)) - 1 ; 粒度为4k，内存界限

    ; gdt位置信息
gdt_ptr:
    dw ((gdt_end - gdt_base) - 1) ; GDT 段长度(界限)
    dd gdt_base                 ; 访问起始内存

    ; GDT 三个(NULL,代码段,数据段)
gdt_base:
    dd 0, 0 ; NULL 32bit
gdt_code:
    dw memory_limit & 0xffff                 ; 0~15位段界限
    dw memory_base & 0xffff                  ; 16~31位基地址
    db (memory_base >> 16) & 0xff            ; 32~39位基地址
    db 0b10011010                              ; 在内存中(1)特权级(00)非系统段(1)代码段(1)非依从代码(0)可读(1)未被CPU访问过(0)
    db 0b11000000 | (memory_limit >> 16) & 0xf ; 粒度(1)32位(1)64位扩展(0)available(0)内存界限最后高4位
    db (memory_base >> 24) & 0xff            ; 56~63位基地址最后高8位
gdt_data:
    dw memory_limit & 0xffff                 ; 0~15位段界限
    dw memory_base & 0xffff                  ; 16~31位基地址
    db (memory_base >> 16) & 0xff            ; 32~39位基地址
    db 0b10010010                              ; 在内存中(1)特权级(00)非系统段(1)数据段(0)向上扩展(0)可写(1)未被CPU访问过(0)
    db 0b11000000 | (memory_limit >> 16) & 0xf 
    ; 粒度(1)32位(1)64位扩展(0)available(0)内存界限最后高4位
    db (memory_base >> 24) & 0xff            ; 基地址最后高8位
gdt_end:


ards_count:
    dw 0
ards_buffer:

