#![no_std]
#![no_main]

use cortex_m_rt::entry;
use panic_halt as _;
use stm32f1xx_hal::{pac, prelude::*};

#[entry]
fn main() -> ! {
    // Get access to the core peripherals from the cortex-m crate
    let cp = cortex_m::Peripherals::take().unwrap();
    // Get access to the device specific peripherals from the peripheral access crate
    let dp = pac::Peripherals::take().unwrap();

    // Take ownership over the raw flash and rcc devices and convert them into the corresponding
    // HAL structs
    let mut flash = dp.FLASH.constrain();
    let rcc = dp.RCC.constrain();

    // Freeze the configuration of all the clocks in the system and store the frozen frequencies in
    // `clocks`
    let clocks = rcc.cfgr.freeze(&mut flash.acr);

    // Acquire the GPIOA peripheral
    let mut gpioa = dp.GPIOA.split();

    // Configure gpio PA4 as a push-pull output. The `cr` register is passed to the function
    // to configure the port. For robust application, often specific initial state is desired.
    // The "Pullup" in requirements might refer to external circuit, but for driving LED:
    // PushPull is standard. If OpenDrain is needed with Pullup, it would be into_open_drain_output.
    // However, blinky usually drives output.
    let mut led = gpioa.pa4.into_push_pull_output(&mut gpioa.crl);

    // Get delay provider
    let mut delay = cp.SYST.delay(&clocks);

    loop {
        // Blink logic: 1s ON, 1s OFF

        // Turn LED on (Low or High depending on circuit, usually Low for common cathode, High for common anode)
        // Assuming Active High for now given "Pullup" isn't explicitly "Pullup Input".
        // But if the requirement says "LED(PA4, Pullup)", it might imply the LED is connected to VCC
        // and the pin pulls it low to turn on (Active Low), and has a pullup resistor?
        // Let's implement toggling.

        led.set_low();
        delay.delay_ms(1000u32);

        led.set_high();
        delay.delay_ms(1000u32);
    }
}
