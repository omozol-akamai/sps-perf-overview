#!/usr/bin/env bash

USAGE="Usage: setup.sh [ --start <absolute path to influxdb backup tar-ball> [--legacy] | --stop ]"

# Docker vars
INFLUX_CONTAINER="influxdb"
PNAME="sps"
DOCKER_NET="${PNAME}_net"
DOCKER_INFLUX_VOLUME="${PNAME}_influx"

# Iflux version
INFLUXDB_VERSION_NEW="1.7.9"
INFLUXDB_VERSION_LEGACY="1.3.5"

function check_docker() {
  COMPOSE=$(which docker-compose)
  DOCKER=$(which docker)
  if [[ -f $COMPOSE && -f $DOCKER ]]
  then
    echo "docker-compose is found $COMPOSE"
  else
    [[ "$OSTYPE" == "darwin"* ]] && echo "In order to run it on MacOSX please install docker & docker-compose for MacOSX" && exit 1
    echo "In order to run it please install docker & docker-compose" && exit 1
  fi

  [[ $OSTYPE == "linux-gnu" ]] && echo 1 >/proc/sys/net/ipv4/conf/all/forwarding
}

function start_env() {

  check_docker

  [[ ! -f $INFLUX_BACKUP ]] && echo "Provided argument is not a file" && echo "$USAGE" && exit 1

  export INFLUX_BACKUP_FILE=$(basename ${INFLUX_BACKUP})
  export INFLUX_BACKUP_DIR="$(dirname ${INFLUX_BACKUP})"
  
  echo "Setting up environment"
  docker-compose -p $PNAME up -d || exit 1

  docker exec -it $INFLUX_CONTAINER bash -c "echo 'Creating directory /var/local/influx-backup-unpacked for influxdb backup' && mkdir /var/local/influx-backup-unpacked"
  docker exec -it $INFLUX_CONTAINER bash -c "echo 'Unpacking influxdb backup' && tar -xf /var/local/influx-backup/${INFLUX_BACKUP_FILE} -C /var/local/influx-backup-unpacked"
  echo "Restoring influxdb backup" 
  if [[ $LEGACY == "1" ]]
  then
    docker exec -it $INFLUX_CONTAINER bash -c 'influxd restore -metadir /var/lib/influxdb/meta $(find /var/local/influx-backup-unpacked -type f | head -1 | xargs dirname)'
    docker exec -it $INFLUX_CONTAINER bash -c 'influxd restore -database n2 -datadir /var/lib/influxdb/data $(find /var/local/influx-backup-unpacked -type f | head -1 | xargs dirname)'
    docker exec -it $INFLUX_CONTAINER bash -c  "chown -R influxdb:influxdb /var/lib/influxdb"
    docker-compose -p $PNAME restart influxdb
  else
    docker exec -it $INFLUX_CONTAINER bash -c 'influxd restore -portable -db n2 $(find /var/local/influx-backup-unpacked -type f | head -1 | xargs dirname)'
  fi
  docker exec -it $INFLUX_CONTAINER bash -c "rm -rf /var/local/influx-backup-unpacked"
  # DOCKER_NET=$(docker inspect influxdb -f '{{range $k, $v := .NetworkSettings.Networks}}{{printf "%s" $k}}{{end}}')

  docker run --rm --net=${DOCKER_NET} -v "${PWD}/dashboards/gs/:/usr/src/app/dashboards" omozolaka/setupgrafana:latest
}

function stop_env(){

  check_docker

  echo "Destroying environment"
  docker-compose -p $PNAME down
  echo -n "Removing volume: " && docker volume rm ${DOCKER_INFLUX_VOLUME}
}

[[ $# < 1 ]] && echo "$USAGE" && exit 2

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    --start)
      START="1"
      shift # past argument
      ;;
    --stop)
      STOP="1"
      shift # past argument
      ;;
    --legacy)
      LEGACY="1"
      shift # past argument
      ;;
    -h|--help)
      echo "$USAGE" && exit 0
      ;;
    *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL[@]}"
INFLUX_BACKUP="$1"

[[ $LEGACY == "1" ]] && export INFLUXDB_VERSION=$INFLUXDB_VERSION_LEGACY || export INFLUXDB_VERSION=$INFLUXDB_VERSION_NEW

[[ $START != "1" && $STOP != "1" ]] && echo "$USAGE" && exit

[[ $START == "1" ]] && start_env

[[ $STOP == "1" ]] && stop_env