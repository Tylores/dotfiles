FROM ubuntu:latest

RUN apt-get update && apt-get install -y \
    curl \
    git \
    sudo


# Delete the default "ubuntu" user and group to free up UID/GID 1000
# (The 'touch' and 'chown' prevent harmless but annoying mail spool warnings)
RUN if id -u ubuntu >/dev/null 2>&1; then \
        touch /var/mail/ubuntu && chown ubuntu /var/mail/ubuntu && userdel -r ubuntu; \
    fi

# Create a non-root user "tslay" with passwordless sudo
# (UID 999 is used to match standard WSL/Windows host permissions)
RUN useradd -m -s /bin/bash -u 999 tslay \
    && echo "tslay ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER tslay
ENV USER=tslay
ENV HOME=/home/tslay
ENV SHELL=/bin/bash

WORKDIR $HOME
COPY --chown=tslay:tslay . $HOME/dotfiles

CMD ["/bin/bash"]
