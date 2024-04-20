ARG BASE=hadoop-pash-base
ARG RELEASE=latest

FROM $BASE:$RELEASE

HEALTHCHECK CMD curl -f http://localhost:9864/ || exit 1

ENV HDFS_CONF_dfs_datanode_data_dir=file:///hadoop/dfs/data
RUN mkdir -p /hadoop/dfs/data
VOLUME /hadoop/dfs/data

ADD run.sh /run.sh
RUN chmod a+x /run.sh

EXPOSE 9864

# Launch the primary service in the background
CMD ["/run.sh --loop"] &

# Keep the container running in the foreground
CMD tail -f /dev/null
