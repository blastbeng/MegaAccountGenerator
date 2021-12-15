#!/bin/sh
sudo mkdir -p /usr/local/bin
sudo cp mailserverMegaGenerator /usr/local/bin/mailserverMegaGenerator 
sudo cp mountMega /usr/local/bin/mountMega
sudo cp umountMega /usr/local/bin/umountMega
sudo cp mountMegaMerged /usr/local/bin/mountMegaMerged
sudo cp umountMegaMerged /usr/local/bin/umountMegaMerged
sudo cp restartSystemdIfNotRunning /usr/local/bin/restartSystemdIfNotRunning

sudo cp rclone-mega@.service /lib/systemd/system/rclone-mega@.service
