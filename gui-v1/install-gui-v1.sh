#!/bin/bash
#
# Install GUI v1 Starlink pages
#
# This script installs the Starlink page into GUI v1 (classic interface)
# and patches PageSettings.qml to add a menu entry.
#

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "${SCRIPT_DIR}")"

# GUI v1 paths
GUI_DIR="/opt/victronenergy/gui/qml"
BACKUP_DIR="/data/starlink-gui-v1-backup"
RC_LOCAL="/data/rc.local"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if GUI v1 exists
check_gui_v1() {
    if [ ! -d "${GUI_DIR}" ]; then
        echo_error "GUI v1 not found at ${GUI_DIR}"
        echo_error "This device may only have GUI v2"
        exit 1
    fi

    if [ ! -f "${GUI_DIR}/PageSettings.qml" ]; then
        echo_error "PageSettings.qml not found"
        exit 1
    fi

    echo_info "GUI v1 found at ${GUI_DIR}"
}

# Backup original files
backup_files() {
    echo_info "Backing up original files..."

    mkdir -p "${BACKUP_DIR}"

    if [ ! -f "${BACKUP_DIR}/PageSettings.qml.orig" ]; then
        cp "${GUI_DIR}/PageSettings.qml" "${BACKUP_DIR}/PageSettings.qml.orig"
        echo_info "Backed up PageSettings.qml"
    else
        echo_info "Backup already exists"
    fi
}

# Install Starlink QML page
install_page() {
    echo_info "Installing Starlink page..."

    # Copy the QML file
    cp "${SCRIPT_DIR}/PageStarlink.qml" "${GUI_DIR}/PageStarlink.qml"
    chmod 644 "${GUI_DIR}/PageStarlink.qml"

    echo_info "PageStarlink.qml installed"
}

# Patch PageSettings.qml to add Starlink menu entry
patch_settings() {
    echo_info "Patching PageSettings.qml..."

    local settings_file="${GUI_DIR}/PageSettings.qml"

    # Check if already patched
    if grep -q "PageStarlink" "${settings_file}"; then
        echo_info "PageSettings.qml already patched"
        return 0
    fi

    # Find the model: VisualItemModel section and add our entry
    # We'll add it before the last closing brace of the model

    # Create patch content - add Starlink entry to Settings menu
    local patch_content='
        MbSubMenu {
            id: starlinkMenu
            description: qsTr("Starlink")
            subpage: Component { PageStarlink {} }
        }
'

    # Find a good place to insert - look for "General" or another known menu item
    if grep -q 'description: qsTr("General")' "${settings_file}"; then
        # Insert after the General menu block
        # Use sed to insert after the General MbSubMenu block
        sed -i '/description: qsTr("General")/,/^[[:space:]]*}$/{
            /^[[:space:]]*}$/a\
        MbSubMenu {\
            id: starlinkMenu\
            description: qsTr("Starlink")\
            subpage: Component { PageStarlink {} }\
        }
        }' "${settings_file}"

        echo_info "Patched PageSettings.qml (after General)"
    else
        # Alternative: insert before the last closing brace of VisualItemModel
        # This is trickier, so we'll use a simpler approach
        echo_warn "Could not find insertion point, using alternative method"

        # Create a patched version
        cp "${settings_file}" "${settings_file}.tmp"

        # Find line with "model: VisualItemModel" and count braces to find end
        # For simplicity, we'll add a comment marker and sed

        # Add after the last MbSubMenu before model closes
        # Look for pattern like "} // end of VisualItemModel" or similar

        # Simpler approach: add to end of file before last }
        # This may not be perfect but should work for most versions

        python3 << PYEOF
import re

with open("${settings_file}", 'r') as f:
    content = f.read()

# Check if already patched
if 'PageStarlink' in content:
    print("Already patched")
    exit(0)

# Find the VisualItemModel block in the model property
# Add our menu item before the closing of the model

patch = '''
        MbSubMenu {
            id: starlinkMenu
            description: qsTr("Starlink")
            subpage: Component { PageStarlink {} }
        }
'''

# Find pattern: look for last MbSubMenu or MbItem before model closes
# Insert before the closing ] of the model array or before closing }

# Simple approach: find "model: VisualItemModel {" and its matching "}"
# Then insert before that closing }

lines = content.split('\n')
result = []
in_model = False
brace_count = 0
inserted = False

for i, line in enumerate(lines):
    if 'model: VisualItemModel' in line or 'model:VisualItemModel' in line:
        in_model = True
        brace_count = 0

    if in_model:
        brace_count += line.count('{')
        brace_count -= line.count('}')

        # When we're about to close the VisualItemModel (brace_count goes to 0)
        if brace_count == 0 and '}' in line and not inserted:
            # Insert our menu before this closing brace
            result.append(patch)
            inserted = True
            in_model = False

    result.append(line)

if inserted:
    with open("${settings_file}", 'w') as f:
        f.write('\n'.join(result))
    print("Patched successfully")
else:
    print("Could not find insertion point")
    exit(1)
PYEOF

        if [ $? -eq 0 ]; then
            echo_info "Patched PageSettings.qml"
        else
            echo_error "Failed to patch PageSettings.qml"
            # Restore backup
            cp "${BACKUP_DIR}/PageSettings.qml.orig" "${settings_file}"
            exit 1
        fi
    fi
}

# Setup rc.local for persistence across firmware updates
setup_persistence() {
    echo_info "Setting up persistence..."

    # Create restoration script
    cat > "/data/starlink-gui-v1-restore.sh" << 'RESTORE_EOF'
#!/bin/bash
# Restore Starlink GUI v1 after firmware update

GUI_DIR="/opt/victronenergy/gui/qml"
APP_DIR="/data/venus_starlink_control"

if [ -f "${APP_DIR}/gui-v1/PageStarlink.qml" ]; then
    cp "${APP_DIR}/gui-v1/PageStarlink.qml" "${GUI_DIR}/PageStarlink.qml"

    # Patch PageSettings.qml if not already patched
    if ! grep -q "PageStarlink" "${GUI_DIR}/PageSettings.qml"; then
        # Run the install script
        "${APP_DIR}/gui-v1/install-gui-v1.sh"
    fi
fi
RESTORE_EOF

    chmod +x "/data/starlink-gui-v1-restore.sh"

    # Add to rc.local if not already there
    if [ ! -f "${RC_LOCAL}" ]; then
        cat > "${RC_LOCAL}" << 'EOF'
#!/bin/bash
# VenusOS rc.local - runs after each boot

EOF
        chmod +x "${RC_LOCAL}"
    fi

    if ! grep -q "starlink-gui-v1-restore" "${RC_LOCAL}"; then
        echo "" >> "${RC_LOCAL}"
        echo "# Restore Starlink GUI v1 pages" >> "${RC_LOCAL}"
        echo "/data/starlink-gui-v1-restore.sh" >> "${RC_LOCAL}"
        echo_info "Added restoration to rc.local"
    else
        echo_info "rc.local already configured"
    fi
}

# Restart GUI
restart_gui() {
    echo_info "Restarting GUI..."

    if [ -d "/service/gui" ]; then
        svc -t /service/gui 2>/dev/null || true
        echo_info "GUI restart requested"
    else
        echo_warn "GUI service not found, please restart manually"
    fi
}

# Uninstall function
uninstall() {
    echo_info "Uninstalling Starlink GUI v1..."

    # Restore original PageSettings.qml
    if [ -f "${BACKUP_DIR}/PageSettings.qml.orig" ]; then
        cp "${BACKUP_DIR}/PageSettings.qml.orig" "${GUI_DIR}/PageSettings.qml"
        echo_info "Restored original PageSettings.qml"
    fi

    # Remove Starlink page
    rm -f "${GUI_DIR}/PageStarlink.qml"

    # Remove from rc.local
    if [ -f "${RC_LOCAL}" ]; then
        sed -i '/starlink-gui-v1-restore/d' "${RC_LOCAL}"
        sed -i '/Restore Starlink GUI v1/d' "${RC_LOCAL}"
    fi

    rm -f "/data/starlink-gui-v1-restore.sh"

    restart_gui

    echo_info "Uninstall complete"
}

# Main
main() {
    echo ""
    echo "=========================================="
    echo "  Starlink GUI v1 Installer"
    echo "=========================================="
    echo ""

    if [ "$1" = "--uninstall" ] || [ "$1" = "-u" ]; then
        uninstall
        exit 0
    fi

    check_gui_v1
    backup_files
    install_page
    patch_settings
    setup_persistence
    restart_gui

    echo ""
    echo "=========================================="
    echo "  Installation Complete!"
    echo "=========================================="
    echo ""
    echo "The Starlink page has been added to:"
    echo "  Settings -> Starlink"
    echo ""
    echo "To uninstall:"
    echo "  $0 --uninstall"
    echo ""
}

main "$@"
