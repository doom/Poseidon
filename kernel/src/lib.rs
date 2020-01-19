#![no_std]
#![feature(core_intrinsics)]

use core::intrinsics::volatile_store;
use core::panic::PanicInfo;

#[panic_handler]
fn panic_handler(_: &PanicInfo) -> !
{
    loop {}
}

#[no_mangle]
pub extern fn main()
{
    unsafe {
        let vga = 0xb8000 as *mut u16;

        volatile_store(vga, 0x024f);
        volatile_store(vga.offset(1), 0x024b);
    }
    loop {}
}
