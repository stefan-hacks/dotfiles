#!/usr/bin/env bash

# Catppuccin color palette
mauve=$(tput setaf 183)    # Header elements
sapphire=$(tput setaf 117) # Accent 1
sky=$(tput setaf 123)      # Accent 2
peach=$(tput setaf 214)    # Highlight
text=$(tput setaf 255)     # Primary text
overlay=$(tput setaf 242)  # Dimmed text
reset=$(tput sgr0)

# Formatting elements
divider="────────────────────────────────────────────────────────────────"
header_divider="════════════════════════════════════════════════════════════════"

# Function to convert to hex
convert_to_hex() {
  local input="$1"
  echo -n "$input" | xxd -p -u | tr -d '\n'
}

# Function to reverse bytes for little-endian
reverse_bytes() {
  local hex="$1"
  echo "$hex" | fold -w2 | tac | tr -d '\n'
}

# Display help
show_help() {
  echo "${mauve}Usage:${reset} $0 [input|file.txt]"
  echo "Convert text/files to big-endian and little-endian hex representations"
  exit 1
}

# Check input
if [ $# -eq 0 ]; then
  show_help
fi

# Process input
input="$1"
if [ -f "$input" ]; then
  content=$(cat "$input")
  input_type="${mauve}File:${reset} ${text}$input${reset}"
else
  content="$input"
  input_type="${mauve}Text input${reset}"
fi

# Perform conversions
big_endian=$(convert_to_hex "$content")
little_endian=$(reverse_bytes "$big_endian")

# Display results
clear
echo -e "\n${overlay}${header_divider}${reset}"

figlet "endian cvrt" | lolcat
echo "${overlay}${header_divider}${reset}"

printf "${sapphire}%-25s ${overlay}│${reset} ${text}%s${reset}\n" "Input Type" "$input_type"
printf "${sapphire}%-25s ${overlay}│${reset} ${text}%s${reset}\n" "Original Content" "$content"
echo "${overlay}${divider}${reset}"

printf "${sapphire}%-25s ${overlay}│${reset} ${sky}%s${reset}\n" "Big-Endian (BE)" "$big_endian"
printf "${sapphire}%-25s ${overlay}│${reset} ${peach}%s${reset}\n" "Little-Endian (LE)" "$little_endian"
echo "${overlay}${divider}${reset}"
