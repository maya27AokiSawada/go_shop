#!/bin/sh

# Flutter flavor-based GoogleService-Info.plist selector for iOS
# This script copies the appropriate GoogleService-Info.plist based on the Flutter build flavor

echo "🔥 Firebase Config Script: Starting..."
echo "Configuration: ${CONFIGURATION}"

# Determine flavor from build configuration name
if [[ "${CONFIGURATION}" == *"prod"* ]] || [[ "${CONFIGURATION}" == "Release" ]] || [[ "${CONFIGURATION}" == "Profile" ]]; then
    FLAVOR="prod"
else
    FLAVOR="dev"
fi

echo "🎯 Detected Flavor: ${FLAVOR}"

# Set source file paths
GOOGLESERVICE_INFO_PROD="${PROJECT_DIR}/GoogleService-Info-prod.plist"
GOOGLESERVICE_INFO_DEV="${PROJECT_DIR}/GoogleService-Info-dev.plist"
GOOGLESERVICE_INFO_DEST="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"

# Copy appropriate file
if [ "${FLAVOR}" == "prod" ]; then
    if [ -f "${GOOGLESERVICE_INFO_PROD}" ]; then
        cp "${GOOGLESERVICE_INFO_PROD}" "${GOOGLESERVICE_INFO_DEST}"
        echo "✅ Copied GoogleService-Info-prod.plist"
    else
        echo "❌ Error: GoogleService-Info-prod.plist not found"
        exit 1
    fi
else
    if [ -f "${GOOGLESERVICE_INFO_DEV}" ]; then
        cp "${GOOGLESERVICE_INFO_DEV}" "${GOOGLESERVICE_INFO_DEST}"
        echo "✅ Copied GoogleService-Info-dev.plist"
    else
        echo "❌ Error: GoogleService-Info-dev.plist not found"
        exit 1
    fi
fi

echo "🔥 Firebase Config Script: Complete"
