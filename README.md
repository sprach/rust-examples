# Rust Embedded Examples Repository

Rust를 이용한 다양한 임베디드 펌웨어 및 애플리케이션 예제 통합 저장소입니다.
STM32, ESP32 등 다양한 MCU 타겟과 PC 기반 Rust 애플리케이션을 포함합니다.

---

## 1. 프로젝트 개요 (Overview)
- **목표**: Rust 임베디드 생태계 학습 및 실무 적용 가능한 레퍼런스 코드 구축
- **주요 대상 하드웨어**:
    - STM32F103 (Cortex-M3)
    - ESP32 (Xtensa / RISC-V)
- **주요 기능**:
    - Workspace 기반의 멀티 프로젝트 관리
    - Cross-Compilation 환경 구성
    - VS Code 연동 자동 빌드 시스템

---

## 2. 폴더 구조 (Project Structure)
본 저장소는 Cargo Workspace 기능을 사용하여 여러 프로젝트를 통합 관리합니다.

```text
rust-examples/
├── apps/                   # PC/Server 사이드 애플리케이션
│   ├── dotnet/             # .NET 테스트/연동 앱 (참고용)
│   └── rust/               # Rust 기반 PC 앱 (Agent, Tools 등)
│
├── firmwares/              # MCU 펌웨어 소스
│   ├── stm32f103c8t6/      # STM32F1 시리즈 펌웨어
│   │   ├── 01-blink1/      # 기본 LED 제어 예제
│   │   └── ...
│   └── esp32/              # ESP32 시리즈 펌웨어
│
├── help/                   # 프로젝트 관련 문서 및 가이드
├── .vscode/                # VS Code 설정 (Task, Launch 등)
├── Cargo.toml              # Workspace 루트 설정 파일
└── target/                 # 빌드 결과물 (Git 제외됨)
```

---

## 3. 환경 설정 (Setup)
### 3.1 필수 요구사항
1.  **Rust Toolchain**: `rustup` 설치 필수
2.  **Cross Compilation Targets**:
    ```bash
    rustup target add thumbv7m-none-eabi       # Cortex-M3 (STM32F1)
    rustup target add riscv32imc-unknown-none-elf # ESP32-C3 (Optional)
    ```
3.  **Tools**:
    - `cargo-binutils` (LLVM 도구 모음): `cargo install cargo-binutils`
    - `rust-objcopy`: 바이너리 변환용 (VS Code Task에서 사용)

### 3.2 VS Code 확장 (Extensions)
- **rust-analyzer**: 코드 자동완성 및 분석 (필수)
- **CodeLLDB**: 디버깅 용도
- **Even Better TOML**: TOML 파일 편집기

---

## 4. 설정 파일 설명 (Configuration)
### 4.1 Root `Cargo.toml`
Workspace 전체의 공통 설정을 관리합니다.
- `[workspace]`: 하위 프로젝트(`members`) 지정
- `resolver = "2"`: Rust 2021 Edition 호환성 설정
- `[profile.release]`: 펌웨어 최적화 설정 (`opt-level = "z"`, `lto = true` 등)

### 4.2 Project `Cargo.toml`
개별 프로젝트의 의존성을 관리합니다.
- 예: `cortex-m`, `stm32f1xx-hal`, `embedded-hal` 등

### 4.3 `.cargo/config.toml` (각 펌웨어 폴더)
해당 펌웨어의 타겟별 링커 설정 및 러너(Probe-rs 등)를 정의합니다.

---

## 5. 설계 및 구현 가이드 (Design & Implementation)
**프로젝트 진행 시 반드시 고려해야 할 핵심 사항들입니다.**

### 5.1 Cargo Workspace 관리
- 모든 하위 프로젝트는 Root `Cargo.toml`의 `members`에 포함되어야 합니다.
- 빈 폴더가 있다면 임시 `Cargo.toml`을 생성하여 Workspace 에러를 방지해야 합니다.

### 5.2 최적화 및 빌드 프로필
- 임베디드 장치 특성상 **바이너리 크기 최적화**가 필수적입니다.
- Root `Cargo.toml`의 `[profile.release]` 섹션에서 `lto`, `codegen-units`, `panic="abort"` 설정을 유지하십시오.

### 5.3 바이너리 생성 자동화
- `cargo build`는 기본적으로 ELF 파일만 생성합니다.
- 배포를 위해 `.bin` 또는 `.hex` 파일이 필요한 경우, 각 프로젝트 내의 `make_fw.ps1` 스크립트나 VS Code Task를 활용하여 자동화하십시오.
- **네이밍 규칙**: `MCU모델-프로젝트명_v버전.bin` (예: `f103-blink1_v0101.bin`)

### 5.4 하드웨어 추상화 (HAL)
- 직접 레지스터를 조작하기보다 `embedded-hal` 트레이트와 제조사 HAL(`stm32f1xx-hal` 등)을 사용하여 이식성을 높이십시오.
- 핀 설정 시 **Active High/Low** 여부를 주석으로 명시하여 회로 변경에 유연하게 대처하십시오.

---

## 6. 참고 라이브러리 (References)
- **embedded-hal**: 임베디드 하드웨어 추상화 계층 표준
- **cortex-m**: ARM Cortex-M 프로세서용 저수준 접근
- **cortex-m-rt**: 런타임 및 스타트업 코드
- **panic-halt**: 패닉 발생 시 동작 정의 (무한루프 등)
