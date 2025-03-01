#!/bin/sh /etc/rc.common

START=99
STOP=10
USE_PROCD=1

# Probably you want to change these variables:
# Adress of overlord(ip address, or dns name)
OVERLORD_HOST=${OVERLORD_HOST:-overlord_host_sed_template}
# Port of ssh server on overlord, that we are connecting to
OVERLORD_PORT=${OVERLORD_PORT:-overlord_port_sed_template}
# Port on overlord that will be created after zerling successful connect, number from 2000 to 62000
SSH_TUNNEL_PORT=${SSH_TUNNEL_PORT:-ssh_tunnel_port_sed_template}
# Name of registration file on overlord
ZERGLING_ID=${ZERGLING_ID:-"zergling_id_sed_template"}


# Probably you don't want to change these variables:
OVERLORD_USER=${OVERLORD_USER:-"overlord"}
LOCAL_SSH_PORT=${LOCAL_SSH_PORT:-22}
SSH_KEY=${SSH_KEY:-"/root/.ssh/zergling_ssh_key"}
REG_VAR="./register.sh ${ZERGLING_ID} ${SSH_TUNNEL_PORT}"
ETHERNAL_LOOP="while true ; do sleep 1h ; done"

start_service() {
    logger -t zergling "Starting SSH tunnel service..."
    
    # Wait until the internet connection is available
    while ! ping -c 1 1.1.1.1 >/dev/null 2>&1; do
        sleep 5
    done
    logger -t zergling "Internet connection detected."
    
    # Start reverse SSH tunnel using autossh
    procd_open_instance
    procd_set_param command /usr/bin/ssh -N -R 127.0.0.1:${SSH_TUNNEL_PORT}:localhost:${LOCAL_SSH_PORT} \
        -o ServerAliveInterval=60 -o ExitOnForwardFailure=yes \
        -i ${SSH_KEY} ${OVERLORD_USER}@${OVERLORD_HOST} -p ${OVERLORD_PORT} \
        "$ETHERNAL_LOOP"
    procd_set_param env HOME=/root
    procd_set_param stdout 1 # forward stdout of the command to logd
    procd_set_param stderr 1 # same for stderr
    procd_set_param respawn ${respawn_threshold:-3600} ${respawn_timeout:-5} ${respawn_retry:-5}
    procd_close_instance
    
    # Create the registration file on the remote server
    HOME=/root ssh -i ${SSH_KEY} ${OVERLORD_USER}@${OVERLORD_HOST} "$REG_VAR"
    logger -t zergling "SSH tunnel established and overlord got connection registration"
}

stop_service() {
    logger -t zergling "Stopping SSH tunnel service..."
    procd_kill
    
    # Remove the registration file on the remote server
    logger -t zergling "Warning: overlord was not notificated about zerling stop, not supported yet"
    
    logger -t zergling "SSH tunnel stopped."
}
