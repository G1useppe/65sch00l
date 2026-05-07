#!/bin/bash
# =============================================================================
# download_datasets.sh — Lesson 2: Suricata Read Mode and Wireshark
# =============================================================================
# Downloads and prepares PCAP datasets for this lesson.
#
# Usage:
#   chmod +x .rsrc/download_datasets.sh
#   ./.rsrc/download_datasets.sh
#
# Environment:
#   MTA_PASS  — password for malware-traffic-analysis.net zip files.
#               Check https://www.malware-traffic-analysis.net/about.html
#               for the current password scheme.
#
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

LESSON_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RSRC_DIR="${LESSON_DIR}/.rsrc"

DEMO_URL="https://www.malware-traffic-analysis.net/2024/09/04/2024-09-04-traffic-analysis-exercise.pcap.zip"
DEMO_ZIP="${RSRC_DIR}/2024-09-04-traffic-analysis-exercise.pcap.zip"
DEMO_EXTRACTED="2024-09-04-traffic-analysis-exercise.pcap"
DEMO_PCAP="${RSRC_DIR}/demo.pcap"

FIGHT_URL="https://www.malware-traffic-analysis.net/2024/07/30/2024-07-30-traffic-analysis-exercise.pcap.zip"
FIGHT_ZIP="${RSRC_DIR}/2024-07-30-traffic-analysis-exercise.pcap.zip"
FIGHT_EXTRACTED="2024-07-30-traffic-analysis-exercise.pcap"
FIGHT_PCAP="${RSRC_DIR}/fights_on.pcap"

# Lesson 1 path — reuse if available
LESSON1_DEMO="../arkime_a1/.rsrc/demo.pcap"

# Log directories used by this lesson
DEMO_LOGS="${LESSON_DIR}/demo_logs"
FIGHT_LOGS="${LESSON_DIR}/fight_logs"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

info()  { echo "[INFO]  $*"; }
warn()  { echo "[WARN]  $*"; }
error() { echo "[ERROR] $*" >&2; }
die()   { error "$*"; exit 1; }

check_command() {
    if ! command -v "$1" &>/dev/null; then
        die "'$1' is not installed. Please install it before running this script."
    fi
}

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------

info "Running pre-flight checks..."

check_command curl
check_command unzip

if [ -z "${MTA_PASS:-}" ]; then
    error "MTA_PASS is not set."
    echo ""
    echo "  The zip files from malware-traffic-analysis.net are password-protected."
    echo "  Check https://www.malware-traffic-analysis.net/about.html for the current"
    echo "  password, then run:"
    echo ""
    echo "    export MTA_PASS=\"the_password\""
    echo "    ./.rsrc/download_datasets.sh"
    echo ""
    exit 1
fi

# ---------------------------------------------------------------------------
# Create directories
# ---------------------------------------------------------------------------

info "Creating directories..."

mkdir -p "${RSRC_DIR}"
mkdir -p "${DEMO_LOGS}"
mkdir -p "${FIGHT_LOGS}"

info "  .rsrc/       -> ${RSRC_DIR}"
info "  demo_logs/   -> ${DEMO_LOGS}"
info "  fight_logs/  -> ${FIGHT_LOGS}"

# ---------------------------------------------------------------------------
# Demo PCAP
# ---------------------------------------------------------------------------

echo ""
info "=== Demo PCAP ==="

if [ -f "${DEMO_PCAP}" ]; then
    info "Already exists: ${DEMO_PCAP} — skipping."
elif [ -f "${LESSON_DIR}/${LESSON1_DEMO}" ]; then
    info "Found demo PCAP from Lesson 1, copying..."
    cp "${LESSON_DIR}/${LESSON1_DEMO}" "${DEMO_PCAP}"
    info "Copied to ${DEMO_PCAP}"
else
    info "Downloading demo PCAP..."
    info "  URL: ${DEMO_URL}"

    curl --fail --location --progress-bar \
        --output "${DEMO_ZIP}" \
        "${DEMO_URL}"

    if [ ! -f "${DEMO_ZIP}" ]; then
        die "Download failed — zip file not found at ${DEMO_ZIP}"
    fi

    info "Download complete. Size: $(du -h "${DEMO_ZIP}" | cut -f1)"
    info "Extracting..."

    unzip -o -P "${MTA_PASS}" "${DEMO_ZIP}" -d "${RSRC_DIR}"

    if [ ! -f "${RSRC_DIR}/${DEMO_EXTRACTED}" ]; then
        die "Extraction failed — expected file not found: ${DEMO_EXTRACTED}"
    fi

    mv "${RSRC_DIR}/${DEMO_EXTRACTED}" "${DEMO_PCAP}"
    info "Renamed to ${DEMO_PCAP}"

    # Clean up the zip
    rm -f "${DEMO_ZIP}"
    info "Removed zip file."
fi

# ---------------------------------------------------------------------------
# Fights On PCAP
# ---------------------------------------------------------------------------

echo ""
info "=== Fights On PCAP ==="

if [ -f "${FIGHT_PCAP}" ]; then
    info "Already exists: ${FIGHT_PCAP} — skipping."
else
    info "Downloading Fights On PCAP..."
    info "  URL: ${FIGHT_URL}"

    curl --fail --location --progress-bar \
        --output "${FIGHT_ZIP}" \
        "${FIGHT_URL}"

    if [ ! -f "${FIGHT_ZIP}" ]; then
        die "Download failed — zip file not found at ${FIGHT_ZIP}"
    fi

    info "Download complete. Size: $(du -h "${FIGHT_ZIP}" | cut -f1)"
    info "Extracting..."

    unzip -o -P "${MTA_PASS}" "${FIGHT_ZIP}" -d "${RSRC_DIR}"

    if [ ! -f "${RSRC_DIR}/${FIGHT_EXTRACTED}" ]; then
        die "Extraction failed — expected file not found: ${FIGHT_EXTRACTED}"
    fi

    mv "${RSRC_DIR}/${FIGHT_EXTRACTED}" "${FIGHT_PCAP}"
    info "Renamed to ${FIGHT_PCAP}"

    # Clean up the zip
    rm -f "${FIGHT_ZIP}"
    info "Removed zip file."
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo ""
info "=== Dataset Summary ==="
echo ""

for pcap in "${DEMO_PCAP}" "${FIGHT_PCAP}"; do
    if [ -f "${pcap}" ]; then
        name=$(basename "${pcap}")
        size=$(du -h "${pcap}" | cut -f1)
        echo "  ✔  ${name}  (${size})"
    else
        name=$(basename "${pcap}")
        echo "  ✘  ${name}  MISSING"
    fi
done

echo ""
info "Done. You're ready to start Lesson 2."
