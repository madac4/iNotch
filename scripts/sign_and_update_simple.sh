#!/bin/bash
# Simplified script to sign a DMG file and update appcast.xml
# Uses Swift script instead of compiled sign_update tool
# Usage: ./scripts/sign_and_update_simple.sh path/to/iNotch.dmg version build_number

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
    echo "Example: $0 ./iNotch.dmg 1.1 2"
    exit 1
fi

DMG_PATH="$1"
VERSION="$2"
BUILD_NUMBER="$3"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPCAST_PATH="$PROJECT_DIR/appcast.xml"
SIGN_SCRIPT="$PROJECT_DIR/scripts/sign_update_simple.swift"

# Check if DMG exists
if [ ! -f "$DMG_PATH" ]; then
    echo -e "${RED}Error: DMG file not found: $DMG_PATH${NC}"
    exit 1
fi

# Check if sign script exists
if [ ! -f "$SIGN_SCRIPT" ]; then
    echo -e "${RED}Error: Sign script not found: $SIGN_SCRIPT${NC}"
    exit 1
fi

# Make script executable
chmod +x "$SIGN_SCRIPT"

# Get file size
FILE_SIZE=$(stat -f%z "$DMG_PATH")
echo -e "${GREEN}📦 DMG file size: $FILE_SIZE bytes${NC}"

# Sign the DMG
echo -e "${GREEN}🔐 Signing DMG...${NC}"
SIGNATURE_OUTPUT=$(swift "$SIGN_SCRIPT" "$DMG_PATH" -p 2>&1)
SWIFT_EXIT_CODE=$?

# Extract only the signature (last line, remove warnings)
SIGNATURE=$(echo "$SIGNATURE_OUTPUT" | grep -v "warning:" | tail -1 | tr -d '\n\r ')

if [ $SWIFT_EXIT_CODE -ne 0 ] || [ -z "$SIGNATURE" ]; then
    echo -e "${RED}Error: Failed to generate signature${NC}"
    echo "$SIGNATURE_OUTPUT"
    echo ""
    echo "Make sure your private EdDSA key is in Keychain:"
    echo "  - Service: https://sparkle-project.org"
    echo "  - Account: ed25519"
    echo ""
    echo "If you don't have keys, generate them first:"
    echo "  swift scripts/generate_keys_simple.swift"
    exit 1
fi

echo -e "${GREEN}✅ Signature generated:${NC}"
echo "$SIGNATURE"

# Generate release date (RFC 822 format)
RELEASE_DATE=$(date -u +"%a, %d %b %Y %H:%M:%S +0000")

# Ask user for download URL
echo ""
echo -e "${YELLOW}📋 To create a download URL:${NC}"
echo "   1. Go to: https://github.com/madac4/iNotch/releases"
echo "   2. Create a new release (tag: v$VERSION)"
echo "   3. Upload your DMG file"
echo "   4. Copy the download URL (right-click on DMG → Copy link)"
echo ""
read -p "Enter download URL for the DMG (or press Enter to use placeholder): " DOWNLOAD_URL

if [ -z "$DOWNLOAD_URL" ]; then
    echo -e "${YELLOW}⚠️  No URL provided. Using placeholder URL${NC}"
    DOWNLOAD_URL="https://github.com/madac4/iNotch/releases/download/v$VERSION/iNotch-v$VERSION.dmg"
    echo -e "${YELLOW}   You can update it later in appcast.xml${NC}"
fi

# Ask for release description
echo ""
read -p "Enter release description (HTML, press Enter for default): " RELEASE_DESC
if [ -z "$RELEASE_DESC" ]; then
    RELEASE_DESC="<h1>iNotch $VERSION</h1><p>Update description here</p>"
fi

# Create appcast item
TEMP_ITEM=$(cat <<EOF
        <item>
            <title>iNotch $VERSION</title>
            <pubDate>$RELEASE_DATE</pubDate>
            <sparkle:version>$BUILD_NUMBER</sparkle:version>
            <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>26.0</sparkle:minimumSystemVersion>
            <description><![CDATA[
                $RELEASE_DESC
            ]]></description>
            <enclosure 
                url="$DOWNLOAD_URL" 
                length="$FILE_SIZE" 
                type="application/octet-stream" 
                sparkle:edSignature="$SIGNATURE"/>
        </item>
EOF
)

echo ""
echo -e "${GREEN}📝 Generated appcast item:${NC}"
echo "$TEMP_ITEM"
echo ""

# Ask if user wants to update appcast.xml automatically
read -p "Update appcast.xml automatically? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Backup appcast.xml
    cp "$APPCAST_PATH" "$APPCAST_PATH.backup"
    echo -e "${GREEN}✅ Backup created: $APPCAST_PATH.backup${NC}"
    
    # Use Python to update XML properly
    python3 <<PYTHON_SCRIPT
import xml.etree.ElementTree as ET
from datetime import datetime

# Parse appcast
tree = ET.parse("$APPCAST_PATH")
root = tree.getroot()

# Register Sparkle namespace
ET.register_namespace('sparkle', 'http://www.andymatuschak.org/xml-namespaces/sparkle')

# Find channel
channel = root.find('channel')

# Create new item
item = ET.Element('item')
ET.SubElement(item, 'title').text = 'iNotch $VERSION'
ET.SubElement(item, 'pubDate').text = '$RELEASE_DATE'

# Add Sparkle namespace elements
sparkle_ns = '{http://www.andymatuschak.org/xml-namespaces/sparkle}'
version_elem = ET.SubElement(item, f'{sparkle_ns}version')
version_elem.text = '$BUILD_NUMBER'

short_version_elem = ET.SubElement(item, f'{sparkle_ns}shortVersionString')
short_version_elem.text = '$VERSION'

min_sys_elem = ET.SubElement(item, f'{sparkle_ns}minimumSystemVersion')
min_sys_elem.text = '26.0'

desc_elem = ET.SubElement(item, 'description')
desc_elem.text = '$RELEASE_DESC'

# Create enclosure
enclosure = ET.SubElement(item, 'enclosure')
enclosure.set('url', '$DOWNLOAD_URL')
enclosure.set('length', '$FILE_SIZE')
enclosure.set('type', 'application/octet-stream')
enclosure.set(f'{sparkle_ns}edSignature', '$SIGNATURE')

# Insert at the beginning of channel (newest first)
channel.insert(0, item)

# Write back with proper formatting
tree.write("$APPCAST_PATH", encoding='utf-8', xml_declaration=True)
PYTHON_SCRIPT

    echo -e "${GREEN}✅ appcast.xml updated!${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  Next steps:${NC}"
    echo "   1. Review appcast.xml to make sure everything is correct"
    echo "   2. Commit and push appcast.xml to GitHub:"
    echo "      git add appcast.xml"
    echo "      git commit -m 'Release v$VERSION'"
    echo "      git push origin main"
    echo "   3. Upload the DMG to GitHub Releases"
    echo "   4. Test the update in your app"
else
    echo -e "${YELLOW}📋 Copy this item to appcast.xml (insert at the beginning of <channel>):${NC}"
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

