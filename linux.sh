#!/bin/sh
#
# @author dinhnv

set -e
# ask sudo password (timeout to cache 15minutes)
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &


# constants
EMAIL="dinhnv.mr@gmail.com"
REPO_ROOT=$(pwd)
# I don't want to get stuck in trouble of /opt permissions and .apps to be less conflictable
APPS_DIR="$HOME/.apps"
TMP_DIR="${HOME}/tmp"
# instead of bashrc or .profile
PROFILE="$HOME/.zshrc"


# mkdir
mkdir -p $APPS_DIR
mkdir -p $TMP_DIR


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

append_profile() {
    cat >> $PROFILE $@
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


# ----------------------------------------------------------------------
# terminal tools
# ----------------------------------------------------------------------
_tmux() {
    log "tmux"
    cd $APPS_DIR && git clone https://github.com/tmux/tmux.git
    cd tmux
    sh autogen.sh
    ./configure && make
    sudo make install
    sudo apt-get install tmuxinator
    tmux_conf="$HOME/.tmux.conf"
    backup $tmux_conf && ln -s "$REPO_ROOT/tmux/tmux.conf" $tmux_conf
    mkdir -p $HOME/.tmuxinator
    ln -s $REPO_ROOT/tmux/tmuxinator/ $HOME/.tmuxinator/
}

_neovim() {
    log "neovim"
    sudo add-apt-repository ppa:neovim-ppa/unstable
    sudo apt-get update
    su_apt neovim
    # clipboard, search, ctags for plugin requirements
    su_apt silversearcher-ag ctags
    NVDIR="$HOME/.config/nvim/"
    mkdir -p $NVDIR && backup "$NVDIR/init.vim"\
        && ln -s $REPO_ROOT/vim/init.vim "${NVDIR}/init.vim"
    # vim plug
    curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
}

_zsh() {
    log "zsh & oh-my-zsh"
    sudo apt-get install zsh
    chsh -s $(which zsh)
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    ln -s $REPO_ROOT/zsh/zshrc.local $HOME/.zshrc.local
    append_profile <<EOF
if [ -f \$HOME/.zshrc.local ]; then
    source \$HOME/.zshrc.local
fi
EOF
}

_spacemacs() {
    sudo apt-add-repository -y ppa:adrozdoff/emacs
    sudo apt update
    sudo apt install emacs25
    git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d
}

install_term() {
    _tmux
    _neovim
    _zsh
    _spacemacs
}

generate_sshkeys() {
    log "generate ssh key and add to ssh-agent"
    ssh keys & ssh-agent
    ssh-keygen -t rsa -b 4096 -C $EMAIL -f $HOME/.ssh/id_rsa -N ""
    eval "$(ssh-agent -s)"
    ssh-add $HOME/.ssh/id_rsa
}


# ----------------------------------------------------------------------
# development env
# ----------------------------------------------------------------------
python_env() {
    log "python environment"
    su_apt libmysqlclient-dev

    # python environment
    cd $APP_DIR && wget https://bootstrap.pypa.io/get-pip.py
    sudo python3 get-pip.py
    # install later to make pip2 is default
    sudo python2 get-pip.py

    # pyenv
    curl -L https://raw.github.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash
    git clone https://github.com/yyuu/pyenv-virtualenvwrapper.git ~/.pyenv/plugins/pyenv-virtualenvwrapper
    append_profile <<EOF

# pyenv
export PATH="\$HOME/.pyenv/bin:\$PATH"
export PYENV_VIRTUALENVWRAPPER_PREFER_PYVENV="true"
eval "\$(pyenv init -)"
eval "\$(pyenv virtualenv-init -)"
eval "\$(pyenv virtualenvwrapper -)"

EOF

    sudo pip3 install virtualenv
    sudo pip2 install virtualenv
}

oracle_jdk() {
    log "oracle jdk"
    sudo add-apt-repository ppa:webupd8team/java
    sudo apt-get update
    sudo apt-get install oracle-java8-installer
    su_apt oracle-java8-set-default
    append_profile <<EOF
export JAVA_HOME=/usr/lib/jvm/java-8-oracle/
EOF
}

docker() {
    log "docker & docker-compose"
    curl -sSL "https://gist.githubusercontent.com/dinhnv/fa0ffbd5aab37e8dc5956992a559da41/raw/install_latest_docker_compose.sh" | sh
}

nodejs() {
    log "nodejs"
    curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash -
    su_apt nodejs
    sudo chown -R $(whoami) $(npm config get prefix)/{lib/node_modules,bin,share}
    sudo npm install -g coffee-script
    sudo npm install -g grunt-cli
    sudo npm install -g jshint
    sudo npm install -g less
    # yoman
    sudo npm install -g yo
}

golang() {
    GO_VERSION=go1.7.1.linux-amd64
    cd $TMP_DIR && wget https://storage.googleapis.com/golang/$GO_VERSION.tar.gz
    sudo tar -C /usr/local -xzf $GO_VERSION.tar.gz
    append_profile <<EOF
export PATH=$PATH:/usr/local/go/bin
EOF
}

dev_env() {
    python_env
    oracle_jdk
    docker
    nodejs
    golang
}


# ----------------------------------------------------------------------
# UI
# ----------------------------------------------------------------------
setup_fonts() {
    FONT_DIR=$HOME/.local/share/fonts

    cd $TMP_DIR
    git clone https://github.com/powerline/fonts.git
    cd fonts && ./install.sh

    cd $TMP_DIR
    git clone https://github.com/ProgrammingFonts/programming-fonts-collection.git
    cd programming-fonts-collection
    find ./ -maxdepth 1 -type d ! -name '.*' -exec mv {} $FONT_DIR \;

    fc-cache -f $FONT_DIR
}



# ----------------------------------------------------------------------
# tools
# ----------------------------------------------------------------------
_markdown() {
    # optional, but recommended
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BA300B7755AFCFAE
    # add Typora's repository
    sudo add-apt-repository 'deb https://typora.io ./linux/'
    sudo apt-get update
    # install typora
    sudo apt-get install typora
}

_google_chrome() {
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - 
    sudo sh -c 'echo "deb https://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
    sudo apt-get update
    sudo apt-get install google-chrome-stable
}

_gradle() {
    GRADLE_VERSION=gradle-3.1
    cd $APPS_DIR && wget https://services.gradle.org/distributions/$GRADLE_VERSION-bin.zip
    unzip $GRADLE_VERSION-bin.zip
    # to easy upgrade
    ln -s $APPS_DIR/$GRADLE_VERSION $APPS_DIR/gradle
    append_profile <<EOF
export GRADLE_HOME="$APPS_DIR/gradle"
export PATH="\$GRADLE_HOME/bin:\$PATH"
EOF
}

_vagrant() {
    su_apt virtualbox virtualbox-dkms vagrant
    # vagrant box add precise32 http://files.vagrantup.com/precise32.box
}


setup_tools() {
    # _markdown
    su_apt mysql-workbench
    _google_chrome
    _gradle
    _vagrant

    # vietnamese
    su_apt ibus-unikey
    su_apt skype
}


__main__() {
    log "start installing!"
    sudo apt-get update
    install_os_dependencies
    install_term
    generate_sshkeys
    dev_env
    setup_fonts
    setup_tools

    # clean up
    rm -rf $TMP_DIR
}

__main__
