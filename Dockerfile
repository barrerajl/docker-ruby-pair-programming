FROM aspgems/dev-base-ruby:image-refactor
MAINTAINER barrerajl

ARG USER_UID=1000
ARG USER_GID=1000

ENV USER_UID $USER_UID
ENV USER_GID $USER_GID

RUN /bin/setup_user.sh

# Start by changing the apt otput, as stolen from Discourse's Dockerfiles.
RUN echo "debconf debconf/frontend select Teletype" | debconf-set-selections &&\
# Probably a good idea
    apt-get update &&\

# Basic dev tools
    apt-get install -y sudo openssh-client git build-essential vim ctags man curl direnv software-properties-common locales ack-grep postgresql-client

# Install Homesick, through which dotfiles configurations will be installed
RUN apt-get install -y ruby &&\
    gem install homesick --no-rdoc --no-ri

# Set up SSH. We set up SSH forwarding so that transactions like git pushes
# from the container happen magically.
RUN apt-get install -y openssh-server &&\
    mkdir /var/run/sshd &&\
    echo "AllowAgentForwarding yes" >> /etc/ssh/sshd_config

# Setting locale
#RUN locale-gen es_ES.UTF-8 en_US.UTF-8
#RUN echo 'LANG="en_US.UTF-8"\nLANGUAGE="en_US:en"\n' > /etc/default/locale
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    sed -i -e 's/# es_ES.UTF-8 UTF-8/es_ES.UTF-8 UTF-8/' /etc/locale.gen && \
    echo 'LANG="en_US.UTF-8"'>/etc/default/locale && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8


# Install tmux
RUN apt-get install -y libevent-dev libncurses-dev wget
RUN cd /tmp && wget https://github.com/tmux/tmux/releases/download/2.4/tmux-2.4.tar.gz 
RUN cd /tmp && tar -zxvf /tmp/tmux-2.4.tar.gz && cd /tmp/tmux-2.4 && ./configure && make && make install

RUN adduser $USER_NAME sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

COPY ssh_key_adder.rb $USER_HOME/ssh_key_adder.rb
RUN chown $USER_NAME:$USER_NAME $USER_HOME/ssh_key_adder.rb &&\
    chmod +x $USER_HOME/ssh_key_adder.rb

USER $USER_NAME
RUN echo 'set-option -g default-terminal "screen-256color"' >> $USER_HOME/.tmux.conf
WORKDIR $USER_HOME
RUN homesick clone https://github.com/barrerajl/vim-dot-files.git &&\
    homesick symlink vim-dot-files &&\
    exec vim -c ":PluginInstall" -c "qall"

# Expose SSH
EXPOSE 22

# Install the SSH keys of ENV-configured GitHub users before running the SSH
# server process. See README for SSH instructions.
CMD gem install github-auth --no-rdoc --no-ri && $USER_HOME/ssh_key_adder.rb && sudo /usr/sbin/sshd -D
