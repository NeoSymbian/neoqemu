# NeoQEMU

QEMU for [NeoSymbian](https://github.com/NeoSymbian): the `virt` machine its AArch64 EKA2 kernel runs on in CI and on a
build machine, with the tools that start and drive it.

- `qemu/` — upstream [QEMU](https://gitlab.com/qemu-project/qemu) v11.1.2, vendored with `git subtree --squash`, plus
  our fixes as separate commits (`git log -- qemu`); today one: `ppm_save` writes `width * 3` bytes per row (screendumps
  of odd-width screens were sheared).
- `tools/run-qemu.sh` — boots a kernel `Image` on the machine NeoSymbian/kernel's `baseport/arm64/qemu_variant` expects:
  GICv3, Cortex-A55 × `SMP` (4), 512 MB, a `ramfb` screen, a virtio tablet and keyboard, an optional virtio-blk disk,
  the debug serial port; `QMP=`, `VNC=:N`, `INPUT=` (typed on the console), `SERIAL1=`, `MON=`.
- `tools/ui-qemu.py` — runs a UI ROM by script (`expect TEXT`, `wait N`, `abs X Y` taps through QMP, HMP commands),
  saves the screen as a PNG and fails on a kernel fault. neoui's `symbian/taps.sh` writes the scripts; its
  `virt-taps` CI runs them.
- `container/` — the image `ghcr.io/neosymbian/neoqemu` (`/opt/neoqemu/bin`: `qemu-system-aarch64`, the two tools),
  published by the `image` workflow. NeoSymbian/build's toolchain image copies it, pinned by digest.

The guest side (the `virt` board, ramfb and virtio-input drivers) is NeoSymbian/kernel's `baseport/arm64/qemu_variant`
and `virt_assp`. Watch or use a `virt` boot over VNC from NeoSymbian/build: `VNC=:0 neo qemu 3600`.

Updating QEMU: `git subtree pull --prefix qemu --squash https://gitlab.com/qemu-project/qemu.git vX.Y.Z`, then rebuild
the image and re-pin it in build.

## Licences

`qemu/` is QEMU's: GPL-2.0 (see `qemu/COPYING`, `qemu/LICENSE`); our fixes there are GPL-2.0 too. Everything outside
`qemu/` is Apache-2.0 (`LICENSE`). This repository replaces NeoSymbian/symbian-qemu (archived), which carried the old
Syborg board.
