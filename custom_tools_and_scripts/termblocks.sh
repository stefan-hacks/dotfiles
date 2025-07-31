#!/bin/bash

# Enhanced Terminal Blocks with Gum
# Replicates Warp's terminal block experience with interactive features

# Configuration
BLOCK_DB="$HOME/.term_blocks.db"
SESSION_DIR="$HOME/.term_sessions"
THEME="dark"  # light/dark

# Setup directories
mkdir -p "$SESSION_DIR"

# Initialize Gum styles
init_styles() {
    if [[ "$THEME" == "light" ]]; then
        HEADER_STYLE="bold fg=0 bg=7"
        CMD_STYLE="fg=4 bold"
        OUTPUT_STYLE="fg=0"
        META_STYLE="fg=5"
        SUCCESS_STYLE="fg=2"
        ERROR_STYLE="fg=1"
        HIGHLIGHT_STYLE="fg=0 bg=11"
    else
        HEADER_STYLE="bold fg=7 bg=0"
        CMD_STYLE="fg=12 bold"
        OUTPUT_STYLE="fg=7"
        META_STYLE="fg=13"
        SUCCESS_STYLE="fg=10"
        ERROR_STYLE="fg=9"
        HIGHLIGHT_STYLE="fg=0 bg=11"
    fi
}

# Start new session
new_session() {
    session_id=$(gum input --placeholder "Enter session name (optional)" | tr ' ' '_')
    [[ -z "$session_id" ]] && session_id="session_$(date +%s)"
    session_file="$SESSION_DIR/$session_id"
    
    gum style \
        "$(gum format --theme "$THEME" "## 🚀 Starting new session")" \
        "$(gum format --theme "$THEME" "ID: $session_id")"
    
    echo "$session_file"
}

# Execute command and capture block
exec_block() {
    local cmd="$*"
    [[ -z "$cmd" ]] && return
    
    local start_time=$(date +%s.%N)
    local output_file=$(mktemp)
    
    # Execute command with real-time output capture
    eval "$cmd" 2>&1 | tee "$output_file"
    local exit_status=${PIPESTATUS[0]}
    
    local end_time=$(date +%s.%N)
    local duration=$(printf "%.2f" $(echo "$end_time - $start_time" | bc))
    local output=$(base64 < "$output_file" | tr -d '\n')
    rm "$output_file"
    
    # Generate block
    local block_id="blk_$(uuidgen | cut -d'-' -f1)"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    # Save to database
    jq -n \
        --arg id "$block_id" \
        --arg cmd "$cmd" \
        --arg ts "$timestamp" \
        --arg dur "$duration" \
        --arg stat "$exit_status" \
        --arg out "$output" \
        --arg sess "$TERM_SESSION" \
        '{
            id: $id,
            command: $cmd,
            timestamp: $ts,
            duration: $dur,
            status: $stat,
            output: $out,
            session: $sess
        }' >> "$BLOCK_DB"
    
    return $exit_status
}

# Render block with formatting
render_block() {
    local block="$1"
    local highlight="${2:-}"
    
    local id=$(jq -r '.id' <<< "$block")
    local cmd=$(jq -r '.command' <<< "$block")
    local ts=$(jq -r '.timestamp' <<< "$block")
    local dur=$(jq -r '.duration' <<< "$block")
    local stat=$(jq -r '.status' <<< "$block")
    local out=$(jq -r '.output' <<< "$block" | base64 --decode)
    
    # Build header
    local status_icon
    [[ "$stat" == "0" ]] && status_icon="✅" || status_icon="❌"
    
    gum style \
        "$(gum format --theme "$THEME" "## $status_icon $cmd")" \
        "$(gum join --horizontal "$(gum style "$META_STYLE" "⏱ $dur s")" \
        "│" \
        "$(gum style "$META_STYLE" "$ts")" \
        "│" \
        "$(gum style "$META_STYLE" "ID: $id")")"
    
    # Highlight matches if specified
    if [[ -n "$highlight" ]]; then
        out=$(echo "$out" | grep --color=always -i -E "$highlight|$")
    fi
    
    # Display output
    echo "$out" | gum style "$OUTPUT_STYLE"
    gum style "$(gum format --theme "$THEME" "---")"
}

# Interactive block explorer
explore_blocks() {
    local blocks=()
    local commands=()
    
    # Read all blocks
    while IFS= read -r line; do
        local cmd=$(jq -r '.command' <<< "$line")
        local ts=$(jq -r '.timestamp' <<< "$line")
        local stat=$(jq -r '.status' <<< "$line")
        
        blocks+=("$line")
        commands+=("$ts [$stat] $cmd")
    done < <(jq -c '.' "$BLOCK_DB" | tac)
    
    # Select block
    local selected=$(printf "%s\n" "${commands[@]}" | \
        gum filter --height 20 --placeholder "Search commands...")
    
    [[ -z "$selected" ]] && return
    
    # Find matching block
    for i in "${!commands[@]}"; do
        if [[ "${commands[$i]}" == "$selected" ]]; then
            local highlight=$(gum input --placeholder "Highlight pattern (regex) [optional]")
            render_block "${blocks[$i]}" "$highlight"
            break
        fi
    done
}

# Session manager
session_manager() {
    case $(gum choose "New session" "List sessions" "Delete session" "Back") in
        "New session")
            TERM_SESSION=$(new_session)
            ;;
        "List sessions")
            local sessions=("$SESSION_DIR"/*)
            [[ ${#sessions[@]} -eq 0 ]] && sessions=("No sessions found")
            gum table -c "Session ID,Modified" \
                <(for s in "${sessions[@]}"; do 
                    echo "$(basename "$s"),$(date -r "$s" +'%Y-%m-%d %H:%M:%S')"; 
                done)
            ;;
        "Delete session")
            local sessions=()
            for s in "$SESSION_DIR"/*; do
                sessions+=("$(basename "$s")")
            done
            [[ ${#sessions[@]} -eq 0 ]] && {
                gum format "No sessions available"
                return
            }
            local to_delete=$(printf "%s\n" "${sessions[@]}" | \
                gum filter --height 15 --placeholder "Select session to delete")
            [[ -n "$to_delete" ]] && {
                rm "$SESSION_DIR/$to_delete"
                gum format "Deleted session: $to_delete"
            }
            ;;
    esac
}

# Main interface
main_menu() {
    init_styles
    
    while true; do
        choice=$(gum choose \
            "Execute command" \
            "Explore history" \
            "Manage sessions" \
            "Export session" \
            "Exit")
        
        case $choice in
            "Execute command")
                [[ -z "$TERM_SESSION" ]] && TERM_SESSION=$(new_session)
                cmd=$(gum input --placeholder "Enter command to execute" --prompt "❯ " --width 100)
                exec_block "$cmd"
                ;;
            "Explore history")
                explore_blocks
                ;;
            "Manage sessions")
                session_manager
                ;;
            "Export session")
                [[ -z "$TERM_SESSION" ]] && {
                    gum format "No active session!"
                    continue
                }
                output_file="${TERM_SESSION}.log"
                jq -c '.' "$BLOCK_DB" | grep "$(basename "$TERM_SESSION")" > "$output_file"
                gum format "Exported session to: $(gum style "$HIGHLIGHT_STYLE" "$output_file")"
                ;;
            "Exit")
                exit 0
                ;;
        esac
    done
}

# Initialize
if ! command -v gum &>/dev/null; then
    echo "Error: gum not installed. Please install from https://github.com/charmbracelet/gum"
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo "Error: jq not installed. Please install jq"
    exit 1
fi

# Start main interface
main_menu
