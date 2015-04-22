#! /bin/bash

set -e

echo "Configuring XN VM. This process will take several minutes."

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

# variables
debug=${debug}
jruby_version=${xn_jruby_version}
datomic_version=${xn_datomic_version}
torquebox_version=${xn_torquebox_version}
timezone=${xn_timezone}

hr
echo "Configuring environment"
hr
export XN_CLIENT=${xn_client}
export DATOMIC_VERSION=${datomic_version}
export JAVA_OPTS=""
export DEBIAN_FRONTEND=noninteractive
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
sudo locale-gen en_US.UTF-8
sudo dpkg-reconfigure locales

# make jruby processes boot faster
export JRUBY_OPTS=--dev

hr
echo "Setting timezone:"
echo "$timezone" | sudo tee /etc/timezone
sudo dpkg-reconfigure --frontend noninteractive tzdata

hr
echo "Installing base packages"
echo "deb http://us.archive.ubuntu.com/ubuntu/ trusty multiverse" | sudo tee --append /etc/apt/sources.list
echo "deb http://us.archive.ubuntu.com/ubuntu/ trusty-updates multiverse" | sudo tee --append /etc/apt/sources.list

sudo apt-add-repository -y ppa:awstools-dev/awstools
sudo apt-get update
sudo apt-get install -y --force-yes software-properties-common python-software-properties
sudo apt-get install -y --force-yes git curl wget vim maven nodejs npm unzip zsh htop dos2unix ec2-api-tools ec2-ami-tools
sudo ln -sf /usr/bin/nodejs /usr/bin/node

hr
echo "Configuring shell"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh || true
fi
cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
sudo chsh -s /usr/bin/zsh $USER

hr
echo "Configuring ssh"
chmod -R 700 $HOME/.ssh
curl https://gist.githubusercontent.com/stevepereira/61b7ed1e6e0ba9ae5132/raw/cc3af2c2f57da734142bfbfa05fe96c1c96c5b1a/gistfile1.txt > $HOME/.ssh/authorized_keys
chmod 600 $HOME/.ssh/authorized_keys

hr
echo "Installing RVM"
echo progress-bar > ~/.curlrc
echo gem: --no-document > ~/.gemrc
gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
curl -sSL https://get.rvm.io | bash -s stable --auto-dotfiles
source $HOME/.rvm/scripts/rvm

hr
echo "Installing JRuby"
ruby_ver=$(ruby -v | awk '{print $2}')
if [ "$ruby_ver" != "$jruby_version" ]; then
    rvm mount -r https://s3.amazonaws.com/jruby.org/downloads/${jruby_version}/jruby-bin-${jruby_version}.tar.gz --verify-downloads 1
    rvm use jruby-${jruby_version} --default
    gem update --system
    gem sources --add https://rubygems.org/ --remove http://rubygems.org/
fi

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
git config --global --add alias.co "checkout"
git config --global --add alias.ci "commit"
git config --global --add alias.br "branch"
git config --global --add alias.ignore "update-index --assume-unchanged"
git config --global --add alias.unignore "update-index --no-assume-unchanged"
git config --global --add alias.cp "cherry-pick"
git config --global --add alias.unadd "reset HEAD"
git config --global --add alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)[%an]%Creset' --abbrev-commit"
git config --global --add alias.lga "lg --all"
git config --global --add alias.branches "submodule foreach 'git branch | grep \*'"

hr
echo "Installing Lein"
hr
cd $HOME
if [ ! -f "$HOME/bin/lein" ]; then
    mkdir -p bin
    cd bin
    silent wget https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
    chmod a+x $HOME/bin/lein
    silent lein
fi

hr
echo "Installing Node deps"
hr
silent sudo npm install --loglevel silent -g jshint coffee-script jasmine-node issues

hr
echo "Installing Torquebox"
hr
if [ ! -d "$JRUBY_HOME/gems/torquebox-server-${torquebox_version}-java" ]; then
    silent gem install --quiet torquebox-server -v $torquebox_version
fi

hr
echo "Configuring XN gems"
hr
## We need to stick to 1.7.11 in order to be able bundle a new XN app (xnlogic dependency)
bundler_ver=$(bundle -v | awk '{print $3}')
if [ "$bundler_ver" != "1.7.11" ]; then
    gem uninstall -Ix -i ${HOME}/.rvm/gems/jruby-*@global bundler
    gem install bundler -v 1.7.11
fi

hr
echo "Configuring XN"
hr
sudo chown $USER /opt
sudo mkdir -p /opt/xn_apps
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
git clone https://gist.github.com/1906d98f58f0ce7a0285.git datomic_conf
sudo ln -sf $HOME/datomic_conf/datomic.conf /etc/init/datomic.conf
sudo mkdir -p /etc/datomic
sudo ln -sf $HOME/datomic_conf/transactor.properties /etc/datomic/transactor.properties
sudo initctl reload-configuration

hr
echo "Done!"
