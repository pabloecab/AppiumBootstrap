#!/usr/bin/env bash
#title           :bootstrap.sh
#description     :Script for bootstraping Appium's environment on macOS
#author          :pespinel
#date            :2019/03/01
#version         :0.1
#usage           :./bootstrap.sh
#comments        :sudo password is required at some points of the script and your current bash_profile (if any) will be saved as bash_profile.bak and a new one will be created
#==============================================================================================================================================================================#

export root_path="$(pwd)"
export home_path="/Users/$(whoami)"

declare -A shell
shell[red]="\033[0;31m"
shell[green]="\033[0;32m"
shell[yellow]="\033[0;33m"
shell[default]="\033[0m"
shell[bold]=$(tput bold)
shell[weak]=$(tput sgr0)

function display_info(){
    echo -e "\n${shell[bold]}[$1]${shell[green]} $2 ${shell[default]}${shell[weak]}"
}

function display_warning(){
    echo -e "\n${shell[bold]}${shell[yellow]} $1 ${shell[default]}${shell[weak]}"
}

function display_error(){
    echo -e "\n${shell[bold]}${shell[red]} $1 ${shell[default]}${shell[weak]}"
}

function is_brew_cask_installed(){
    if brew cask info $1 | grep -i "Not Installed"; then
        return 1
    else
        return 0
    fi
}

function is_brew_package_installed(){
    if brew info $1 | grep -i "Not Installed"; then
        return 1
    else
        return 0
    fi
}

function install_homebrew(){
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

function brew_cleanup(){
    brew cleanup > /dev/null 2>&1
}

function brew_update(){
    brew update > /dev/null 2>&1
}

function install_xcode_dev_tools(){
    sleep 1
    osascript <<EOD
        tell application "System Events"
            tell process "Install Command Line Developer Tools"
                keystroke return
                click button "Agree" of window "License Agreement"
            end tell
        end tell
EOD
}

function install_brew_casks(){
    display_info "***" "Installing brew casks..."
    rm -rf /usr/local/var/homebrew/locks  > /dev/null 2>&1
    brew tap caskroom/versions  > /dev/null 2>&1
    BREW_CASKS=(
        homebrew/cask-versions/adoptopenjdk8
        android-sdk
        android-platform-tools
    )
    for cask in "${BREW_CASKS[@]}"; do
        if is_brew_cask_installed $cask;then
            display_info "***" "$cask already installed, showing info"
            brew cask info $cask
        else
            display_info "***" "Installing $cask ..."
            brew cask install $cask
        fi
    done
}

function backup_bash_profile(){
    mv $home_path/.bash_profile $home_path/.bash_profile.backup > /dev/null 2>&1
}

function update_bash_profile(){
    for export in "$@"; do
        echo $export >> $home_path/.bash_profile
    done
}

function load_bash_profile(){
    source $home_path/.bash_profile
}

function install_brew_packages(){
    BREW_PACKAGES=(
        jq
        wget
        cmake
        ruby
        ffmpeg
        gnu-sed
        bash
        npm
        python2
        python3.7
        usbmuxd
        ideviceinstaller
        ios-deploy
        ios-webkit-debug-proxy
        automake
        autoconf
        libtool
        openssl
        pkg-config
    )
    display_info "***" "Installing brew packages..."
    for package in "${BREW_PACKAGES[@]}"; do
        if is_brew_package_installed $package;then
            display_info "***" "$package already installed, showing info"
            brew info $package
        else
            display_info "***" "Installing $package ..."
            brew install $package
        fi
    done
}

function install_node_packages(){
    NODE_PACKAGES=(
        wd
        appium@latest
        appium-doctor
        deviceconsole
        ios-deploy
        opencv4nodejs@5.2.0
        react-syntax-highlighter
        yarn@latest
    )
    display_info "**" "Installing Node packages..."
    for package in "${NODE_PACKAGES[@]}"; do
        npm list -g | grep $package 2> /dev/null || npm install -g $package --no-shrinkwrap
    done
}

function install_libimobiledevice(){
    display_info "***" "Installing libimobiledevice HEAD..."
    brew install libimobiledevice --HEAD
}

function install_idevicelocation(){
    display_info "***" "Installing Idevicelocation..."
    openssl_version="$(ls /usr/local/Cellar/openssl)"
    ln -s /usr/local/Cellar/openssl/${openssl_version}/lib/pkgconfig/* /usr/local/lib/pkgconfig/
    git clone https://github.com/JonGabilondoAngulo/idevicelocation.git $home_path/idevicelocation && cd $home_path/idevicelocation
    ./autogen.sh > /dev/null 2>&1
    make > /dev/null 2>&1
    sudo make install
    cd $root_path && rm -rf $home_path/idevicelocation
}

function install_applesimutils(){
    brew tap wix/brew
    if is_brew_package_installed wix/brew/applesimutils; then
        display_info "***" "applesimutils already installed, showing info"
        brew info wix/brew/applesimutils
    else
        display_info "***" "Installing applesimutils..."
        brew install wix/brew/applesimutils
    fi
}

function install_fbsimctl(){
    brew tap facebook/fb
    if is_brew_package_installed facebook/fb/fbsimctl; then
        display_info "***" "fbsimctl already installed, showing info"
        brew info facebook/fb/fbsimctl
    else
        display_info "***" "Installing fbsimctl..."
        brew install facebook/fb/fbsimctl
    fi
}

function install_idb(){
    brew tap facebook/fb
    if is_brew_package_installed idb-companion; then
        display_info "***" "idb-companion already installed, showing info"
        brew info idb-companion
    else
        display_info "***" "Installing idb-companion..."
        brew install idb-companion
    fi
    pip3 list | grep fb-idb 2> /dev/null || pip3 install fb-idb
    if brew info facebook/fb/fbsimctl &>/dev/null; then
        brew unlink fbsimctl
        brew link idb-companion
    fi
}

function install_ifuse(){
    if is_brew_cask_installed osxfuse; then
        display_info "***" "osxfuse already installed, showing info"
        brew cask info osxfuse
    else
        display_info "***" "Installing osxfuse..."
        brew cask install osxfuse
    fi
    display_info "***" "Installing ifuse HEAD..."
    brew install ifuse --HEAD # newer iOS versions need the latest codebase
}

function install_mjpeg-consumer(){
    display_info "***" "Installing mjpeg-consumer..."
    npm i -g mjpeg-consumer
}

function select_xcode(){
    display_info "***" "Selecting Xcode in Applications..."
    sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
}

function wda_setup(){
    display_info "***" "Configuring WDA..."
    mkdir -p /usr/local/lib/node_modules/appium/node_modules/appium-xcuitest-driver/WebDriverAgent/Resources/WebDriverAgent.bundle
    cd /usr/local/lib/node_modules/appium/node_modules/appium-webdriveragent
    ./Scripts/bootstrap.sh -d
    cd $root_path
}

function install_google_bundletools(){
    display_info "***" "Installing Google Bundletools..."
    bundletool_url="$(curl -s https://api.github.com/repos/google/bundletool/releases/latest | jq -r ".assets[] | select(.name | test(\"${spruce_type}\")) | .browser_download_url")"
    wget -q -P $home_path $bundletool_url
    bundletool_name="$(ls $home_path | grep bundletool)" && chmod +x ~/$bundletool_name
    mkdir -p "$android_home/bundle-tool" && mv ~/$bundletool_name $android_home/bundle-tool/bundletool.jar
    echo 'export PATH=$ANDROID_HOME/bundle-tool:$PATH' >> $home_path/.bash_profile && source $home_path/.bash_profile
}

function fix_lockdown(){
    brew update
    brew uninstall --ignore-dependencies libimobiledevice
    brew uninstall --ignore-dependencies usbmuxd
    brew install --HEAD usbmuxd
    brew unlink usbmuxd
    brew link usbmuxd
    brew install --HEAD libimobiledevice
    brew install ideviceinstaller
}

function install_android_build_tools(){
    sdkmanager "build-tools;28.0.3"
}

#====================================================================================================================================================================================#

rm $home_path/bootstrap.log
exec &> >(tee -a "$home_path/bootstrap.log")

display_info "*" "Starting bootstrap..."
echo "Root path: $root_path"
echo "Home path: $home_path"

display_info "**" "Looking for Xcode..."
if [ -d "/Applications/Xcode.app" ];then
    echo "Xcode is already installed."
else
    display_error "Xcode app not found, install it and run the bootstrap script again!"
    exit
fi

#  _    _                      _
# | |  | |                    | |
# | |__| | ___  _ __ ___   ___| |__  _ __ _____      __
# |  __  |/ _ \| '_ ` _ \ / _ \ '_ \| '__/ _ \ \ /\ / /
# | |  | | (_) | | | | | |  __/ |_) | | |  __/\ V  V /
# |_|  |_|\___/|_| |_| |_|\___|_.__/|_|  \___| \_/\_/

display_info "**" "Looking for Homebrew..."
which -s brew
if [[ $? != 1 ]] ; then
    echo "Homebrew is already installed."
else
    echo "Installing homebrew."
    install_homebrew
fi

display_info "**" "Updating homebrew repositories..."
brew_cleanup
brew_update

# ______               _                         _              _
# |  _  \             | |                       | |            | |
# | | | |_____   _____| | ___  _ __   ___ _ __  | |_ ___   ___ | |___
# | | | / _ \ \ / / _ \ |/ _ \| '_ \ / _ \ '__| | __/ _ \ / _ \| / __|
# | |/ /  __/\ V /  __/ | (_) | |_) |  __/ |    | || (_) | (_) | \__ \
# |___/ \___| \_/ \___|_|\___/| .__/ \___|_|     \__\___/ \___/|_|___/
#                             | |
#                             |_|

display_info "**" "Looking for the xcode command line tools..."
xcode-select --install > /dev/null 2>&1
if [[ $? != 0 ]]; then
    echo "Xcode command line developer tools are already installed."
else
    echo "Installing xcode command line developer tools..."
    install_xcode_dev_tools
fi

# ______                                   _
# | ___ \                                 | |
# | |_/ /_ __ _____      __   ___ __ _ ___| | _____
# | ___ \ '__/ _ \ \ /\ / /  / __/ _` / __| |/ / __|
# | |_/ / | |  __/\ V  V /  | (_| (_| \__ \   <\__ \
# \____/|_|  \___| \_/\_/    \___\__,_|___/_|\_\___/

install_brew_casks

#  ______
# |  ____|
# | |__   _ ____   __ __   ____ _ _ __ ___
# |  __| | '_ \ \ / / \ \ / / _` | '__/ __|
# | |____| | | \ V /   \ V / (_| | |  \__ \
# |______|_| |_|\_/     \_/ \__,_|_|  |___/

display_info "**" "Setting up environment variables..."

# Android home for the installed sdk version
sdk_version="$(ls /usr/local/Caskroom/android-sdk)"
android_home="/usr/local/Caskroom/android-sdk/${sdk_version}"

# Android platform tools for the installed version
platformtools_version="$(ls /usr/local/Caskroom/android-platform-tools)"
platformtools_home="/usr/local/Caskroom/android-platform-tools/${platformtools_version}/platform-tools"

# Java home for the installed jdk version
jdk_version="$(ls /Library/Java/JavaVirtualMachines/ | grep jdk | head -n 1)"
java_home="/Library/Java/JavaVirtualMachines/${jdk_version}/Contents/Home"

# Symbolic link from Android platform tools to Android Home
ln -s $platformtools_home $android_home 2> /dev/null

if [[ -f $home_path/.bash_profile ]]; then
    backup_bash_profile
fi

# Set ANDROID_HOME AND JAVA_HOME and load bash_profile
HOME_EXPORT=(
    "export ANDROID_HOME=${android_home}"
    "export JAVA_HOME=${java_home}"
)

update_bash_profile "${HOME_EXPORT[@]}"
load_bash_profile

# Android build tools
install_android_build_tools

# Set Android tools, Android platform tools, node, Java binary, gnu sed and load bash_profile
TOOLS_EXPORT=(
    "export PATH=${platformtools_home}:$PATH"
    'export PATH=$ANDROID_HOME/tools:$PATH'
    'export PATH=$ANDROID_HOME/build-tools/28.0.3:$PATH'
    'export PATH=${JAVA_HOME}/bin:$PATH'
    'export PATH=/usr/local/opt/node/bin:$PATH'
    'export PATH=/usr/local/opt/gnu-sed/libexec/gnubin:$PATH'
)

update_bash_profile "${TOOLS_EXPORT[@]}"
load_bash_profile

echo "Bash profile updated and loaded."

#  ____                                       _
# |  _ \                                     | |
# | |_) |_ __ _____      __  _ __   __ _  ___| | ____ _  __ _  ___  ___
# |  _ <| '__/ _ \ \ /\ / / | '_ \ / _` |/ __| |/ / _` |/ _` |/ _ \/ __|
# | |_) | | |  __/\ V  V /  | |_) | (_| | (__|   < (_| | (_| |  __/\__ \
# |____/|_|  \___| \_/\_/   | .__/ \__,_|\___|_|\_\__,_|\__, |\___||___/
#                           | |                          __/ |
#                           |_|                         |___/

install_brew_packages

#  _   _           _                         _
# | \ | |         | |                       | |
# |  \| | ___   __| | ___   _ __   __ _  ___| | ____ _  __ _  ___  ___
# | . ` |/ _ \ / _` |/ _ \ | '_ \ / _` |/ __| |/ / _` |/ _` |/ _ \/ __|
# | |\  | (_) | (_| |  __/ | |_) | (_| | (__|   < (_| | (_| |  __/\__ \
# |_| \_|\___/ \__,_|\___| | .__/ \__,_|\___|_|\_\__,_|\__, |\___||___/
#                          | |                          __/ |
#                          |_|                         |___/

pre_install_opencv
install_node_packages
post_install_opencv

#  ______      _                   _
# |  ____|    | |                 | |
# | |__  __  _| |_ _ __ __ _   ___| |_ ___ _ __  ___
# |  __| \ \/ / __| '__/ _` | / __| __/ _ \ '_ \/ __|
# | |____ >  <| |_| | | (_| | \__ \ ||  __/ |_) \__ \
# |______/_/\_\\__|_|  \__,_| |___/\__\___| .__/|___/
#                                         | |
#                                         |_|

display_info "**" "Installing extra requirements..."

# Libimobiledevice
install_libimobiledevice

# Idevicelocation
install_idevicelocation

# Applesimutils
install_applesimutils

# Fbsimctl
install_fbsimctl

# idb
install_idb

# ifuse
install_ifuse

# mjpeg-consumer
install_mjpeg-consumer

# Selecting XcodeApp
select_xcode

# WDA bootstrap
wda_setup

# Google bundletools
install_google_bundletools

# ______ _             _        _               _
# |  ___(_)           | |      | |             | |
# | |_   _ _ __   __ _| |   ___| |__   ___  ___| | _____
# |  _| | | '_ \ / _` | |  / __| '_ \ / _ \/ __| |/ / __|
# | |   | | | | | (_| | | | (__| | | |  __/ (__|   <\__ \
# \_|   |_|_| |_|\__,_|_|  \___|_| |_|\___|\___|_|\_\___/

# lockdown error resulting in ideviceinfo not available
if [[ $(which ideviceinfo | wc -l) -eq 0 ]]; then
    display_warning "Lockdown error detected!"
    display_info "**" "Fixing lockdown error..."
    fix_lockdown
fi
# lockdown error where ideviceinfo is available but returns some kind of error
if $(ideviceinfo | grep "ERROR"); then
    display_warning "Lockdown error detected!"
    display_info "**" "Fixing lockdown error..."
    fix_lockdown
fi

display_info "**" "Running appium-doctor..."
appium-doctor

display_info "**" "Cleaning up..."
brew_cleanup

display_info "*" "Bootstrap finished."
