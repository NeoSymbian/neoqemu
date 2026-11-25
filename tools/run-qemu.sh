#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# run-qemu.sh -- boot a NeoSymbian kernel Image on QEMU virt with a timeout; serial to stdout and $OUT/serial.log.
# The machine is the one NeoSymbian/kernel's baseport/arm64/qemu_variant expects: GICv3, Cortex-A55 x SMP (default 4),
# 512 MB, a ramfb screen (virt_assp/a64_ramfb.cpp), a virtio tablet and keyboard (virt_assp/virtio_input.cpp) and an
# optional virtio-blk disk, all on legacy virtio-mmio; the second PL011 is the debug serial port.
# Usage: run-qemu.sh [seconds] [expected-final-line]   exit 0 iff the expected line appeared.
# Env: OUT (required: the kernel's output directory holding Image, e.g. kernel/out/ekern-qemu), SMP, MON (an HMP
#      monitor socket path),
#      INPUT=<text> (printf escapes, e.g. "dir\r"; each "~" waits 5 s): typed into the serial console after INPUT_DELAY
#      seconds (default 15); Ctrl-T ("\024") makes the kernel dump its threads, Ctrl-B a line for its debug monitor,
#      SERIAL1=<chardev>: the second PL011, default null; e.g. unix:/tmp/uart1.sock,server=on,wait=off,
#      DISK=<file>: a virtio-blk disk (the persistent C:), created 256 MB if missing,
#      QMP=<socket path>: a QMP server there (ui-qemu.py: input-send-event, screendump),
#      VNC=<display>: the screen and input over VNC, e.g. VNC=:0 (port 5900) on VNC_LISTEN (default 127.0.0.1; no
#      password: forward the port, never listen beyond localhost).
set -u
OUT=${OUT:?run-qemu.sh: set OUT to the kernel output directory with Image (e.g. kernel/out/ekern-qemu)}
SECS=${1:-10}; EXPECT=${2:-}
MONITOR=none
[ -n "${MON:-}" ] && rm -f "$MON" && MONITOR="unix:$MON,server,nowait"
DISKARGS=""
if [ -n "${DISK:-}" ]; then
	[ -f "$DISK" ] || truncate -s 256M "$DISK"
	DISKARGS="-drive file=$DISK,if=none,format=raw,id=d0 -device virtio-blk-device,drive=d0"
fi
EXTRA=""
[ -n "${QMP:-}" ] && rm -f "$QMP" && EXTRA="-qmp unix:$QMP,server=on,wait=off"
[ -n "${VNC:-}" ] && EXTRA="$EXTRA -vnc ${VNC_LISTEN:-127.0.0.1}$VNC"
qemu() { timeout "$SECS" qemu-system-aarch64 -M virt,gic-version=3 -cpu cortex-a55 -smp "${SMP:-4}" -m 512 \
	-display none -serial stdio -serial "${SERIAL1:-null}" -monitor "$MONITOR" $EXTRA \
	-no-reboot -nic none -global virtio-mmio.force-legacy=true -device ramfb \
	-device virtio-tablet-device -device virtio-keyboard-device $DISKARGS -kernel "$OUT/Image" > "$OUT/serial.log" 2>&1; }
if [ -n "${INPUT:-}" ]; then
	{ sleep "${INPUT_DELAY:-15}"
	  rest=$INPUT
	  while :; do piece=${rest%%"~"*}; printf "$piece"; [ "$piece" = "$rest" ] && break; rest=${rest#*"~"}; sleep 5; done
	  sleep "$SECS"; } | qemu &
else
	qemu < /dev/null &
fi
wait $!		# QEMU (the pipeline's last command), not the input writer's last sleep
QSTATUS=$?
tr -d '\r' < "$OUT/serial.log"
case $QSTATUS in 0|124) ;; *) echo "run-qemu: QEMU failed ($QSTATUS)" >&2; exit "$QSTATUS" ;; esac	# 124: the timeout
[ -z "$EXPECT" ] || grep -q "$EXPECT" "$OUT/serial.log"
