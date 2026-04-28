# SoftRF Multi-Target Build Quick Reference

## Build Output Location

All compiled binaries are placed in `${BUILD_DIR}/binaries/` where `${BUILD_DIR}` is specified with `-B` flag.

### File Descriptions

| File                        | Purpose         | Size        | Use Case                                                     |
| --------------------------- | --------------- | ----------- | ------------------------------------------------------------ |
| `SoftRF.ino.bin`            | Main firmware   | ~1.7-1.8 MB | **Primary file** — Flash at 0x10000; use for OTA/web updates |
| `SoftRF.ino.bootloader.bin` | Bootloader      | ~33 KB      | Flash at 0x1000; rarely needed after first setup             |
| `SoftRF.ino.partitions.bin` | Partition table | ~64 B       | Flash at 0x8000; defines storage layout                      |
| `SoftRF.ino.elf`            | Debug symbols   | ~5-6 MB     | Use with debugger (`gdb`, VS Code) or memory analysis        |
| `SoftRF.ino.map`            | Linker map      | ~500 KB     | Analyze code/data memory usage by section                    |

## Single Target Builds

### ESP32-C3 (Recommended for most users)

```bash
cd /run/media/decimal/dev/Projects/SoftRF

cmake -S software/firmware/source/SoftRF \
    -B /tmp/softrf-c3 \
    -DSOFTRF_FQBN=esp32:esp32:esp32c3 \
    -DSOFTRF_BOARD_OPTIONS="PartitionScheme=huge_app" \
    -DSOFTRF_PYTHONPATH="/run/media/decimal/dev/Projects/SoftRF/.venv/lib/python3.14/site-packages"

cmake --build /tmp/softrf-c3
```

**Binaries:** `/tmp/softrf-c3/binaries/SoftRF.ino.bin` etc.

### ESP32 (Generic Dev Module)

```bash
cmake -S software/firmware/source/SoftRF \
    -B /tmp/softrf-esp32 \
    -DSOFTRF_FQBN=esp32:esp32:esp32 \
    -DSOFTRF_BOARD_OPTIONS="PartitionScheme=huge_app" \
    -DSOFTRF_PYTHONPATH="/run/media/decimal/dev/Projects/SoftRF/.venv/lib/python3.14/site-packages"

cmake --build /tmp/softrf-esp32
```

### ESP32-S3

```bash
cmake -S software/firmware/source/SoftRF \
    -B /tmp/softrf-s3 \
    -DSOFTRF_FQBN=esp32:esp32:esp32s3 \
    -DSOFTRF_BOARD_OPTIONS="PartitionScheme=huge_app" \
    -DSOFTRF_PYTHONPATH="/run/media/decimal/dev/Projects/SoftRF/.venv/lib/python3.14/site-packages"

cmake --build /tmp/softrf-s3
```

## Batch Build Multiple Targets

```bash
cd /run/media/decimal/dev/Projects/SoftRF
bash software/firmware/build-all-targets.sh ~/softrf-binaries
```

Output structure:

```
~/softrf-binaries/
├── build-esp32/binaries/
├── build-esp32c3/binaries/
├── build-esp32s3/binaries/
├── build-esp32c6/binaries/
└── build-esp32s2/binaries/
```

## Manual Loop Build (bash)

To build multiple targets and organize binaries:

```bash
#!/bin/bash
TARGETS=("esp32" "esp32c3" "esp32s3")
OUT_DIR="$HOME/softrf-bins"

for TARGET in "${TARGETS[@]}"; do
    FQBN="esp32:esp32:$TARGET"
    BUILD_DIR="/tmp/softrf-$TARGET"

    echo "Building $TARGET..."
    cmake -S software/firmware/source/SoftRF -B "$BUILD_DIR" \
        -DSOFTRF_FQBN="$FQBN" \
        -DSOFTRF_BOARD_OPTIONS="PartitionScheme=huge_app" \
        -DSOFTRF_PYTHONPATH="/run/media/decimal/dev/Projects/SoftRF/.venv/lib/python3.14/site-packages"

    cmake --build "$BUILD_DIR" || exit 1

    # Copy binaries
    mkdir -p "$OUT_DIR/$TARGET"
    cp "$BUILD_DIR/binaries/"*.bin "$OUT_DIR/$TARGET/"
    echo "✓ $TARGET binaries in $OUT_DIR/$TARGET/"
done
```

## Flashing Binaries

Using esptool.py (for ESP32 chips):

```bash
# Full flash (bootloader + partitions + firmware)
esptool.py --chip esp32c3 --port /dev/ttyUSB0 write_flash \
    0x0000 /tmp/softrf-c3/binaries/SoftRF.ino.bootloader.bin \
    0x8000 /tmp/softrf-c3/binaries/SoftRF.ino.partitions.bin \
    0x10000 /tmp/softrf-c3/binaries/SoftRF.ino.bin

# Firmware-only update (fast, safe if partition table unchanged)
esptool.py --chip esp32c3 --port /dev/ttyUSB0 write_flash \
    0x10000 /tmp/softrf-c3/binaries/SoftRF.ino.bin
```

## Available Partition Schemes

All ESP32 boards support:

- `default` — 1.2 MB app + 1.5 MB SPIFFS
- `huge_app` — 3 MB app + 1 MB SPIFFS (**recommended** for SoftRF)
- `no_ota` — 2 MB app + 2 MB SPIFFS
- `minimal` — 1.3 MB app + 700 KB SPIFFS

Choose `huge_app` for full SoftRF features.

## Troubleshooting

**Error: "No module named 'serial'"**
→ Set `-DSOFTRF_PYTHONPATH` to path containing pyserial:

```bash
-DSOFTRF_PYTHONPATH="/run/media/decimal/dev/Projects/SoftRF/.venv/lib/python3.14/site-packages"
```

**Error: "Sketch uses XXXX bytes ... Maximum is YYYY bytes"**
→ The firmware doesn't fit; try `no_ota` or `minimal` partition:

```bash
-DSOFTRF_BOARD_OPTIONS="PartitionScheme=no_ota"
```

**CMake: "unknown FQBN"**
→ Verify board exists: `arduino-cli board listall | grep esp32`

**Build hangs**
→ Check USB port is accessible: `ls -l /dev/ttyUSB*`
