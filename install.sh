#!/bin/sh
#
# @author dinhnv

set -e
# ask sudo password (timeout to cache 15minutes)
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &


# constants
REPO_ROOT=$(pwd)
# I don't want to get stuck in trouble of /opt permissions and .apps to be less conflictable
APPS_DIR="$HOME/.apps"


# mkdir
mkdir -p $APPS_DIR


# utils
log() {
    echo "----------------------------------------------------------------------"
    echo $1
    echo "----------------------------------------------------------------------"
}

su_apt() {
    sudo apt-get install -y $@
}

# backup if existed
backup() {
    if [ -f $1 ] || [ -d $1 ]; then
        mv $1 "$1.origin"
    fi
}


# install
install_os_dependencies() {
    log "install os dependencies"
    # build
    su_apt build-essential make automake gcc python-dev python3-dev libssl-dev software-properties-common\
    # dev
    su_apt zlib1g-dev libpq-dev libtiff5-dev libjpeg8-dev libfreetype6-dev\
    liblcms2-dev libwebp-dev graphviz-dev gettext libbz2-dev\
    libreadline-dev libsqlite3-dev xclip
    # vim
    su_apt ncurses-dev
    # tmux
    su_apt libevent-dev
}


_tmux() {
    cd $APPS_DIR && git clone https://github.com/tmux/tmux.git
    cd tmux
    sh autogen.sh
    ./configure && make
    sudo make install
    sudo apt-get install tmuxinator
}

_neovim() {
    sudo add-apt-repository ppa:neovim-ppa/unstable
    sudo apt-get update
    su_apt neovim
    # clipboard, search, ctags for plugin requirements
    su_apt silversearcher-ag ctags
}


link_dotfiles() {
    log "make softlink dotfiles"
    tmux_conf="$HOME/.tmux.conf"
    backup $tmux_conf && ln -s "$REPO_ROOT/tmux/tmux.conf" $tmux_conf

    nv_dir="$HOME/.config/nvim/"
    mkdir -p $nv_dir && backup "$nv_dir/init.vim"\
        && ln -s $REPO_ROOT/vim/init.vim "$nv_dir/init.vim"
}


__main__() {
    log "start installing!"
}

__main__

