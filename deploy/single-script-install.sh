#!/bin/bash
set -eu

printf "Install script for DTaaS software platform.\n"
printf "You can run the script multiple times until the installation succeeds.\n "
printf ".........\n \n \n "

printf "Install the required system software dependencies...\n "
printf ".........\n \n \n "
sudo apt-get update -y
sudo apt-get upgrade -y


# Install docker for containers and microservices
# https://docs.docker.com/engine/install/ubuntu/
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    zsh \
    apache2-utils \
    net-tools

sudo mkdir -p /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]
then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo printf \
  "deb [arch=%s signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  %s stable" "$(dpkg --print-architecture)" "$(lsb_release -cs)"  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
fi

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo groupadd docker || true
sudo usermod -aG docker "$USER" || true

printf "\n\n\nMake docker available to your user account....\n "
printf ".......\n "
printf "Your user account is member of:\n "
groups
printf "groups.\n "

printf "If your user account is a member of docker group, let the installation script continue.\n "
printf "Otherwise, exit this script and run the following command\n\n "
printf "sudo usermod -aG docker %s\n\n " "$USER"
printf "logout and login again. You can run this script again after login\n\n "
printf "Press Ctl+C if you need to complete the this task....\n "
printf "Waiting for 60 seconds....\n "
sleep 60

#newgrp docker
sudo service docker start
docker run hello-world

sudo systemctl enable docker.service
sudo systemctl enable containerd.service


# Install nodejs environment
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash -
sudo apt-get install -y nodejs

if [ ! -f /usr/share/keyrings/yarnkey.gpg ]
then
  curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/yarnkey.gpg >/dev/null
  printf "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
fi

sudo apt-get update -y
sudo apt-get install -y yarn
sudo npm install -g serve

printf "\n\n End of installing dependencies...\n\n\n "
#----

# get the required docker images
printf "Download the required docker images...\n "
printf ".........\n\n\n "
docker pull traefik:v2.5
docker pull influxdb:2.4
docker pull mltooling/ml-workspace:0.13.2
docker pull grafana/grafana
docker pull telegraf
docker pull gitlab/gitlab-ce:15.10.0-ce.0
printf "\n\n docker images successfully downloaded...\n \n \n "
#----

printf "NOTE\n "
printf "....\n "
printf "This script installs DTaaS with default settings.\n "
printf "The setup is good for testing but not for secure installation.\n "


printf "\n\nClone the DTaaS codebase\n "
printf "...........\n "
if [ -d DTaaS ]
then
  cd DTaaS || exit
else
  git clone https://github.com/INTO-CPS-Association/DTaaS.git DTaaS
  cd DTaaS || exit
  git fetch --all
  git checkout feature/distributed-demo
fi

TOP_DIR=$(pwd)

#-------------
printf "\n\n Build, configure and run the react website\n "
printf ".....\n "
cd "${TOP_DIR}/client" || exit
yarn install
yarn build

yarn configapp dev
cp "${TOP_DIR}/deploy/config/client/env.js" build/env.js
nohup serve -s build -l 4000 & disown

#-------------
printf "\n\n Build, configure and run the lib microservice\n "
printf "...........\n "
cd "${TOP_DIR}/servers/lib" || exit
yarn install
yarn build

{
  printf "PORT='4001'\n "
  printf "MODE='local'\n "
  printf "LOCAL_PATH ='%s'\n " "$TOP_DIR"
  printf "GITLAB_GROUP ='dtaas'\n "
  printf "GITLAB_URL='https://gitlab.com/api/graphql'\n "
  printf "TOKEN='123-sample-token'\n "
  printf "LOG_LEVEL='debug'\n "
  printf "APOLLO_PATH='lib'\n "
  printf "GRAPHQL_PLAYGROUND='true'\n "
} > .env
nohup yarn start & disown


#-------------
printf "\n\n Start the user workspaces\n "
printf "...........\n "
docker run -d \
 -p 8090:8080 \
  --name "ml-workspace-user1" \
  -v "${TOP_DIR}/files/user1:/workspace" \
  -v "${TOP_DIR}/files/common:/workspace/common:ro" \
  --env AUTHENTICATE_VIA_JUPYTER="" \
  --env WORKSPACE_BASE_URL="user1" \
  --shm-size 512m \
  --restart always \
  mltooling/ml-workspace:0.13.2 || true

docker run -d \
 -p 8091:8080 \
  --name "ml-workspace-user2" \
  -v "${TOP_DIR}/files/user2:/workspace" \
  -v "${TOP_DIR}/files/common:/workspace/common:ro" \
  --env AUTHENTICATE_VIA_JUPYTER="" \
  --env WORKSPACE_BASE_URL="user2" \
  --shm-size 512m \
  --restart always \
  mltooling/ml-workspace:0.13.2 || true

#-------------
printf "\n\n Start the traefik gateway server\n "
printf "...........\n "
cd "${TOP_DIR}/servers/config/gateway" || exit
cp "${TOP_DIR}/deploy/config/gateway/auth" auth
cp "${TOP_DIR}/deploy/config/gateway/fileConfig.yml" "dynamic/fileConfig.yml"

docker run -d \
 --name "traefik-gateway" \
 --network=host -v "$PWD/traefik.yml:/etc/traefik/traefik.yml" \
 -v "$PWD/auth:/etc/traefik/auth" \
 -v "$PWD/dynamic:/etc/traefik/dynamic" \
 -v /var/run/docker.sock:/var/run/docker.sock \
 traefik:v2.5 || true


#----------
printf "\n\n Create crontabs to run the application in daemon mode.\n "
printf "...........\n "
cd "$TOP_DIR" || exit
bash deploy/create-cronjob.sh

printf "\n\n The installation is complete.\n\n\n "


printf "Continue with the application configuration.\n "
printf ".........\n\n\n "
printf "Remember to change foo.com to your local hostname in the following files.\n "
printf "1. %s/client/build/env.js\n " "$TOP_DIR"
printf "2. %s/servers/config/gateway/dynamic/fileConfig.yml\n " "$TOP_DIR"
