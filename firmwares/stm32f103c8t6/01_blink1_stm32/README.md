# Project: Blink1 STM32

STM32F103C8T6 펌웨어 개발 프로젝트입니다.
LED(PA4)가 1초마다 깜빡이는 기능을 수행합니다.

## 1. 개요 및 요구사항
### 1.1 목표
- MCU: STM32F103C8T6
- 기능: 1초 간격으로 LED(PA4) 점멸 (Toggle), UART1 로그 출력
- 구현 언어: Rust (Embedded)

### 1.2 하드웨어 스펙
- **MCU**: STM32F103C8T6
- **Pins Definition**:
    - **Signal LEDs**:
        - **PA4**: LED1 (#14) - **(본 프로젝트 사용 핀)**
        - PA5: LED2 (#15)
        - PA6: LED3 (#16)
        - PA7: LED4 (#17)
        - PB0: LED5 (#18)
    - **Communication**:
        - **USART1**: PA9(TX), PA10(RX) - **(로그 출력용, 115200bps)**
        - I2C2: PB10(SCL), PB11(SDA)
        - I2C2 LEDs (Serial용 핀 변경): PB8(TX -> SCL), PB9(RX -> SDA)
    - **Signal Inputs**:
        - PA8(SIG1), PB15(SIG2), PB14(SIG3), PB13(SIG4), PB12(SIG5)
- **I2C Address**: 0xA1 (MAGNET)

---

## 2. 구현 방법 (Implementation)
### 2.1 개발 환경
- **언어**: Rust (Edition 2021)
- **프레임워크**: `stm32f1xx-hal` (Embedded HAL)
- **Toolchain**: `thumbv7m-none-eabi`

### 2.2 소스 코드 구조
- `src/main.rs`: 주요 로직
    - System Clock: HSI (Internal 8MHz) 사용
    - GPIO PA4: **Push-Pull Output** (Standard Drive)
    - UART1: 115200bps, 8N1 (PA9/PA10)
    - Loop: 1초 간격 Toggle 및 로그 출력

---

## 3. 빌드 및 배포 (Build & Distribution)
### 3.1 사전 요구사항
- Rust Toolchain 설치 (`rustup`)
- 타겟 추가: `rustup target add thumbv7m-none-eabi`
- Tools: `cargo-binutils`

### 3.2 빌드 명령어
#### 방법 1: VS Code Task (추천)
- 단축키: **`Ctrl + Shift + B`**
- 동작: 자동으로 `make_fw.ps1` 스크립트를 실행하여 빌드 및 바이너리 생성을 수행합니다.

#### 방법 2: PowerShell 스크립트 실행
터미널에서 직접 실행:
```powershell
./make_fw.ps1
```
- **기능 개선**:
    - **Resource Usage 표시**: 빌드 성공 시 RAM/Flash 사용량 및 비율을 시각적으로 표시합니다.
    - **Log Redirection 지원**: `./make_fw.ps1 > build.log`와 같이 실행하면 Warning/Error를 포함한 모든 로그를 파일로 저장할 수 있습니다.
- **결과물**: `target/thumbv7m-none-eabi/release/f103-blink1_stm32_vXXXX.bin`

#### 방법 3: 수동 Cargo 빌드 (ELF 파일만 생성)
```bash
cargo build --release
```

### 3.3 출력 파일
- **BIN**: `target/thumbv7m-none-eabi/release/f103-blink1_stm32_v0102.bin` (펌웨어 배포용)

### 3.4 디버깅 (Debugging)
VS Code에서 `F5` 키를 통해 바로 디버깅이 가능합니다. (`probe-rs` 사용)

1.  **Run and Debug (Ctrl+Shift+D)** 패널로 이동
2.  **Debug (probe-rs)**: 개발용 (브레이크포인트, 변수 확인 가능, 최적화 끔)
3.  **Release (probe-rs)**: 배포용 테스트 (최적화 됨, 브레이크포인트 제한적)

> **Tip**: `main.rs`의 `led_count` 변수는 `Debug` 모드에서만 활성화됩니다.

---

## 4. 주의사항 및 참고 (Precautions)
### 4.1 부트 모드 설정 (BOOT0)
- 펌웨어 플래싱 후 정상 동작을 위해서는 반드시 **BOOT0 점퍼를 0 (GND)**으로 설정하고 리셋해야 합니다.
- BOOT0=1 상태에서는 User Flash 코드가 실행되지 않습니다.

### 4.2 Cargo Workspace 경고
빌드 시 `warning: virtual workspace defaulting to resolver = "1" ...` 경고가 발생할 수 있으나, 결과물에는 영향이 없습니다.
(Root Cargo.toml 수정으로 해결 가능)
