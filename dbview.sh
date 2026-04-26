#!/bin/bash

# 1. Configuration & Defaults
DEFAULT_CONTAINER="librenms_main"
LIMIT_QTY=5 

# 2. Validation
if [ "$#" -lt 1 ]; then
clear
    echo "---------------------------------------------------------------------"
	echo "Usage: ./dbview.sh \"<sql_query>\" [device_id] [container_name]"
	echo "       Without [device_id] short device table will be shown to help" 
    echo "Navigation in table view:"
    echo "Arrow Keys: Move the table up, down, left, and right."
    echo "To search: Type / followed by a name to highlight it in the results."
    echo "Exit: Press Q to quit"
    echo "---------------------------------------------------------------------"
    echo "• Container must use DB_HOST, DB_NAME, DB_USER, DB_PASSWORD vars"
    echo "• If no [device_id] supplied, LIMIT_QTY=$LIMIT_QTY will be used"
    echo "• Default container: $DEFAULT_CONTAINER"
    echo "• Example: ./dbview.sh \"SELECT * FROM ports WHERE device_id = DEVICE_ID\" 20"
	echo "• Example: ./dbview.sh \"SELECT * FROM sensors WHERE device_id = DEVICE_ID\" 20"
	echo "• Example: ./dbview.sh \"SHOW tables\""
	echo "• Example: ./dbview.sh \"DESCRIBE devices\""
	echo "• Example: ./dbview.sh \"DESCRIBE sensors\""
    exit 1
fi

# 3. Assign Arguments
SQL_QUERY=$1
ARG2=$2
ARG3=$3

# Logic to determine if ARG2 is a Device ID or a Container Name
if [[ "$ARG2" =~ ^[0-9]+$ ]]; then
    # If ARG2 is a number, it's a Device ID
    DEVICE_ID=$ARG2
    TARGET_CONTAINER=${ARG3:-$DEFAULT_CONTAINER}
elif [ -n "$ARG2" ]; then
    # If ARG2 is text, it's the Container Name, and ID is empty
    DEVICE_ID=""
    TARGET_CONTAINER=$ARG2
else
    # Nothing was provided for ARG2
    DEVICE_ID=""
    TARGET_CONTAINER=$DEFAULT_CONTAINER
fi


# 4. Logic for the Query
if [ -n "$DEVICE_ID" ]; then
    # Replace the placeholder if an ID was provided
    FINAL_QUERY="${SQL_QUERY//DEVICE_ID/$DEVICE_ID}"
else
    # No ID provided: Check if the query is broken or global
    if [[ "$SQL_QUERY" == *"DEVICE_ID"* ]]; then
        # Query needs an ID but got none: Shows device table limited by LIMIT_QTY
        FINAL_QUERY="SELECT device_id, hostname, sysName, os, icon, version, hardware, features, status FROM devices LIMIT $LIMIT_QTY;"
    else
        # It's a general query (e.g. "SELECT * FROM locations"): Run as-is
        FINAL_QUERY="$SQL_QUERY"
    fi
fi

# 5. Execution
EXEC_CMD="docker exec -i $TARGET_CONTAINER sh -c 'mariadb --table -h \"\$DB_HOST\" -u \"\$DB_USER\" -p\"\$DB_PASSWORD\" \"\$DB_NAME\" -e \"$FINAL_QUERY\"'"

# 6. Check if the output is a terminal (TTY)
if [ -t 1 ]; then
    # If it is a terminal, use less
    eval "$EXEC_CMD" | less -S
else
    # If it is being piped to a file or another tool, don't use less
    eval "$EXEC_CMD"
fi


