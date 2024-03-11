#!/bin/bash

"$DISH_TOP/runtime/bin/discovery_server" > /discovery.log &

$HADOOP_HOME/bin/yarn --config $HADOOP_CONF_DIR nodemanager
