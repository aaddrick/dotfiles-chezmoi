#!/bin/bash

# Read JSON input
input=$(cat)

# Get terminal width
term_width=$(tput cols 2>/dev/null || echo 80)

# Line 1: user@hostname:directory and context usage (right-justified)
user_host_dir=$(printf '\033[01;32m%s@%s\033[00m:\033[01;34m%s\033[00m' "$(whoami)" "$(hostname -s)" "$(pwd)")

# Calculate context usage
usage=$(echo "$input" | jq '.context_window.current_usage')
context_info=""
if [ "$usage" != "null" ]; then
    current=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    size=$(echo "$input" | jq '.context_window.context_window_size')
    pct=$((current * 100 / size))
    current_k=$((current / 1000))
    size_k=$((size / 1000))
    context_info=$(printf '\033[01;33m[%d%% - %dk/%dk tokens]\033[00m' "$pct" "$current_k" "$size_k")
fi

# Calculate padding for line 1
# Strip ANSI codes for length calculation
user_host_dir_plain=$(echo "$user_host_dir" | sed 's/\x1b\[[0-9;]*m//g')
context_info_plain=$(echo "$context_info" | sed 's/\x1b\[[0-9;]*m//g')

if [ -n "$context_info" ]; then
    left_len=${#user_host_dir_plain}
    right_len=${#context_info_plain}
    padding=$((term_width - left_len - right_len))
    if [ $padding -lt 1 ]; then
        padding=1
    fi
    line1=$(printf '%s%*s%s' "$user_host_dir" "$padding" "" "$context_info")
else
    line1="$user_host_dir"
fi

echo "$line1"

# Line 2: git branch and model name (right-justified)
branch=$(git --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
branch_info=""
if [ -n "$branch" ]; then
    branch_info=$(printf '\033[01;36m(%s)\033[00m' "$branch")
fi

model_name=$(echo "$input" | jq -r '.model.display_name // .model.id')
model_info=""
if [ -n "$model_name" ] && [ "$model_name" != "null" ]; then
    model_info="$model_name"
fi

# Calculate padding for line 2
branch_info_plain=$(echo "$branch_info" | sed 's/\x1b\[[0-9;]*m//g')

if [ -n "$branch_info" ] && [ -n "$model_info" ]; then
    left_len=${#branch_info_plain}
    right_len=${#model_info}
    padding=$((term_width - left_len - right_len))
    if [ $padding -lt 1 ]; then
        padding=1
    fi
    line2=$(printf '%s%*s%s' "$branch_info" "$padding" "" "$model_info")
    echo "$line2"
elif [ -n "$branch_info" ]; then
    echo "$branch_info"
elif [ -n "$model_info" ]; then
    # Right-justify model name when no branch
    padding=$((term_width - ${#model_info}))
    if [ $padding -lt 0 ]; then
        padding=0
    fi
    printf '%*s%s\n' "$padding" "" "$model_info"
fi
