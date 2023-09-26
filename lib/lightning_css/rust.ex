defmodule LightningCSS.Rust do
  use Rustler, otp_app: :lightning_css, crate: "lightning_css_rust"

  # When your NIF is loaded, it will override this function.
  def add(_a, _b), do: :erlang.nif_error(:nif_not_loaded)
end
