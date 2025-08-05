# Stop on error
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if groups | grep -q sudo; then
  sudo apt update
  sudo apt install curl git htop vim bat
fi

CONFIGS_ORIG="$HOME/.configs-orig/"

mkdir -p $CONFIGS_ORIG

link_file() {
  DEST_FILE="$HOME/$1"  
  if [ ! -L $DEST_FILE ]; then
    [ ! -f $DEST_FILE ] || mv $DEST_FILE $CONFIGS_ORIG
    ln -s "$SCRIPT_DIR/$1" $DEST_FILE
  fi
}

link_file .bashrc
link_file .bash_aliases
link_file .vimrc
link_file .ls.awk

# if k3s is installed then copy the config to the home directory so that sudo is not necessary to run kubectl
# see https://github.com/k3s-io/k3s/issues/389#issuecomment-745808339
if [ -f /etc/rancher/k3s/k3s.yaml ]; then
  sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/k3s-config && sudo chown $USER: ~/.kube/k3s-config
fi

# TODO: The below won't work because .bashrc checks whether it's run interactively or not:
# https://unix.stackexchange.com/questions/481816/sourcing-bashrc-inside-script-doesnt-update-the-env-variables
source .bashrc
