#![no_std] // 金庸标准库
#![no_main] // 不使用一般入口点

use core::panic::PanicInfo;

mod vga_buffer;

/// 出现 panic 时调用
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

/// no_mangle 属性防止编译器修改函数名
#[no_mangle]
pub extern "C" fn _start() -> ! {
    vga_buffer::print_something();

    loop {}
}
