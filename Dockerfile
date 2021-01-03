FROM ubuntu:focal

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV TIMEZONE=Asia/Shanghai

ARG NVIM_VERSION
ARG nvim_url=https://github.com/neovim/neovim/releases/download/${NVIM_VERSION:-nightly}/nvim-linux64.tar.gz
ENV just_version=0.8.3
ENV watchexec_version=1.14.1
ENV yq_version=4.2.1
ENV websocat_version=1.6.0
ENV wasmtime_version=0.21.0

ENV PYTHONUNBUFFERED=x

RUN set -eux \
  ; apt-get update \
  ; apt-get upgrade -y \
  ; DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
      locales tzdata sudo ca-certificates pwgen \
      openssh-client openssh-server gnupg rsync \
      inetutils-ping net-tools iproute2 iptables \
      mlocate procps xz-utils zstd unzip tree \
      zsh git curl wget tcpdump socat jq ripgrep \
      python3 python3-pip python3-setuptools ipython3 \
  \
  ; curl -sSL ${nvim_url} | tar zxf - -C /usr/local --strip-components=1 \
  ; curl -sL https://deb.nodesource.com/setup_14.x | bash - \
  ; apt-get install -y --no-install-recommends \
      nodejs python3-neovim \
  ; pip3 --no-cache-dir install neovim-remote \
  ; mkdir -p /opt/language-server \
  \
  ; ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime \
  ; echo "$TIMEZONE" > /etc/timezone \
  ; sed -i /etc/locale.gen \
		-e 's/# \(en_US.UTF-8 UTF-8\)/\1/' \
		-e 's/# \(zh_CN.UTF-8 UTF-8\)/\1/' \
	; locale-gen \
  \
  ; sed -i 's/^.*\(%sudo.*\)ALL$/\1NOPASSWD:ALL/g' /etc/sudoers \
  ; sed -i /etc/ssh/sshd_config \
        -e 's!.*\(AuthorizedKeysFile\).*!\1 /etc/authorized_keys/%u!' \
        -e 's!.*\(GatewayPorts\).*!\1 yes!' \
        -e 's!.*\(PasswordAuthentication\).*yes!\1 no!' \
  ; apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

ARG just_url=https://github.com/casey/just/releases/download/v${just_version}/just-v${just_version}-x86_64-unknown-linux-musl.tar.gz
ARG watchexec_url=https://github.com/watchexec/watchexec/releases/download/${watchexec_version}/watchexec-${watchexec_version}-x86_64-unknown-linux-musl.tar.xz
ARG yq_url=https://github.com/mikefarah/yq/releases/download/v${yq_version}/yq_linux_amd64
ARG websocat_url=https://github.com/vi/websocat/releases/download/v${websocat_version}/websocat_amd64-linux-static
ARG wasmtime_url=https://github.com/bytecodealliance/wasmtime/releases/download/v${wasmtime_version}/wasmtime-v${wasmtime_version}-x86_64-linux.tar.xz

RUN set -ex \
  ; wget -q -O- ${just_url} \
    | tar zxf - -C /usr/local/bin just \
  ; wget -q -O- ${watchexec_url} \
    | tar Jxf - --strip-components=1 -C /usr/local/bin watchexec-${watchexec_version}-x86_64-unknown-linux-musl/watchexec \
  ; wget -q -O /usr/local/bin/yq ${yq_url} \
    ; chmod +x /usr/local/bin/yq \
  ; wget -q -O /usr/local/bin/websocat ${websocat_url} \
    ; chmod +x /usr/local/bin/websocat \
  ; wget -O- ${wasmtime_url} | tar Jxf - --strip-components=1 -C /usr/local/bin \
        wasmtime-v${wasmtime_version}-x86_64-linux/wasmtime

# conf
RUN set -eux \
  ; mkdir /etc/skel/.zshrc.d \
  ; git clone --depth=1 https://github.com/murphil/.zshrc.d.git /etc/skel/.zshrc.d \
  ; mv /etc/skel/.zshrc.d/_zshrc /etc/skel/.zshrc \
  ; mkdir /etc/skel/.config \
  ; git clone --depth=1 https://github.com/murphil/nvim-coc.git /etc/skel/.config/nvim \
  ; NVIM_SETUP_PLUGINS=1 \
    nvim -u /root/.config/nvim/init.vim --headless +'PlugInstall' +qa \
  ; rm -rf /root/.config/nvim/plugged/*/.git \
  ; for x in $(cat /etc/skel/.config/nvim/coc-core-extensions) \
  ; do nvim -u /root/.config/nvim/init.vim --headless +"CocInstall -sync coc-$x" +qa; done \
  #; npm config set registry https://registry.npm.taobao.org \
  ; npm cache clean -f

WORKDIR /root

ENV SSH_USERS=
ENV SSH_ENABLE_ROOT=
ENV SSH_OVERRIDE_HOST_KEYS=

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
