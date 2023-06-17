#!/bin/bash

# Set the webhook URL
webhook_url="your_webhook_URL"

# Keyword to search for in chat messages
keyword="savecoord"

# Function to send a message to Discord
send_discord_message() {
    local message="$1"
    # Construct the payload JSON
    local payload=$(jq -n --arg content "$message" '{ "content": $content }')
    # Send the message using cURL
    curl -X POST -H "Content-Type: application/json" -d "$payload" "$webhook_url"
}

# Function to extract string until the first space
get_string_until_space() {
    local input_string="$1"
    read -r -d ' ' output_string <<< "$input_string"
    echo "$output_string"
}

# Function to extract string after the first space until the next space
get_string_after_first_space() {
    local input_string="$1"
    output_string="${input_string#* }"
    output_string="${output_string%% *}"
    echo "$output_string"
}

get_string_after_last_space() {
    local input_string="$1"
    output_string="${input_string##* }"
    echo "$output_string"
}

truncate_string() {
    local string="$1"
    local decimal_places="$2"
    local decimal_part="${string#*.}"
    local truncated_decimal_part="${decimal_part:0:$decimal_places}"
    local truncated_string="${string%.*}.$truncated_decimal_part"
    echo "$truncated_string"
}

# Start monitoring the latest.log file for chat messages
tail -f logs/latest.log | while read -r line; do
    # Check if the line contains the keyword
    if [[ $line == *"$keyword"* ]]; then
        # Extract the player name from the chat message
        player_name=$(echo "$line" | grep -oP '(?<=<).*?(?=>)')
        # Retrieve player coordinates using mcrcon
        player_coordinates=$(echo "data get entity @p[name=$player_name] Pos" | mcrcon -H localhost -p kevinsiraki -P 25575)
        # Extract x, y, z coordinates from the response
        coordinates=$(echo "$player_coordinates" | awk -F '[][]' '{gsub(/,/,"",$2); print $2}')
        # Format the message with coordinates
        final_coords=$(echo "${coordinates}" | tr -d "d")
        # Extract the user's chat message after the "savecoord" command
        user_message=$(echo "$line" | grep -oP '(?<=savecoord ).*')
        # Check if user_message is empty and assign "null" if true
        if [ -z "$user_message" ]; then
            user_message="BCA"
        fi
        # Extract the string until the first space
        result=$(get_string_until_space "$final_coords")
        # Extract the string after the first space until the next space
        result2=$(get_string_after_first_space "$final_coords")
        # Extract the string after the last space until the end
        result3=$(get_string_after_last_space "$final_coords")
        decimal_places=3
        truncated_string=$(truncate_string "$result" "$decimal_places")
        truncated_string2=$(truncate_string "$result2" "$decimal_places")
        truncated_string3=$(truncate_string "$result3" "$decimal_places")
        # Construct the final message with coordinates and user's chat
        message="$player_name: ${user_message}: ${truncated_string} ${truncated_string2} ${truncated_string3}"
        send_discord_message "$message"
    fi
    sleep 1s # Add a delay of 1 second
done &