# Android Project Package Renaming Script (`rename.sh`)

## Overview
This bash script simplifies the process of renaming an Android Studio project's package name, app name, and project name. It performs several operations to ensure that your Android project is properly refactored, including updating Java package declarations, Gradle configurations, and directory structures.

---

## Features
1. Renames package names across the entire project (main, androidTest, and test directories).
2. Updates `<string name="app_name">` in `strings.xml`.
3. Updates `rootProject.name` in `settings.gradle`.
4. Updates `namespace` and `applicationId` in `app/build.gradle`.
5. Renames package directories in `java`, `androidTest`, and `test`.
6. Updates `package` statements in `.java` files.
7. Modifies `assertEquals` statements for testing (`ExampleInstrumentedTest`, `ExampleUnitTest`).
8. Updates the `package` attribute in `AndroidManifest.xml`.
9. Optionally refreshes Gradle dependencies and rebuilds the project.

---

## Usage

### Command:
```bash
chmod +x rename.sh
```
```bash
sudo ./rename.sh <OLD_PACKAGE> <NEW_PACKAGE> <NEW_APP_NAME> <NEW_PROJECT_NAME>
```

### Example:
```bash
sudo ./rename.sh com.packagename.appname com.erikli.pizza "Erikli Pizza" "Erikli Pizza"
```

### Arguments:
- `<OLD_PACKAGE>`: The current package name (e.g., `com.packagename.appname`)
- `<NEW_PACKAGE>`: The new package name (e.g., `com.erikli.pizza`)
- `<NEW_APP_NAME>`: The new app name as it appears in `strings.xml` (e.g., `Erikli Pizza`)
- `<NEW_PROJECT_NAME>`: The new project name as it appears in `settings.gradle` (e.g., `Erikli Pizza`)

---

## What the Script Does

1. **Update `strings.xml`**  
   Replaces the `<string name="app_name">` value with the new app name.

2. **Update `settings.gradle`**  
   Changes `rootProject.name` to the new project name.

3. **Update `app/build.gradle`**  
   Updates the `namespace` and `applicationId` with the new package name.

4. **Update Java Package Declarations**  
   Replaces `package com.old.package;` with `package com.new.package;` in all `.java` files.

5. **Update `assertEquals` Statements**  
   Replaces `assertEquals("com.old.package", ...)` with `assertEquals("com.new.package", ...)` in test files.

6. **Rename Package Directories**  
   Renames package directories for `main/java`, `androidTest/java`, and `test/java`.

7. **Update `AndroidManifest.xml`**  
   Changes the `package` attribute to the new package name.

8. **Refresh Gradle and Build**  
   - Runs `./gradlew --refresh-dependencies` to update dependencies.
   - Cleans and builds the project with `./gradlew clean assembleDebug`.

---

## Script Breakdown

### Main Variables
```bash
OLD_PACKAGE="$1"
NEW_PACKAGE="$2"
NEW_APP_NAME="$3"
NEW_PROJECT_NAME="$4"
```
These variables represent the old and new package names, the new app name, and the new project name passed as command-line arguments.

### Package Directory Paths
```bash
OLD_MAIN_PKG="app/src/main/java/$(echo "$OLD_PACKAGE" | tr '.' '/')"
NEW_MAIN_PKG="app/src/main/java/$(echo "$NEW_PACKAGE" | tr '.' '/')"
```
Defines paths for the old and new package directories in `main`, `androidTest`, and `test`.

### Function: `renamePackageDirStepByStep`
```bash
renamePackageDirStepByStep() {
  local OLD_DIR="$1"
  local NEW_DIR="$2"
  local ROOT_DIR="$3"

  IFS="/" read -ra OLD_PARTS <<< "$OLD_DIR"
  IFS="/" read -ra NEW_PARTS <<< "$NEW_DIR"
  
  local CURRENT_DIR="$ROOT_DIR"

  for ((i=0; i<${#NEW_PARTS[@]}; i++)); do
    if [ -d "$CURRENT_DIR/${OLD_PARTS[i]}" ]; then
      mv "$CURRENT_DIR/${OLD_PARTS[i]}" "$CURRENT_DIR/${NEW_PARTS[i]}"
      CURRENT_DIR="$CURRENT_DIR/${NEW_PARTS[i]}"
    fi
  done
}
```
This function renames package directories step by step to ensure proper restructuring, even if the new package name differs significantly from the old one.

### Gradle Refresh and Build
```bash
./gradlew --refresh-dependencies || echo "Gradle refresh failed (non-fatal)."
./gradlew clean assembleDebug || echo "Gradle build failed (check logs)."
```
Refreshes Gradle dependencies and attempts to build the project.

---

## Important Notes
- **Backup Your Project:** Always back up or commit your project before running this script.
- **Valid Java Package Names:** Ensure the new package name is valid (all lowercase letters, no special characters, and separated by dots).
- **Gradle Build:** After running the script, even if you see some build errors on your terminal do not worry. Just clean, rebuild and sync your project via Android Studio manually.

---

## Troubleshooting
1. **Directories Not Renamed Properly**: Ensure the old package name is accurately specified and that your project follows standard directory structures.
2. **Gradle Build Failure**: Check your `build.gradle` files for syntax errors or unresolved dependencies.

---

## License
This script is open-source and free to use under the MIT License.

---

## Conclusion
The `rename.sh` script automates the tedious process of renaming Android package names, ensuring consistency across files and directories. After running this script, verify the changes in Android Studio and rebuild the project.

---
