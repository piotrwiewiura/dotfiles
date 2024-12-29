# Stop on error
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if groups | grep -q sudo; then
  sudo apt update
  sudo apt install curl git htop vim
fi

mkdir -p ~/.configs-orig

if ([ ! -L ~/.bashrc ]); then
  [ ! -f src ] || mv ~/.bashrc ~/.configs-orig/
  ln -s "$SCRIPT_DIR/.bashrc" ~/.bashrc
fi

if ([ ! -L ~/.vimrc ]); then
  [ ! -f src ] || mv ~/.vimrc ~/.configs-orig/
  ln -s "$SCRIPT_DIR/.vimrc" ~/.vimrc
fi

