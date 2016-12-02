# Metasploit docker container

## Build

docker build -t metasploit:master .

## Run

docker run --rm -i -t -v /root/.msf4:/root/.msf4 -v /tmp/data:/tmp/data metasploit:master
