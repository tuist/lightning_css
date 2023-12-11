Application.ensure_all_started(:lightning_css)

Mimic.copy(LightningCSS.Architectures)
Mimic.copy(LightningCSS.Configuration)
Mimic.copy(LightningCSS.Installer)
Mimic.copy(LightningCSS.Paths)
Mimic.copy(LightningCSS.Runner)
Mimic.copy(LightningCSS.Versions)

ExUnit.start()
