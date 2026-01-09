# Project: Blink1 ESP32

ESP32-S3-WROOM-1-N16R8 펌웨어 개발 프로젝트입니다.
LED(GPIO 40)가 1초마다 깜빡이는 기능을 수행합니다.

## 1. 개요 및 요구사항
### 1.1 목표
- **MCU**: ESP32-S3-WROOM-1-N16R8
- **기능**: 1초 간격으로 LED(GPIO 40) 점멸 (Toggle), UART1 로그 출력
- **구현 언어**: Rust (Embedded, no_std)

### 1.2 하드웨어 스펙
- **MCU**: ESP32-S3-WROOM-1-N16R8
- **Pins Definition**:
    - **Signal LEDs**:
        - **GPIO 40**: LED Green - **(본 프로젝트 사용 핀)**
        - GPIO 41: LED Yellow
        - GPIO 42: LED Red
    - **Communication**:
        - **UART1**: GPIO 17(TX), GPIO 18(RX) - **(로그 출력용, 115200bps)**
    - **Signal Inputs (Hall Sensors)**:
        - GPIO 38: Hall Sensor1
        - GPIO 39: Hall Sensor2

---

## 2. 구현 방법 (Implementation)
### 2.1 개발 환경
- **언어**: Rust (Edition 2021)
- **프레임워크**: `esp-hal`
- **Toolchain**: `xtensa-esp32s3-none-elf`

### 2.2 소스 코드 구조
- `src/main.rs`: 주요 로직
    - GPIO 40: Output (Push-Pull)
    - UART1: 115200bps (TX:17, RX:18)
    - Loop: 1초 간격 Toggle 및 로그 출력

---

## 3. 빌드 및 배포 (Build & Distribution)
### 3.1 사전 요구사항
- Rust Toolchain 설치 (`rustup`)
- ESP32 타겟 추가: 
  ```bash
  rustup toolchain install nightly
  rustup component add rust-src --toolchain nightly
  # Or for stable (if supported):
  rustup target add xtensa-esp32s3-none-elf
  ```
- Tools: `cargo-espflash` 또는 `espflash` 설치
  ```bash
  cargo install espflash
  ```

### 3.2 빌드 명령어
#### 방법 1: PowerShell 스크립트 실행
터미널에서 직접 실행:
```powershell
./make_fw.ps1
```
- **결과물**: `target/xtensa-esp32s3-none-elf/release/esp32-blink1_esp32_vXXXX.bin`

#### 방법 2: 수동 빌드 및 플래싱
1. **빌드**:
   ```bash
   cargo build --release
   ```
2. **플래싱**:
   ```bash
   espflash flash target/xtensa-esp32s3-none-elf/release/blink1_esp32 --monitor
   ```

### 3.3 출력 파일
- **BIN**: `target/xtensa-esp32s3-none-elf/release/esp32-blink1_esp32_v0100.bin`

---

## 4. 참고 사항
- `esp-hal` 라이브러리의 버전 업데이트에 따라 설정 방식이 변경될 수 있습니다.
- UART 로그는 USB PORT가 아닌 UART1 핀(17, 18)을 통해 출력됩니다. External USB-to-UART 컨버터가 필요할 수 있습니다.
