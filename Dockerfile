FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    file \
    git \
    iproute2 \
    iputils-ping \
    less \
    locales \
    man-db \
    procps \
    sudo \
    tzdata \
    zsh \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*


# Delete the default "ubuntu" user and group to free up UID/GID 1000
# (The 'touch' and 'chown' prevent harmless but annoying mail spool warnings)
RUN if id -u ubuntu >/dev/null 2>&1; then \
        touch /var/mail/ubuntu && chown ubuntu /var/mail/ubuntu && userdel -r ubuntu; \
    fi

# Create a non-root user "tslay" with passwordless sudo
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd --gid "${USER_GID}" tslay \
    && useradd -m -s /bin/zsh --uid "${USER_UID}" --gid "${USER_GID}" tslay \
    && echo "tslay ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER tslay
ENV USER=tslay
ENV HOME=/home/tslay
ENV SHELL=/bin/zsh
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

WORKDIR $HOME
RUN git clone https://github.com/Tylores/dotfiles.git $HOME/dotfiles

CMD ["/bin/zsh", "-l"]
