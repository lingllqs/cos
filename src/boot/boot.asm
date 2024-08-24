    ; 代码起始内存位置
    [org 0x7c00]

    ; 设置屏幕模式为文本模式，清屏
    mov ax, 3
    int 0x10


    ; 初始化段寄存器
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00

    ; 0xb8000 为为本显示器内存区域
    ; 实模式寻址方式 EA(effective address) = 段地址 * 0x10 + 偏移地址
    ; 8086 处理器地址线有20条，需要寻址范围为 1M(20bit)，也就是 2^20(bit)
    ; 寄存器的位数是16bit，因此需要特别方式才能寻址20bit长度的内存地址
    ;mov ax, 0xb800
    ;mov ds, ax
    ;mov byte [0], 'H'
    ;mov byte [2], 'e'
    ;mov byte [4], 'l'
    ;mov byte [6], 'l'
    ;mov byte [8], 'o'


    ; 将源指针指向字符串开始，并调用 print 函数
    mov si, str_booting
    call print


    ; 读取硬盘
    mov edi, 0x1000 ; 将硬盘数据读取到内存 0x10000 位置开始
    mov ecx, 2      ; 起始扇区号
    mov bl, 4       ; 读取扇区数量
    call read_disk

    cmp word [0x1000], 0x55aa
    jnz error
    jmp 0:0x1002

    ;xchg bx, bx ; bochs 魔术断点

    ; 阻塞 $ 表示当前位置
    jmp $




    ; 定义读取山区函数
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
    and cl, 0b1111 ; 扇区号高 4 位保存在 cl 寄存器低四位
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


error:
    mov si, .msg
    call print
    hlt ; 停止 CPU
    jmp $
    .msg db "Booting error...", 0x0a, 0x0d, 0x00


    ; 定义 print 函数
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

    ; 定义一个正在引导信息字符串
str_booting:
    db "Booting minios...", 0x0a, 0x0d, 0x00 ; 0x0a 为换行，0x0d 为回车，0x00 为字符串结束

    ; 不满512字节区域填充0
    times 510 - ($ - $$) db 0x00

    ; 主引导扇区标志
    db 0x55, 0xaa


; 写硬盘
;write_disk:
;    ; 设置写入参数
;    mov dx, 0x1f2
;    mov al, bl
;    out dx, al
;
;    inc dx ; 0x1f3
;    mov al, cl ; 0~7 位
;    out dx, al
;
;    inc dx ; 0x1f4
;    shr ecx, 8
;    mov al, cl
;    out dx, al
;
;    inc dx ; 0x1f5
;    shr ecx, 8
;    mov al, cl
;    out dx, al
;
;    inc dx ; 0x1f6
;    shr cx, 8
;    and cl, 0b1111 ; 扇区号高 4 位保存在 cl 寄存器低四位
;    mov al, 0b1110_0000 ; 第4位0表示主盘，第6位1表示LBA方式，第5、7位固定为1
;    or al, cl
;    out dx, al
;
;    inc dx ; 0x1f7
;    mov al, 0x30 ; 0x20 为读硬盘，0x30 为写硬盘
;    out dx, al
;
;    ; 参数设置完毕，准备写入
;    xor ecx, ecx ; 清空 ecx 寄存器
;    mov cl, bl ; 保存写入扇区数量到 cl 寄存器(cx 寄存器用于循环计数)
;
;    .write:
;        push cx                 ; 写入一个扇区时修改了 cx 寄存器，需要保存之前的 cx 数据
;        call .wait_disk_leisure ; 等待硬盘空闲
;        call .write_sec         ; 写入一个扇区
;        pop cx                  ; 回复 cx 数据
;        loop .write             ; 循环写入cl个扇区数
;    ret
;
;    .wait_disk_leisure:
;        mov dx, 0x1f7
;        .check:
;            in al, dx           ; 读取端口数据以判断硬盘状态
;            jmp $+2             ; 跳转下一行，延迟
;            jmp $+2             ; 跳转下一行，延迟
;            jmp $+2             ; 跳转下一行，延迟
;            and al, 0b1000_0000 ; 保留第3位(DRQ)和第7位(BSY)
;            cmp al, 0b0000_0000 ; al数据和‘硬盘空闲'状态比较
;            jnz .check          ; 硬盘繁忙结束继续
;        ret
;
;        ; 写入一个扇区数据
;    .write_sec:
;        mov dx, 0x1f0 ; 主盘数据端口 0x1f0
;        mov cx, 256   ; 一次写入一个字，写入256次
;        .write_word:
;            mov ax, [edi]
;            out dx, ax
;            jmp $+2
;            jmp $+2
;            jmp $+2
;            add edi, 2    ; 写入下一个字
;            loop .write_word
;
;        ret
