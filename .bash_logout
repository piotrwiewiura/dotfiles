# ~/.bash_logout
if [[ -n "$WSL_DISTRO_NAME" ]] && command -v keychain >/dev/null 2>&1; then
    # Only clean up keychain in WSL
    ssh-add -D 2>/dev/null
    eval $(keychain --stop all) 2>/dev/null
fi
