# Stop on error
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if groups | grep -q sudo; then
  sudo apt update
  sudo apt install curl git htop vim
fi

CONFIGS_ORIG="$HOME/.configs-orig/"

mkdir -p $CONFIGS_ORIG

link_file() {
  DEST_FILE="$HOME/$1"  
  if ([ ! -L $DEST_FILE ]); then
    [ ! -f $DEST_FILE ] || mv $DEST_FILE $CONFIGS_ORIG
    ln -s "$SCRIPT_DIR/$1" $DEST_FILE
  fi
}

link_file .bashrc
link_file .vimrc
link_file .ls.awk
