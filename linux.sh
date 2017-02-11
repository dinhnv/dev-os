#!/bin/sh
#
# @author dinhnv

# enable exit-on-error
set -e
# ask sudo password (timeout to cache 15minutes)
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &


# constants
EMAIL="dinhnv.mr@gmail.com"
REPO_ROOT=$(pwd)
DOTFILES=$(pwd)/dotfiles
# GROUP=$(id -g -n)

APPS_DIR="$HOME/applications" # I don't want to get trouble of /opt permissions
TMP_DIR="${HOME}/tmp"
PROFILE="$HOME/.zshrc" # .bashrc or .profile


mkdir -p $APPS_DIR
mkdir -p $TMP_DIR


log() {
    echo "--------------------------------------------------------------------"
    echo $1
    echo "--------------------------------------------------------------------"
}

sysget() {
    sudo apt-get install -y $@
}

# color
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

is_installed() {
    # set to 1 initially, yes
    local rtn=0
    # set to 1 if not found, default boolean behavior of shell
    which $1 >/dev/null 2>&1 || { local rtn=1; }
    local msg=""
    if [ $rtn -eq 0 ]; then
        msg="${GREEN}✔"
    else
        msg="${RED}✘"
    fi
    echo "[${1}] ${msg}"
    echo "${NC}"
    return $rtn
}

# backup if existed
backup() {
    if [ -f $1 ] || [ -d $1 ]; then
        mv $1 "$1.origin"
    fi
}

# http://stackoverflow.com/questions/226703/how-do-i-prompt-for-yes-no-cancel-input-in-a-linux-shell-script/27875395#27875395
read_input() {
    echo ""
select result in Yes No Cancel
do
    echo $result
    break
done
}

append_profile() {
    cat >> $PROFILE $@
}

update_system() {
    log "update & upgrade system"
    sudo apt-get update
    sudo apt-get upgrade
}

# install
install_os_deps() {
    log "add debian source list"
    sudo sh -c 'echo "deb http://archive.getdeb.net/ubuntu xenial-getdeb apps" >> /etc/apt/sources.list.d/getdeb.list'
    wget -q -O - http://archive.getdeb.net/getdeb-archive.key | sudo apt-key add -

    log "install os dependencies"
    # build
    sysget build-essential make automake software-properties-common \
        python-dev python3-dev gcc libssl-dev \
        zlib1g-dev libpq-dev libtiff5-dev libjpeg8-dev libfreetype6-dev \
        liblcms2-dev libwebp-dev graphviz-dev gettext libbz2-dev \
        libreadline-dev libsqlite3-dev xclip
    # vim
    sysget ncurses-dev
    # tmux
    sysget libevent-dev
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

    # for pre layout
    sysget tmuxinator
    tmux_conf="$HOME/.tmux.conf"
    backup $tmux_conf && ln -s "$DOTFILES/tmux/tmux.conf" $tmux_conf
    mkdir -p $HOME/.tmuxinator
    ln -s $DOTFILES/tmux/tmuxinator/ $HOME/.tmuxinator/

    # plugin manager
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
}

_neovim() {
    log "neovim"
    sudo add-apt-repository ppa:neovim-ppa/unstable
    sudo apt-get update
    sysget neovim
    # clipboard, search, ctags for plugin requirements
    sysget ctags
    NVDIR="$HOME/.config/nvim/"
    mkdir -p $NVDIR && backup "$NVDIR/init.vim"\
        && ln -s $REPO_ROOT/vim/init.vim "${NVDIR}/init.vim"

    # support python
    sudo pip2 install neovim
    sudo pip3 install neovim
}

_zsh() {
    log "zsh & oh-my-zsh"
    sysget zsh
    chsh -s $(which zsh)
    # sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    git clone git://github.com/robbyrussell/oh-my-zsh.git $HOME/.oh-my-zsh
    wget -P $HOME/.oh-my-zsh/themes/ https://raw.githubusercontent.com/dracula/zsh/master/dracula.zsh-theme
    ln -s $DOTFILES/zsh/zshrc $HOME/.zshrc
}

_spacemacs() {
    sudo apt-add-repository -y ppa:adrozdoff/emacs
    sudo apt update
    sysget emacs25
    git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d

    sudo pip install jedi json-rpc service_factory
    sudo pip3 install jedi json-rpc service_factory
    # python remove unused imports
    sudo pip install autoflake flake8
    sudo pip3 install autoflake flake8
}

install_term() {
    # TODO cann't logout of zsh shell after installing, fix later!
    # powerline for vim, zsh, tmux
    sudo pip install powerline-status
    _zsh
    _tmux
    _neovim
    _spacemacs
    sysget tree
}

generate_sshkeys() {
    log "generate ssh key and add to ssh-agent"
    ssh keys & ssh-agent
    ssh-keygen -t rsa -b 4096 -C "$EMAIL-$HOSTNAME" -f $HOME/.ssh/id_rsa -N ""
    eval "$(ssh-agent -s)"
    ssh-add $HOME/.ssh/id_rsa
}


# ----------------------------------------------------------------------
# development env
# ----------------------------------------------------------------------
python_env() {
    log "python environment"
    sysget libmysqlclient-dev

    # python environment
    cd $APP_DIR && wget https://bootstrap.pypa.io/get-pip.py
    sudo python3 get-pip.py
    # install later to make pip2 is default
    sudo python2 get-pip.py

    # pyenv
    curl -L https://raw.github.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash
    # git clone https://github.com/yyuu/pyenv-virtualenvwrapper.git ~/.pyenv/plugins/pyenv-virtualenvwrapper
    append_profile <<EOF

# pyenv
export PYENV_ROOT="\$HOME/.pyenv"
if [[ -d \$PYENV_ROOT ]];then
    PATH="\$PYENV_ROOT/bin:$PATH"
    eval "\$(pyenv init -)"
    eval "\$(pyenv virtualenv-init -)"
fi
EOF

    sudo pip3 install virtualenv
    sudo pip2 install virtualenv
}

oracle_jdk() {
    log "oracle jdk"
    sudo add-apt-repository ppa:webupd8team/java
    sudo apt-get update
    sudo apt-get install oracle-java8-installer
    sysget oracle-java8-set-default
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
    curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
    sysget nodejs
    # TODO
    # sudo chown -R $(whoami) $(npm config get prefix)/{lib/node_modules,bin,share}
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
export GOPATH=\$HOME/gocode
export PATH=\$GOPATH:\$GOPATH/bin:\$PATH
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

    cd $FONT_DIR
    git clone https://github.com/Salauyou/Consolas-High-Line

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
    GRADLE_VERSION=gradle-3.3
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
    sysget virtualbox virtualbox-dkms vagrant
    # vagrant box add precise32 http://files.vagrantup.com/precise32.box
    # if guest machine is ubuntu, add permission
    # sudo usermod -a -G vboxsf $USER
}


setup_tools() {
    # _markdown
    sysget mysql-workbench
    _google_chrome
    _gradle
    _vagrant

    # Vietnamese
    sysget ibus-unikey
    # sysget skype
    # for vpn setup
    sysget network-manager-gnome
}

clean() {
    sudo apt-get -y autoclean
    sudo apt-get -y clean
    sudo apt-get -y autoremove

    rm -rf $TMP_DIR

    unset EMAIL REPO_ROOT APPS_DIR TMP_DIR PROFILE
}

__main__() {
    log "start installing!"

    update_system
    install_os_deps

    install_term
    generate_sshkeys
    dev_env
    setup_fonts
    setup_tools

    clean
}

# __main__
$@
