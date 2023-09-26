#[rustler::nif(schedule = "DirtyCpu")]
fn add(a: i64, b: i64) -> i64 {
    a + b
}

rustler::init!("Elixir.LightningCSS.Rust", [add]);
