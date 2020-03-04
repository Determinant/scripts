#!/bin/bash
function die {
    echo "$1"
    exit 1
}

if [[ "$#" -lt 1 ]]; then
    die ">1 arguments are expected"
fi

CN="ted-docker"
HOST="$1"
IPS=(
    127.0.0.1
    0.0.0.0
    "$HOST"
)
WORKDIR="${2:-docker_env}"
KEYDIR="$WORKDIR/key"

read -r -d '' _pubkey << PKEY
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDXgSTKIsq7HSrVcI8qMXfrT0uh04lv9ffu7UDZAF5onryrlJc0vzH1dAN4a0nKcQuHaoT7jtTQaiF38wldBpqqeipLqb/Y8dXhnTB5i4DCeLx2820k9Jf9uZceybo6RtLfF/k3GJnKL2lkQ1/CkOQSoZSTmmP4t5c4YiWivAWIBo/4oP4F9mQIGm6uXxgWFfuB6QrOIUv53Ht69LmwQ3/UzOHGD3oPtm10YG3IUOjbAJ0UKu6pvX8Ei1rjRhT5hf3L/0y0JUJ3aEDwocKyYr+ioYmV9XxE9nlijJaZ1hU9/TMKSZJVQe6wPHB8SRwxpfRSiXuOQlyUafMj3jRFnZqlvot3aIOs6IggnOCREeOnbswBI5xfFSKGHyZD9DYRWfek0Lqdfm+wXRSKlkZ7HVTGMtXmUIHNqnbrDuKuwd2Sw2Dva734efRtUVK+ZbCdbm+e9XVauB2N5Z3MP2WpiqycbcN5PdGRMg01mJYvKRlR01plXiG0yqJbesMeP1rmL3vafVhmgeXEC2VTcHuwhrR+Aw3fgjfxVMUc0Lx/WZ4vwlIdNNEiUXziEca915TDPkKN5CF/23edqWJvs8/va2njpClM4DLEGBxj8Q6ahGhvieXX/64eph+NdSoYj3mZpIgHEcaUjZmJBiaS2x/ZHa9wWDuuwLKOkkrQxiXa/VeESQ== ymf@Ted-Pico
PKEY
pubkey="${3:-$_pubkey}"

ips=($(for ip in "${IPS[@]}"; do
    echo "IP:$ip"
done))

function join_by { local IFS="$1"; shift; echo "$*"; }
alt_name=$(join_by , "${ips[@]}")

ssh -i ~/.ssh/ted-ava-key.pem "ubuntu@$HOST" "sudo bash -c \"echo '$pubkey' | cat > /root/.ssh/authorized_keys\""

function sudo {
    ssh "root@$HOST" "$@"
}

function copy {
    rsync -avP "$1" "root@$HOST:$2"
}

mkdir -p "$WORKDIR"

if [[ ! -f "$WORKDIR/docker.service" ]]; then
    cat > "$WORKDIR/docker.service" << EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
BindsTo=containerd.service
After=network-online.target firewalld.service containerd.service
Wants=network-online.target
Requires=docker.socket

[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
ExecStart=/usr/bin/dockerd --tlsverify --tlscacert=/etc/docker/keys/ca.pem --tlscert=/etc/docker/keys/server-cert.pem --tlskey=/etc/docker/keys/server-key.pem -H=0.0.0.0:22222 --containerd=/run/containerd/containerd.sock
ExecReload=/bin/kill -s HUP \$MAINPID
TimeoutSec=0
RestartSec=2
Restart=always

# Note that StartLimit* options were moved from "Service" to "Unit" in systemd 229.
# Both the old, and new location are accepted by systemd 229 and up, so using the old location
# to make them work for either version of systemd.
StartLimitBurst=3

# Note that StartLimitInterval was renamed to StartLimitIntervalSec in systemd 230.
# Both the old, and new name are accepted by systemd 230 and up, so using the old name to make
# this option work for either version of systemd.
StartLimitInterval=60s

# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity

# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this option.
TasksMax=infinity

# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes

# kill only the docker process, not all processes in the cgroup
KillMode=process

[Install]
WantedBy=multi-user.target
EOF
fi

if [[ ! -d "$KEYDIR" ]]; then
    mkdir -p "$KEYDIR"
    cd "$KEYDIR"
    ## generate CA key
    #openssl genrsa -aes256 -out ca-key.pem 4096
    openssl genrsa -out ca-key.pem 4096
    openssl req -new -x509 -subj "/C=US/O=Dis/CN=$CN" -days 365 -key ca-key.pem -sha256 -out ca.pem
    
    # generate server key
    openssl genrsa -out server-key.pem 4096
    # request a cert for the server
    openssl req -subj "/CN=$CN" -sha256 -new -key server-key.pem -out server.csr
    echo "subjectAltName = $alt_name" >> extfile.cnf
    # sign the certificate with CA key (for server)
    openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem \
        -CAcreateserial -out server-cert.pem -extfile extfile.cnf
    
    # generate client key
    openssl genrsa -out key.pem 4096
    # request a cert for the client
    openssl req -subj '/CN=ted' -new -key key.pem -out client.csr
    echo extendedKeyUsage = clientAuth > extfile-client.cnf
    # sign the certificate with CA key (for client)
    openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem \
      -CAcreateserial -out cert.pem -extfile extfile-client.cnf
    
    chmod -v 0400 ca-key.pem key.pem server-key.pem
    chmod -v 0444 ca.pem server-cert.pem cert.pem
    cd -
fi

sudo add-apt-repository -y ppa:neovim-ppa/stable
sudo apt-get -y update
# dev env
sudo apt-get -y install neovim python3-pip python-pip tmux fish rsync git
# docker
sudo apt-get -y install docker.io

sudo useradd ymf -m -s /bin/bash
sudo mkdir -pm 700 /root/.ssh/

sudo mkdir -p /etc/docker/keys/
copy "$KEYDIR/ca.pem" /etc/docker/keys/ca.pem
copy "$KEYDIR/server-cert.pem" /etc/docker/keys/server-cert.pem
copy "$KEYDIR/server-key.pem" /etc/docker/keys/server-key.pem
copy "$WORKDIR/docker.service" /lib/systemd/system/docker.service
sudo systemctl daemon-reload
sudo systemctl stop docker
sudo systemctl start docker
sudo systemctl enable docker

mkdir -p "$WORKDIR/bin"
cat > "$WORKDIR/bin/docker" << EOF
#!/bin/bash
SRC_DIR="\$(dirname "\${BASH_SOURCE[0]}")"
KEYDIR="\$SRC_DIR/../key"
/usr/bin/docker --tlsverify --tlscacert=\$KEYDIR/ca.pem --tlscert=\$KEYDIR/cert.pem --tlskey=\$KEYDIR/key.pem  -H=$HOST:22222 "\$@"
EOF
chmod +x "$WORKDIR/bin/docker"
