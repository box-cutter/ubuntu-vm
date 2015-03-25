#! /bin/bash

echo "Configuring XN VM. This process will take several minutes."

set -e

# variables
debug=
jruby_version=$xn_jruby_version
datomic_version=$xn_datomic_version
timezone=$xn_timezone

hr() {
printf "%$(tput cols)s\n"|tr " " "-"
}

hr
echo "Configuring environment"
hr
export DATOMIC_VERSION=$datomic_version
export DEBIAN_FRONTEND=noninteractive
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
sudo locale-gen en_US.UTF-8
sudo dpkg-reconfigure locales

hr
echo "Validating script upload"
hr
ls -l /data

# make jruby processes boot faster
export JRUBY_OPTS=--dev

hr
echo "Setting timezone:"
echo "$timezone" | sudo tee /etc/timezone
sudo dpkg-reconfigure --frontend noninteractive tzdata

hr
echo "Installing base packages"
sudo apt-get install -y --force-yes software-properties-common python-software-properties
sudo apt-get install -y --force-yes git curl wget vim maven nodejs npm unzip zsh htop
sudo ln -s /usr/bin/nodejs /usr/bin/node

hr
echo "Configuring shell"
git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh || true
cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
sudo chsh -s /usr/bin/zsh $USER

hr
echo "Installing RVM"
echo progress-bar > ~/.curlrc
echo gem: --no-document > ~/.gemrc
gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
curl -sSL https://get.rvm.io | bash -s stable --auto-dotfiles
source $HOME/.rvm/scripts/rvm

hr
echo "Installing JRuby"
rvm mount -r https://s3.amazonaws.com/jruby.org/downloads/${jruby_version}/jruby-bin-${jruby_version}.tar.gz --verify-downloads 1
rvm use jruby-${jruby_version} --default
gem update --system
gem sources --add https://rubygems.org/ --remove http://rubygems.org/

hr
echo "Installing Java"
sudo add-apt-repository -y ppa:webupd8team/java
echo "Java: Updating apt"
sudo apt-get update
echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
echo "Java: Installing Java package"
sudo apt-get install -yq oracle-java7-installer
echo "Java: Installing default"
sudo apt-get install -yq oracle-java7-set-default
echo "Java: Setting default"
sudo update-java-alternatives -s java-7-oracle

hr
echo "Updating PATH"
export       PATH="$HOME/bin:$HOME/xn.dev/cli-utils/bin:$PATH"
echo 'export PATH="$HOME/bin:$HOME/xn.dev/cli-utils/bin:$PATH"' >> ~/.zshrc
echo "alias gs='git status'" >> ~/.zshrc
echo "alias gd='git diff -w'" >> ~/.zshrc
echo "alias gdc='git diff -w --cached'" >> ~/.zshrc

hr
echo "Installing Lein"
cd $HOME
mkdir -p bin
cd bin
wget https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
chmod a+x $HOME/bin/lein
lein

hr
echo "Installing Node deps"
hr
sudo npm install --loglevel silent -g jshint coffee-script jasmine-node issues

hr
echo "Installing Torquebox"
hr
gem install --quiet torquebox-server -v '3.1.1'

hr
echo "Configuring XN"
sudo mkdir -p /opt/xn_apps
sudo chown -R $USER /opt
cd

hr
echo "Installing Datomic Service"
cd $HOME
wget "https://s3.amazonaws.com/xn-datomic/datomic-free-${datomic_version}.zip?dl=1" --quiet -O datomic.zip
unzip datomic.zip
rm datomic.zip
mkdir -p /opt/datomic/
mv "datomic-free-${datomic_version}" /opt/datomic/
ln -sf "/opt/datomic/datomic-free-${datomic_version}" /opt/datomic/current
sudo cp /data/etc_init_datomic.conf /etc/init/datomic.conf
sudo mkdir -p /etc/datomic
sudo ln -sf /data/transactor.properties /etc/datomic/transactor.properties
sudo initctl reload-configuration

hr
echo "Done!"
