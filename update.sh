#!/bin/bash
set -e

README_FILE="README.md"
API_URL="https://api.github.com/emojis"
START_MARKER="<!-- generate:start -->"
STOP_MARKER="<!-- generate:stop -->"

# Check if README exists
if [ ! -f "$README_FILE" ]; then
  echo "Error: $README_FILE not found."
  exit 1
fi

# Fetch emojis and generate table
echo "Fetching emojis..."
EMOJIS=$(curl -s "$API_URL" | jq -r 'keys[]' | sort)

echo "Generating table..."
TABLE="| All | The | Emojis |\n|:---:|:---:|:---:|\n"
COLUMN=0
ROW_BUFFER=""

for name in $EMOJIS; do
  # Format: `:name:` :name:
  CELL="\`:$name:\` :$name:"
  
  if [ -z "$ROW_BUFFER" ]; then
    ROW_BUFFER="| $CELL "
  else
    ROW_BUFFER="$ROW_BUFFER| $CELL "
  fi
  
  COLUMN=$((COLUMN + 1))
  
  if [ "$COLUMN" -eq 3 ]; then
    TABLE="${TABLE}${ROW_BUFFER}|\n"
    ROW_BUFFER=""
    COLUMN=0
  fi
done

# Fill remaining columns if any
if [ "$COLUMN" -ne 0 ]; then
  while [ "$COLUMN" -lt 3 ]; do
    ROW_BUFFER="$ROW_BUFFER| "
    COLUMN=$((COLUMN + 1))
  done
  TABLE="${TABLE}${ROW_BUFFER}|\n"
fi

# Create a temporary file
TEMP_FILE=$(mktemp)

# Write content before the start marker (inclusive)
sed -n "1,/$START_MARKER/p" "$README_FILE" > "$TEMP_FILE"

# Write the table
echo -e "$TABLE" >> "$TEMP_FILE"

# Write content after the stop marker (inclusive)
sed -n "/$STOP_MARKER/,\$p" "$README_FILE" >> "$TEMP_FILE"

# Replace the original file
mv "$TEMP_FILE" "$README_FILE"

echo "Successfully updated $README_FILE with emoji list."

