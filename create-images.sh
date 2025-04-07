#!/bin/bash

set -euo pipefail

# SOURCE=./src/
DEST=./out/
C2W_V="${C2W:-c2w}"
C2W_EXTRA_FLAGS_V=${C2W_EXTRA_FLAGS:-}
QEMU_WASM_REPO_V="${QEMU_WASM_REPO}"
QEMU_WASM_REPO_EXAMPLE_V="${QEMU_WASM_REPO_EXAMPLE}"

# /image : image name
# /Dockerfile : dockerfile to use
# /arch : image architecture (default: amd64)

function generate() {
    local TARGETARCH="${1}"
    local IMAGE="${2}"
    local OUTPUT="${3}"

    if [ "${TARGETARCH}" = "aarch64" ] ; then
        ${C2W_V} --to-js --build-arg LOAD_MODE=separated --target-arch="${TARGETARCH}" ${C2W_EXTRA_FLAGS_V} "${IMAGE}" "${OUTPUT}"
    elif [ "${TARGETARCH}" = "amd64" ] ; then
        ${C2W_V} --target-stage=js-qemu-amd64 --build-arg LOAD_MODE=separated ${C2W_EXTRA_FLAGS_V} "${IMAGE}" "${OUTPUT}"
    else
        echo "unknown arch ${TARGETARCH}"
        exit 1
    fi
}

mkdir "${DEST}"
ls "${DEST}"

# raspi demo
docker build --progress=plain -t buildbase-demo - < ${QEMU_WASM_REPO_V}/tests/docker/dockerfiles/emsdk-wasm32-cross.docker
cat <<EOF | docker build --progress=plain -t buildqemu-tmp -
FROM buildbase
WORKDIR /builddeps/
ENV EMCC_CFLAGS="-Wno-unused-command-line-argument --js-library=/builddeps/node_modules/xterm-pty/emscripten-pty.js -sLZ4"
RUN npm i xterm-pty@v0.10.1
WORKDIR /build/
EOF

docker run --rm --init -d --name build-qemu-wasm-demo -v "${QEMU_WASM_REPO_V}":/qemu/:ro buildqemu-tmp sleep infinity
sleep 5
docker exec -it build-qemu-wasm-demo emconfigure /qemu/configure --static --disable-tools --target-list=aarch64-softmmu
docker exec -it build-qemu-wasm-demo emmake make -j$(nproc)

TMPDIR=$(mktemp -d)

mkdir "${TMPDIR}/pack"
docker build --output=type=local,dest="${TMPDIR}/pack" "${QEMU_WASM_REPO_EXAMPLE_V}"/examples/raspi3ap/image/
docker cp "${TMPDIR}/pack" build-qemu-wasm-demo:/
docker exec -it build-qemu-wasm-demo /bin/sh -c "/emsdk/upstream/emscripten/tools/file_packager.py qemu-system-aarch64.data --preload /pack > load.js"

mkdir "${DEST}/raspi3ap"
docker cp build-qemu-wasm-demo:/build/qemu-system-aarch64.js "${DEST}/raspi3ap/out.js"
for f in qemu-system-aarch64.wasm qemu-system-aarch64.worker.js qemu-system-aarch64.data load.js ; do
    docker cp build-qemu-wasm-demo:/build/${f} "${DEST}/raspi3ap/"
done

# alpine demo
docker kill build-qemu-wasm-demo
sleep 3
docker run --rm --init -d --name build-qemu-wasm-demo -v "${QEMU_WASM_REPO_V}":/qemu/:ro buildqemu-tmp sleep infinity
sleep 5
docker exec -it build-qemu-wasm-demo emconfigure /qemu/configure --static --disable-tools --target-list=x86_64-softmmu
docker exec -it build-qemu-wasm-demo emmake make -j$(nproc)

mkdir "${DEST}/alpine-x86_64"

mkdir "${TMPDIR}"/{pack-kernel,pack-initramfs,pack-rootfs,pack-rom}
docker build --progress=plain --build-arg PACKAGES="vim python3" --output type=local,dest="${TMPDIR}" "${QEMU_WASM_REPO_EXAMPLE_V}"/examples/x86_64-alpine/image/
cp "${TMPDIR}"/vmlinuz-virt "${TMPDIR}"/pack-kernel/
cp "${TMPDIR}"/initramfs-virt "${TMPDIR}"/pack-initramfs/
cp "${TMPDIR}"/disk-rootfs.img "${TMPDIR}"/pack-rootfs/
cp "${QEMU_WASM_REPO_V}"/pc-bios/{bios-256k.bin,vgabios-stdvga.bin,kvmvapic.bin,linuxboot_dma.bin,efi-virtio.rom} "${TMPDIR}"/pack-rom/
for f in kernel initramfs rom rootfs ; do
    docker cp "${TMPDIR}"/pack-${f} build-qemu-wasm-demo:/
    flags=
    if [ "${f}" == "rootfs" ] ; then
       flags=--lz4
    fi
    docker exec -it build-qemu-wasm-demo /bin/sh -c "/emsdk/upstream/emscripten/tools/file_packager.py load-${f}.data ${flags} --preload /pack-${f} > load-${f}.js"
    docker cp build-qemu-wasm-demo:/build/load-${f}.js "${DEST}/alpine-x86_64/"
    docker cp build-qemu-wasm-demo:/build/load-${f}.data "${DEST}/alpine-x86_64/"
done
( cd "${QEMU_WASM_REPO_EXAMPLE_V}"/examples/networking/htdocs/ && npx webpack )
cp -R "${QEMU_WASM_REPO_EXAMPLE_V}"/examples/networking/htdocs/dist "${DEST}/alpine-x86_64/"
wget -O - https://github.com/ktock/container2wasm/releases/download/v0.5.0/c2w-net-proxy.wasm | gzip > "${DEST}/alpine-x86_64/c2w-net-proxy.wasm.gzip"
docker cp build-qemu-wasm-demo:/build/qemu-system-x86_64.js "${DEST}/alpine-x86_64/out.js"
for f in qemu-system-x86_64.wasm qemu-system-x86_64.worker.js ; do
    docker cp build-qemu-wasm-demo:/build/${f} "${DEST}/alpine-x86_64/"
done

docker kill build-qemu-wasm-demo
rm -r "${TMPDIR}"
