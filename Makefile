DOCKER_NETWORK = hbase
ENV_FILE = hadoop.env

ifdef RELEASE
RELEASE := $(RELEASE)
else
RELEASE := latest
endif

ifdef NO_CACHE
BUILD_FLAG := --no-cache
else
BUILD_FLAG :=
endif

build:
#   https://stackoverflow.com/a/34392052/15104821
	docker build $(BUILD_FLAG) -t pash-base:$(RELEASE) -f ./pash-base/Dockerfile --build-arg RELEASE=$(RELEASE) ..
	docker build $(BUILD_FLAG) -t hadoop-pash-base:$(RELEASE) -f ./base/Dockerfile --build-arg RELEASE=$(RELEASE) ..

	docker build $(BUILD_FLAG) -t hadoop-namenode:$(RELEASE) --build-arg RELEASE=$(RELEASE) ./namenode
	docker build $(BUILD_FLAG) -t hadoop-datanode:$(RELEASE) --build-arg RELEASE=$(RELEASE) ./datanode
	docker build $(BUILD_FLAG) -t hadoop-resourcemanager:$(RELEASE) --build-arg RELEASE=$(RELEASE) ./resourcemanager
	docker build $(BUILD_FLAG) -t hadoop-nodemanager:$(RELEASE) --build-arg RELEASE=$(RELEASE) ./nodemanager
	docker build $(BUILD_FLAG) -t hadoop-historyserver:$(RELEASE) --build-arg RELEASE=$(RELEASE) ./historyserver
	docker build $(BUILD_FLAG) -t hadoop-submit:$(RELEASE) --build-arg RELEASE=$(RELEASE) ./submit

wordcount:
	docker build -t hadoop-wordcount ./submit
	docker run --network ${DOCKER_NETWORK} --env-file ${ENV_FILE} hadoop-base:$(RELEASE) hdfs dfs -mkdir -p /input/
	docker run --network ${DOCKER_NETWORK} --env-file ${ENV_FILE} hadoop-base:$(RELEASE) hdfs dfs -copyFromLocal -f /opt/hadoop-3.2.2/README.txt /input/
	docker run --network ${DOCKER_NETWORK} --env-file ${ENV_FILE} hadoop-wordcount
	docker run --network ${DOCKER_NETWORK} --env-file ${ENV_FILE} hadoop-base:$(RELEASE) hdfs dfs -cat /output/*
	docker run --network ${DOCKER_NETWORK} --env-file ${ENV_FILE} hadoop-base:$(RELEASE) hdfs dfs -rm -r /output
	docker run --network ${DOCKER_NETWORK} --env-file ${ENV_FILE} hadoop-base:$(RELEASE) hdfs dfs -rm -r /input