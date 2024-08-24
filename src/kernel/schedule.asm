    ; 人物切换
global task_switch
task_switch:
    push ebp
    mov ebp, esp

    push esi
    push edi
    push ebx

    mov eax, esp        ; 获取当前栈顶值到 eax 中
    and eax, 0xfffff000 ; 当前任务

    mov [eax], esp ; 保存当前任务的 PCB 位置到当前 PCB 的起始内存位置

    mov eax, [ebp + 8] ; 下一个任务的 PCB 地址 next
    mov esp, [eax]     ; 栈顶指向下一个任务 PCB 起始位置(切换栈)


    pop ebx
    pop edi
    pop esi
    pop ebp

    ret
