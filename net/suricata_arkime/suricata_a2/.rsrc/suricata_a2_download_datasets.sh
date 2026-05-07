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

set -uo pipefail

# ---------------------------------------------------------------------------
# Configuration — EDIT THESE if URLs or filenames change
# ---------------------------------------------------------------------------

LESSON_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RSRC_DIR="${LESSON_DIR}/.rsrc"

# Demo PCAP — Trickbot (gtag chil13) infection in AD environment
# Source: https://www.malware-traffic-analysis.net/2020/05/08/index.html
# This PCAP is reused as the demo dataset across all lessons.
DEMO_URL="https://www.malware-traffic-analysis.net/2020/05/08/2020-05-08-Trickbot-gtag-chil13-infection-traffic.pcap.zip"
DEMO_ZIP_NAME="2020-05-08-Trickbot-gtag-chil13-infection-traffic.pcap.zip"
DEMO_PCAP_NAME="2020-05-08-Trickbot-gtag-chil13-infection-traffic.pcap"
DEMO_FINAL_NAME="demo.pcap"

# Fights On PCAP — independent exercise dataset
# Source: https://www.malware-traffic-analysis.net/2024/07/30/index.html
FIGHT_URL="https://www.malware-traffic-analysis.net/2024/07/30/2024-07-30-traffic-analysis-exercise.pcap.zip"
FIGHT_ZIP_NAME="2024-07-30-traffic-analysis-exercise.pcap.zip"
FIGHT_PCAP_NAME="2024-07-30-traffic-analysis-exercise.pcap"
FIGHT_FINAL_NAME="fights_on.pcap"

# Lesson 1 path — reuse demo PCAP if already downloaded there
LESSON1_DEMO="../arkime_a1/.rsrc/${DEMO_FINAL_NAME}"

# Log directories used by this lesson
DEMO_LOGS="${LESSON_DIR}/demo_logs"
FIGHT_LOGS="${LESSON_DIR}/fight_logs"

# Track overall success
ERRORS=0

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
# download_and_extract — downloads a zip, extracts a PCAP, renames it.
#
# Args:
#   $1  URL to download
#   $2  zip filename (basename)
#   $3  expected PCAP filename inside the zip
#   $4  final renamed PCAP filename (basename)
#
# On password failure: prints a clear error, cleans up, increments ERRORS.
# ---------------------------------------------------------------------------

download_and_extract() {
    local url="$1"
    local zip_name="$2"
    local pcap_name="$3"
    local final_name="$4"

    local zip_path="${RSRC_DIR}/${zip_name}"
    local final_path="${RSRC_DIR}/${final_name}"

    # --- Skip if final file already exists ---
    if [ -f "${final_path}" ]; then
        info "Already exists: ${final_name} — skipping."
        return 0
    fi

    # --- Check if we can reuse from Lesson 1 ---
    if [ "${final_name}" = "${DEMO_FINAL_NAME}" ] && [ -f "${LESSON_DIR}/${LESSON1_DEMO}" ]; then
        info "Found ${final_name} from Lesson 1, copying..."
        cp "${LESSON_DIR}/${LESSON1_DEMO}" "${final_path}"
        info "Copied to ${final_path}"
        return 0
    fi

    # --- Download ---
    info "Downloading ${final_name}..."
    info "  URL: ${url}"

    if ! curl --fail --location --progress-bar \
        --output "${zip_path}" \
        "${url}"; then

        error "curl download failed."
        error "Check that the URL is still valid:"
        error "  ${url}"
        echo ""
        error "If the filename has changed, update the URL at the top of this script."
        ERRORS=$((ERRORS + 1))
        return 1
    fi

    info "Download complete. Size: $(du -h "${zip_path}" | cut -f1)"

    # --- Extract ---
    info "Extracting with password..."

    local unzip_output
    local unzip_rc=0
    unzip_output=$(unzip -o -P "${MTA_PASS}" "${zip_path}" -d "${RSRC_DIR}" 2>&1) || unzip_rc=$?

    if [ "${unzip_rc}" -ne 0 ]; then
        echo ""
        error "============================================================"
        error "unzip FAILED (exit code ${unzip_rc})"
        error "============================================================"

        if echo "${unzip_output}" | grep -qiE "incorrect password|wrong password|bad password|skipping|invalid"; then
            error "CAUSE: Incorrect password."
            error "Your MTA_PASS does not unlock this zip file."
        fi

        echo ""
        echo "  The password scheme for malware-traffic-analysis.net changes"
        echo "  periodically. Check the current password at:"
        echo ""
        echo "    https://www.malware-traffic-analysis.net/about.html"
        echo ""
        echo "  Then re-run:"
        echo ""
        echo "    export MTA_PASS=\"correct_password\""
        echo "    ./.rsrc/download_datasets.sh"
        echo ""
        echo "  --- unzip output ---"
        echo "  ${unzip_output}"
        echo "  --------------------"
        echo ""

        rm -f "${zip_path}"
        ERRORS=$((ERRORS + 1))
        return 1
    fi

    # --- Verify extraction ---
    # First check for the expected filename
    if [ -f "${RSRC_DIR}/${pcap_name}" ]; then
        mv "${RSRC_DIR}/${pcap_name}" "${final_path}"
        info "Renamed ${pcap_name} -> ${final_name}"
    else
        # The zip might contain a differently named file — try to find it
        warn "Expected file '${pcap_name}' not found after extraction."
        warn "Looking for any .pcap file in ${RSRC_DIR}/..."

        local found_pcap
        found_pcap=$(find "${RSRC_DIR}" -maxdepth 1 -name "*.pcap" -newer "${zip_path}" -print -quit 2>/dev/null || true)

        if [ -n "${found_pcap}" ]; then
            warn "Found: $(basename "${found_pcap}")"
            warn "Using this file instead. Update DEMO_PCAP_NAME or FIGHT_PCAP_NAME"
            warn "at the top of this script if this keeps happening."
            mv "${found_pcap}" "${final_path}"
            info "Renamed to ${final_name}"
        else
            error "No .pcap file found after extraction."
            error "Check the zip contents manually:"
            error "  unzip -l ${zip_path}"
            ERRORS=$((ERRORS + 1))
            rm -f "${zip_path}"
            return 1
        fi
    fi

    # --- Clean up zip ---
    rm -f "${zip_path}"
    info "Removed zip file."

    return 0
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
    echo "  password scheme, then run:"
    echo ""
    echo "    export MTA_PASS=\"the_password\""
    echo "    ./.rsrc/download_datasets.sh"
    echo ""
    exit 1
fi

info "MTA_PASS is set (length: ${#MTA_PASS} chars)."

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
info "=== Demo PCAP (${DEMO_FINAL_NAME}) ==="
download_and_extract \
    "${DEMO_URL}" \
    "${DEMO_ZIP_NAME}" \
    "${DEMO_PCAP_NAME}" \
    "${DEMO_FINAL_NAME}"

# ---------------------------------------------------------------------------
# Fights On PCAP
# ---------------------------------------------------------------------------

echo ""
info "=== Fights On PCAP (${FIGHT_FINAL_NAME}) ==="
download_and_extract \
    "${FIGHT_URL}" \
    "${FIGHT_ZIP_NAME}" \
    "${FIGHT_PCAP_NAME}" \
    "${FIGHT_FINAL_NAME}"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo ""
info "=== Dataset Summary ==="
echo ""

for pcap in "${RSRC_DIR}/${DEMO_FINAL_NAME}" "${RSRC_DIR}/${FIGHT_FINAL_NAME}"; do
    name=$(basename "${pcap}")
    if [ -f "${pcap}" ]; then
        size=$(du -h "${pcap}" | cut -f1)
        echo "  ✔  ${name}  (${size})"
    else
        echo "  ✘  ${name}  MISSING"
    fi
done

echo ""

if [ "${ERRORS}" -gt 0 ]; then
    error "${ERRORS} error(s) occurred. Review the output above."
    echo ""
    echo "  Most common causes:"
    echo "    1. Incorrect MTA_PASS — check the about page"
    echo "    2. Filename changed — update the variables at the top of this script"
    echo "    3. Network issue — try the URL in a browser"
    echo ""
    exit 1
else
    info "Done. You're ready to start Lesson 2."
fi
