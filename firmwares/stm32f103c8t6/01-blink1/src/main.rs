#![no_std]
#![no_main]

use core::fmt::Write;
use cortex_m_rt::entry;
use panic_halt as _;
use stm32f1xx_hal::{
    pac,
    prelude::*,
    serial::{Config, Serial},
    time::U32Ext,
};

#[entry]
fn main() -> ! {
    // Core peripheral 획득
    let cp = cortex_m::Peripherals::take().unwrap();
    // Device specific peripheral 획득
    let dp = pac::Peripherals::take().unwrap();

    // Flash 및 RCC 소유권 획득, HAL 구조체로 변환
    let mut flash = dp.FLASH.constrain();
    let rcc = dp.RCC.constrain();

    // 시스템 클럭 설정: 기본값 (HSI 8MHz)
    // 별도 설정 없이 freeze()를 호출하면 HSI(내부 클럭)가 사용된다.
    let clocks = rcc.cfgr.freeze(&mut flash.acr);

    // GPIOA peripheral 획득
    let mut gpioa = dp.GPIOA.split();
    let mut afio = dp.AFIO.constrain();

    // USART1 (PA9/PA10)
    let tx = gpioa.pa9.into_alternate_push_pull(&mut gpioa.crh);
    let rx = gpioa.pa10;

    // USART1 초기화
    // param 1: USART1 peripheral (데이터 송수신 담당)
    // param 2: (TX, RX) 핀 튜플 (PA9, PA10)
    // param 3: AFIO 매핑 레지스터 (핀 기능 매핑)
    //          (AFIO: Alternate Function Input/Output)
    // param 4: 통신 설정 (Baudrate 115200)
    // param 5: 시스템 클럭 (Baudrate 계산용)
    let mut serial = Serial::new(
        dp.USART1,
        (tx, rx),
        &mut afio.mapr,
        Config::default().baudrate(115200.bps()),
        &clocks,
    );

    writeln!(serial, "Firmware Start\r").unwrap();

    // GPIO PA4를 Push-Pull Output으로 설정
    // Active Low 설정 (Low = ON, High = OFF)
    let mut led = gpioa.pa4.into_push_pull_output(&mut gpioa.crl);

    // Delay provider 생성
    let mut delay = cp.SYST.delay(&clocks);

    #[cfg(debug_assertions)]
    let mut led_count: u32 = 0;

    loop {
        // LED 점멸 루프 (1초 간격)

        // LED ON (Active Low)
        #[cfg(debug_assertions)]
        {
            led_count += 1;
            writeln!(serial, "LED ON (Count: {})\r", led_count).unwrap();
        }
        #[cfg(not(debug_assertions))]
        writeln!(serial, "LED ON\r").unwrap();

        led.set_low();
        delay.delay_ms(1000u32);

        // LED OFF (Active Low)
        led.set_high();
        writeln!(serial, "LED OFF\r").unwrap();
        delay.delay_ms(1000u32);
    }
}
