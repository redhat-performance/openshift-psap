#!/bin/bash

demoimg=pgstrom
quayuser=zvonkok
myname=ZvonkoKosic
distro=centos/postgresql-10-centos7
distrorelease=latest
pkgmgr=yum

#Setting up some colors for helping read the demo output
bold=$(tput bold)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
cyan=$(tput setaf 6)
reset=$(tput sgr0)

echo -e "Using ${green}GREEN${reset} to introduce Buildah steps"
echo -e "Using ${yellow}YELLOW${reset} to introduce code"
echo -e "Using ${blue}BLUE${reset} to introduce Podman steps"
echo -e "Using ${cyan}CYAN${reset} to introduce bash commands"
echo -e "Using ${red}RED${reset} to introduce Docker commands"


echo -e "Building an image called ${demoimg}"

set -x 

echo -e "${green}Create a new container on disk from ${distro}${reset}"
newcontainer=$(buildah from docker://${distro}:${distrorelease})

echo -e "${green}Install pg-strom${reset}"
buildah run --user 0 $newcontainer -- rpm --nodeps -ivh https://heterodb.github.io/swdc/yum/rhel7-x86_64/pg_strom-PG10-2.0-180607.el7.x86_64.rpm 

echo -e "${green}Install dependencies for pg-strom test${reset}"
buildah run --user 0 $newcontainer -- ${pkgmgr} -y install git gcc make which rh-postgresql10-postgresql-devel postgresql-odbc
buildah run --user 0 $newcontainer -- bash -c "ln -sf /usr/pgsql-10/share/extension/*  /opt/rh/rh-postgresql10/root/usr/share/pgsql/extension/."
buildah run --user 0 $newcontainer -- rpm -ivh https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-repo-rhel7-9.2.88-1.x86_64.rpm
buildah run --user 0 $newcontainer -- ${pkgmgr} -y install cuda-nvrtc-9-2 cuda-nvcc-9-2 cuda-libraries-9-2 cuda-nvtx-9-2 
buildah run --user 0 $newcontainer -- ${pkgmgr} -y install cuda-libraries-dev-9-2 cuda-nvml-dev-9-2 cuda-minimal-build-9-2  cuda-command-line-tools-9-2 

buildah run --user 0 $newcontainer -- ${pkgmgr} -y clean all
buildah run --user 0 $newcontainer -- bash -c "echo \"/usr/local/cuda-9.2/targets/x86_64-linux/lib\" > /etc/ld.so.conf.d/z-cuda.conf"
buildah run --user 0 $newcontainer -- bash -c "ldconfig"
buildah run --user 0 $newcontainer -- bash -c "ln -sf /usr/local/cuda-9.2 /usr/local/cuda"
buildah run --user 0 $newcontainer -- bash -c "ln -sf /usr/pgsql-10/lib/pg_strom.so /opt/rh/rh-postgresql10/root/usr/lib64/pgsql/."


echo -e "${green}Get pg-strom test${reset}"
buildah run --user 26 $newcontainer -- git clone https://github.com/heterodb/pg-strom.git /var/lib/pgsql/pg-strom
buildah run --user 26 $newcontainer -- bash -c "cd /var/lib/pgsql/pg-strom && git checkout 47196e1eca71a4bec0624ed499cf5bb0f3d5beea && git reset --hard"

echo -e "${green}Use buildah config to expose the port and set the entrypoint${reset}"
buildah config --port 5432 $newcontainer

echo -e "${green}Set other meta data using buildah config${reset}"
buildah config --created-by "${quayuser}"  $newcontainer
buildah config --author "${myname}" --label name=$demoimg $newcontainer

echo -e "${green}Inspect the container image meta data${yellow}"
buildah inspect $newcontainer 

echo -e "${green}Commit the container to an OCI image called ${demoimg}.${reset}"
buildah commit $newcontainer $demoimg

echo -e "${green}List the images we have.${reset}"
buildah images

echo -e "${blue}Push the image to the local Docker repository using docker-daemon${reset}"
buildah push $demoimg docker-daemon:$quayuser/${demoimg}:latest 

echo -e "${red}List the Docker images in the repository${reset}"
docker images 



