#!/usr/bin/env bash
# Build SoftRF firmware for multiple ESP32 targets
# Usage: ./build-all-targets.sh [output-base-dir]
# Example: ./build-all-targets.sh ~/softrf-builds

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$SCRIPT_DIR/source/SoftRF"
OUTPUT_BASE="${1:-.}"

# Find Python site-packages path for pyserial (in venv if available, otherwise system)
if [ -f "$SCRIPT_DIR/../../.venv/bin/activate" ]; then
    PYTHONPATH=$("$SCRIPT_DIR/../../.venv/bin/python3" -c "import site; print(':'.join(site.getsitepackages()))" 2>/dev/null)
else
    PYTHONPATH=$(python3 -c "import site; print(':'.join(site.getsitepackages()))" 2>/dev/null || echo "")
fi

echo "Python path for dependencies: $PYTHONPATH"

# Define targets: FQBN, partition scheme (optional), description
declare -a TARGETS=(
    "esp32:esp32:esp32:huge_app:ESP32 Dev Module (huge_app)"
    "esp32:esp32:esp32c3:huge_app:ESP32-C3 Dev Module (huge_app)"
    "esp32:esp32:esp32s3:huge_app:ESP32-S3 Dev Module (huge_app)"
    "esp32:esp32:esp32c6:huge_app:ESP32-C6 Dev Module (huge_app)"
    "esp32:esp32:esp32s2:huge_app:ESP32-S2 Dev Module (huge_app)"
)

# Add more targets by appending to TARGETS:
# "esp32:esp32:esp32doit-devkit-v1::ESP32 DOIT DevKit v1 (default partition)"
# "esp32:esp32:lolin_s3:huge_app:LOLIN S3 (huge_app)"

SUCCESS_COUNT=0
FAILED_COUNT=0
FAILED_TARGETS=()

for TARGET_DEF in "${TARGETS[@]}"; do
    IFS=':' read -ra PARTS <<< "$TARGET_DEF"
    FQBN="${PARTS[0]}:${PARTS[1]}:${PARTS[2]}"
    PARTITION="${PARTS[3]}"
    DESC="${PARTS[4]}"
    
    # Extract target variant name for directory naming
    TARGET_NAME="${PARTS[2]}"
    BUILD_DIR="$OUTPUT_BASE/build-$TARGET_NAME"
    OUTPUT_DIR="$BUILD_DIR/binaries"
    
    echo ""
    echo "=========================================="
    echo "Building: $DESC"
    echo "FQBN: $FQBN"
    if [ -n "$PARTITION" ]; then
        echo "Partition: $PARTITION"
    fi
    echo "Output: $OUTPUT_DIR"
    echo "=========================================="
    
    # Configure CMake
    if [ -n "$PARTITION" ]; then
        BOARD_OPTIONS="PartitionScheme=$PARTITION"
    else
        BOARD_OPTIONS=""
    fi
    
    if cmake -S "$PROJECT_DIR" -B "$BUILD_DIR" \
        -DSOFTRF_FQBN="$FQBN" \
        ${BOARD_OPTIONS:+-DSOFTRF_BOARD_OPTIONS="$BOARD_OPTIONS"} \
        ${PYTHONPATH:+-DSOFTRF_PYTHONPATH="$PYTHONPATH"} \
        2>&1 | tail -5; then
        
        # Build
        if cmake --build "$BUILD_DIR" 2>&1 | tail -5; then
            echo "✓ Build successful: $DESC"
            echo "  Binaries: $OUTPUT_DIR/"
            ((SUCCESS_COUNT++))
        else
            echo "✗ Build failed: $DESC"
            ((FAILED_COUNT++))
            FAILED_TARGETS+=("$DESC")
        fi
    else
        echo "✗ Configuration failed: $DESC"
        ((FAILED_COUNT++))
        FAILED_TARGETS+=("$DESC")
    fi
done

echo ""
echo "=========================================="
echo "Build Summary"
echo "=========================================="
echo "Successful: $SUCCESS_COUNT"
echo "Failed: $FAILED_COUNT"

if [ $FAILED_COUNT -gt 0 ]; then
    echo ""
    echo "Failed targets:"
    for target in "${FAILED_TARGETS[@]}"; do
        echo "  - $target"
    done
    exit 1
fi

echo ""
echo "All builds completed successfully!"
echo "Binaries are in subdirectories of: $OUTPUT_BASE"
echo "  - $OUTPUT_BASE/build-esp32/binaries/"
echo "  - $OUTPUT_BASE/build-esp32c3/binaries/"
echo "  - etc..."
