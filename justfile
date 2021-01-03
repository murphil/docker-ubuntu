cp cfg="~/pub/Configuration":
    rm -rf home
    mkdir -p home/.config/nvim
    cp -R {{cfg}}/_zshrc home/.zshrc
    cp -R {{cfg}}/.zshrc.d home/.zshrc.d
    cp -R {{cfg}}/_vimrc home/.config/nvim/init.vim
    cp -R {{cfg}}/_tmux.conf home/.tmux.conf

ext:
    docker build . -t ub:ext -f Dockerfile-ext

test:
    docker run --rm \
        --name=test \
        -p 8090:80 \
        -p 2255:22 \
        -v $(pwd):/app \
        -v $PWD/entrypoint.sh:/entrypoint.sh \
        -v vscode-server:/root/.vscode-server \
        -e WS_FIXED=1 \
        -e SSH_ENABLE_ROOT=true \
        -v $PWD/id_ed25519.pub:/etc/authorized_keys/root \
        ub sshd

wasmtime:
    docker build . \
        -t wasmtime \
        -f Dockerfile-wasmtime \
        --build-arg wasmtime_url=http://172.178.1.204:2015/wasmtime-dev-x86_64-linux.tar.xz

login:
    ssh -v -i id_ed25519 \
        -p 2255 \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o IdentitiesOnly=yes \
        root@localhost
