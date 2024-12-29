# Stop on error
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if groups | grep -q sudo; then
  sudo apt update
  sudo apt install curl git htop vim
fi

mkdir -p ~/.configs-orig

if ([ ! -L ~/.bashrc ]); then
  [ ! -f ~/.bashrc ] || mv ~/.bashrc ~/.configs-orig/
  ln -s "$SCRIPT_DIR/.bashrc" ~/.bashrc
fi

if ([ ! -L ~/.vimrc ]); then
  [ ! -f ~/.vimrc ] || mv ~/.vimrc ~/.configs-orig/
  ln -s "$SCRIPT_DIR/.vimrc" ~/.vimrc
fi

if ([ ! -L ~/.ls.awk ]); then
  [ ! -f ~/.ls.awk ] || mv ~/.ls.awk ~/.configs-orig/
  ln -s "$SCRIPT_DIR/.ls.awk" ~/.ls.awk
fi
