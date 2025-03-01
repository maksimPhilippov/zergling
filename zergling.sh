#!/bin/sh /etc/rc.common

START=99
STOP=10
USE_PROCD=1

# Probably you want to change
OVERLORD_HOST=${OVERLORD_HOST:-"example.com"}
OVERLORD_PORT=${OVERLORD_PORT:-22}
SSH_TUNNEL_PORT=${SSH_TUNNEL_PORT:-2000}
ZERLING_ID=${ZERLING_ID:-"ZerlingID"}

# Probably you don't want to change
OVERLORD_USER=${OVERLORD_USER:-"overlord"}
LOCAL_SSH_PORT=${LOCAL_SSH_PORT:-22}
SSH_KEY=${SSH_KEY:-"/root/.ssh/zerling_ssh_key"}
REG_FILE=${REG_FILE:-"/var/lib/regs/${ZERLING_ID}"}
REG_VAR="port is ${SSH_TUNNEL_PORT}"
ETHERNAL_LOOP="while true ; do sleep 1h ; done"

start_service() {
    logger -t zerling "Starting SSH tunnel service..."
    
    # Wait until the internet connection is available
    while ! ping -c 1 1.1.1.1 >/dev/null 2>&1; do
        sleep 5
    done
    logger -t zerling "Internet connection detected."
    
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
    ssh -i ${SSH_KEY} ${OVERLORD_USER}@${OVERLORD_HOST} "mkdir -p $(dirname ${REG_FILE}) && echo ${REG_VAR} > ${REG_FILE} && date >> ${REG_FILE}"
    logger -t zerling "SSH tunnel established and remote registration file created."
}

stop_service() {
    logger -t zerling "Stopping SSH tunnel service..."
    procd_kill
    
    # Remove the registration file on the remote server
    ssh -i ${SSH_KEY} ${OVERLORD_USER}@${OVERLORD_HOST} "rm -f ${REG_FILE}"
    logger -t zerling "Remote registration file removed."
    
    logger -t zerling "SSH tunnel stopped."
}
