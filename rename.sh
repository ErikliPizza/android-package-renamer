#!/usr/bin/env bash

if [ $# -lt 4 ]; then
  echo "Usage: $0 <OLD_PACKAGE> <NEW_PACKAGE> <NEW_APP_NAME> <NEW_PROJECT_NAME>"
  echo "Example: $0 com.example.oldapp com.example.newapp \"My New App\" \"MyNewProject\""
  exit 1
fi

OLD_PACKAGE="$1"
NEW_PACKAGE="$2"
NEW_APP_NAME="$3"
NEW_PROJECT_NAME="$4"

STRINGS_FILE="app/src/main/res/values/strings.xml"
APP_BUILD_GRADLE="app/build.gradle"
SETTINGS_GRADLE="settings.gradle"
MANIFEST_FILE="app/src/main/AndroidManifest.xml"

OLD_MAIN_PKG="app/src/main/java/$(echo "$OLD_PACKAGE" | tr '.' '/')"
NEW_MAIN_PKG="app/src/main/java/$(echo "$NEW_PACKAGE" | tr '.' '/')"
OLD_ANDROIDTEST_PKG="app/src/androidTest/java/$(echo "$OLD_PACKAGE" | tr '.' '/')"
NEW_ANDROIDTEST_PKG="app/src/androidTest/java/$(echo "$NEW_PACKAGE" | tr '.' '/')"
OLD_TEST_PKG="app/src/test/java/$(echo "$OLD_PACKAGE" | tr '.' '/')"
NEW_TEST_PKG="app/src/test/java/$(echo "$NEW_PACKAGE" | tr '.' '/')"

echo "======================================"
echo " Old package name: $OLD_PACKAGE"
echo " New package name: $NEW_PACKAGE"
echo " New app name:     $NEW_APP_NAME"
echo " New project name: $NEW_PROJECT_NAME"
echo "======================================"
echo

# Update app_name in strings.xml
echo "Updating <string name=\"app_name\"> in $STRINGS_FILE ..."
if [ -f "$STRINGS_FILE" ]; then
  sed -i "s|\(<string name=\"app_name\">\).*\(</string>\)|\1${NEW_APP_NAME}\2|" "$STRINGS_FILE"
else
  echo "Warning: $STRINGS_FILE not found. Skipping."
fi

# Update rootProject.name in settings.gradle
echo "Updating rootProject.name in $SETTINGS_GRADLE ..."
if [ -f "$SETTINGS_GRADLE" ]; then
  sed -i "s|^rootProject.name = \".*\"|rootProject.name = \"${NEW_PROJECT_NAME}\"|" "$SETTINGS_GRADLE"
else
  echo "Warning: $SETTINGS_GRADLE not found. Skipping."
fi

# Update namespace + applicationId in app/build.gradle
echo "Updating namespace + applicationId in $APP_BUILD_GRADLE ..."
if [ -f "$APP_BUILD_GRADLE" ]; then
  sed -i "s|^\(\s*\)namespace\s\+['\"].*['\"]|\1namespace '${NEW_PACKAGE}'|" "$APP_BUILD_GRADLE"
  sed -i "s|^\(\s*\)applicationId\s\+['\"].*['\"]|\1applicationId '${NEW_PACKAGE}'|" "$APP_BUILD_GRADLE"
else
  echo "Warning: $APP_BUILD_GRADLE not found. Skipping."
fi

# Function to rename package directories step by step
renamePackageDirStepByStep() {
  local OLD_DIR="$1"
  local NEW_DIR="$2"
  local ROOT_DIR="$3"

  IFS="/" read -ra OLD_PARTS <<< "$OLD_DIR"
  IFS="/" read -ra NEW_PARTS <<< "$NEW_DIR"
  
  local CURRENT_DIR="$ROOT_DIR"

  for ((i=0; i<${#NEW_PARTS[@]}; i++)); do
    if [ -d "$CURRENT_DIR/${OLD_PARTS[i]}" ]; then
      echo "Renaming: $CURRENT_DIR/${OLD_PARTS[i]} -> ${NEW_PARTS[i]}"
      mv "$CURRENT_DIR/${OLD_PARTS[i]}" "$CURRENT_DIR/${NEW_PARTS[i]}"
      CURRENT_DIR="$CURRENT_DIR/${NEW_PARTS[i]}"
    else
      echo "Warning: $CURRENT_DIR/${OLD_PARTS[i]} does not exist. Skipping."
    fi
  done
}

# Update package lines and assertEquals statements
echo "Updating package lines and assertEquals statements in Java files..."
find app/src/main/java/ app/src/androidTest/java/ app/src/test/java/ \
  -type f -name "*.java" \
  -exec sed -i "s|^package $OLD_PACKAGE;|package $NEW_PACKAGE;|g" {} \;

find app/src/androidTest/java/ app/src/test/java/ \
  -type f -name "*.java" \
  -exec sed -i "s|assertEquals(\"$OLD_PACKAGE\",|assertEquals(\"$NEW_PACKAGE\",|g" {} \;

# Rename package directories for main, androidTest, and test
echo "Renaming package directories in main/java ..."
renamePackageDirStepByStep "$OLD_MAIN_PKG" "$NEW_MAIN_PKG" "app/src/main/java"

echo "Renaming package directories in androidTest/java ..."
renamePackageDirStepByStep "$OLD_ANDROIDTEST_PKG" "$NEW_ANDROIDTEST_PKG" "app/src/androidTest/java"

echo "Renaming package directories in test/java ..."
renamePackageDirStepByStep "$OLD_TEST_PKG" "$NEW_TEST_PKG" "app/src/test/java"

# Update package attribute in AndroidManifest.xml
echo "Updating package attribute in $MANIFEST_FILE ..."
if [ -f "$MANIFEST_FILE" ]; then
  sed -i "s|package=\"$OLD_PACKAGE\"|package=\"$NEW_PACKAGE\"|" "$MANIFEST_FILE"
else
  echo "Warning: $MANIFEST_FILE not found. Skipping."
fi

# Refresh Gradle and build
echo "Refreshing Gradle dependencies..."
./gradlew --refresh-dependencies || echo "Gradle refresh failed (non-fatal)."

echo "Cleaning and assembling Debug build..."
./gradlew clean assembleDebug || echo "Gradle build failed (check logs)."

echo
echo "======================================"
echo "  Done! Verify changes in Android Studio."
echo "======================================"
