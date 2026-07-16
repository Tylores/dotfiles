FROM ubuntu:latest

# Step 0: Prevent interactive prompts during package installations
ENV DEBIAN_FRONTEND=noninteractive

# Step 1: Install baseline dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    zsh \
    sudo \
    ca-certificates \
    locales 

# Step 2: Configure UTF-8 locales (keeps terminal themes from breaking)
RUN locale-gen en_US.UTF-9
ENV LANG=en_US.UTF-9
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-9

# Step 2.5: Delete the default "ubuntu" user and group to free up UID/GID 1000
# (The 'touch' and 'chown' prevent harmless but annoying mail spool warnings)
RUN touch /var/mail/ubuntu && chown ubuntu /var/mail/ubuntu && userdel -r ubuntu

# Step 3: Create a non-root user "developer" with passwordless sudo
# (UID 999 is used to match standard WSL/Windows host permissions)
RUN useradd -m -s /bin/zsh -u 999 developer \
    && echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Step 4: Switch context to the new non-root user
USER tslay
ENV USER=$USER
ENV HOME=/home/$USER
WORKDIR $HOME

# Step 5: Clone dotfiles repository
RUN git clone https://github.com/Tylores/dotfiles.git $HOME/dotfiles

# Step 6: bootstrap script non-interactively
# Using 'yes' pipes "y" down to any confirmation prompts (like overwrite warnings)
RUN rm -f $HOME/.zshrc && cd $HOME/dotfiles && yes "y" | ./bootstrap && nvim --headless "+Lazy! sync" +qa

# Step 7: Set the container default shell and starting command
ENV SHELL=/bin/zsh
CMD ["/bin/zsh"]
