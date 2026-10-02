# f_

A collection of bpatchers for [Vsynth](https://www.kevinkripper.com/vsynth) in [Max](https://cycling74.com/products/max): generators, processors and utilities that follow Vsynth conventions and are designed to work in Vsynth signal chains. Includes a family of vector-field modules (`f_vf_`) that produce and consume float32 vector-field textures.

## Requirements

- **Max 9** (earlier versions are untested).
- **Vsynth**, installable from Max's Package Manager. These modules were developed against Vsynth 1.7.0; other versions are untested.

## Using the package

- Modules appear in Max's file browser under `f_`. Drop one into a Vsynth chain like any other Vsynth module.
- `help/` has a help patch for many of the modules, and `examples/` has complete Vsynth patches that use them. Where an example has a saved preset, it sits next to it as `f_demo_<name>.json`.
- Every patcher in `patchers/` is listed, with a description, in the project README (https://github.com/mttfshr/f_). Entries marked ⚠ there are unfinished: don't rely on them.

## Notes

These patches are developed alongside personal Vsynth performance work and released as-is. There is no release schedule, and modules may change significantly as development continues.

## Credits

Built for Vsynth by Kevin Kripper.

## License

Not yet specified.
