# Blind sheet: f_lens

Mark each param **P** (primary), **S** (secondary) or **?** (unsure). Primary = it sets the character of the effect (changes
what it *is*, you reach for it live, or other params depend on it). Secondary = it scales, tunes or is set once.
Few primaries per module is typical (0 to 5), not a quota. Current widgets are left off on purpose. Notes are welcome where you hesitate.

| Param | Label | Range | Default | P / S / ? | Note |
|---|---|---|---|---|---|
| `aberration` | Aberr | -1.0 to 1.0 | 0.0 |  |  |
| `distortion` | Distort | -1.0 to 1.0 | 0.0 |  |  |
| `transmission` | Trans | -1.0 to 1.0 | 0.0 |  |  |
| `ghost` | Ghost | -1.0 to 1.0 | 0.0 |  |  |
| `ghost_spacing` | Ghost Sp | -1.0 to 1.0 | 0.3 |  |  |
| `halation` | Halation | 0.0 to 1.0 | 0.0 |  |  |
| `halation_threshold` | Hal Thresh | 0.0 to 1.0 | 0.7 |  |  |

Context, not to mark (menus and buttons that change what the params above do): none

Not on this sheet (a type rule decides the widget, spec H3): `aberration_mod`, `distortion_mod`, `transmission_mod`, `surface_mod`, `ghost_count`
