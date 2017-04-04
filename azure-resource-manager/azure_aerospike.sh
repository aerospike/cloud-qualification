#!/bin/bash

START=${1}
NODEADDRESS=${2}
PUBLICIP=${3}
NAMESPACE=${4}
LOG=/var/log/cluster.log

IFS='.' read -ra OCTETS <<< "$START"
#for i in "${OCTETS[@]}"; do
#	echo $i
#done

NODE=$START
CLUSTER=()

echo "My address: $NODEADDRESS" >> $LOG
echo "Start: $START" >> $LOG
echo "Public IP: $PUBLICIP" >> $LOG

while [ "$NODE" != "$NODEADDRESS" ]
do
	CLUSTER+=("$NODE")
	echo "node:  $NODE" >> $LOG
	OCTETS[3]=$(expr ${OCTETS[3]} + 1 )
	OCTETS[2]=$(expr $(expr ${OCTETS[3]} / 255 ) + ${OCTETS[2]})
	OCTETS[3]=$(expr ${OCTETS[3]} % 255 )
	NODE="${OCTETS[0]}.${OCTETS[1]}.${OCTETS[2]}.${OCTETS[3]}"
done


echo "Cluster: " >> $LOG
for i in ${CLUSTER[@]}; do
    echo $i >> $LOG
done

CONF=/etc/aerospike/aerospike.conf

if [ "$PUBLICIP" ]; then
	sed -i "/port 3000/a \\\t\taccess-address $PUBLICIP virtual" $CONF
fi

sed -i '/.*mesh-seed-address-port/d' $CONF
for i in ${CLUSTER[@]}; do
 	sed -i "/interval/i \\\t\tmesh-seed-address-port $i 3002" $CONF
done


if [ "$NAMESPACE" ]; then
	curl -fs $NAMESPACE >> $CONF
fi

service aerospike restart
umount /mnt
