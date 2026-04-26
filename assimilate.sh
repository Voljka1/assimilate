#!/bin/bash
set -e
# P.S. Actually, this is not a bash script, this is the BORG script now. :)
# To prevent nasty bash tricks when nothing is found, we enable nullglob 
# so that the array is empty instead of containing the pattern itself.
shopt -s nullglob

# Terminal (but not deadly) colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RESET='\033[0m'

# I said, I want more colours! More colours, more fun!
error() {
    printf '%b\n' "${RED}$1${RESET}"
}

warning() {
    printf '%b\n' "${YELLOW}$1${RESET}"
}

info() {
    printf '%b\n' "${BLUE}$1${RESET}"
}

BORG() {
    printf '%b\n' "${GREEN}$1${RESET}"
}

# 0. Variable Initialization
CONTAINERS_LIST="librenms_main,librenms_dispatcher"

# Define Source MIBs Folder (keep your vendor mibs here)
MIBS_SRC_DIR="mibs"
# Define Source Prefixes for other file types
ICONS_SRC_PREFIX="icon_"
LOGOS_SRC_PREFIX="logo_"
OS_DET_SRC_PREFIX="os_detection_"
OS_DISC_SRC_PREFIX="os_discovery_"
PHP_SRC_PREFIX="os_logic_"

# Define Internal Container Paths (destinations)
VENDOR=""
ICON_DEST="/opt/librenms/html/images/os/"
LOGO_DEST="/opt/librenms/html/images/logos/"
YAML_DET_DEST="/opt/librenms/resources/definitions/os_detection/"
YAML_DISC_DEST="/opt/librenms/resources/definitions/os_discovery/"
PHP_DEST="/opt/librenms/LibreNMS/OS/"

# 1. Greetings, Earthlings.
BORG "Starting Assimilation..."
BORG "Today it will be LibreNMS containers, tomorrow it will be the Collective."
BORG "Resistance is futile."

# 2. Functions block
# -----------------------------------------------------------------------------
docker_exec_all() {
    local user=$1
    shift
    for container in "${CONTAINERS[@]}"; do
        docker exec -u "$user" "$container" "$@"
    done
}

docker_cp_all() {
    local src=$1
    local dest=$2
    for container in "${CONTAINERS[@]}"; do
        docker cp "$src" "$container":"$dest"
    done
}

assimilate() {
    local prefix=$1
    local dest_dir=$2

    local raw_files=( "${prefix}"* )

    if (( ${#raw_files[@]} == 0 )); then
        return
    fi

    if (( ${#raw_files[@]} > 1 )); then
        warning "Warning: multiple files found for prefix '$prefix' (${raw_files[*]}). Skipping copy."
        return
    fi

    local raw_filename=${raw_files[0]}
    local stripped_name="${raw_filename#"$prefix"}"
    local full_dest_path="$dest_dir$stripped_name"

    info "Assimilating $raw_filename -> $stripped_name"
    docker_cp_all "$raw_filename" "$full_dest_path"
    docker_exec_all 0 chown librenms:librenms "$full_dest_path"
    docker_exec_all 0 chmod 644 "$full_dest_path"
}
# -----------------------------------------------------------------------------

# 3. Detect Vendor/Path from filename
# Filename format: Single file __Vendor-Sub__ or __Vendor__ with or without extension.
#                  Vendor can have dashes which will be converted to slashes for subdirectories.
#                  Result must be in the form of vendor/sub or vendor (all lowercase).
VENDOR_FILES=( __*__* )
[[ ${#VENDOR_FILES[@]} -gt 1 ]] && { error "Error: Multiple markers found: ${VENDOR_FILES[*]}"; exit 1; }
# Extract name between __ markers, replace dashes with slashes, and lowercase
if [[ "${VENDOR_FILES[0]}" =~ ^__(.+)__ ]]; then
    VENDOR="${BASH_REMATCH[1]//-/\/}"
    VENDOR="${VENDOR,,}"
fi

# 4. Container list support
CONTAINERS_LIST=${CONTAINERS_LIST//[[:space:]]/}
IFS=',' read -ra CONTAINERS <<< "$CONTAINERS_LIST"

if [[ ${#CONTAINERS[@]} -eq 0 ]]; then
    error "Error: CONTAINERS_LIST is empty."
    exit 1
fi

# 5. Mass Assimilation of MIBs
# Note to myself: I am not stealing, I just borrowing :)
if [ -d "$MIBS_SRC_DIR" ] && [ -n "$VENDOR" ]; then
    info "Assimilating MIB files for vendor: $VENDOR"
    # Assign variable for MIB_DEST with the final VENDOR path
    MIB_DEST="/opt/librenms/mibs/$VENDOR/"
    info "Preparing Vendor MIB folder: $MIB_DEST"
    # Create the folder as the librenms user so the directory is owned correctly
    docker_exec_all librenms mkdir -p "$MIB_DEST"
    for mib in "$MIBS_SRC_DIR"/*; do
        mib_filename=$(basename "$mib")
        dest_path="$MIB_DEST$mib_filename"
        # Copy file (arrives as root)
        docker_cp_all "$mib" "$dest_path"
    done
    # Apply permissions once for the whole directory to save time
    docker_exec_all 0 chown -R librenms:librenms "$MIB_DEST"
    docker_exec_all 0 chmod -R u=rwX,g=rX,o=rX "$MIB_DEST"
fi

# 6. Consolidated Assimilation Calls
# Just provide the prefix and the destination. The function does the rest.
assimilate "$ICONS_SRC_PREFIX"      "$ICON_DEST"
assimilate "$LOGOS_SRC_PREFIX"      "$LOGO_DEST"
assimilate "$OS_DET_SRC_PREFIX"     "$YAML_DET_DEST"
assimilate "$OS_DISC_SRC_PREFIX"    "$YAML_DISC_DEST"
assimilate "$PHP_SRC_PREFIX"        "$PHP_DEST"

# 7. Finalize collective state
info "Clearing cache..."
docker_exec_all librenms php lnms cache:clear

# 8. Final Words.
BORG "Assimilation complete. $VENDOR is now part of the Collective."
BORG "Your files now our files"
BORG "Yours truly, 7 of 9."