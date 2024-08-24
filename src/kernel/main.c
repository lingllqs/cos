#include <minios/minios.h>
#include <minios/types.h>
#include <minios/io.h>
#include <minios/string.h>
#include <minios/console.h>
#include <minios/printk.h>
#include <minios/assert.h>
#include <minios/debug.h>
#include <minios/global.h>
#include <minios/task.h>



char message[] = "hello rust!!\n";

void kernel_init()
{
    console_init();


    gdt_init();
    
    task_init();

    return;
}

