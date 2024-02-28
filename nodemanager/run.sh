#!/bin/bash
bash $PASH_TOP/compiler/dspash/worker_manager.sh &> worker_manager.log &

$HADOOP_HOME/bin/yarn --config $HADOOP_CONF_DIR nodemanager
