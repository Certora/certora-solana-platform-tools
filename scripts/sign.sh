#!/usr/bin/env bash
set -ex

FILES_TO_SIGN=$@

for FILE_PATH in $FILES_TO_SIGN; do
    FILE_NAME=$(basename $FILE_PATH)
    APPLE_TEMPKEYCHAIN_NAME=$(echo $FILE_NAME | tr -cd 'a-zA-Z')$(($RANDOM)) # use a random name
    
    echo "File path: $FILE_PATH"
    echo "File name: $FILE_NAME"
    echo "Apple temp keychain name: $APPLE_TEMPKEYCHAIN_NAME"

    # create keychain
    printf "$APPLE_P12_BASE64" | base64 -d > dev.p12
    security create-keychain -p "$APPLE_TEMPKEYCHAIN_PASSWORD" "$APPLE_TEMPKEYCHAIN_NAME"
    security list-keychains -d user -s "$APPLE_TEMPKEYCHAIN_NAME" $(security list-keychains -d user | tr -d '"')
    security set-keychain-settings "$APPLE_TEMPKEYCHAIN_NAME"
    security import dev.p12 -k "$APPLE_TEMPKEYCHAIN_NAME" -P "$APPLE_P12_PASSWORD" -T "/usr/bin/codesign"
    security set-key-partition-list -S apple-tool:,apple: -s -k "$APPLE_TEMPKEYCHAIN_PASSWORD" -D "$APPLE_CODESIGN_IDENTITY" -t private "$APPLE_TEMPKEYCHAIN_NAME"
    security default-keychain -d user -s "$APPLE_TEMPKEYCHAIN_NAME"
    security unlock-keychain -p "$APPLE_TEMPKEYCHAIN_PASSWORD" "$APPLE_TEMPKEYCHAIN_NAME"

    # sign the binary
    codesign -o runtime --force --timestamp --entitlements ./scripts/hardened_runtime_entitlements.plist -s "$APPLE_CODESIGN_IDENTITY" -v $FILE_PATH

    # notarize binary
    ditto -c -k $FILE_PATH $FILE_NAME.zip # notarization require zip files
    xcrun notarytool store-credentials --apple-id shelly@certora.com --password "$APPLE_CRED" --team-id "$APPLE_TEAMID" altool
    xcrun notarytool submit $FILE_NAME.zip --keychain-profile altool --wait
done
