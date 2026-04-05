#!/bin/bash
# Script to get a motivational quote for study.
# Usage: ./get_motivation.sh [subject]

# Fallback quotes
QUOTES=(
    "Success is the sum of small efforts, repeated day in and day out."
    "The secret of getting ahead is getting started."
    "Focus on being productive instead of busy."
    "Don't stop when you're tired. Stop when you're done."
    "Study like there's no tomorrow."
)

# Return a random fallback
echo "${QUOTES[$RANDOM % ${#QUOTES[@]}]}"
