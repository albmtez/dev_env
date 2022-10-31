#!/bin/bash

script_name=$0
SCRIPT=$(readlink -f $script_name)
BASEDIR=$(dirname $SCRIPT)
BUNDLESDIR=$BASEDIR/bundles
BINDIR=$BASEDIR/bin

function usage {
    echo "Retrieves and generates the distributable of the bundle specified"
    echo "  Usage: $script_name <bundle_or_package_name>"
    echo "         $script_name all # Retrieves the las version of all bundles"
    echo "Bundles available:"
    echo "  git            - Installs Git SCM from source code using the latest version"
    echo "  maven          - Installs the latest version of Apache Maven"
    echo "  ant            - Installs the latest version of Apache Ant"
    echo "  docker-compose - Docker compose"
    echo "  minikube       - Minikube"
    echo "  kubectl        - Kubectl"
    echo "  kubectx        - Kubectx"
    echo "  kubens         - Kubens"
    echo "  k3sup          - K3sup"
    echo "  k3d            - K3d"
    echo "  kind           - Kind"
    echo "  knative        - Knative"
    echo "  terraform      - Terraform"
}

function git_install {
    echo "Git scm bundle generation"

    # Recreate tmp working dir
    tmpDir=$BASEDIR/tmp
    [[ -d $tmpDir ]] && rm -rf $tmpDir && echo "tmp dir $tmpDir deleted" || (echo "Error deleting tmp dir $tmpDir" && exit 1)
    mkdir $tmpDir && echo "Temp dir $tmpDir created" || (echo "Error creating tmp dir $tmpDir" && exit 1)
    cd $tmpDir

    # Clone git repo and choose the latest released version
    git clone https://github.com/git/git.git
    cd git
    git fetch --tags
    tag=$(git tag -l --sort=-v:refname | grep -oP '^v[0-9\.]+$' | head -n 1)

    # Arch x86_64 is replaced by amd64
    git_arch=$ARCH
    [ $ARCH = 'x86_64' ] && git_arch='amd64'

    # Check if already installed
    [ -d $BUNDLESDIR/git/git-$tag-$PLATFORM-$git_arch ] && echo "Git version ${tag} already installed!" && rm -rf $tmpDir && unset tmpDir && exit 1
    [[ ! -d $BUNDLESDIR/git ]] && mkdir -p $BUNDLESDIR/git

    # Configure, build and install
    git checkout $tag -b version-to-install
    make configure
    ./configure --prefix=$BUNDLESDIR/git/git-$tag-$PLATFORM-$git_arch
    make all
    make install

    # Set the default version
    rm -f $BUNDLESDIR/git/default-$PLATFORM-$git_arch
    ln -s git-$tag-$PLATFORM-$git_arch $BUNDLESDIR/git/default-$PLATFORM-$git_arch

    # Link 

    unset git_arch
    unset tmpDir
}

function maven_install {
    echo "Maven installation"

    # Find latest version
    echo "Finding latest version of Apache Maven..."
    latest="$(wget -qO- https://dlcdn.apache.org/maven/maven-3/ | grep -oP '[0-9\.]+/<' | grep -oP '[0-9\.]+' | tail -n 1)"

    # Check if already installed
    [ -d $BUNDLESDIR/apache-maven/apache-maven-"${latest}" ] && echo "Apache Maven version ${latest} already installed!" && exit 0
    [[ ! -d $BUNDLESDIR/apache-maven ]] && mkdir -p $BUNDLESDIR/apache-maven

    # Download Apache Maven
    tmpDir=$BASEDIR/tmp
    [[ -d $tmpDir ]] && rm -rf $tmpDir && echo "tmp dir $tmpDir deleted" || (echo "Error deleting tmp dir $tmpDir" && exit 1)
    mkdir $tmpDir && echo "Temp dir $tmpDir created" || (echo "Error creating tmp dir $tmpDir" && exit 1)
    cd ${tmpDir}
    echo "Downloading latest Apache Maven: ${latest}"
    wget --quiet --continue --show-progress https://dlcdn.apache.org/maven/maven-3/"${latest}"/binaries/apache-maven-"${latest}"-bin.tar.gz
    unset url

    tar -C $BUNDLESDIR/apache-maven -xzf apache-maven-"${latest}"-bin.tar.gz

    # Set the default version
    rm -f $BUNDLESDIR/apache-maven/default
    ln -s apache-maven-"${latest}" $BUNDLESDIR/apache-maven/default

    unset tmpDir
}

function ant_install {
    echo "Ant installation"

    # Find latest version
    echo "Finding latest version of Apache Ant..."
    latest="$(wget -qO- http://apache.uvigo.es//ant/binaries/ | grep -oP 'apache-ant-([0-9\.]+)-bin.tar.gz<' | grep -oP 'ant-[0-9\.]+' | grep -oP '[0-9\.]+' | sort --version-sort | tail -n 1)"

    # Check if already installed
    [ -d $BUNDLESDIR/apache-ant/apache-ant-"${latest}" ] && echo "Apache Ant version ${latest} already installed!" && exit 0
    [[ ! -d $BUNDLESDIR/apache-ant ]] && mkdir -p $BUNDLESDIR/apache-ant

    # Download Apache Ant
    tmpDir=$BASEDIR/tmp
    [[ -d $tmpDir ]] && rm -rf $tmpDir && echo "tmp dir $tmpDir deleted" || (echo "Error deleting tmp dir $tmpDir" && exit 1)
    mkdir $tmpDir && echo "Temp dir $tmpDir created" || (echo "Error creating tmp dir $tmpDir" && exit 1)
    cd ${tmpDir}
    echo "Downloading latest Apache Ant: ${latest}"
    wget --quiet --continue --show-progress http://apache.uvigo.es//ant/binaries/apache-ant-"${latest}"-bin.tar.gz
    unset url

    tar -C $BUNDLESDIR/apache-ant -xzf apache-ant-"${latest}"-bin.tar.gz

    # Set the default version
    rm -f $BUNDLESDIR/apache-ant/default
    ln -s apache-ant-"${latest}" $BUNDLESDIR/apache-ant/default

    unset tmpDir
}

function docker_compose_install {
    echo "Docker compose install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)

    # Arch x86_64 replaced by amd64
    docker_compose_arch=$ARCH
    [ $ARCH = 'x86_64' ] && docker_compose_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/docker-compose/docker-compose-${latest}-$PLATFORM-${docker_compose_arch} ] && echo "Docker compose version ${latest} already installed!" && exit 0
    [[ ! -d $BUNDLESDIR/docker-compose ]] && mkdir -p $BUNDLESDIR/docker-compose

    # Download docker compose
    echo "Installing docker compose version ${latest}"
    curl -L "https://github.com/docker/compose/releases/download/${latest}/docker-compose-$PLATFORM-$ARCH" -o $BUNDLESDIR/docker-compose/docker-compose-${latest}-$PLATFORM-${docker_compose_arch}
    chmod +x $BUNDLESDIR/docker-compose/docker-compose-${latest}-$PLATFORM-${docker_compose_arch}

    # Set the default version
    rm -f $BUNDLESDIR/docker-compose/default-$PLATFORM-${docker_compose_arch}
    ln -s docker-compose-$latest-$PLATFORM-${docker_compose_arch} $BUNDLESDIR/docker-compose/default-$PLATFORM-${docker_compose_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${docker_compose_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${docker_compose_arch}
    [[ ! -f $BINDIR/$PLATFORM-${docker_compose_arch}/docker-compose ]] && ln -s $BUNDLESDIR/docker-compose/default-$PLATFORM-${docker_compose_arch} $BINDIR/$PLATFORM-${docker_compose_arch}/docker-compose

    unset docker_compose_arch
    unset latest
}

function minikube_install {
    echo "Minikube install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/kubernetes/minikube/releases/latest | grep 'tag_name' | cut -d\" -f4)

    # Arch x86_64 replaced by amd64
    minikube_arch=$ARCH
    [ $ARCH = 'x86_64' ] && minikube_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/minikube/minikube-${latest}-$PLATFORM-${minikube_arch} ] && echo "Minikube version ${latest} already installed!" && exit 0
    [[ ! -d $BUNDLESDIR/minikube ]] && mkdir -p $BUNDLESDIR/minikube

    # Download minikube
    echo "Installing minikube version ${latest}"    
    curl -L "https://github.com/kubernetes/minikube/releases/download/${latest}/minikube-$PLATFORM-${minikube_arch}" -o $BUNDLESDIR/minikube/minikube-${latest}-$PLATFORM-${minikube_arch}
    chmod +x $BUNDLESDIR/minikube/minikube-${latest}-$PLATFORM-$minikube_arch

    # Set the default version
    rm -f $BUNDLESDIR/minikube/default-$PLATFORM-${minikube_arch}
    ln -s minikube-$latest-$PLATFORM-${minikube_arch} $BUNDLESDIR/minikube/default-$PLATFORM-${minikube_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${minikube_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${minikube_arch}
    [[ ! -f $BINDIR/$PLATFORM-${minikube_arch}/minikube ]] && ln -s $BUNDLESDIR/minikube/default-$PLATFORM-${minikube_arch} $BINDIR/$PLATFORM-${minikube_arch}/minikube

    unset minikube_arch
    unset latest
}

function kubectl_install {
    # https://kubernetes.io/releases/download/#kubectl
    echo "Kubectl install"

    # Find latest version
    latest=$(curl -L -s https://dl.k8s.io/release/stable.txt)

    # Arch x86_64 replaced by amd64
    kubectl_arch=$ARCH
    [ $ARCH == 'x86_64' ] && kubectl_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/kubectl/kubectl-${latest}-$PLATFORM-${kubectl_arch} ] && echo "Kubectl version ${latest} already installed!" && exit 0
    [[ ! -d $BUNDLESDIR/kubectl ]] && mkdir -p $BUNDLESDIR/kubectl

    # Download kubectl
    echo "Installing kubectl version ${latest}"
    curl -L "https://dl.k8s.io/release/${latest}/bin/$PLATFORM/${kubectl_arch}/kubectl" -o $BUNDLESDIR/kubectl/kubectl-${latest}-$PLATFORM-${kubectl_arch}
    chmod +x $BUNDLESDIR/kubectl/kubectl-${latest}-$PLATFORM-${kubectl_arch}

    # Set the default version
    rm -f $BUNDLESDIR/kubectl/default-$PLATFORM-${kubectl_arch}
    ln -s kubectl-${latest}-$PLATFORM-${kubectl_arch} $BUNDLESDIR/kubectl/default-$PLATFORM-${kubectl_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${kubectl_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${kubectl_arch}
    [[ ! -f $BINDIR/$PLATFORM-${kubectl_arch}/kubectl ]] && ln -s $BUNDLESDIR/kubectl/default-$PLATFORM-${kubectl_arch} $BINDIR/$PLATFORM-${kubectl_arch}/kubectl

    unset kubectl_arch
    unset latest
}

function kubectx_install {
    echo "Kubectx install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/ahmetb/kubectx/releases/latest | grep 'tag_name' | cut -d\" -f4)

    # Arch x86_64 replaced by amd64
    kubectx_arch=$ARCH
    [ $ARCH = 'x86_64' ] && kubectx_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/kubectx/kubectx-${latest}-$PLATFORM-${kubectx_arch} ] && echo "Kubectx version ${latest} already installed!" && exit 0
    [[ ! -d $BUNDLESDIR/kubectx ]] && mkdir -p $BUNDLESDIR/kubectx

    # Download kubectx
    tmpDir=$BASEDIR/tmp
    [[ -d $tmpDir ]] && rm -rf $tmpDir && echo "tmp dir $tmpDir deleted" || (echo "Error deleting tmp dir $tmpDir" && exit 1)
    mkdir $tmpDir && echo "Temp dir $tmpDir created" || (echo "Error creating tmp dir $tmpDir" && exit 1)
    cd ${tmpDir}
    echo "Installing kubectx version ${latest}"
    wget "https://github.com/ahmetb/kubectx/releases/download/${latest}/kubectx_${latest}_${PLATFORM}_$ARCH.tar.gz"
    tar xzvf kubectx_${latest}_${PLATFORM}_$ARCH.tar.gz
    mv kubectx $BUNDLESDIR/kubectx/kubectx-${latest}-$PLATFORM-${kubectx_arch}

    # Set the default version
    rm -f $BUNDLESDIR/kubectx/default-$PLATFORM-${kubectx_arch}
    ln -s kubectx-$latest-$PLATFORM-${kubectx_arch} $BUNDLESDIR/kubectx/default-$PLATFORM-${kubectx_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${kubectx_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${kubectx_arch}
    [[ ! -f $BINDIR/$PLATFORM-${kubectx_arch}/kubectx ]] && ln -s $BUNDLESDIR/kubectx/default-$PLATFORM-${kubectx_arch} $BINDIR/$PLATFORM-${kubectx_arch}/kubectx

    unset tmpDir
    unset kubectx_arch
    unset latest
}

function kubens_install {
    echo "Kubens install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/ahmetb/kubectx/releases/latest | grep 'tag_name' | cut -d\" -f4)

    # Arch x86_64 replaced by amd64
    kubens_arch=$ARCH
    [ $ARCH = 'x86_64' ] && kubens_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/kubens/kubens-${latest}-$PLATFORM-${kubens_arch} ] && echo "kubens version ${latest} already installed!" && exit 0
    [[ ! -d $BUNDLESDIR/kubens ]] && mkdir -p $BUNDLESDIR/kubens

    # Download kubens
    tmpDir=$BASEDIR/tmp
    [[ -d $tmpDir ]] && rm -rf $tmpDir && echo "tmp dir $tmpDir deleted" || (echo "Error deleting tmp dir $tmpDir" && exit 1)
    mkdir $tmpDir && echo "Temp dir $tmpDir created" || (echo "Error creating tmp dir $tmpDir" && exit 1)
    cd ${tmpDir}
    echo "Installing kubens version ${latest}"
    wget "https://github.com/ahmetb/kubectx/releases/download/${latest}/kubens_${latest}_${PLATFORM}_$ARCH.tar.gz"
    tar xzvf kubens_${latest}_${PLATFORM}_$ARCH.tar.gz
    mv kubens $BUNDLESDIR/kubens/kubens-${latest}-$PLATFORM-${kubens_arch}

    # Set the default version
    rm -f $BUNDLESDIR/kubens/default-$PLATFORM-${kubens_arch}
    ln -s kubens-$latest-$PLATFORM-${kubens_arch} $BUNDLESDIR/kubens/default-$PLATFORM-${kubens_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${kubens_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${kubens_arch}
    [[ ! -f $BINDIR/$PLATFORM-${kubens_arch}/kubens ]] && ln -s $BUNDLESDIR/kubens/default-$PLATFORM-${kubens_arch} $BINDIR/$PLATFORM-${kubens_arch}/kubens

    unset tmpDir
    unset kubens_arch
    unset latest
}

function k3sup_install {
    echo "K3sup install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/alexellis/k3sup/releases/latest | grep 'tag_name' | cut -d\" -f4)

    # Filenames
    k3sup_arch=$ARCH
    [ $ARCH = 'x86_64' ] && k3sup_arch='amd64'
    k3sup_bin_name=k3sup
    [ $PLATFORM != 'linux' ] && k3sup_bin_name=${k3sup_bin_name}-$PLATFORM
    [ $ARCH != 'x86_64' ] && k3sup_bin_name=${k3sup_bin_name}-$ARCH
    k3sup_dest_name=k3sup-v${latest}-$PLATFORM-${k3sup_arch}

    # Check if already installed
    [ -f $BUNDLESDIR/k3sup/${k3sup_dest_name} ] && echo "V3sup version v${latest} already installed!" && exit 0
    [[ ! -d $BUNDLESDIR/k3sup ]] && mkdir -p $BUNDLESDIR/k3sup

    # Download kubectl
    echo "Installing K3sup version v${latest}"
    curl -L "https://github.com/alexellis/k3sup/releases/download/${latest}/${k3sup_bin_name}" -o $BUNDLESDIR/k3sup/${k3sup_dest_name}
    chmod +x $BUNDLESDIR/k3sup/${k3sup_dest_name}

    # Set the default version
    rm -f $BUNDLESDIR/k3sup/default-$PLATFORM-${k3sup_arch}
    ln -s ${k3sup_dest_name} $BUNDLESDIR/k3sup/default-$PLATFORM-${k3sup_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${k3sup_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${k3sup_arch}
    [[ ! -f $BINDIR/$PLATFORM-${k3sup_arch}/k3sup ]] && ln -s $BUNDLESDIR/k3sup/default-$PLATFORM-${k3sup_arch} $BINDIR/$PLATFORM-${k3sup_arch}/k3sup

    unset k3sup_bin_name
    unset k3sup_dest_name
    unset kubectl_arch
    unset latest
}

function k3d_install {
    echo "K3d install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/k3d-io/k3d/releases/latest | grep 'tag_name' | cut -d\" -f4)

    # Arch x86_64 replaced by amd64
    k3d_arch=$ARCH
    [ $ARCH = 'x86_64' ] && k3d_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/k3d/k3d-${latest}-$PLATFORM-${k3d_arch} ] && echo "K3d version ${latest} already installed!" && exit 0
    [[ ! -d $BUNDLESDIR/k3d ]] && mkdir -p $BUNDLESDIR/k3d

    # Download k3d
    echo "Installing k3d version ${latest}"    
    curl -L "https://github.com/k3d-io/k3d/releases/download/${latest}/k3d-$PLATFORM-${k3d_arch}" -o $BUNDLESDIR/k3d/k3d-${latest}-$PLATFORM-${k3d_arch}
    chmod +x $BUNDLESDIR/k3d/k3d-${latest}-$PLATFORM-$k3d_arch

    # Set the default version
    rm -f $BUNDLESDIR/k3d/default-$PLATFORM-${k3d_arch}
    ln -s k3d-$latest-$PLATFORM-${k3d_arch} $BUNDLESDIR/k3d/default-$PLATFORM-${k3d_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${k3d_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${k3d_arch}
    [[ ! -f $BINDIR/$PLATFORM-${k3d_arch}/k3d ]] && ln -s $BUNDLESDIR/k3d/default-$PLATFORM-${k3d_arch} $BINDIR/$PLATFORM-${k3d_arch}/k3d

    unset k3d_arch
    unset latest
}

function kind_install {
    echo "Kind install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | grep 'tag_name' | cut -d\" -f4)

    # Arch x86_64 replaced by amd64
    kind_arch=$ARCH
    [ $ARCH = 'x86_64' ] && kind_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/kind/kind-${latest}-$PLATFORM-${kind_arch} ] && echo "Kind version ${latest} already installed!" && exit 0
    [[ ! -d $BUNDLESDIR/kind ]] && mkdir -p $BUNDLESDIR/kind

    # Download kind
    echo "Installing kind version ${latest}"    
    curl -L "https://github.com/kubernetes-sigs/kind/releases/download/${latest}/kind-$PLATFORM-${kind_arch}" -o $BUNDLESDIR/kind/kind-${latest}-$PLATFORM-${kind_arch}
    chmod +x $BUNDLESDIR/kind/kind-${latest}-$PLATFORM-$kind_arch

    # Set the default version
    rm -f $BUNDLESDIR/kind/default-$PLATFORM-${kind_arch}
    ln -s kind-$latest-$PLATFORM-${kind_arch} $BUNDLESDIR/kind/default-$PLATFORM-${kind_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${kind_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${kind_arch}
    [[ ! -f $BINDIR/$PLATFORM-${kind_arch}/kind ]] && ln -s $BUNDLESDIR/kind/default-$PLATFORM-${kind_arch} $BINDIR/$PLATFORM-${kind_arch}/kind

    unset kind_arch
    unset latest
}

function knative_install {
    echo "Knative install"

    # Find latest version
    latest=$(curl -s https://api.github.com/repos/knative/client/releases/latest | grep 'tag_name' | cut -d\" -f4)

    # Arch x86_64 replaced by amd64
    kn_arch=$ARCH
    [ $ARCH = 'x86_64' ] && kn_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/knative/kn-${latest}-$PLATFORM-${kn_arch} ] && echo "Knative version ${latest} already installed!" && exit 0
    [[ ! -d $BUNDLESDIR/knative ]] && mkdir -p $BUNDLESDIR/knative

    # Download Knative
    echo "Installing kn version ${latest}"    
    curl -L "https://github.com/knative/client/releases/download/${latest}/kn-$PLATFORM-${kn_arch}" -o $BUNDLESDIR/knative/kn-${latest}-$PLATFORM-${kn_arch}
    chmod +x $BUNDLESDIR/knative/kn-${latest}-$PLATFORM-$kn_arch

    # Set the default version
    rm -f $BUNDLESDIR/knative/default-$PLATFORM-${kn_arch}
    ln -s kn-$latest-$PLATFORM-${kn_arch} $BUNDLESDIR/knative/default-$PLATFORM-${kn_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${kn_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${kn_arch}
    [[ ! -f $BINDIR/$PLATFORM-${kn_arch}/kn ]] && ln -s $BUNDLESDIR/knative/default-$PLATFORM-${kn_arch} $BINDIR/$PLATFORM-${kn_arch}/kn

    unset kn_arch
    unset latest
}

function terraform_install {
    echo "Terraform install"

    # Get the latest version
    latest=$(wget -qO- https://releases.hashicorp.com/terraform/ | grep -oP 'terraform_[0-9\.]+<' | grep -oP 'terraform_[0-9.]+' | grep -oP '[0-9\.]+' | head -n 1)

    # Arch x86_64 replaced by amd64
    terraform_arch=$ARCH
    [ $ARCH = 'x86_64' ] && terraform_arch='amd64'

    # Check if already installed
    [ -f $BUNDLESDIR/terraform/terraform-v${latest}-$PLATFORM-${kubens_arch} ] && echo "Terraform version v${latest} already installed!" && exit 0
    [[ ! -d $BUNDLESDIR/terraform ]] && mkdir -p $BUNDLESDIR/terraform

    # Download terraform
    tmpDir=$BASEDIR/tmp
    [[ -d $tmpDir ]] && rm -rf $tmpDir && echo "tmp dir $tmpDir deleted" || (echo "Error deleting tmp dir $tmpDir" && exit 1)
    mkdir $tmpDir && echo "Temp dir $tmpDir created" || (echo "Error creating tmp dir $tmpDir" && exit 1)
    cd ${tmpDir}
    echo "Downloading latest Terraform version: v${latest}"
    wget --quiet --continue --show-progress https://releases.hashicorp.com/terraform/${latest}/terraform_${latest}_${PLATFORM}_${terraform_arch}.zip
    unzip terraform_${latest}_${PLATFORM}_${terraform_arch}.zip

    mv terraform $BUNDLESDIR/terraform/terraform-${latest}-$PLATFORM-${terraform_arch}

    # Set the default version
    rm -f $BUNDLESDIR/terraform/default-$PLATFORM-${terraform_arch}
    ln -s terraform-$latest-$PLATFORM-${terraform_arch} $BUNDLESDIR/terraform/default-$PLATFORM-${terraform_arch}

    # Link binary file
    [[ ! -d $BINDIR/$PLATFORM-${terraform_arch} ]] && mkdir -p $BINDIR/$PLATFORM-${terraform_arch}
    [[ ! -f $BINDIR/$PLATFORM-${terraform_arch}/terraform ]] && ln -s $BUNDLESDIR/terraform/default-$PLATFORM-${terraform_arch} $BINDIR/$PLATFORM-${terraform_arch}/terraform

    unset tmpDir
    unset terraform_arch
    unset latest
}

# Determine OS platform
PLATFORM=$(uname | tr "[:upper:]" "[:lower:]")
# If Linux, try to determine specific distribution
if [ "$PLATFORM" = "linux" ]; then
    # If available, use LSB to identify distribution
    if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
        export DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
    # Otherwise, use release info file
    else
        export DISTRO=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1)
    fi
fi
# For everything else (or if above failed), just use generic identifier
[ "$DISTRO" = "" ] && export DISTRO=$PLATFORM
ARCH=$(arch)

echo "OS platform detected: $PLATFORM $DISTRO ($ARCH)"

[[ "$@" = "" ]] && usage && exit 0
[ "$#" -ne 1 ] && echo "Error: Wrong number of arguments" && usage && exit 1

case "$1" in
    "git")
        git_install
        ;;
    "maven")
        maven_install
        ;;
    "ant")
        ant_install
        ;;
    "docker-compose")
        docker_compose_install
        ;;
    "minikube")
        minikube_install
        ;;
    "kubectl")
        kubectl_install
        ;;
    "kubectx")
        kubectx_install
        ;;
    "kubens")
        kubens_install
        ;;
    "k3sup")
        k3sup_install
        ;;
    "k3d")
        k3d_install
        ;;
    "kind")
        kind_install
        ;;
    "knative")
        knative_install
        ;;
    "terraform")
        terraform_install
        ;;
    "all")
        git_install
        maven_install
        ant_install
        docker_compose_install
        minikube_install
        kubectl_install
        kubectx_install
        kubens_install
        k3sup_install
        k3d_install
        kind_install
        knative_install
        terraform_install
        ;;
    *)
        echo "Error: Bundle or package name invalid" && usage && exit 1
        ;;
esac

exit 0
