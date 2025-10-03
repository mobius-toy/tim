#!/usr/bin/env bash
set -euo pipefail

# Script to update opentoy_android AAR in TIM
# Usage: ./update_opentoy_aar.sh [opentoy_android_path]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIM_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TIM_ANDROID_DIR="${TIM_ROOT}/android"
OPENTOY_ANDROID_PATH="${1:-../opentoy_android}"

# Resolve absolute path for opentoy_android
if [[ "${OPENTOY_ANDROID_PATH:0:1}" == "/" ]]; then
    OPENTOY_ANDROID_ABS_PATH="${OPENTOY_ANDROID_PATH}"
else
    OPENTOY_ANDROID_ABS_PATH="$(cd "${TIM_ROOT}/${OPENTOY_ANDROID_PATH}" && pwd)"
fi

OPENTOY_AAR_SOURCE="${OPENTOY_ANDROID_ABS_PATH}/build/outputs/aar/opentoy_android-release.aar"
OPENTOY_AAR_DEST="${TIM_ANDROID_DIR}/libs/opentoy_android-release-v1.0.0.aar"

log() {
    echo "[update_opentoy_aar] $*"
}

error() {
    echo "[update_opentoy_aar] ERROR: $*" >&2
    exit 1
}

# Check if opentoy_android source exists
if [[ ! -d "${OPENTOY_ANDROID_ABS_PATH}" ]]; then
    error "opentoy_android directory not found: ${OPENTOY_ANDROID_ABS_PATH}"
fi

# Check if AAR source exists
if [[ ! -f "${OPENTOY_AAR_SOURCE}" ]]; then
    error "opentoy_android-release.aar not found at: ${OPENTOY_AAR_SOURCE}"
    echo "Please build opentoy_android first by running: cd ${OPENTOY_ANDROID_ABS_PATH} && ./gradlew assembleRelease"
fi

# Ensure libs directory exists
mkdir -p "${TIM_ANDROID_DIR}/libs"

# Remove existing AAR
if [[ -f "${OPENTOY_AAR_DEST}" ]]; then
    log "Removing existing AAR..."
    rm -f "${OPENTOY_AAR_DEST}"
fi

# Copy new AAR
log "Copying opentoy_android-release.aar from ${OPENTOY_AAR_SOURCE} to ${OPENTOY_AAR_DEST}..."
cp "${OPENTOY_AAR_SOURCE}" "${OPENTOY_AAR_DEST}"

log "AAR updated successfully!"
log "AAR location: ${OPENTOY_AAR_DEST}"

# Verify the AAR file
if [[ -f "${OPENTOY_AAR_DEST}" ]]; then
    AAR_SIZE=$(stat -f%z "${OPENTOY_AAR_DEST}" 2>/dev/null || stat -c%s "${OPENTOY_AAR_DEST}" 2>/dev/null)
    if [[ "${AAR_SIZE}" -gt 10000 ]]; then
        log "AAR file verified ✓ (${AAR_SIZE} bytes)"
    else
        error "AAR file verification failed (too small: ${AAR_SIZE} bytes)"
    fi
else
    error "AAR file verification failed"
fi

log "Done!"
