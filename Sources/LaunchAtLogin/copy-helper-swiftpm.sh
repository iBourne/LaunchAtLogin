#!/bin/bash

HELPER_CHECKSUM="2828d76bb469187413a1d276382267e10d761dacce696dab62edca225c8cdff3"
HELPER_CHECKSUM_RUNTIME="97efc206832c9ff92f9835b372d23ea32fd32a21008a4b7df43dc54d1c4bbaf2"

verlte() {
	[ "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]
}

if verlte "10.14.4" "$MACOSX_DEPLOYMENT_TARGET"; then
	helper_name="LaunchAtLoginHelper"
	checksum="$HELPER_CHECKSUM"
else
	helper_name="LaunchAtLoginHelper-with-runtime"
	checksum="$HELPER_CHECKSUM_RUNTIME"
fi

package_resources_path="$BUILT_PRODUCTS_DIR/LaunchAtLogin_LaunchAtLogin.bundle/Contents/Resources"

helper_path="$package_resources_path/$helper_name.zip"

contents_path="$BUILT_PRODUCTS_DIR/$CONTENTS_FOLDER_PATH"
login_items="$contents_path/Library/LoginItems"
login_helper_path="$login_items/LaunchAtLoginHelper.app"

rm -rf "$login_helper_path"
mkdir -p "$login_items"

# Verify SHA256 checksum of LaunchAtLoginHelper.
zip_checksum="$(shasum -a 256 "$helper_path" | awk '{print $1}')"

if [[ "$zip_checksum" != "$checksum" ]]; then
	echo "Wrong checksum of LaunchAtLoginHelper"
	exit 1
fi

unzip "$helper_path" -d "$login_items/"

defaults write "$login_helper_path/Contents/Info" CFBundleIdentifier -string "$PRODUCT_BUNDLE_IDENTIFIER-LaunchAtLoginHelper"

if [[ -n $CODE_SIGN_ENTITLEMENTS ]]; then
	codesign --force --entitlements="$package_resources_path/LaunchAtLogin.entitlements" --deep --options=runtime --sign="$EXPANDED_CODE_SIGN_IDENTITY_NAME" "$login_helper_path"
else
	codesign --force --deep --options=runtime --sign="$EXPANDED_CODE_SIGN_IDENTITY_NAME" "$helper_path"
fi

# If this is being built for multiple architectures, assume it is a release build and we should clean up.
if [[ $ONLY_ACTIVE_ARCH == "NO" ]]; then
	rm -rf "$contents_path/Resources/LaunchAtLogin_LaunchAtLogin.bundle"
fi
