# zergling
## Overview

zerling is a service for remote management of OpenWRT router
It forwards ssh port from router to server with reverse ssh tunnel(also known as a remote ssh tunnel)
All the configurations done right inside the service file

## Installation

1. Connect to your router CLI(ssh or serial interface)
2. Make sure you have internet connection:
```
ping github.com
```
3. Run installer on router:
```
cd ; wget https://raw.githubusercontent.com/maksimPhilippov/zergling/refs/heads/main/zergling_installer.sh && chmod +x zergling_installer.sh
```
```
./zergling_installer.sh <overlord address> <overlord server port> <tunnel port> <unique zerling id>
```
4. Make sure you can connect to your server without password
5. Reboot router
6. Check if /var/lib/ registration file is created
7. Try to connect from server to router:
```
ssh root@localhost -p <port from registration file>
```

## Forwarding of web UI

In order to forward web UI to server run this comman on the router:
```
ssh -R <port on the server>:localhost:80
```
