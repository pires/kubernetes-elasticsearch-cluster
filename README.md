# kubernetes-elasticsearch-cluster
Elasticsearch (2.1.0) cluster on top of Kubernetes made easy.

Elasticsearch best-practices recommend to separate nodes in three roles:
* `Master` nodes - intended for clustering management only, no data, no HTTP API
* `Client` nodes - intended for client usage, no data, with HTTP API
* `Data` nodes - intended for storing and indexing your data, no HTTP API

Given this, I'm hereby making possible for you to scale as needed. For instance, a good strong scenario could be 3 master, 2 client, 5 data nodes.

*Attention:* As of the moment, Kubernetes pod descriptors use an `emptyDir` for storing data in each data node container. This is meant to be for the sake of simplicity and should be adapted according to your storage needs.

## Pre-requisites

* Kubernetes cluster (tested with v1.1.2 on top of [Vagrant + CoreOS](https://github.com/pires/kubernetes-vagrant-coreos-cluster))
* `kubectl` configured to access your cluster master API Server

## Build images (optional)

Providing your own version of [the images automatically built from this repository](https://github.com/pires/docker-elasticsearch-kubernetes) will not be supported. This is an *optional* step. You have been warned.

## Test

### Deploy

```
kubectl create -f service-account.yaml
kubectl create -f es-discovery-svc.yaml
kubectl create -f es-svc.yaml
kubectl create -f es-master-rc.yaml
```

Wait until `es-master` is provisioned, and
```
kubectl create -f es-client-rc.yaml
```

Wait until `es-client` is provisioned, and
```
kubectl create -f es-data-rc.yaml
```

Wait until `es-data` is provisioned.

Now, I leave up to you how to validate the cluster, but a first step is to wait for containers to be in the `Running` state and check Elasticsearch master logs:

```
$ kubectl get svc,rc,pods
NAME                      CLUSTER_IP       EXTERNAL_IP   PORT(S)         SELECTOR                              AGE
elasticsearch             10.100.116.17                  9200/TCP        component=elasticsearch,role=client   11m
elasticsearch-discovery   10.100.152.227   <none>        9300/TCP        component=elasticsearch,role=master   11m
kube-dns                  10.100.0.10      <none>        53/UDP,53/TCP   k8s-app=kube-dns                      46m
kubernetes                10.100.0.1       <none>        443/TCP         <none>                                46m
CONTROLLER   CONTAINER(S)   IMAGE(S)                                              SELECTOR                              REPLICAS   AGE
es-client    es-client      quay.io/pires/docker-elasticsearch-kubernetes:2.1.0   component=elasticsearch,role=client   1          8m
es-data      es-data        quay.io/pires/docker-elasticsearch-kubernetes:2.1.0   component=elasticsearch,role=data     1          3m
es-master    es-master      quay.io/pires/docker-elasticsearch-kubernetes:2.1.0   component=elasticsearch,role=master   1          11m
kube-dns     etcd           gcr.io/google_containers/etcd:2.0.9                   k8s-app=kube-dns                      1          46m
             kube2sky       gcr.io/google_containers/kube2sky:1.11
             skydns         gcr.io/google_containers/skydns:2015-03-11-001
NAME              READY     STATUS    RESTARTS   AGE
es-client-suigi   1/1       Running   0          8m
es-data-ygq6o     1/1       Running   0          3m
es-master-n4ykt   1/1       Running   0          11m
kube-dns-ac0jp    3/3       Running   0          46m
```

```
$ kubectl logs es-master-n4ykt
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
[2015-11-25 14:20:21,538][INFO ][node                     ] [Beta Ray Bill] version[2.1.0], pid[13], build[72cd1f1/2015-11-18T22:40:03Z]
[2015-11-25 14:20:21,539][INFO ][node                     ] [Beta Ray Bill] initializing ...
[2015-11-25 14:20:21,915][INFO ][plugins                  ] [Beta Ray Bill] loaded [cloud-kubernetes], sites []
[2015-11-25 14:20:21,968][INFO ][env                      ] [Beta Ray Bill] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [14.2gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2015-11-25 14:20:26,201][INFO ][node                     ] [Beta Ray Bill] initialized
[2015-11-25 14:20:26,202][INFO ][node                     ] [Beta Ray Bill] starting ...
[2015-11-25 14:20:26,645][INFO ][transport                ] [Beta Ray Bill] publish_address {10.244.85.2:9300}, bound_addresses {10.244.85.2:9300}
[2015-11-25 14:20:26,671][INFO ][discovery                ] [Beta Ray Bill] myesdb/3exFpLDzRpWKpaI9Vhafyg
[2015-11-25 14:20:31,714][INFO ][cluster.service          ] [Beta Ray Bill] new_master {Beta Ray Bill}{3exFpLDzRpWKpaI9Vhafyg}{10.244.85.2}{10.244.85.2:9300}{data=false, master=true}, reason: zen-disco-join(elected_as_master, [0] joins received)
[2015-11-25 14:20:31,717][INFO ][node                     ] [Beta Ray Bill] started
[2015-11-25 14:20:31,774][INFO ][gateway                  ] [Beta Ray Bill] recovered [0] indices into cluster_state
[2015-11-25 14:23:44,437][INFO ][cluster.service          ] [Beta Ray Bill] added {{Demogoblin}{j5RheK6uTJ2kDXOs9QC9Tg}{10.244.66.2}{10.244.66.2:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{Demogoblin}{j5RheK6uTJ2kDXOs9QC9Tg}{10.244.66.2}{10.244.66.2:9300}{data=false, master=false}])
[2015-11-25 14:28:34,418][INFO ][cluster.service          ] [Beta Ray Bill] added {{Tethlam}{manY6pckTZeDQmeLyifD8Q}{10.244.101.2}{10.244.101.2:9300}{master=false},}, reason: zen-disco-join(join from node[{Tethlam}{manY6pckTZeDQmeLyifD8Q}{10.244.101.2}{10.244.101.2:9300}{master=false}])
```

As you can assert, the cluster is up and running. Easy, wasn't it?

### Scale

Scaling each type of node to handle your cluster is as easy as:

```
kubectl scale --replicas=3 rc es-master
kubectl scale --replicas=2 rc es-client
kubectl scale --replicas=2 rc es-data
```

Did it work?

```
$ kubectl get pods
NAME              READY     STATUS    RESTARTS   AGE
es-client-jnnnv   1/1       Running   0          1m
es-client-suigi   1/1       Running   0          11m
es-data-2g2iv     1/1       Running   0          1m
es-data-ygq6o     1/1       Running   0          6m
es-master-n4ykt   1/1       Running   0          14m
es-master-svkq1   1/1       Running   0          2m
es-master-yre86   1/1       Running   0          2m
kube-dns-ac0jp    3/3       Running   0          49m
```

Let's take another look of the Elasticsearch master logs:
```
$ kubectl logs es-master-n4ykt
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
[2015-11-25 14:20:21,538][INFO ][node                     ] [Beta Ray Bill] version[2.1.0], pid[13], build[72cd1f1/2015-11-18T22:40:03Z]
[2015-11-25 14:20:21,539][INFO ][node                     ] [Beta Ray Bill] initializing ...
[2015-11-25 14:20:21,915][INFO ][plugins                  ] [Beta Ray Bill] loaded [cloud-kubernetes], sites []
[2015-11-25 14:20:21,968][INFO ][env                      ] [Beta Ray Bill] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [14.2gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2015-11-25 14:20:26,201][INFO ][node                     ] [Beta Ray Bill] initialized
[2015-11-25 14:20:26,202][INFO ][node                     ] [Beta Ray Bill] starting ...
[2015-11-25 14:20:26,645][INFO ][transport                ] [Beta Ray Bill] publish_address {10.244.85.2:9300}, bound_addresses {10.244.85.2:9300}
[2015-11-25 14:20:26,671][INFO ][discovery                ] [Beta Ray Bill] myesdb/3exFpLDzRpWKpaI9Vhafyg
[2015-11-25 14:20:31,714][INFO ][cluster.service          ] [Beta Ray Bill] new_master {Beta Ray Bill}{3exFpLDzRpWKpaI9Vhafyg}{10.244.85.2}{10.244.85.2:9300}{data=false, master=true}, reason: zen-disco-join(elected_as_master, [0] joins received)
[2015-11-25 14:20:31,717][INFO ][node                     ] [Beta Ray Bill] started
[2015-11-25 14:20:31,774][INFO ][gateway                  ] [Beta Ray Bill] recovered [0] indices into cluster_state
[2015-11-25 14:23:44,437][INFO ][cluster.service          ] [Beta Ray Bill] added {{Demogoblin}{j5RheK6uTJ2kDXOs9QC9Tg}{10.244.66.2}{10.244.66.2:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{Demogoblin}{j5RheK6uTJ2kDXOs9QC9Tg}{10.244.66.2}{10.244.66.2:9300}{data=false, master=false}])
[2015-11-25 14:28:34,418][INFO ][cluster.service          ] [Beta Ray Bill] added {{Tethlam}{manY6pckTZeDQmeLyifD8Q}{10.244.101.2}{10.244.101.2:9300}{master=false},}, reason: zen-disco-join(join from node[{Tethlam}{manY6pckTZeDQmeLyifD8Q}{10.244.101.2}{10.244.101.2:9300}{master=false}])
[2015-11-25 14:31:10,670][INFO ][cluster.service          ] [Beta Ray Bill] added {{Anomalito}{H90Ozq1CTYO60oMOWd2VfA}{10.244.101.3}{10.244.101.3:9300}{data=false, master=true},}, reason: zen-disco-join(join from node[{Anomalito}{H90Ozq1CTYO60oMOWd2VfA}{10.244.101.3}{10.244.101.3:9300}{data=false, master=true}])
[2015-11-25 14:31:10,939][INFO ][cluster.service          ] [Beta Ray Bill] added {{Viper}{WtZLz13oRfSEDnweayWABw}{10.244.66.3}{10.244.66.3:9300}{data=false, master=true},}, reason: zen-disco-join(join from node[{Viper}{WtZLz13oRfSEDnweayWABw}{10.244.66.3}{10.244.66.3:9300}{data=false, master=true}])
[2015-11-25 14:32:08,522][INFO ][cluster.service          ] [Beta Ray Bill] added {{Necromantra}{z1BrCL1SRW23i8aID0l2rw}{10.244.85.3}{10.244.85.3:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{Necromantra}{z1BrCL1SRW23i8aID0l2rw}{10.244.85.3}{10.244.85.3:9300}{data=false, master=false}])
[2015-11-25 14:32:10,712][INFO ][cluster.service          ] [Beta Ray Bill] added {{Protector}{-PqouJYzTJK_AJj4uJJaQg}{10.244.85.4}{10.244.85.4:9300}{master=false},}, reason: zen-disco-join(join from node[{Protector}{-PqouJYzTJK_AJj4uJJaQg}{10.244.85.4}{10.244.85.4:9300}{master=false}])
```

### Access the service

*Don't forget* that services in Kubernetes are only acessible from containers in the cluster. For different behavior you should [configure the creation of an external load-balancer](http://kubernetes.io/v1.1/docs/user-guide/services.html#type-loadbalancer). While it's supported within this example service descriptor, its usage is out of scope of this document, for now.

```
$ kubectl get service elasticsearch
NAME            CLUSTER_IP      EXTERNAL_IP   PORT(S)    SELECTOR                              AGE
elasticsearch   10.100.116.17                 9200/TCP   component=elasticsearch,role=client   15m
```

From any host on your cluster (that's running `kube-proxy`), run:

```
curl http://10.100.116.17:9200
```

You should see something similar to the following:

```json
$ curl http://10.100.116.17:9200
{
  "name" : "Demogoblin",
  "cluster_name" : "myesdb",
  "version" : {
    "number" : "2.1.0",
    "build_hash" : "72cd1f1a3eee09505e036106146dc1949dc5dc87",
    "build_timestamp" : "2015-11-18T22:40:03Z",
    "build_snapshot" : false,
    "lucene_version" : "5.3.1"
  },
  "tagline" : "You Know, for Search"
}
```

Or if you want to see cluster information:

```
curl http://10.100.116.17:9200/_cluster/health?pretty
```

You should see something similar to the following:

```json
{
  "cluster_name" : "myesdb",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 7,
  "number_of_data_nodes" : 2,
  "active_primary_shards" : 0,
  "active_shards" : 0,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 0,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 100.0
}
```
