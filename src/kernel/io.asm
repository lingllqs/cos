    [bits 32]

    section .text ; 代码段
    global inb    ; 导出 inb 函数
inb:
    push ebp
    mov ebp, esp

    xor eax, eax
    mov edx, [ebp + 8] ; 端口号
    in al, dx

    ; 延迟
    jmp $+2
    jmp $+2
    jmp $+2

    leave ; 恢复栈帧
    ret

    global outb
outb:
    push ebp
    mov ebp, esp
    
    mov edx, [ebp + 8] ; port
    mov eax, [ebp + 12] ; value
    out dx, al

    jmp $+2
    jmp $+2
    jmp $+2

    leave
    ret

    global intw
intw:
    push ebp
    mov ebp, esp

    xor eax, eax
    mov edx, [ebp + 8] ; port
    in ax, dx

    jmp $+2
    jmp $+2
    jmp $+2

    leave
    ret

    global outw
outw:
    push ebp
    mov ebp, esp

    mov edx, [ebp + 8]
    mov eax, [ebp + 12]
    out dx, ax

    jmp $+2
    jmp $+2
    jmp $+2

    leave
    ret
