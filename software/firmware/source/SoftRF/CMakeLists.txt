cmake_minimum_required(VERSION 3.16)

project(SoftRFFirmware LANGUAGES NONE)

find_program(ARDUINO_CLI arduino-cli REQUIRED)

set(SOFTRF_FQBN "esp32:esp32:esp32" CACHE STRING
    "Arduino CLI FQBN used to build SoftRF")
set(SOFTRF_BOARD_OPTIONS "PartitionScheme=huge_app" CACHE STRING
    "Board options passed to Arduino CLI for SoftRF")
set(SOFTRF_PYTHONPATH "" CACHE PATH
    "Python site-packages path for esptool (optional, e.g., ~/.venv/lib/python3.11/site-packages)")
set(SOFTRF_SKETCH "${CMAKE_CURRENT_SOURCE_DIR}/SoftRF.ino")
set(SOFTRF_LIBRARIES "${CMAKE_CURRENT_SOURCE_DIR}/../libraries" CACHE PATH
    "Path to the bundled SoftRF libraries")
set(SOFTRF_BUILD_DIR "${CMAKE_BINARY_DIR}/arduino-build" CACHE PATH
    "Temporary Arduino CLI build directory")
set(SOFTRF_OUTPUT_DIR "${CMAKE_BINARY_DIR}/binaries" CACHE PATH
    "Directory where compiled binaries are exported")

# Extract target variant from FQBN for naming (e.g., esp32c3 from esp32:esp32:esp32c3)
string(REGEX MATCH "[^:]+$" SOFTRF_TARGET_VARIANT "${SOFTRF_FQBN}")

add_custom_target(softrf ALL
    COMMAND ${CMAKE_COMMAND} -E make_directory "${SOFTRF_BUILD_DIR}"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${SOFTRF_OUTPUT_DIR}"
    COMMAND ${CMAKE_COMMAND} -E env "PYTHONPATH=${SOFTRF_PYTHONPATH}:$ENV{PYTHONPATH}"
        ${ARDUINO_CLI} compile
            --fqbn "${SOFTRF_FQBN}"
            --board-options "${SOFTRF_BOARD_OPTIONS}"
            --libraries "${SOFTRF_LIBRARIES}"
            --build-path "${SOFTRF_BUILD_DIR}"
            --output-dir "${SOFTRF_OUTPUT_DIR}"
            --export-binaries
            "${SOFTRF_SKETCH}"
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    COMMENT "Building SoftRF firmware for ${SOFTRF_TARGET_VARIANT} with Arduino CLI")
