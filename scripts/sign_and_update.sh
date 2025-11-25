#!/bin/bash
# Script to sign a DMG file and update appcast.xml for Sparkle auto-updates
# Usage: ./scripts/sign_and_update.sh path/to/iNotch.dmg version build_number

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check arguments
if [ "$#" -lt 3 ]; then
    echo -e "${RED}Error: Missing arguments${NC}"
    echo "Usage: $0 <dmg_path> <version> <build_number>"
    echo "Example: $0 ./iNotch.dmg 1.0 1"
    exit 1
fi

DMG_PATH="$1"
VERSION="$2"
BUILD_NUMBER="$3"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPCAST_PATH="$PROJECT_DIR/appcast.xml"
SPARKLE_TOOLS_DIR="$PROJECT_DIR/sparkle-tools"

# Check if DMG exists
if [ ! -f "$DMG_PATH" ]; then
    echo -e "${RED}Error: DMG file not found: $DMG_PATH${NC}"
    exit 1
fi

# Get file size
FILE_SIZE=$(stat -f%z "$DMG_PATH")
echo -e "${GREEN}📦 DMG file size: $FILE_SIZE bytes${NC}"

# Check if sign_update tool exists (compiled)
SIGN_UPDATE_TOOL=""
if [ -f "$SPARKLE_TOOLS_DIR/bin/sign_update" ]; then
    SIGN_UPDATE_TOOL="$SPARKLE_TOOLS_DIR/bin/sign_update"
elif command -v sign_update &> /dev/null; then
    SIGN_UPDATE_TOOL="sign_update"
else
    echo -e "${YELLOW}⚠️  sign_update tool not found. Building it...${NC}"
    
    # Try to build sign_update
    cd "$SPARKLE_TOOLS_DIR"
    if [ -f "Sparkle.xcodeproj/project.pbxproj" ]; then
        echo "Building sign_update from Xcode project..."
        xcodebuild -project Sparkle.xcodeproj -scheme sign_update -configuration Release -derivedDataPath ./build
        SIGN_UPDATE_TOOL="$SPARKLE_TOOLS_DIR/build/Build/Products/Release/sign_update"
    else
        echo -e "${RED}Error: Cannot find Sparkle.xcodeproj to build sign_update${NC}"
        echo "Please compile sign_update manually or install it"
        exit 1
    fi
fi

# Sign the DMG
echo -e "${GREEN}🔐 Signing DMG...${NC}"
SIGNATURE=$("$SIGN_UPDATE_TOOL" -p "$DMG_PATH" 2>/dev/null)

if [ -z "$SIGNATURE" ]; then
    echo -e "${RED}Error: Failed to generate signature${NC}"
    echo "Make sure your private EdDSA key is in Keychain with account name 'ed25519'"
    echo "Or use: $SIGN_UPDATE_TOOL --ed-key-file <key_file> -p $DMG_PATH"
    exit 1
fi

echo -e "${GREEN}✅ Signature generated:${NC}"
echo "$SIGNATURE"

# Generate release date (RFC 822 format)
RELEASE_DATE=$(date -u +"%a, %d %b %Y %H:%M:%S +0000")

# Create temporary appcast item
TEMP_ITEM=$(cat <<EOF
        <item>
            <title>iNotch $VERSION</title>
            <pubDate>$RELEASE_DATE</pubDate>
            <sparkle:version>$BUILD_NUMBER</sparkle:version>
            <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
            <description><![CDATA[
                <h1>iNotch $VERSION</h1>
                <p>Update description here</p>
            ]]></description>
            <enclosure 
                url="REPLACE_WITH_DOWNLOAD_URL" 
                length="$FILE_SIZE" 
                type="application/octet-stream" 
                sparkle:edSignature="$SIGNATURE"/>
        </item>
EOF
)

echo ""
echo -e "${GREEN}📝 Appcast item generated:${NC}"
echo "$TEMP_ITEM"
echo ""

# Ask user for download URL
read -p "Enter download URL for the DMG (GitHub Releases URL): " DOWNLOAD_URL

if [ -z "$DOWNLOAD_URL" ]; then
    echo -e "${YELLOW}⚠️  No URL provided. You'll need to update appcast.xml manually${NC}"
else
    # Replace placeholder URL
    TEMP_ITEM=$(echo "$TEMP_ITEM" | sed "s|REPLACE_WITH_DOWNLOAD_URL|$DOWNLOAD_URL|g")
fi

# Ask if user wants to update appcast.xml automatically
read -p "Update appcast.xml automatically? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Backup appcast.xml
    cp "$APPCAST_PATH" "$APPCAST_PATH.backup"
    
    # Find the </channel> tag and insert new item before it
    # Using Python for better XML handling
    python3 <<PYTHON_SCRIPT
import xml.etree.ElementTree as ET
from datetime import datetime

# Parse appcast
tree = ET.parse("$APPCAST_PATH")
root = tree.getroot()

# Find channel
channel = root.find('channel')

# Create new item
item = ET.Element('item')
ET.SubElement(item, 'title').text = f'iNotch $VERSION'
ET.SubElement(item, 'pubDate').text = '$RELEASE_DATE'

# Add Sparkle namespace elements
sparkle_ns = 'http://www.andymatuschak.org/xml-namespaces/sparkle'
version_elem = ET.SubElement(item, f'{{{sparkle_ns}}}version')
version_elem.text = '$BUILD_NUMBER'

short_version_elem = ET.SubElement(item, f'{{{sparkle_ns}}}shortVersionString')
short_version_elem.text = '$VERSION'

min_sys_elem = ET.SubElement(item, f'{{{sparkle_ns}}}minimumSystemVersion')
min_sys_elem.text = '14.0'

desc_elem = ET.SubElement(item, 'description')
desc_elem.text = '<![CDATA[\n                <h1>iNotch $VERSION</h1>\n                <p>Update description here</p>\n            ]]>'

# Create enclosure
enclosure = ET.SubElement(item, 'enclosure')
enclosure.set('url', '$DOWNLOAD_URL')
enclosure.set('length', '$FILE_SIZE')
enclosure.set('type', 'application/octet-stream')
enclosure.set(f'{{{sparkle_ns}}}edSignature', '$SIGNATURE')

# Insert at the beginning of channel (newest first)
channel.insert(0, item)

# Write back
tree.write("$APPCAST_PATH", encoding='utf-8', xml_declaration=True)
PYTHON_SCRIPT

    echo -e "${GREEN}✅ appcast.xml updated!${NC}"
    echo -e "${YELLOW}⚠️  Don't forget to:${NC}"
    echo "   1. Update the description in appcast.xml"
    echo "   2. Commit and push appcast.xml to GitHub"
    echo "   3. Upload the DMG to GitHub Releases"
else
    echo -e "${YELLOW}📋 Copy this item to appcast.xml:${NC}"
    echo "$TEMP_ITEM"
fi

echo ""
echo -e "${GREEN}✅ Done!${NC}"
echo ""
echo "Summary:"
echo "  Version: $VERSION"
echo "  Build: $BUILD_NUMBER"
echo "  File size: $FILE_SIZE bytes"
echo "  Signature: $SIGNATURE"
echo "  Download URL: $DOWNLOAD_URL"

