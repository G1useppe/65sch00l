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
# NOTE: we do NOT use set -e here — we trap errors from unzip manually
# so we can give clear feedback on password failures.

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
# extract_pcap — extracts a zip, renames the PCAP, cleans up.
#                Handles password failures with a clear error message.
#
# Usage: extract_pcap <zip_path> <extract_name> <final_path>
# ---------------------------------------------------------------------------

extract_pcap() {
    local zip_path="$1"
    local extract_name="$2"
    local final_path="$3"

    info "Extracting with password..."

    # Run unzip and capture its exit code + output separately.
    # We do NOT let set -e kill us here — we check the result ourselves.
    local unzip_output
    local unzip_rc=0
    unzip_output=$(unzip -o -P "${MTA_PASS}" "${zip_path}" -d "${RSRC_DIR}" 2>&1) || unzip_rc=$?

    if [ "${unzip_rc}" -ne 0 ]; then
        echo ""
        error "============================================================"
        error "unzip FAILED (exit code ${unzip_rc})."
        error "============================================================"
        echo ""

        # Check for password-related messages in the output.
        # Different unzip versions use different wording.
        if echo "${unzip_output}" | grep -qiE "incorrect password|wrong password|bad password|skipping|invalid"; then
            error "CAUSE: Incorrect password."
            error "The MTA_PASS you provided does not unlock this zip file."
        fi

        echo ""
        echo "  The password scheme for malware-traffic-analysis.net changes"
        echo "  periodically. Check the current password at:"
        echo ""
        echo "    https://www.malware-traffic-analysis.net/about.html"
        echo ""
        echo "  Then re-run with the correct password:"
        echo ""
        echo "    export MTA_PASS=\"correct_password\""
        echo "    ./.rsrc/download_datasets.sh"
        echo ""
        echo "  --- unzip output ---"
        echo "  ${unzip_output}"
        echo "  --------------------"
        echo ""

        # Remove the zip so the next run doesn't see a stale file and skip
        rm -f "${zip_path}"

        ERRORS=$((ERRORS + 1))
        return 1
    fi

    # Verify the expected file actually appeared after extraction
    if [ ! -f "${RSRC_DIR}/${extract_name}" ]; then
        error "Extraction appeared to succeed but the expected file was not found."
        error "  Expected: ${extract_name}"
        error "  Contents of ${RSRC_DIR}/:"
        ls -la "${RSRC_DIR}/" >&2
        echo ""
        error "The zip may contain a differently named file. Check manually:"
        error "  unzip -l ${zip_path}"
        rm -f "${zip_path}"
        ERRORS=$((ERRORS + 1))
        return 1
    fi

    mv "${RSRC_DIR}/${extract_name}" "${final_path}"
    info "Renamed to $(basename "${final_path}")"

    # Clean up the zip
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

    if ! curl --fail --location --progress-bar \
        --output "${DEMO_ZIP}" \
        "${DEMO_URL}"; then
        error "curl download failed for demo PCAP."
        error "Check that the URL is still valid:"
        error "  ${DEMO_URL}"
        ERRORS=$((ERRORS + 1))
    else
        info "Download complete. Size: $(du -h "${DEMO_ZIP}" | cut -f1)"
        extract_pcap "${DEMO_ZIP}" "${DEMO_EXTRACTED}" "${DEMO_PCAP}"
    fi
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

    if ! curl --fail --location --progress-bar \
        --output "${FIGHT_ZIP}" \
        "${FIGHT_URL}"; then
        error "curl download failed for Fights On PCAP."
        error "Check that the URL is still valid:"
        error "  ${FIGHT_URL}"
        ERRORS=$((ERRORS + 1))
    else
        info "Download complete. Size: $(du -h "${FIGHT_ZIP}" | cut -f1)"
        extract_pcap "${FIGHT_ZIP}" "${FIGHT_EXTRACTED}" "${FIGHT_PCAP}"
    fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo ""
info "=== Dataset Summary ==="
echo ""

for pcap in "${DEMO_PCAP}" "${FIGHT_PCAP}"; do
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
    echo "  Most common cause: incorrect MTA_PASS."
    echo "  Check https://www.malware-traffic-analysis.net/about.html"
    echo "  and re-run with the correct password."
    echo ""
    exit 1
else
    info "Done. You're ready to start Lesson 2."
fi
