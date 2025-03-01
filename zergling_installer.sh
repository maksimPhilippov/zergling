#!/bin/sh

if [ -z $1 ] ; then 
  echo "Fail: no overlord address specified"
  exit 1
fi
if [ -z $2 ] ; then 
  echo "Fail: no overlord port specified"
  exit 1
fi

KEY_FILE=/root/.ssh/zergling_ssh_key
OVERLORD_ADDR="$1"
OVERLORD_PORT="$2"
ZERGLING_VERSION=${ZERGLING_VERSION:-1.0.0}
SERVICE_FILE=/etc/init.d/zergling
SERVICE_BACKUP_NAME=/etc/init.d/zergling.back

if [ -f "$KEY_FILE" ] ; then
  echo "Key file already exist, skip creating ssh keys"
else
  ssh-keygen -t ed25519 -f /root/.ssh/zergling_ssh_key
fi

if [ ! which wget ] ; then
  echo "Fail: wget not found on system, please install it"
  exit 1
else 
  if [ -f $SERVICE_FILE ] ; then
    echo "Warning: zerling already installed in $SERVICE_FILE"
    echo "Previous $SERVICE_FILE will be saved in $SERVICE_BACKUP_NAME"
    cat $SERVICE_FILE >$SERVICE_BACKUP_NAME
  fi

  wget -O $SERVICE_FILE "https://raw.githubusercontent.com/maksimPhilippov/zergling/$ZERGLING_VERSION/zergling.sh"
  if [ $? ] ; then
    chmod +x $SERVICE_FILE
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

if [ -f "$KEY_FILE.pub" ] ; then
  PUBLIC_KEY=$( cat "$KEY_FILE.pub" )
  echo "Authorize in the overlord please"
  sleep 2
  echo "$PUBLIC_KEY" | ssh "overlord@${OVERLORD_ADDR}" 'echo >> .ssh/authorized_keys'
  echo "Please ensure that next command runs WITHOUT asking password:"
  echo "ssh -i $KEY_FILE -p $OVERLORD_PORT overlord@$OVERLORD_ADDR"
  exit 0
else 
  echo "Fail: public key not found in $KEY_FILE.pub"
  exit 1
fi

