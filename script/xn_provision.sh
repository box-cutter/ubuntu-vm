#! /bin/bash

echo "Configuring XN VM. This process will take several minutes."

# variables
debug=
jruby_version=$xn_jruby_version
datomic_version=$xn_datomic_version
timezone=$xn_timezone

silent() {
  if [[ $debug ]] ; then
    "$@"
  else
    "$@" &>/dev/null
  fi
}
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
#sudo dpkg-reconfigure locales

# make jruby processes boot faster
export JRUBY_OPTS=--dev

hr
echo "Setting timezone:"
echo "$timezone" | sudo tee /etc/timezone
silent sudo dpkg-reconfigure --frontend noninteractive tzdata

hr
echo "Installing base packages"
silent sudo apt-get update
sudo apt-get install -y --force-yes software-properties-common python-software-properties
sudo apt-get install -y git curl wget vim maven nodejs npm unzip zsh htop
sudo ln -s /usr/bin/nodejs /usr/bin/node

hr
echo "Configuring shell"
silent git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh || true
cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
sudo chsh -s /usr/bin/zsh vagrant

hr
echo "Installing RVM"
echo progress-bar > ~/.curlrc
echo gem: --no-document > ~/.gemrc
silent gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
curl -sSL https://get.rvm.io | silent bash -s stable --auto-dotfiles
source $HOME/.rvm/scripts/rvm

hr
echo "Installing JRuby"
silent rvm mount -r https://s3.amazonaws.com/jruby.org/downloads/${jruby_version}/jruby-bin-${jruby_version}.tar.gz --verify-downloads 1
rvm use jruby-${jruby_version} --default
gem update --system
gem source -a https://rubygems.org
gem source -r http://rubygems.org/

hr
echo "Installing Java"
silent sudo add-apt-repository ppa:webupd8team/java
silent sudo apt-get update
echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
silent sudo apt-get install -yq oracle-java7-installer
silent sudo apt-get install -yq oracle-java7-set-default
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
silent wget https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
chmod a+x $HOME/bin/lein

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
sudo chown vagrant /opt/xn_apps
cd

hr
echo "Starting Datomic Service"
hr
cd $HOME
wget https://www.dropbox.com/s/2sxd5gqmai58xnl/datomic-free-0.9.4755.zip?dl=1 --quiet -O datomic.zip
unzip datomic.zip
rm datomic.zip
sudo mv datomic-free-0.9.4755 /usr/local/lib/datomic
sudo cp /vagrant/config/datomic.conf /etc/init/datomic.conf
sudo mkdir -p /etc/datomic
sudo ln -s /vagrant/config/transactor.properties /etc/datomic/transactor.properties
sudo initctl reload-configuration

hr
echo "Done!"
