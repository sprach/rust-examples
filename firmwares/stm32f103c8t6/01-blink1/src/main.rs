#![no_std]
#![no_main]

use cortex_m_rt::entry;
use panic_halt as _;
use stm32f1xx_hal::{pac, prelude::*};

#[entry]
fn main() -> ! {
    // Core peripheral 획득
    let cp = cortex_m::Peripherals::take().unwrap();
    // Device specific peripheral 획득
    let dp = pac::Peripherals::take().unwrap();

    // Flash 및 RCC 소유권 획득, HAL 구조체로 변환
    let mut flash = dp.FLASH.constrain();
    let rcc = dp.RCC.constrain();

    // 시스템 클럭 설정 동결 (기본 설정 사용)
    let clocks = rcc.cfgr.freeze(&mut flash.acr);

    // GPIOA peripheral 획득
    let mut gpioa = dp.GPIOA.split();

    // PA4를 Push-Pull Output으로 설정
    let mut led = gpioa.pa4.into_push_pull_output(&mut gpioa.crl);

    // Delay provider 생성
    let mut delay = cp.SYST.delay(&clocks);

    loop {
        // LED 점멸 루프 (1초 간격)

        // LED Low (회로에 따라 ON/OFF 결정됨)
        led.set_low();
        delay.delay_ms(1000u32);

        // LED High
        led.set_high();
        delay.delay_ms(1000u32);
    }
}
