#!/bin/sh

echo "[STARTUP] AdGuardHome Railway Startup Script"

# Create base target directory
echo "[INFO] Creating base directory /opt/adguardhomelink if it doesn't exist..."
mkdir -p /opt/adguardhomelink
echo "[SUCCESS] Base directory ready"

# Process each directory mapping
for DIR_NAME in work conf data; do
    SOURCE="/opt/adguardhome/$DIR_NAME"
    TARGET="/opt/adguardhomelink/$DIR_NAME"
    
    echo "[PROCESSING] $SOURCE -> $TARGET"
    
    # Check if source exists
    if [ -e "$SOURCE" ]; then
        echo "[CHECK] Source exists: $SOURCE"
        # Check if it's already a symlink
        if [ -L "$SOURCE" ]; then
            CURRENT_TARGET=$(readlink "$SOURCE")
            echo "[INFO] Source is already a symlink pointing to: $CURRENT_TARGET"
            if [ "$CURRENT_TARGET" = "$TARGET" ]; then
                echo "[SKIP] Already correctly linked to $TARGET"
            else
                echo "[WARNING] Symlink points to different location: $CURRENT_TARGET"
                echo "[INFO] Removing old symlink and creating new one..."
                rm "$SOURCE"
                mkdir -p "$TARGET"
                ln -s "$TARGET" "$SOURCE"
                echo "[SUCCESS] Symlink updated to point to $TARGET"
            fi
        else
            # Source exists but is not a symlink (directory or file)
            echo "[INFO] Source is a real directory/file, not a symlink"
            echo "[INFO] Creating target directory: $TARGET"
            mkdir -p "$TARGET"
            # Move contents if source has any
            if [ "$(ls -A $SOURCE 2>/dev/null)" ]; then
                echo "[INFO] Source contains files, moving to target..."
                mv "$SOURCE"/* "$TARGET"/ 2>/dev/null || true
                echo "[SUCCESS] Files moved to $TARGET"
            else
                echo "[INFO] Source is empty, no files to move"
            fi
            # Remove source and create symlink
            echo "[INFO] Removing source directory and creating symlink..."
            rm -rf "$SOURCE"
            ln -s "$TARGET" "$SOURCE"
            echo "[SUCCESS] Symlink created: $SOURCE -> $TARGET"
        fi
    else
        echo "[CHECK] Source does not exist: $SOURCE"
        echo "[INFO] Creating target directory: $TARGET"
        mkdir -p "$TARGET"
        echo "[INFO] Creating symlink: $SOURCE -> $TARGET"
        ln -s "$TARGET" "$SOURCE"
        echo "[SUCCESS] Fresh symlink created"
    fi
    # Verify symlink
    if [ -L "$SOURCE" ]; then
        VERIFY_TARGET=$(readlink "$SOURCE")
        echo "[VERIFY] ✓ Symlink confirmed: $SOURCE -> $VERIFY_TARGET"
    else
        echo "[ERROR] ✗ Failed to create symlink for $SOURCE"
    fi
done

echo "[COMPLETE] Symlink setup complete!"
echo "[INFO] Listing symlink structure:"
ls -la /opt/adguardhome/ 2>/dev/null || echo "[INFO] /opt/adguardhome/ not yet created"
echo "[INFO] Target directory contents:"
ls -la /opt/adguardhomelink/ 2>/dev/null || echo "[INFO] /opt/adguardhomelink/ empty"
echo "[STARTING] Starting AdGuardHome..."

# Start AdGuardHome (adjust the binary path if needed)
exec /opt/adguardhome/AdGuardHome -c /opt/adguardhome/conf/AdGuardHome.yaml -w /opt/adguardhome/work
