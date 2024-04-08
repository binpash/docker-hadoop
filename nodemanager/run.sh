#!/bin/bash

# The current design requires 1) discovery_server running on the worker_manager node and
#                             2) worker.py server running on the client node
# Because right now worker_manager node and client node are the same node, I simply call worker.sh
#               which spawns both the discovery_server and worker.py
bash $PASH_TOP/compiler/dspash/worker.sh &> worker.log &

$HADOOP_HOME/bin/yarn --config $HADOOP_CONF_DIR nodemanager
