#!/bin/bash
set -e

echo "Starting Assimilation..."
echo "Resistance is futile."

# 1. Detect Vendor from _Vendor_.txt (Mandatory for paths)
VENDOR_MARKER=$(ls _*_.* 2>/dev/null | head -n 1)
if [[ -z "$VENDOR_MARKER" ]]; then
    echo "Error: No vendor marker (e.g., _FlexDSL_.txt) found."
    exit 1
fi
TEMP=${VENDOR_MARKER#_}
VENDOR=${TEMP%_*}
echo "Detected Vendor: $VENDOR"

# 2. The All-in-One Assimilation Function
assimilate() {
    local prefix=$1
    local dest_dir=$2
    local targets=$3

    local raw_file=$(ls ${prefix}* 2>/dev/null | head -n 1)

    if [[ -n "$raw_file" ]]; then
        local stripped_name=${raw_file#$prefix}
        local full_dest_path="$dest_dir$stripped_name"
        echo "Assimilating $raw_file -> $stripped_name"

        # Copy and immediately chown in librenms_main
        docker cp "$raw_file" librenms_main:"$full_dest_path"
        docker exec -u 0 librenms_main chown librenms:librenms "$full_dest_path"
		docker exec -u 0 librenms_main chmod 644 "$full_dest_path"
        
        if [[ "$targets" == "both" ]]; then
            docker cp "$raw_file" librenms_dispatcher:"$full_dest_path"
            docker exec -u 0 librenms_dispatcher chown librenms:librenms "$full_dest_path"
			docker exec -u 0 librenms_dispatcher chmod 644 "$full_dest_path"
        fi
    fi
}

# 3. Define Internal Container Paths
MIB_DEST="/opt/librenms/mibs/$VENDOR/"
ICON_DEST="/opt/librenms/html/images/os/"
LOGO_DEST="/opt/librenms/html/images/logos/"
YAML_DET_DEST="/opt/librenms/resources/definitions/os_detection/"
YAML_DISC_DEST="/opt/librenms/resources/definitions/os_discovery/"
PHP_DEST="/opt/librenms/LibreNMS/OS/"

# 4. Mass Assimilate MIBs
echo "Preparing Vendor MIB folder: $MIB_DEST"

for container in librenms_main librenms_dispatcher; do
    # Create the folder as the librenms user so the directory is owned correctly
    docker exec -u librenms "$container" mkdir -p "$MIB_DEST"
done

echo "Assimilating MIB files..."
for mib in mibs/*; do
    mib_filename=$(basename "$mib")
    dest_path="$MIB_DEST$mib_filename"
    
    # Copy file (arrives as root)
    docker cp "$mib" librenms_main:"$dest_path"
    docker cp "$mib" librenms_dispatcher:"$dest_path"
    
    # Surgical chown on the file ONLY
    docker exec -u 0 librenms_main chown librenms:librenms "$dest_path"
    docker exec -u 0 librenms_dispatcher chown librenms:librenms "$dest_path"
	
	# This makes directories 755 and files 644 automatically
	docker exec -u 0 librenms_main chmod -R u=rwX,g=rX,o=rX "$MIB_DEST"
	docker exec -u 0 librenms_dispatcher chmod -R u=rwX,g=rX,o=rX "$MIB_DEST"
done

# 5. Consolidated Assimilation Calls
# Just provide the prefix and the destination. The function does the rest.
assimilate "icon_"         "$ICON_DEST"      "main"
assimilate "logo_"         "$LOGO_DEST"      "main"
assimilate "os_detection_" "$YAML_DET_DEST"  "both"
assimilate "os_discovery_" "$YAML_DISC_DEST" "both"
assimilate "os_logic_"     "$PHP_DEST"       "both"

# 6. Finalize collective state
echo "Clearing cache..."
docker exec -u librenms librenms_main php lnms cache:clear

# 7. Final Words.
echo "Assimilation complete. $VENDOR is now part of the Collective."
echo "Yours truly, 7 of 9."