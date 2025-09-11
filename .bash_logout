# ~/.bash_logout
if [[ -n "$WSL_DISTRO_NAME" ]] && command -v keychain >/dev/null 2>&1; then
    # Only clean up keychain in WSL - silently
    ssh-add -D >/dev/null 2>&1
    eval $(keychain --stop all) >/dev/null 2>&1
fi