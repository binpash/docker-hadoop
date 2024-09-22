#!/bin/bash

# Generates the cluster json config file from available datanodes
CLUSTER_FILE='dspash-config.json'
echo -e "{\n  \"workers\": {" > $CLUSTER_FILE

while read id host ; do
    # Only get the Ip address of the hbase network
    ip=$(docker inspect $id --format '{{range .NetworksAttachments}}{{if eq .Network.Spec.Name "hbase"}}{{.Addresses}}{{end}}{{end}}' | grep -oP "\[\K[^]/]*")
    echo -e "    \"$id\": {\n      \"host\": \"$ip\",\n      \"port\": 65432\n    }," >> $CLUSTER_FILE
    echo $host-datanode $ip
done < <(docker service ps -f "desired-state=running" hadoop_datanode --format '{{.ID}} {{.Node}}')

truncate -s-2 $CLUSTER_FILE

echo -e "\n  }\n}" >> $CLUSTER_FILE
