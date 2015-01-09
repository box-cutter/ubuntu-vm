#!/bin/bash

echo "Configuring XN VM. This process will take several minutes."

set -e

# variables
debug=
jruby_version=$xn_jruby_version
timezone=$xn_timezone
pm_key=$xn_pm_key
mcfly_key=$xn_mcfly_key
pm_version=$xn_pm_version
mcfly_version=$xn_mcfly_version

echo "Configuring environment"
export XN_CLIENT=$xn_client
export DATOMIC_VERSION=$xn_datomic_version
export DEBIAN_FRONTEND=noninteractive
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
#sudo locale-gen en_US.UTF-8
#sudo dpkg-reconfigure locales

echo "Setting timezone:"
echo "$timezone" | sudo tee /etc/timezone
sudo dpkg-reconfigure --frontend noninteractive tzdata

echo "Installing base packages"
sudo apt-get update
sudo apt-get install -y -qq --force-yes software-properties-common python-software-properties
sudo apt-get install -y -qq git curl wget vim maven nodejs npm unzip zsh htop
sudo ln -s /usr/bin/nodejs /usr/bin/node

echo "Configuring shell"
git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh || true
cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
sudo chsh -s /usr/bin/zsh vagrant

echo "Installing RVM"
echo progress-bar > ~/.curlrc
echo gem: --no-document > ~/.gemrc
gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
curl -sSL https://get.rvm.io | bash -s stable --auto-dotfiles
source $HOME/.rvm/scripts/rvm

echo "Installing JRuby"
rvm mount -r https://s3.amazonaws.com/jruby.org/downloads/${jruby_version}/jruby-bin-${jruby_version}.tar.gz --verify-downloads 1
rvm use jruby-${jruby_version} --default
gem source -a https://rubygems.org/
gem source -r http://rubygems.org/

echo "Installing Java"
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get -y -qq update
echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
echo "Installing Java..."
sudo apt-get install -y -qq oracle-java7-installer
echo "Installing installing default..."
sudo apt-get install -y -qq oracle-java7-set-default
echo "Setting Java default..."
sudo update-java-alternatives -s java-7-oracle

echo "Updating PATH"
export       PATH="$HOME/bin:$HOME/xn.dev/cli-utils/bin:$PATH"
echo 'export PATH="$HOME/bin:$HOME/xn.dev/cli-utils/bin:$PATH"' >> ~/.zshrc

echo "Installing Lein"
cd $HOME
mkdir -p bin
cd bin
wget https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
chmod a+x $HOME/bin/lein

echo "Installing Node deps"
sudo npm install --loglevel -g jshint coffee-script jasmine-node issues

echo "Installing Torquebox"
gem install --quiet torquebox-server -v '3.1.1'

echo "Installing XN gems"
#wget http://${mcfly_key}@pacer-mcfly.xnlogic.com/gems/pacer-mcfly-$mcfly_version-java.gem -O pacer-mcfly-$mcfly_version-java.gem --quiet
#wget http://${pm_key}pacer-model.xnlogic.com/gems/pacer-model-$pm_version-java.gem -O pacer-model-$pm_version-java.gem --quiet
#gem install --quiet pacer-mcfly-$mcfly_version-java.gem pacer-model-$pm_version-java.gem
#rm pacer-mcfly-$mcfly_version-java.gem pacer-model-$pm_version-java.gem
gem sources --add "http://${mcfly_key}@pacer-mcfly.xnlogic.net/"
gem sources --add "http://${pm_key}@pacer-model.xnlogic.net/"
gem install pacer-mcfly
gem install pacer-model

echo "Configuring XN"
sudo mkdir -p /opt/xn_apps
sudo chown vagrant /opt/xn_apps
cd
wget https://www.dropbox.com/s/qs1n0c6tig2jfwo/xn.dev.2.tbz -O $HOME/xn.dev.tbz --quiet
tar -xjf xn.dev.tbz
rm xn.dev.tbz
cd xn.dev
source script/setup_stack
cd fe/xn.js
sudo npm install --loglevel silent
cd -
rake --quiet new_tb_version bundle_fe_server fresh_fe_config fe_server_db_init

echo "Starting Datomic Service"
cd $HOME
wget https://www.dropbox.com/s/07wwxn8mbujxugb/datomic-free-0.9.4699.zip?dl=1 --quiet -O datomic.zip
unzip datomic.zip
rm datomic.zip
sudo mv datomic-free-0.9.4699 /usr/local/lib/datomic
sudo cp datomic.conf /etc/init/datomic.conf
sudo mkdir -p /etc/datomic
sudo ln -s transactor.properties /etc/datomic/transactor.properties
sudo initctl reload-configuration
sudo start datomic

echo "Customizing .zshrc for $XN_CLIENT development"
echo "export XN_CLIENT=$XN_CLIENT" >> ~/.zshrc
echo "alias xn-server='(cd ~/xn.dev; ./script/start);'" >> ~/.zshrc
echo 'alias xn-console="(cd ~/$XN_CLIENT; bundle exec jruby -J-Xmx1g -J-XX:MaxPermSize=200m -S irb -I $HOME/$XN_CLIENT/lib -r $HOME/$XN_CLIENT/dev/console)"' >> ~/.zshrc
echo '[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*' >> ~/.zshrc
echo '(cd $HOME/xn.dev; source script/setup_stack)' >> ~/.zshrc

echo "Configuring $XN_CLIENT"
cd $HOME/$XN_CLIENT
bundle
torquebox deploy
echo "Done!"

