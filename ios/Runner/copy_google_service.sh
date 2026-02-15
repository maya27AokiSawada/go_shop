#!/bin/sh

# フレーバーに応じてGoogleService-Info.plistをコピーするスクリプト

FLAVOR="${CONFIGURATION}"

# デバッグ出力
echo "🔧 Configuration: ${CONFIGURATION}"
echo "🔧 Product Flavor: ${PRODUCT_FLAVOR}"

# デフォルトはdev
if [ -z "${FLAVOR}" ]; then
  FLAVOR="dev"
fi

# Configurationから判定（Debug-prod, Release-prodなど）
if [[ "${FLAVOR}" == *"prod"* ]] || [[ "${FLAVOR}" == *"Prod"* ]]; then
  echo "📦 Using PROD GoogleService-Info.plist"
  cp "${SRCROOT}/Runner/prod/GoogleService-Info.plist" "${SRCROOT}/Runner/GoogleService-Info.plist"
else
  echo "🛠️ Using DEV GoogleService-Info.plist"
  cp "${SRCROOT}/Runner/dev/GoogleService-Info.plist" "${SRCROOT}/Runner/GoogleService-Info.plist"
fi

echo "✅ GoogleService-Info.plist copied successfully"
