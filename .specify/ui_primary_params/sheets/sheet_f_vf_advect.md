# Blind sheet: f_vf_advect

Mark each param **P** (primary), **S** (secondary) or **?** (unsure). Primary = it sets the character of the effect (changes
what it *is*, you reach for it live, or other params depend on it). Secondary = it scales, tunes or is set once.
Few primaries per module is typical (0 to 5), not a quota. Current widgets are left off on purpose. Notes are welcome where you hesitate.

| Param | Label | Range | Default | P / S / ? | Note |
|---|---|---|---|---|---|
| `dt` | dt | 0.0 to 0.05 | 0.01 |  |  |
| `decay` | Decay | 0.8 to 1.5 | 0.97 |  |  |
| `injection` | Inject | 0.0 to 0.2 | 0.02 |  |  |
| `separate` | Separate | -2.0 to 2.0 | 0.0 |  |  |
| `trail` | Trail | 0.0 to 120.0 | 0.0 |  |  |

Context, not to mark (menus and buttons that change what the params above do): `mode` (Mode)

Not on this sheet (a type rule decides the widget, spec H3): `gain`, `mix_pct`
