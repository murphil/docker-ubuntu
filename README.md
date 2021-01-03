# SSHD
```bash
docker run \
    -p 2222:22 \
    -e SSH_ENABLE_ROOT=true \
    -v <pubkey>:/etc/authorized_keys/root \
    nnurphy/ub sshd
```
