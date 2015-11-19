# kubernetes-elasticsearch-cluster
Elasticsearch (2.0.0) cluster on top of Kubernetes made easy.

Elasticsearch best-practices recommend to separate nodes in three roles:
* `Master` nodes - intended for clustering management only, no data, no HTTP API
* `Client` nodes - intended for client usage, no data, with HTTP API
* `Data` nodes - intended for storing and indexing your data, no HTTP API

Given this, I'm hereby making possible for you to scale as needed. For instance, a good strong scenario could be 3 master, 2 client, 5 data nodes.

*Attention:* As of the moment, Kubernetes pod descriptors use an `emptyDir` for storing data in each data node container. This is meant to be for the sake of simplicity and should be adapted according to your storage needs.

## Pre-requisites

* Kubernetes cluster (tested with v1.1.1 on top of [Vagrant + CoreOS](https://github.com/pires/kubernetes-vagrant-coreos-cluster))
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
NAME                      CLUSTER_IP      EXTERNAL_IP   PORT(S)         SELECTOR                              AGE
elasticsearch             10.100.13.117                 9200/TCP        component=elasticsearch,role=client   29m
elasticsearch-discovery   10.100.232.72   <none>        9300/TCP        component=elasticsearch,role=master   29m
kube-dns                  10.100.0.10     <none>        53/UDP,53/TCP   k8s-app=kube-dns                      50m
kubernetes                10.100.0.1      <none>        443/TCP         <none>                                53m
CONTROLLER   CONTAINER(S)   IMAGE(S)                                              SELECTOR                              REPLICAS   AGE
es-client    es-client      quay.io/pires/docker-elasticsearch-kubernetes:2.0.0   component=elasticsearch,role=client   1          7m
es-data      es-data        quay.io/pires/docker-elasticsearch-kubernetes:2.0.0   component=elasticsearch,role=data     1          7m
es-master    es-master      quay.io/pires/docker-elasticsearch-kubernetes:2.0.0   component=elasticsearch,role=master   1          29m
kube-dns     etcd           gcr.io/google_containers/etcd:2.0.9                   k8s-app=kube-dns                      1          50m
             kube2sky       gcr.io/google_containers/kube2sky:1.11
             skydns         gcr.io/google_containers/skydns:2015-03-11-001
NAME              READY     STATUS    RESTARTS   AGE
es-client-5lb50   1/1       Running   0          7m
es-data-0x7e0     1/1       Running   0          7m
es-master-qsovc   1/1       Running   0          29m
kube-dns-vkv57    3/3       Running   0          50m
```

```
$ kubectl logs es-master-qsovc
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
[2015-11-19 20:26:13,193][INFO ][node                     ] [Doctor Spectrum] version[2.0.0], pid[10], build[de54438/2015-10-22T08:09:48Z]
[2015-11-19 20:26:13,199][INFO ][node                     ] [Doctor Spectrum] initializing ...
[2015-11-19 20:26:13,548][INFO ][plugins                  ] [Doctor Spectrum] loaded [cloud-kubernetes], sites []
[2015-11-19 20:26:13,590][INFO ][env                      ] [Doctor Spectrum] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [14.2gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2015-11-19 20:26:16,413][INFO ][node                     ] [Doctor Spectrum] initialized
[2015-11-19 20:26:16,413][INFO ][node                     ] [Doctor Spectrum] starting ...
[2015-11-19 20:26:16,602][INFO ][transport                ] [Doctor Spectrum] publish_address {10.244.81.2:9300}, bound_addresses {10.244.81.2:9300}
[2015-11-19 20:26:16,641][INFO ][discovery                ] [Doctor Spectrum] myesdb/nm9NRSuXT7mfJ0YGy-CFFA
[2015-11-19 20:26:21,391][INFO ][cluster.service          ] [Doctor Spectrum] new_master {Doctor Spectrum}{nm9NRSuXT7mfJ0YGy-CFFA}{10.244.81.2}{10.244.81.2:9300}{data=false, master=true}, reason: zen-disco-join(elected_as_master, [0] joins received)
[2015-11-19 20:26:21,408][INFO ][node                     ] [Doctor Spectrum] started
[2015-11-19 20:26:21,443][INFO ][gateway                  ] [Doctor Spectrum] recovered [0] indices into cluster_state
[2015-11-19 20:48:27,303][INFO ][cluster.service          ] [Doctor Spectrum] added {{Termagaira}{rSv0h7NXRg2_Z1MY7fTvRg}{10.244.63.2}{10.244.63.2:9300}{master=false},}, reason: zen-disco-join(join from node[{Termagaira}{rSv0h7NXRg2_Z1MY7fTvRg}{10.244.63.2}{10.244.63.2:9300}{master=false}])
[2015-11-19 20:48:31,288][INFO ][cluster.service          ] [Doctor Spectrum] added {{War V}{Rq6n51RlRFyt1VIgG54byQ}{10.244.13.2}{10.244.13.2:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{War V}{Rq6n51RlRFyt1VIgG54byQ}{10.244.13.2}{10.244.13.2:9300}{data=false, master=false}])
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
es-client-44h9j   1/1       Running   0          6m
es-client-5lb50   1/1       Running   0          40m
es-data-0x7e0     1/1       Running   0          40m
es-data-jidcs     1/1       Running   0          1m
es-master-ic3fd   1/1       Running   0          8m
es-master-qsovc   1/1       Running   0          1h
es-master-vvuba   1/1       Running   0          8m
kube-dns-vkv57    3/3       Running   0          1h
```

Let's take another look of the Elasticsearch master logs:
```
$ kubectl logs es-master-qsovc
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
[2015-11-19 20:26:13,193][INFO ][node                     ] [Doctor Spectrum] version[2.0.0], pid[10], build[de54438/2015-10-22T08:09:48Z]
[2015-11-19 20:26:13,199][INFO ][node                     ] [Doctor Spectrum] initializing ...
[2015-11-19 20:26:13,548][INFO ][plugins                  ] [Doctor Spectrum] loaded [cloud-kubernetes], sites []
[2015-11-19 20:26:13,590][INFO ][env                      ] [Doctor Spectrum] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [14.2gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2015-11-19 20:26:16,413][INFO ][node                     ] [Doctor Spectrum] initialized
[2015-11-19 20:26:16,413][INFO ][node                     ] [Doctor Spectrum] starting ...
[2015-11-19 20:26:16,602][INFO ][transport                ] [Doctor Spectrum] publish_address {10.244.81.2:9300}, bound_addresses {10.244.81.2:9300}
[2015-11-19 20:26:16,641][INFO ][discovery                ] [Doctor Spectrum] myesdb/nm9NRSuXT7mfJ0YGy-CFFA
[2015-11-19 20:26:21,391][INFO ][cluster.service          ] [Doctor Spectrum] new_master {Doctor Spectrum}{nm9NRSuXT7mfJ0YGy-CFFA}{10.244.81.2}{10.244.81.2:9300}{data=false, master=true}, reason: zen-disco-join(elected_as_master, [0] joins received)
[2015-11-19 20:26:21,408][INFO ][node                     ] [Doctor Spectrum] started
[2015-11-19 20:26:21,443][INFO ][gateway                  ] [Doctor Spectrum] recovered [0] indices into cluster_state
[2015-11-19 20:48:27,303][INFO ][cluster.service          ] [Doctor Spectrum] added {{Termagaira}{rSv0h7NXRg2_Z1MY7fTvRg}{10.244.63.2}{10.244.63.2:9300}{master=false},}, reason: zen-disco-join(join from node[{Termagaira}{rSv0h7NXRg2_Z1MY7fTvRg}{10.244.63.2}{10.244.63.2:9300}{master=false}])
[2015-11-19 20:48:31,288][INFO ][cluster.service          ] [Doctor Spectrum] added {{War V}{Rq6n51RlRFyt1VIgG54byQ}{10.244.13.2}{10.244.13.2:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{War V}{Rq6n51RlRFyt1VIgG54byQ}{10.244.13.2}{10.244.13.2:9300}{data=false, master=false}])
[2015-11-19 21:17:54,140][INFO ][cluster.service          ] [Doctor Spectrum] added {{Crossbones}{IVfzPHf8QkS8EX68pEv9oQ}{10.244.63.3}{10.244.63.3:9300}{data=false, master=true},}, reason: zen-disco-join(join from node[{Crossbones}{IVfzPHf8QkS8EX68pEv9oQ}{10.244.63.3}{10.244.63.3:9300}{data=false, master=true}])
[2015-11-19 21:17:54,281][INFO ][cluster.service          ] [Doctor Spectrum] added {{Lady Lark}{TSoI37adQPaNpEDJ2c9bsw}{10.244.13.3}{10.244.13.3:9300}{data=false, master=true},}, reason: zen-disco-join(join from node[{Lady Lark}{TSoI37adQPaNpEDJ2c9bsw}{10.244.13.3}{10.244.13.3:9300}{data=false, master=true}])
[2015-11-19 21:20:33,233][INFO ][cluster.service          ] [Doctor Spectrum] added {{Ben Urich}{P0EqCsVGRhOI5IRAWH34yg}{10.244.81.3}{10.244.81.3:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{Ben Urich}{P0EqCsVGRhOI5IRAWH34yg}{10.244.81.3}{10.244.81.3:9300}{data=false, master=false}])
[2015-11-19 21:25:41,480][INFO ][cluster.service          ] [Doctor Spectrum] added {{Cassandra Nova}{DeElUqr2QdyifWwJU68hcw}{10.244.13.4}{10.244.13.4:9300}{master=false},}, reason: zen-disco-join(join from node[{Cassandra Nova}{DeElUqr2QdyifWwJU68hcw}{10.244.13.4}{10.244.13.4:9300}{master=false}])
```

### Access the service

*Don't forget* that services in Kubernetes are only acessible from containers in the cluster. For different behavior you should [configure the creation of an external load-balancer](http://kubernetes.io/v1.1/docs/user-guide/services.html#type-loadbalancer). While it's supported within this example service descriptor, its usage is out of scope of this document, for now.

```
$ kubectl get service elasticsearch
NAME            CLUSTER_IP      EXTERNAL_IP   PORT(S)    SELECTOR                              AGE
elasticsearch   10.100.13.117                 9200/TCP   component=elasticsearch,role=client   1h
```

From any host on your cluster (that's running `kube-proxy`), run:

```
curl http://10.100.13.117:9200
```

You should see something similar to the following:

```json
{
  "name" : "War V",
  "cluster_name" : "myesdb",
  "version" : {
    "number" : "2.0.0",
    "build_hash" : "de54438d6af8f9340d50c5c786151783ce7d6be5",
    "build_timestamp" : "2015-10-22T08:09:48Z",
    "build_snapshot" : false,
    "lucene_version" : "5.2.1"
  },
  "tagline" : "You Know, for Search"
}
```

Or if you want to see cluster information:

```
curl http://10.100.13.117:9200/_cluster/health?pretty
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
