# QEMU Wasm demo

Page: https://ktock.github.io/qemu-wasm-demo/

Demo page of running Linux-based containers on browser using [QEMU Wasm](https://github.com/ktock/qemu-wasm) and [container2wasm](https://github.com/ktock/container2wasm).

## Building images

- Clone qemu-wasm repo and set the directory path to `QEMU_WASM_REPO` and `QEMU_WASM_REPO_EXAMPLE`.
  - `QEMU_WASM_REPO_EXAMPLE` needs to be the master branch of https://github.com/ktock/qemu-wasm/
  - `QEMU_WASM_REPO` needs to be set to the branch https://github.com/ktock/qemu-wasm/pull/21

```
./create-images.sh
```

container2wasm needs to be available on the host.

## License

Apache License Version 2.0.

Additionally, this repository relies on third-pirty softwares:

- Bootstrap ([MIT License](https://github.com/twbs/bootstrap/blob/main/LICENSE)): https://github.com/twbs/bootstrap
- xterm-pty ([MIT License](https://github.com/mame/xterm-pty/blob/main/LICENSE.txt)): https://github.com/mame/xterm-pty
- xterm.js ([MIT License](https://github.com/xtermjs/xterm.js/blob/master/LICENSE)): https://github.com/xtermjs/xterm.js
- coi-serviceworker.js([MIT License](https://github.com/gzuidhof/coi-serviceworker/blob/master/LICENSE)): https://github.com/gzuidhof/coi-serviceworker
- `browser_wasi_shim` (either of [MIT License](https://github.com/bjorn3/browser_wasi_shim/blob/main/LICENSE-MIT) and [Apache License 2.0](https://github.com/bjorn3/browser_wasi_shim/blob/main/LICENSE-APACHE)): https://github.com/bjorn3/browser_wasi_shim
- container2wasm-genearted images:
  - Containers
    - alpine-based containers: https://pkgs.alpinelinux.org/packages
    - debian-based containers: see `/usr/share/doc/*/copyright`
  - Other dependencies(emulator, etc): https://github.com/ktock/container2wasm#acknowledgement
- QEMU Wasm: https://github.com/ktock/qemu-wasm
- Raspberry Pi kernel and dtb file ([License](https://github.com/raspberrypi/linux/tree/1.20230405/LICENSES)): https://github.com/raspberrypi/linux
