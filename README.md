# kubernetes-elasticsearch-cluster
Elasticsearch (1.6.0) cluster on top of Kubernetes made easy.

Elasticsearch best-practices recommend to separate nodes in three roles:
* `Master` nodes - intended for clustering management only, no data, no HTTP API
* `Load-balancer` nodes - intended for client usage, no data, with HTTP API
* `Data` nodes - intended for storing and indexing your data, no HTTP API

Given this, I'm hereby making possible for you to scale as needed. For instance, a good strong scenario could be 3 Masters, 3 Load-balancers, 5 data-nodes.

*Attention:* As of the moment, Kubernetes pod descriptors use an `emptyDir` for storing data in each data node container. This is meant to be for the sake of simplicity and should be adapted according to your storage needs.

## Pre-requisites

* Docker 1.5+
* Kubernetes cluster (tested with v0.19.0 on top of [Vagrant + CoreOS](https://github.com/pires/kubernetes-vagrant-coreos-cluster))
* `kubectl` configured to access your cluster master API Server

## Build images (optional)

Providing your own version of [the images automatically built from this repository](https://registry.hub.docker.com/u/pires/elasticsearch) will not be supported. This is an *optional* step. You have been warned.

## Test

### Deploy

```
kubectl create -f service-account.yaml
kubectl create -f elasticsearch-discovery-service.yaml
kubectl create -f elasticsearch-service.yaml
kubectl create -f elasticsearch-master-controller.yaml
```

Wait until `elasticsearch-master-controller` is provisioned, and
```
kubectl create -f elasticsearch-lb-controller.yaml
```

Wait until `elasticsearch-data-controller` is provisioned, and
```
kubectl create -f elasticsearch-data-controller.yaml
```

### Validate

I leave to you the steps to validate the provisioned pods, but first step is to wait for containers to be in ```RUNNING``` state and check the logs of the master (as in Elasticsearch):

```
kubectl get pods
```

You should see something like this:

```
$ kubectl get pods
NAME                         READY     REASON    RESTARTS   AGE
elasticsearch-data-3206h     1/1       Running   0          5m
elasticsearch-lb-ti80z       1/1       Running   0          1m
elasticsearch-master-l4xc8   1/1       Running   0          7m
```

Copy master pod identifier and check the logs:

```
kubectl logs elasticsearch-master-l4xc8 elasticsearch-master
```

You should see something like this:

```
$ kubectl logs elasticsearch-master-i0x8d elasticsearch-master
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
[2015-06-24 23:59:14,009][WARN ][bootstrap                ] Unable to lock JVM memory (ENOMEM). This can result in part of the JVM being swapped out. Increase RLIMIT_MEMLOCK (ulimit).
[2015-06-24 23:59:14,108][INFO ][node                     ] [Red Ghost] version[1.6.0], pid[1], build[cdd3ac4/2015-06-09T13:36:34Z]
[2015-06-24 23:59:14,111][INFO ][node                     ] [Red Ghost] initializing ...
[2015-06-24 23:59:14,160][INFO ][plugins                  ] [Red Ghost] loaded [cloud-kubernetes], sites []
[2015-06-24 23:59:14,219][INFO ][env                      ] [Red Ghost] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [14.3gb], net total_space [15.5gb], types [ext4]
[2015-06-24 23:59:17,584][INFO ][node                     ] [Red Ghost] initialized
[2015-06-24 23:59:17,584][INFO ][node                     ] [Red Ghost] starting ...
[2015-06-24 23:59:17,762][INFO ][transport                ] [Red Ghost] bound_address {inet[/0:0:0:0:0:0:0:0:9300]}, publish_address {inet[/10.244.51.3:9300]}
[2015-06-24 23:59:17,774][INFO ][discovery                ] [Red Ghost] elasticsearch-k8s/aZnBnidATKKxQ7G2LBabng
[2015-06-24 23:59:23,208][INFO ][cluster.service          ] [Red Ghost] new_master [Red Ghost][aZnBnidATKKxQ7G2LBabng][elasticsearch-master-70p0s][inet[/10.244.51.3:9300]]{data=false, master=true}, reason: zen-disco-join (elected_as_master)
[2015-06-24 23:59:23,217][INFO ][node                     ] [Red Ghost] started
[2015-06-24 23:59:23,253][INFO ][gateway                  ] [Red Ghost] recovered [0] indices into cluster_state
[2015-06-25 00:07:39,631][INFO ][cluster.service          ] [Red Ghost] added {[Termagaira][GFoS_4c0Rj2R25q1y6qNGw][elasticsearch-lb-usmg3][inet[/10.244.51.4:9300]]{data=false, master=false},}, reason: zen-disco-receive(join from node[[Termagaira][GFoS_4c0Rj2R25q1y6qNGw][elasticsearch-lb-usmg3][inet[/10.244.51.4:9300]]{data=false, master=false}])
[2015-06-25 00:08:23,421][INFO ][cluster.service          ] [Red Ghost] added {[Juggernaut][m-8dg7yuTw-Bfmna3TNarA][elasticsearch-data-56u6c][inet[/10.244.51.5:9300]]{master=false},}, reason: zen-disco-receive(join from node[[Juggernaut][m-8dg7yuTw-Bfmna3TNarA][elasticsearch-data-56u6c][inet[/10.244.51.5:9300]]{master=false}])
```

As you can assert, the cluster is up and running. Easy, wasn't it?

### Scale

Scaling each type of node to handle your cluster is as easy as:

```
kubectl scale --replicas=3 rc elasticsearch-master
kubectl scale --replicas=2 rc elasticsearch-lb
kubectl scale --replicas=5 rc elasticsearch-data
```

### Access the service

*Don't forget* that services in Kubernetes are only acessible from containers in the cluster. For different behavior you should configure the creation of an external-loadbalancer, in your service. That's out of scope of this document, for now.

```
kubectl get service elasticsearch
```

You should see something like this:

```
$ kubectl get service elasticsearch
NAME            LABELS                                       SELECTOR                                     IP(S)           PORT(S)
elasticsearch   component=elasticsearch,role=load-balancer   component=elasticsearch,role=load-balancer   10.100.235.91   9200/TCP
```

From any host on your cluster (that's running `kube-proxy`):

```
curl http://10.100.235.91:9200
```

This should be what you see:

```json
{
  "status" : 200,
  "name" : "Termagaira",
  "cluster_name" : "elasticsearch-k8s",
  "version" : {
    "number" : "1.6.0",
    "build_hash" : "cdd3ac4dde4f69524ec0a14de3828cb95bbb86d0",
    "build_timestamp" : "2015-06-09T13:36:34Z",
    "build_snapshot" : false,
    "lucene_version" : "4.10.4"
  },
  "tagline" : "You Know, for Search"
}
```

Or if you want to see cluster information:

```
curl http://10.100.235.91:9200/_cluster/health?pretty
```

This should be what you see:

```json
{
  "cluster_name" : "elasticsearch-k8s",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 3,
  "number_of_data_nodes" : 1,
  "active_primary_shards" : 0,
  "active_shards" : 0,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0
}
```
