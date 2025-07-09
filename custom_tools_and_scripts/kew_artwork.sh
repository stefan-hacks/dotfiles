#!/bin/bash

# Dependency checks
command -v playerctl >/dev/null 2>&1 || {
  echo "Please install playerctl"
  exit 1
}
command -v jq >/dev/null 2>&1 || {
  echo "Please install jq"
  exit 1
}
command -v curl >/dev/null 2>&1 || {
  echo "Please install curl"
  exit 1
}

# Check if Kew is running
if ! playerctl -l | grep -q kew; then
  echo "Kew is not running"
  exit 1
fi

# Get track metadata
artist=$(playerctl -p kew metadata artist)
title=$(playerctl -p kew metadata title)

if [ -z "$artist" ] || [ -z "$title" ]; then
  echo "No track currently playing or missing metadata"
  exit 1
fi

# Search iTunes API
response=$(curl -Gs "https://itunes.apple.com/search" \
  --data-urlencode "term=$artist $title" \
  --data "media=music" \
  --data "entity=song" \
  --data "limit=1")

# Parse response
result_count=$(echo "$response" | jq '.resultCount')

if [ "$result_count" -eq 0 ]; then
  echo "No results found for: $artist - $title"
  exit 1
fi

artwork_url=$(echo "$response" | jq -r '.results[0].artworkUrl100')

if [[ "$artwork_url" == "null" || -z "$artwork_url" ]]; then
  echo "No artwork available"
  exit 1
fi

# Get higher resolution (500x500 instead of 100x100)
artwork_url="${artwork_url/100x100/500x500}"

# Download and display image
temp_file=$(mktemp /tmp/kew_artwork.XXXXXX.jpg)

if ! curl -s -o "$temp_file" "$artwork_url"; then
  echo "Failed to download artwork"
  rm "$temp_file" 2>/dev/null
  exit 1
fi

# Display with preferred viewer
if command -v feh >/dev/null; then
  feh "$temp_file"
  rm "$temp_file"
elif command -v eog >/dev/null; then
  eog "$temp_file"
  rm "$temp_file"
else
  echo "Artwork saved to: $temp_file"
  xdg-open "$temp_file" 2>/dev/null
fi
