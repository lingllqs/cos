#include <minios/printk.h>
#include <minios/task.h>

#define PAGE_SIZE 0x1000 // 4k

task_t *a = (task_t *)0x1000;
task_t *b = (task_t *)0x2000;

extern void task_switch(task_t *next);

task_t *running_task()
{
    asm volatile("movl %esp, %eax\n"
                 "andl $0xfffff000, %eax\n"); // 返回值在 eax 中
}

void schedule()
{
    task_t *current = running_task();
    task_t *next = current == a ? b : a;
    task_switch(next);
}

u32 thread_a()
{
    while (true)
    {

        printk("A");
        schedule();
    }
}

u32 thread_b()
{
    while (true)
    {

        printk("B");
        schedule();
    }
}

static void task_create(task_t *task, target_t target)
{
    u32 stack = (u32)task + PAGE_SIZE; // 任务栈起始位置

    stack -= sizeof(task_frame_t); // 预留上下文位置
    task_frame_t *frame = (task_frame_t *)stack;

    frame->ebx = 0x11111111;
    frame->esi = 0x22222222;
    frame->edi = 0x33333333;
    frame->ebp = 0x44444444;
    frame->eip = (void *)target; // 保存任务的位置(栈底)

    task->stack = (u32 *)stack; // 保存上文任务栈 esp
}

void task_init()
{
    task_create(a, thread_a);
    task_create(b, thread_b);
    schedule();
}
