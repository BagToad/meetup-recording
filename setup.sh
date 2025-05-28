#!/bin/bash

# Get username as default suggestion for profile name
DEFAULT_PROFILE_NAME="$(whoami)-meetup-recording"

# Get current directory (location of this script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/template"

# Check if template directory exists
if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "Error: Template directory not found at $TEMPLATE_DIR"
    exit 1
fi

# Prompt for profile name
echo "OBS Meetup Recording Setup"
echo "=========================="
echo ""
read -p "Enter a name for your OBS profile [$DEFAULT_PROFILE_NAME]: " PROFILE_NAME
PROFILE_NAME=${PROFILE_NAME:-$DEFAULT_PROFILE_NAME}

# Sanitize profile name (replace spaces with underscores)
PROFILE_NAME=$(echo "$PROFILE_NAME" | tr ' ' '_')

# Prompt for recordings directory with validation
while true; do
    read -p "Enter path to save recordings: " RECORDING_DIR
    
    # Expand ~ if present
    RECORDING_DIR="${RECORDING_DIR/#\~/$HOME}"
    
    # Check if directory exists
    if [ ! -d "$RECORDING_DIR" ]; then
        read -p "Directory does not exist. Create it? (y/n): " CREATE_DIR
        if [[ "$CREATE_DIR" =~ ^[Yy]$ ]]; then
            mkdir -p "$RECORDING_DIR"
            if [ $? -ne 0 ]; then
                echo "Failed to create directory. Please try again."
                continue
            fi
        else
            echo "Please enter a valid directory path."
            continue
        fi
    fi
    
    # Verify write permissions
    if [ ! -w "$RECORDING_DIR" ]; then
        echo "Cannot write to $RECORDING_DIR. Please choose a different location."
        continue
    fi
    
    break
done

# Determine output directory - create locally in the repo
OUTPUT_DIR="$SCRIPT_DIR/generated/$PROFILE_NAME"
IMAGES_DIR="$OUTPUT_DIR/images"

# Summarize and confirm
echo ""
echo "Setup Summary:"
echo "- Profile name: $PROFILE_NAME"
echo "- Recordings will be saved to: $RECORDING_DIR"
echo "- Generated files will be saved to: $OUTPUT_DIR"
echo ""
echo "The following will happen:"
echo "1. OBS profile files will be generated in: $OUTPUT_DIR/profile/"
echo "2. Scene collection will be generated in: $OUTPUT_DIR/scene-collections/"
echo "3. Images will be copied to: $OUTPUT_DIR/images/"
echo "4. Macros will be copied to: $OUTPUT_DIR/macros/ (if available)"
echo ""
echo "You will then need to manually import these into OBS Studio."
echo ""
read -p "Continue with setup? (y/n): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Setup canceled."
    exit 0
fi

echo ""
echo "Generating OBS profile files..."

# Create output directories
mkdir -p "$OUTPUT_DIR/profile"
mkdir -p "$OUTPUT_DIR/scene-collections"
mkdir -p "$IMAGES_DIR"

# Copy and customize profile files
cp -r "$TEMPLATE_DIR/profiles/DESRecording/"* "$OUTPUT_DIR/profile/"

# Copy images
cp -r "$TEMPLATE_DIR/images/"* "$IMAGES_DIR/"

# Copy macros if they exist
if [ -d "$TEMPLATE_DIR/macros" ]; then
    mkdir -p "$OUTPUT_DIR/macros"
    cp -r "$TEMPLATE_DIR/macros/"* "$OUTPUT_DIR/macros/"
fi

# Copy scene collection
cp "$TEMPLATE_DIR/scene-collections/meetuprecording.json" "$OUTPUT_DIR/scene-collections/"

# Replace placeholders in configuration files
echo "Updating configuration files..."

# Update basic.ini with profile name and recording path
sed -i '' "s|{{profile_name}}|$PROFILE_NAME|g" "$OUTPUT_DIR/profile/basic.ini"
sed -i '' "s|{{recording_dir}}|$RECORDING_DIR|g" "$OUTPUT_DIR/profile/basic.ini"

# Update scene collection with images path
sed -i '' "s|{{images_dir}}|$IMAGES_DIR|g" "$OUTPUT_DIR/scene-collections/meetuprecording.json"

echo ""
echo "Setup complete!"
echo ""
echo "Generated files are located in: $OUTPUT_DIR"
echo ""
echo "To import into OBS Studio:"
echo "1. Open OBS Studio"
echo "2. Go to Profile > Import and select: $OUTPUT_DIR/profile/"
echo "3. Go to Scene Collection > Import and select: $OUTPUT_DIR/scene-collections/meetuprecording.json"
echo "4. If using Advanced Scene Switcher, import macros from: $OUTPUT_DIR/macros/"
echo ""
echo "Note: The images are already configured with the correct paths in the scene collection."
echo ""
echo "Happy recording!"