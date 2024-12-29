# Stop on error
set -e

SCRIPT_DIR=$(dirname "$0")

echo $SCRIPT_DIR

cp "$SCRIPT_DIR/.vimrc" ~/.vimrc
