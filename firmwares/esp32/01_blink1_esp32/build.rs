fn main() {
    // Link the standard ESP32-S3 linker scripts
    println!("cargo:rustc-link-arg=-Tlinkall.x");
    println!("cargo:rerun-if-changed=build.rs");
}
