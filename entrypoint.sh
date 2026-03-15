#!/bin/bash
set -e

# Ensure /data is owned by openclaw
chown -R openclaw:openclaw /data
chmod 700 /data

# Set up Homebrew/Linuxbrew paths if already installed on the persistent volume
export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"
export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
export HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar"
export HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew/Homebrew"

# If Homebrew was previously installed to the persistent volume, symlink it back
if [ -d /data/.linuxbrew ] && [ ! -d /home/linuxbrew/.linuxbrew ]; then
  ln -sfn /data/.linuxbrew /home/linuxbrew/.linuxbrew
fi

# Install Homebrew in the background (into persistent volume) if not present.
# This runs AFTER the wrapper starts so it does not block the healthcheck.
install_brew_background() {
  if command -v brew &>/dev/null; then
    echo "[entrypoint] Homebrew already available"
    return
  fi
  echo "[entrypoint] Installing Homebrew in background (into /data/.linuxbrew)..."
  if NONINTERACTIVE=1 HOME=/home/openclaw \
     su -s /bin/bash openclaw -c \
     'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' \
     2>&1; then
    # Move to persistent volume and symlink
    if [ -d /home/linuxbrew/.linuxbrew ] && [ ! -L /home/linuxbrew/.linuxbrew ]; then
      cp -a /home/linuxbrew/.linuxbrew /data/.linuxbrew
      rm -rf /home/linuxbrew/.linuxbrew
      ln -sfn /data/.linuxbrew /home/linuxbrew/.linuxbrew
    fi
    echo "[entrypoint] Homebrew installed successfully"
  else
    echo "[entrypoint] Homebrew install failed (non-fatal, skills can still use fallback installers)"
  fi
}

# Start the wrapper as openclaw user (foreground)
# Launch brew install in background AFTER starting node
install_brew_background &
exec su -s /bin/bash openclaw -c "exec node src/server.js"
