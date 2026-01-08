#!/bin/bash
#
# BrewOS Pull Request Verification Script
#
# This script mirrors the CI workflow and runs all checks required 
# before merging a PR across the monorepo:
#
# 1. Lint, type check and build App (from app repository)
# 2. Lint, type check and build Cloud + Admin (from cloud repository)
# 3. Build App for ESP32 (from app repository)
# 4. Build Firmware (ESP32 + Pico from firmware repository)
# 5. Run Pico Unit Tests (from firmware repository)
#
# Note: This script works with the split monorepo structure where
# repositories are siblings in the workspace.
#
# Usage:
#   ./scripts/verify_pr.sh [--skip-firmware] [--skip-tests] [--skip-app] [--skip-cloud] [--fast]
#
# Options:
#   --skip-firmware  Skip firmware builds (ESP32 + Pico)
#   --skip-tests     Skip running unit tests
#   --skip-app       Skip app lint, typecheck, build, and ESP32 build
#   --skip-cloud     Skip cloud lint, typecheck and build
#   --fast           Skip firmware builds, tests, app, and cloud
#   --help, -h       Show this help message
#

set -e  # Exit on first error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Script directory (root of workspace)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Repository paths
FIRMWARE_DIR="$WORKSPACE_ROOT/firmware"
APP_DIR="$WORKSPACE_ROOT/app"
CLOUD_DIR="$WORKSPACE_ROOT/cloud"

# Timing
START_TIME=$(date +%s)
STEP_START_TIME=$START_TIME

# Parse arguments
SKIP_FIRMWARE=false
SKIP_TESTS=false
SKIP_APP=false
SKIP_CLOUD=false

while [ $# -gt 0 ]; do
    case $1 in
        --skip-firmware)
            SKIP_FIRMWARE=true
            shift
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --skip-app)
            SKIP_APP=true
            shift
            ;;
        --skip-cloud)
            SKIP_CLOUD=true
            shift
            ;;
        --fast)
            SKIP_FIRMWARE=true
            SKIP_TESTS=true
            SKIP_APP=true
            SKIP_CLOUD=true
            shift
            ;;
        --help|-h)
            head -n 25 "$0" | tail -n +2
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Functions
print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} $1"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════╝${NC}"
}

print_step() {
    STEP_START_TIME=$(date +%s)
    echo ""
    echo -e "${BLUE}▶ $1${NC}"
}

print_success() {
    local duration=$(($(date +%s) - STEP_START_TIME))
    echo -e "${GREEN}✓ $1${NC} ${YELLOW}(${duration}s)${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${MAGENTA}→ $1${NC}"
}

# Error handler for unexpected failures
on_error() {
    local exit_code=$?
    echo ""
    print_error "Verification failed at: ${BASH_COMMAND}"
    echo ""
    print_info "To fix:"
    print_info "  1. Review the error message above"
    print_info "  2. Make necessary changes"
    print_info "  3. Run this script again"
    echo ""
    exit $exit_code
}

trap on_error ERR

# ============================================================================
# Repository Checks
# ============================================================================

check_repository() {
    local repo_name=$1
    local repo_path=$2
    
    if [ ! -d "$repo_path" ]; then
        print_error "$repo_name repository not found at $repo_path"
        print_info "Expected structure:"
        print_info "  $WORKSPACE_ROOT/"
        print_info "    ├── firmware/"
        print_info "    ├── app/"
        print_info "    └── scripts/verify_pr.sh"
        echo ""
        print_info "Please ensure all repositories are cloned in the workspace root"
        exit 1
    fi
    
    if [ ! -d "$repo_path/.git" ]; then
        print_warning "$repo_name directory exists but is not a git repository"
    fi
}

# ============================================================================
# Main Verification Steps
# ============================================================================

print_header "BrewOS Pull Request Verification (Monorepo)"
echo ""
echo -e "  ${CYAN}Workspace:${NC} $WORKSPACE_ROOT"
echo -e "  ${CYAN}Mode:${NC}       $([ "$SKIP_FIRMWARE" = true ] && echo "Fast (no firmware)" || echo "Full verification")"
echo ""

# Check repositories exist
print_step "Checking repositories..."
check_repository "Firmware" "$FIRMWARE_DIR"
check_repository "App" "$APP_DIR"
check_repository "Cloud" "$CLOUD_DIR"
print_success "All repositories found"

# ----------------------------------------------------------------------------
# Step 1: Lint, type check and build App
# ----------------------------------------------------------------------------
if [ "$SKIP_APP" = false ]; then
    if [ ! -f "$APP_DIR/package.json" ]; then
        print_error "App package.json not found"
        exit 1
    fi
    
    cd "$APP_DIR"
    if [ ! -d "node_modules" ]; then
        print_info "Installing app dependencies..."
        npm ci > /dev/null 2>&1
    fi
    
    print_step "Linting App..."
    npm run lint > /dev/null 2>&1
    print_success "App lint passed"
    
    print_step "Type checking App..."
    npx tsc --noEmit
    print_success "App type check passed"
    
    print_step "Building App (Cloud)..."
    npm run build > /dev/null 2>&1
    print_success "App built for Cloud"
    
    print_step "Building App for ESP32..."
    if [ ! -f "$APP_DIR/scripts/build-esp32.sh" ]; then
        print_error "App build script not found at $APP_DIR/scripts/build-esp32.sh"
        exit 1
    fi
    ESP32_DATA_DIR="$FIRMWARE_DIR/src/esp32/data" ./scripts/build-esp32.sh > /dev/null 2>&1
    print_success "App built for ESP32"
else
    print_step "App checks (lint, typecheck, build, ESP32 build)..."
    print_warning "Skipped (--skip-app or --fast)"
fi

# ----------------------------------------------------------------------------
# Step 2: Lint, type check and build Cloud + Admin
# ----------------------------------------------------------------------------
if [ "$SKIP_CLOUD" = false ]; then
    if [ ! -f "$CLOUD_DIR/package.json" ]; then
        print_error "Cloud package.json not found"
        exit 1
    fi
    
    cd "$CLOUD_DIR"
    if [ ! -d "node_modules" ]; then
        print_info "Installing cloud dependencies..."
        npm ci > /dev/null 2>&1
    fi
    
    print_step "Linting Cloud..."
    npm run lint > /dev/null 2>&1
    print_success "Cloud lint passed"
    
    print_step "Type checking Cloud + Admin..."
    # Type check cloud service
    npx tsc --noEmit
    print_success "Cloud service type check passed"
    
    # Type check admin
    if [ ! -f "$CLOUD_DIR/admin/package.json" ]; then
        print_error "Admin package.json not found"
        exit 1
    fi
    
    cd "$CLOUD_DIR/admin"
    if [ ! -d "node_modules" ]; then
        print_info "Installing admin dependencies..."
        npm ci > /dev/null 2>&1
    fi
    
    npx tsc --noEmit
    print_success "Admin type check passed"
    
    # Build cloud service
    cd "$CLOUD_DIR"
    print_step "Building Cloud + Admin..."
    npm run build > /dev/null 2>&1
    
    # Build admin UI
    cd "$CLOUD_DIR/admin"
    npm run build > /dev/null 2>&1
    print_success "Cloud + Admin built successfully"
else
    print_step "Cloud checks (lint, typecheck, build)..."
    print_warning "Skipped (--skip-cloud or --fast)"
fi

# ----------------------------------------------------------------------------
# Step 3: Build Firmware (optional)
# ----------------------------------------------------------------------------
if [ "$SKIP_FIRMWARE" = false ]; then
    print_step "Building Firmware (ESP32 + Pico)..."
    
    if [ ! -f "$FIRMWARE_DIR/src/scripts/build_firmware.sh" ]; then
        print_error "Firmware build script not found at $FIRMWARE_DIR/src/scripts/build_firmware.sh"
        exit 1
    fi
    
    cd "$FIRMWARE_DIR/src/scripts"
    
    # Build Pico firmware
    print_info "Building Pico firmware..."
    set +e  # Temporarily disable exit on error to capture output
    BUILD_OUTPUT=$(./build_firmware.sh pico 2>&1)
    BUILD_EXIT_CODE=$?
    set -e  # Re-enable exit on error
    
    if [ $BUILD_EXIT_CODE -eq 0 ]; then
        print_success "Pico firmware built successfully"
    else
        print_error "Pico firmware build failed"
        echo ""
        echo "$BUILD_OUTPUT"
        exit $BUILD_EXIT_CODE
    fi
    
    # Build ESP32 firmware (with screen)
    print_info "Building ESP32 firmware (with screen)..."
    set +e  # Temporarily disable exit on error to capture output
    BUILD_OUTPUT=$(./build_firmware.sh esp32 2>&1)
    BUILD_EXIT_CODE=$?
    set -e  # Re-enable exit on error
    
    if [ $BUILD_EXIT_CODE -eq 0 ]; then
        print_success "ESP32 firmware (with screen) built successfully"
    else
        print_error "ESP32 firmware (with screen) build failed"
        echo ""
        echo "$BUILD_OUTPUT"
        exit $BUILD_EXIT_CODE
    fi
    
    # Build ESP32 firmware (no screen)
    print_info "Building ESP32 firmware (headless)..."
    set +e  # Temporarily disable exit on error to capture output
    BUILD_OUTPUT=$(./build_firmware.sh esp32-noscreen 2>&1)
    BUILD_EXIT_CODE=$?
    set -e  # Re-enable exit on error
    
    if [ $BUILD_EXIT_CODE -eq 0 ]; then
        print_success "ESP32 firmware (headless) built successfully"
    else
        print_error "ESP32 firmware (headless) build failed"
        echo ""
        echo "$BUILD_OUTPUT"
        exit $BUILD_EXIT_CODE
    fi
    
    print_success "All firmware variants built successfully"
else
    print_step "Building Firmware (ESP32 + Pico)..."
    print_warning "Skipped (--skip-firmware or --fast)"
fi

# ----------------------------------------------------------------------------
# Step 4: Run Unit Tests (optional)
# ----------------------------------------------------------------------------
if [ "$SKIP_TESTS" = false ]; then
    print_step "Running Pico Unit Tests..."
    
    if [ ! -f "$FIRMWARE_DIR/src/scripts/run_pico_tests.sh" ]; then
        print_error "Pico test script not found at $FIRMWARE_DIR/src/scripts/run_pico_tests.sh"
        exit 1
    fi
    
    cd "$FIRMWARE_DIR/src/scripts"
    # Capture output and exit code, only show on error
    set +e  # Temporarily disable exit on error to capture output
    TEST_OUTPUT=$(./run_pico_tests.sh 2>&1)
    TEST_EXIT_CODE=$?
    set -e  # Re-enable exit on error
    
    if [ $TEST_EXIT_CODE -eq 0 ]; then
        print_success "All unit tests passed"
    else
        print_error "Unit tests failed"
        echo ""
        echo "$TEST_OUTPUT"
        exit $TEST_EXIT_CODE
    fi
else
    print_step "Running Pico Unit Tests..."
    print_warning "Skipped (--skip-tests or --fast)"
fi

# ============================================================================
# Summary
# ============================================================================

TOTAL_DURATION=$(($(date +%s) - START_TIME))
MINUTES=$((TOTAL_DURATION / 60))
SECONDS=$((TOTAL_DURATION % 60))

echo ""
print_header "✅ Pull Request Verification Complete"
echo ""
echo -e "  ${GREEN}All checks passed!${NC}"
echo -e "  ${CYAN}Total time:${NC} ${MINUTES}m ${SECONDS}s"
echo ""
echo -e "  ${MAGENTA}Ready to create/merge pull request${NC}"
echo ""

# Optional suggestions based on mode
if [ "$SKIP_FIRMWARE" = true ] || [ "$SKIP_APP" = true ] || [ "$SKIP_CLOUD" = true ]; then
    echo -e "  ${YELLOW}Note:${NC} Some checks were skipped. Run without --fast for full verification."
    echo ""
fi

exit 0

