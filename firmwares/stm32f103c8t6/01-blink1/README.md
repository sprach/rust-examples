# Project: Blink1

STM32F103C8T6 펌웨어 개발 프로젝트입니다.
LED(PA4)가 1초마다 깜빡이는 기능을 수행합니다.

## 1. 개요 및 요구사항
### 1.1 목표
- MCU: STM32F103C8T6
- 기능: 1초 간격으로 LED(PA4) 점멸 (Toggle)
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
        - USART1: PA9(TX), PA10(RX)
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
    - System Clock 및 GPIOA 초기화
    - PA4를 **Push-Pull Output**으로 설정
    - `cp.SYST`를 이용한 Delay 생성
    - `loop` 문에서 1초 간격으로 `set_low()` / `set_high()` 반복

---

## 3. 빌드 및 배포 (Build & Distribution)
### 3.1 사전 요구사항
- Rust Toolchain 설치 (`rustup`)
- 타겟 추가: `rustup target add thumbv7m-none-eabi`
- ARM Toolchain (선택): `.bin` 파일 생성을 위한 `arm-none-eabi-objcopy`

### 3.2 빌드 명령어
#### 방법 1: VS Code Task (추천)
- 단축키: **`Ctrl + Shift + B`**
- 동작: 자동으로 `make_fw.ps1` 스크립트를 실행하여 빌드 및 바이너리 생성을 수행합니다.

#### 방법 2: PowerShell 스크립트 실행
터미널에서 직접 실행:
```powershell
./make_fw.ps1
```
- 결과물: `target/thumbv7m-none-eabi/release/f103-blink1_vXXXX.bin` (버전별 네이밍 적용)

#### 방법 3: 수동 Cargo 빌드 (ELF 파일만 생성)
```bash
cargo build --release
```

### 3.3 출력 파일
- **ELF**: `target/thumbv7m-none-eabi/release/blink1` (디버깅/플래싱 도구용)
- **BIN**: `target/thumbv7m-none-eabi/release/f103-blink1_v0100.bin` (펌웨어 배포용)

---

## 4. 주의사항 및 참고 (Precautions)
### 4.1 LED 회로 구성 (Active Low vs High)
- 현재 코드는 **Push-Pull** 모드로 동작하며, `set_low`와 `set_high`를 반복합니다.
- 만약 LED가 VCC에 연결된 풀업 회로(Active Low)라면 `set_low`시 켜지고 `set_high`시 꺼집니다.
- 반대로 GND에 연결된 회로(Active High)라면 `set_high`시 켜집니다.
- 본 펌웨어는 상태를 1초마다 반전시키므로 회로 구성과 관계없이 점멸은 정상 동작합니다.

### 4.2 Cargo Workspace 경고
빌드 시 다음과 같은 경고가 발생할 수 있습니다:
```text
warning: virtual workspace defaulting to resolver = "1" ...
```
- 이는 루트 `Cargo.toml`의 workspace 설정과 관련된 Rust 에디션 호환성 경고입니다.
- **빌드 결과물에는 영향을 주지 않으므로** 무시해도 좋습니다. (해결을 원하면 루트 `Cargo.toml`에 `resolver = "2"` 추가)

### 4.3 Workspace 워크어라운드
- 전체 Workspace 빌드 오류를 방지하기 위해, 동일 Workspace 내의 다른 빈 프로젝트 폴더(`02-blink2`, `esp32/*` 등)에 임시 `Cargo.toml`과 `main.rs`가 포함되어 있을 수 있습니다.
