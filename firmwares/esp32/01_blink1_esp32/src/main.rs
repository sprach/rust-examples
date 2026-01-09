#![no_std]
#![no_main]

use esp_backtrace as _;
use esp_hal::{
    delay::Delay,
    gpio::{Level, Output, OutputConfig},
};
use esp_println::println;

// Function to create a fixed-size array from a string slice
const fn str_to_array<const N: usize>(s: &str) -> [u8; N] {
    let mut arr = [0u8; N];
    let bytes = s.as_bytes();
    let len = if bytes.len() > N { N } else { bytes.len() };
    let mut i = 0;
    while i < len {
        arr[i] = bytes[i];
        i += 1;
    }
    arr
}

#[repr(C)]
pub struct AppDesc {
    magic_word: u32,
    secure_version: u32,
    reserv1: [u32; 2],
    version: [u8; 32],
    project_name: [u8; 32],
    time: [u8; 16],
    date: [u8; 16],
    idf_ver: [u8; 32],
    app_elf_sha256: [u8; 32],
    reserv2: [u32; 20],
}

#[link_section = ".rodata_desc"]
#[no_mangle]
#[used]
pub static APP_DESC: AppDesc = AppDesc {
    magic_word: 0xABCD5432,
    secure_version: 0,
    reserv1: [0; 2],
    version: str_to_array("0.1.0"),
    project_name: str_to_array("blink1_esp32"),
    time: str_to_array("00:00:00"),
    date: str_to_array("2024-01-01"),
    idf_ver: str_to_array("0.0.0"),
    app_elf_sha256: [0; 32],
    reserv2: [0; 20],
};

#[esp_hal::main]
fn main() -> ! {
    let peripherals = esp_hal::init(esp_hal::Config::default());
    // 1.0.0-rc.3: Output::new takes 3 args
    let mut led = Output::new(peripherals.GPIO40, Level::Low, OutputConfig::default());

    // 1.0.0-rc.3: Delay::new takes 0 args (if configured correctly)
    let delay = Delay::new();

    println!("Blink Start! (1.0.0-rc.3 on 1.89 - Manual AppDesc)");

    loop {
        led.toggle();
        println!("Blink!");
        delay.delay_millis(1000);
    }
}
