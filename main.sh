#!/bin/bash

# Define colors and formatting
GREEN="\e[32m"
BLUE="\e[34m"
CYAN="\e[36m"
RED="\e[31m"
RESET="\e[0m"
BOLD="\e[1m"
UNDERLINE="\e[4m"

# Path to the JSON file
json_file="db/data.json"

# Function to display options with animations
function display_options() {
    clear
    echo -e "${GREEN}${BOLD}Installer${RESET}"
    echo -e "${CYAN}${UNDERLINE}Select an option:${RESET}"
    echo ""

    # Extract names from the JSON file and display them with colors and formatting
    jq -r '.apt | to_entries[] | "\(.key) \(.value.name)"' "$json_file" | nl -w 2 -s ' ' | while IFS= read -r line; do
        number=$(echo "$line" | awk '{print $1}')
        name=$(echo "$line" | awk '{$1=""; print substr($0,2)}')
        echo -e "${BLUE}[${RESET}${number}${BLUE}]${RESET} ${BOLD}${name}${RESET}"
    done
    echo ""
}

# Display the menu with options
display_options

# Read user choice
read -p "Enter your choice: " option

# Check the Package Manager
package_manager=$(./router/check.sh)

# Define a function to get the key and URL based on package manager and user choice
function get_key() {
    jq -r --arg name "$1" '.apt | to_entries[] | select(.value.name == $name) | .key' "$json_file"
}

function get_url() {
    jq -r --arg pm "$package_manager" --arg key "$1" '.[$pm][$key]?.url' "$json_file"
}

# Extract option names and find the corresponding key
option_name=$(jq -r --argjson num "$((option - 1))" '.apt | to_entries[$num].value.name' "$json_file")

if [[ -z "$option_name" || "$option_name" == "null" ]]; then
    echo -e "${RED}Invalid option selected.${RESET}" && exit 1
fi

# Get the key and URL for the selected option
key=$(get_key "$option_name")
url=$(get_url "$key")

# Print the package manager detected
if [[ "$package_manager" == "unknown" ]]; then
    echo -e "${RED}No known package manager found.${RESET}"
elif [[ -z "$url" || "$url" == "null" ]]; then
    echo -e "${RED}No URL found for the selected option.${RESET}"
else
    echo -e "${GREEN}${package_manager^} package manager detected.${RESET}"
    echo -e "${CYAN}Executing script from URL: ${RESET}${url}"

    # Fetch and execute the script content
    script_content=$(curl -sL "$url")
    eval "$script_content"
fi
