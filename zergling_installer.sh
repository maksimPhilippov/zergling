#!/bin/sh

usage() {
  echo "$0 <overlord address> <overlord server port> <tunnel port> <unique zerling id>"
}

if [ -z $1 ] ; then 
  echo "Fail: no overlord address specified"
  usage
  exit 1
fi
if [ -z $2 ] ; then 
  echo "Fail: overlord port not specified"
  usage
  exit 1
fi
if [ -z $3 ] ; then 
  echo "Fail: tunnel port not specified"
  usage
  exit 1
fi
if [ -z $4 ] ; then 
  echo "Fail: zerling id not specified"
  usage
  exit 1
fi

OVERLORD_ADDR="$1"
OVERLORD_PORT="$2"
TUNNEL_PORT="$3"
ZERGLING_ID="$4"
ZERGLING_VERSION=${ZERGLING_VERSION:-1.0.1}
KEY_FILE=/root/.ssh/zergling_ssh_key
SERVICE_FILE=/etc/init.d/zergling
SERVICE_BACKUP_NAME=/etc/init.d/zergling.back

if [ ! which wget ] ; then
  echo "Fail: wget not found on system, please install it"
  exit 1
else 
  if [ -f $SERVICE_FILE ] ; then
    echo "Warning: zerling already installed in $SERVICE_FILE"
    echo "Previous $SERVICE_FILE will be saved in $SERVICE_BACKUP_NAME"
    cat $SERVICE_FILE >$SERVICE_BACKUP_NAME
  fi

  echo "begin download $ZERGLING_VERSION version of zerling"
  sleep 1
  wget -O $SERVICE_FILE "https://raw.githubusercontent.com/maksimPhilippov/zergling/$ZERGLING_VERSION/zergling.sh"
  if [ $? ] ; then
    chmod +x $SERVICE_FILE
    sed -i "s/overlord_host_sed_template/$OVERLORD_ADDR/" "$SERVICE_FILE"
    sed -i "s/overlord_port_sed_template/$OVERLORD_PORT/" "$SERVICE_FILE"
    sed -i "s/ssh_tunnel_port_sed_template/$TUNNEL_PORT/" "$SERVICE_FILE"
    sed -i "s/zergling_id_sed_template/$ZERGLING_ID/" "$SERVICE_FILE"
    $SERVICE_FILE enable
    $SERVICE_FILE status
  else
    echo "Fail: Download zergling failed"
    if [ -f $SERVICE_BACKUP_NAME ] ; then
      echo "Warning: zerling already installed in $SERVICE_FILE"
      echo "Previous $SERVICE_FILE will be saved in $SERVICE_BACKUP_NAME"
      echo "Restoring from backup $SERVICE_BACKUP_NAME"
      cat $SERVICE_BACKUP_NAME >$SERVICE_FILE
    else 
      echo "No backup found in $SERVICE_BACKUP_NAME"
    fi
  fi
fi

if [ -f "$KEY_FILE" ] ; then
  echo "Key file already exist, skip creating ssh keys"
else
  mkdir -p /root/.ssh
  ssh-keygen -y -t ed25519 -f $KEY_FILE
fi

if [ -f "$KEY_FILE.pub" ] ; then
  PUBLIC_KEY=$( cat "$KEY_FILE.pub" )
  echo "Authorize in the overlord please"
  sleep 2
  ssh "overlord@${OVERLORD_ADDR}" "echo \"$PUBLIC_KEY\" >> .ssh/authorized_keys"
  echo "Please ensure that next command runs WITHOUT asking password:"
  echo "ssh -i $KEY_FILE -p $OVERLORD_PORT overlord@$OVERLORD_ADDR"
  exit 0
else 
  echo "Fail: public key not found in $KEY_FILE.pub"
  exit 1
fi

