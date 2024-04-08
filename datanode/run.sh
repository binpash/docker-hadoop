#!/bin/bash

# pull latest changes (added for convenience) and start worker
cd $PASH_TOP
git config --global --add safe.directory /opt/dish/pash
git pull
cd -
# TODO: set up logrotate
if [[ "$@" == *"resurrect"* ]]; then
  # This appends to worker.log while also capturing both stdout and stderr
  bash $PASH_TOP/compiler/dspash/worker.sh --resurrect >> worker.log 2>&1 &
else
  bash $PASH_TOP/compiler/dspash/worker.sh &> worker.log &
fi

datadir=`echo $HDFS_CONF_dfs_datanode_data_dir | perl -pe 's#file://##'`
if [ ! -d $datadir ]; then
  echo "Datanode data directory not found: $datadir"
  exit 2
fi

# Datanode is background process, so we can kill it
$HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR datanode &> whdfs.log & 

# Check if --loop parameter is passed
if [[ "$@" == *"--loop"* ]]; then
  # Keep the container running via main process
  echo "Starting datanode in loop mode"
  while true; do sleep 1; done
fi
