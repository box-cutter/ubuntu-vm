FROM phusion/baseimage

ENV timezone America/Toronto
ENV DEBIAN_FRONTEND noninteractive
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV JRUBY_OPTS --dev

RUN useradd -ms /bin/bash vagrant

RUN mkdir -p /opt/xn_apps
RUN chown vagrant /opt/xn_apps

RUN locale-gen en_US.UTF-8
RUN dpkg-reconfigure locales

RUN echo "$timezone" | sudo tee /etc/timezone
RUN dpkg-reconfigure --frontend noninteractive tzdata

RUN apt-get update
RUN apt-get install -y --force-yes software-properties-common python-software-properties
RUN apt-get install -y --force-yes git curl wget vim maven nodejs npm unzip zsh htop
RUN ln -s /usr/bin/nodejs /usr/bin/node
RUN npm install --loglevel silent -g jshint coffee-script jasmine-node issues

RUN add-apt-repository -y ppa:webupd8team/java
RUN apt-get update
RUN echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
RUN apt-get install -yq oracle-java7-installer
RUN apt-get install -yq oracle-java7-set-default
RUN update-java-alternatives -s java-7-oracle

RUN echo 'vagrant ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

USER vagrant

RUN /bin/bash -l -c "git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh || true"
RUN /bin/bash -l -c "cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc"
RUN /bin/bash -l -c "sudo chsh -s /usr/bin/zsh vagrant"

RUN /bin/bash -l -c "echo 'progress-bar' > ~/.curlrc"

ENV jruby_version 1.7.18
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
RUN /bin/bash -l -c "curl -L get.rvm.io | bash -s stable --auto-dotfiles"
RUN /bin/bash -l -c "rvm mount -r https://s3.amazonaws.com/jruby.org/downloads/${jruby_version}/jruby-bin-${jruby_version}.tar.gz"
RUN /bin/bash -l -c "echo 'gem: --no-document' > ~/.gemrc"

ONBUILD ENV USER vagrant
ONBUILD ENV HOME /home/$USER
ONBUILD RUN /bin/bash -l -c "source $HOME/.rvm/scripts/rvm"

RUN /bin/bash -l -c "rvm use jruby-${jruby_version} --default"
RUN /bin/bash -l -c "gem update --system"
RUN /bin/bash -l -c "gem install bundler"
RUN /bin/bash -l -c "gem sources --add https://rubygems.org/ --remove http://rubygems.org/"

ENV PATH $HOME/bin:$HOME/xn.dev/cli-utils/bin:$PATH
RUN echo 'export PATH="$HOME/bin:$HOME/xn.dev/cli-utils/bin:$PATH"' >> ~/.zshrc
RUN echo "alias gs='git status'" >> ~/.zshrc
RUN echo "alias gd='git diff -w'" >> ~/.zshrc
RUN echo "alias gdc='git diff -w --cached'" >> ~/.zshrc

RUN mkdir -p $HOME/bin
RUN wget https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein -O $HOME/bin/lein
RUN chmod a+x $HOME/bin/lein
RUN /bin/bash -l -c "lein"

RUN /bin/bash -l -c "gem install --quiet torquebox-server -v '3.1.1'"

USER root
ADD `pwd`/data /
WORKDIR /data

ENV DATOMIC_VERSION 0.9.4755
ADD https://my.datomic.com/downloads/free/${DATOMIC_VERSION} /data/datomic.zip
RUN unzip /data/datomic.zip
RUN rm -f /data/datomic.zip
RUN mv /data/datomic-free-${DATOMIC_VERSION} /usr/local/lib/datomic
RUN ln -s /data/etc_init_datomic.conf /etc/init/datomic.conf
RUN mkdir -p /etc/datomic
RUN ln -s /data/transactor.properties /etc/datomic/transactor.properties
RUN initctl reload-configuration

ENTRYPOINT []
CMD []
