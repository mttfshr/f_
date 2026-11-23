# Blind sheet: f_halftone

Mark each param **P** (primary), **S** (secondary) or **?** (unsure). Primary = it sets the character of the effect (changes
what it *is*, you reach for it live, or other params depend on it). Secondary = it scales, tunes or is set once.
Few primaries per module is typical (0 to 5), not a quota. Current widgets are left off on purpose. Notes are welcome where you hesitate.

| Param | Label | Range | Default | P / S / ? | Note |
|---|---|---|---|---|---|
| `pitch` | Pitch | 0.009 to 0.2 | 0.012 |  |  |
| `scale_r` | Scale R | 0.25 to 4.0 | 1.0 |  |  |
| `scale_g` | Scale G | 0.25 to 4.0 | 1.0 |  |  |
| `scale_b` | Scale B | 0.25 to 4.0 | 1.0 |  |  |
| `softness` | Soft | 0.0 to 1.0 | 0.1 |  |  |
| `dot_shape` | Shape | 0.0 to 1.0 | 0.0 |  |  |
| `jitter` | Jitter | 0.0 to 1.0 | 0.0 |  |  |
| `level` | Level | 0.0 to 1.0 | 0.5 |  |  |
| `phase_r_x` | R x | -1.0 to 1.0 | 0.0 |  |  |
| `phase_r_y` | R y | -1.0 to 1.0 | 0.0 |  |  |
| `phase_g_x` | G x | -1.0 to 1.0 | 0.0 |  |  |
| `phase_g_y` | G y | -1.0 to 1.0 | 0.0 |  |  |
| `phase_b_x` | B x | -1.0 to 1.0 | 0.0 |  |  |
| `phase_b_y` | B y | -1.0 to 1.0 | 0.0 |  |  |

Context, not to mark (menus and buttons that change what the params above do): `screen` (Screen), `plate_mode` (Plate), `bayer_cell` (Read), `plate_out` (Out)

Not on this sheet (a type rule decides the widget, spec H3): `seed`, `levels`, `angle_r`, `angle_g`, `angle_b`
