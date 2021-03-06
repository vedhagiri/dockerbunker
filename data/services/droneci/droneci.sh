#!/usr/bin/env bash

while true;do ls | grep -q dockerbunker.sh;if [[ $? == 0 ]];then BASE_DIR=$PWD;break;else cd ../;fi;done

PROPER_NAME="Drone CI"
SERVICE_NAME="$(echo -e "${PROPER_NAME,,}" | tr -cd '[:alnum:]')"
PROMPT_SSL=1

declare -a environment=( "data/env/dockerbunker.env" "data/include/init.sh" )

for env in "${environment[@]}";do
	[[ -f "${BASE_DIR}"/$env ]] && source "${BASE_DIR}"/$env
done

declare -A WEB_SERVICES
declare -a containers=( "${SERVICE_NAME}-service-dockerbunker" )
declare -a add_to_network=( "${SERVICE_NAME}-service-dockerbunker" )
declare -A IMAGES=( [service]="drone/drone:1" )
declare -A volumes=( [${SERVICE_NAME}-data-vol-1]="/data" )
declare -a networks=( )

[[ -z $1 ]] && options_menu

configure() {
	pre_configure_routine
	
	echo -e "# \e[4mDrone CI Settings\e[0m"

	set_domain
	
	read -p "Gogs server address: " -ei "https://" DRONE_GOGS_SERVER
	
	read -p "Gogs username: " -ei "" GOGS_USER
	
	cat <<-EOF >> "${SERVICE_ENV}"
	PROPER_NAME="${PROPER_NAME}"
	SERVICE_NAME=${SERVICE_NAME}
	SSL_CHOICE=${SSL_CHOICE}
	LE_EMAIL=${LE_EMAIL}

	DRONE_GOGS_SERVER=${DRONE_GOGS_SERVER}
	DRONE_SERVER_HOST=${SERVICE_DOMAIN}
	DRONE_SERVER_PROTO=https
	DRONE_RUNNER_CAPACITY=2
	DRONE_TLS_AUTOCERT=false
	DRONE_GIT_ALWAYS_AUTH=false
	DRONE_USER_CREATE=username:${GOGS_USER},admin:true
	DRONE_DATABASE_SECRET=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 32)
	SERVICE_DOMAIN=${SERVICE_DOMAIN}
	DRONE_AGENTS_DISABLED=true
	EOF

	post_configure_routine
}

if [[ $1 == "letsencrypt" ]];then
	$1 $*
else
	$1
fi
