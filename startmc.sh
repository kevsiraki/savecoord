#!/bin/bash

screen -X -S mc quit
cd /path/to

screen -dmS mc bash -c 'java -Xms1024M -Xmx4G -jar server.jar nogui'

echo "Waiting for Minecraft server to start..."
sleep 10

while ! grep -q "Preparing spawn area" /path/to/logs/latest.log; do
	echo "Server starting..."
	sleep 1
done

sleep 10

./savecoord.sh
