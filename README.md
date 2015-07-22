# kubernetes-elasticsearch-cluster
Elasticsearch (1.7.0) cluster on top of Kubernetes made easy.

Elasticsearch best-practices recommend to separate nodes in three roles:
* `Master` nodes - intended for clustering management only, no data, no HTTP API
* `Load-balancer` nodes - intended for client usage, no data, with HTTP API
* `Data` nodes - intended for storing and indexing your data, no HTTP API

Given this, I'm hereby making possible for you to scale as needed. For instance, a good strong scenario could be 3 Masters, 3 Load-balancers, 5 data-nodes.

*Attention:* As of the moment, Kubernetes pod descriptors use an `emptyDir` for storing data in each data node container. This is meant to be for the sake of simplicity and should be adapted according to your storage needs.

## Pre-requisites

* Docker 1.5+
* Kubernetes cluster (tested with v1.0.1 on top of [Vagrant + CoreOS](https://github.com/pires/kubernetes-vagrant-coreos-cluster))
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
NAME                         READY     STATUS    RESTARTS   AGE
elasticsearch-data-881wf     1/1       Running   0          47s
elasticsearch-lb-tujlb       1/1       Running   0          1m
elasticsearch-master-hh4gw   1/1       Running   0          2m
```

Copy master pod identifier and check the logs:

```
kubectl logs elasticsearch-master-hh4gw
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
[2015-07-22 13:53:12,234][WARN ][bootstrap                ] Unable to lock JVM memory (ENOMEM). This can result in part of the JVM being swapped out. Increase RLIMIT_MEMLOCK (ulimit).
[2015-07-22 13:53:12,375][INFO ][node                     ] [American Samurai] version[1.7.0], pid[1], build[929b973/2015-07-16T14:31:07Z]
[2015-07-22 13:53:12,377][INFO ][node                     ] [American Samurai] initializing ...
[2015-07-22 13:53:12,513][INFO ][plugins                  ] [American Samurai] loaded [cloud-kubernetes], sites []
[2015-07-22 13:53:12,551][INFO ][env                      ] [American Samurai] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [14.4gb], net total_space [15.5gb], types [ext4]
[2015-07-22 13:53:16,445][INFO ][node                     ] [American Samurai] initialized
[2015-07-22 13:53:16,446][INFO ][node                     ] [American Samurai] starting ...
[2015-07-22 13:53:16,676][INFO ][transport                ] [American Samurai] bound_address {inet[/0:0:0:0:0:0:0:0:9300]}, publish_address {inet[/10.244.78.4:9300]}
[2015-07-22 13:53:16,709][INFO ][discovery                ] [American Samurai] elasticsearch-k8s/dlkCkOJaQ4SkfUPfAPNubQ
[2015-07-22 13:53:22,631][INFO ][cluster.service          ] [American Samurai] new_master [American Samurai][dlkCkOJaQ4SkfUPfAPNubQ][elasticsearch-master-hh4gw][inet[/10.244.78.4:9300]]{data=false, master=true}, reason: zen-disco-join (elected_as_master)
[2015-07-22 13:53:22,666][INFO ][node                     ] [American Samurai] started
[2015-07-22 13:53:22,704][INFO ][gateway                  ] [American Samurai] recovered [0] indices into cluster_state
[2015-07-22 13:54:24,682][INFO ][cluster.service          ] [American Samurai] added {[Warlock][zvGs3UQ8QE-uxBaqXF5Prw][elasticsearch-lb-tujlb][inet[/10.244.78.5:9300]]{data=false, master=false},}, reason: zen-disco-receive(join from node[[Warlock][zvGs3UQ8QE-uxBaqXF5Prw][elasticsearch-lb-tujlb][inet[/10.244.78.5:9300]]{data=false, master=false}])
[2015-07-22 13:54:54,744][INFO ][cluster.service          ] [American Samurai] added {[Mastermind of the UK][fpkffLbzTTy0P4ox10xJxg][elasticsearch-data-881wf][inet[/10.244.78.6:9300]]{master=false},}, reason: zen-disco-receive(join from node[[Mastermind of the UK][fpkffLbzTTy0P4ox10xJxg][elasticsearch-data-881wf][inet[/10.244.78.6:9300]]{master=false}])
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
elasticsearch   component=elasticsearch,role=load-balancer   component=elasticsearch,role=load-balancer   10.100.251.16   9200/TCP
```

From any host on your cluster (that's running `kube-proxy`):

```
curl http://10.100.251.16:9200
```

This should be what you see:

```json
{
  "status" : 200,
  "name" : "Warlock",
  "cluster_name" : "elasticsearch-k8s",
  "version" : {
    "number" : "1.7.0",
    "build_hash" : "929b9739cae115e73c346cb5f9a6f24ba735a743",
    "build_timestamp" : "2015-07-16T14:31:07Z",
    "build_snapshot" : false,
    "lucene_version" : "4.10.4"
  },
  "tagline" : "You Know, for Search"
}
```

Or if you want to see cluster information:

```
curl http://10.100.251.16:9200/_cluster/health?pretty
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
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0
}
```
