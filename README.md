# kubernetes-elasticsearch-cluster
Elasticsearch (2.3.3) cluster on top of Kubernetes made easy.

Elasticsearch best-practices recommend to separate nodes in three roles:
* `Master` nodes - intended for clustering management only, no data, no HTTP API
* `Client` nodes - intended for client usage, no data, with HTTP API
* `Data` nodes - intended for storing and indexing your data, no HTTP API

Given this, I'm hereby making possible for you to scale as needed. For instance, a good strong scenario could be 3 master, 2 client, 5 data nodes.

*Attention:* As of the moment, Kubernetes pod descriptors use an `emptyDir` for storing data in each data node container. This is meant to be for the sake of simplicity and should be adapted according to your storage needs.

## Pre-requisites

* Kubernetes cluster (tested with v1.2.4 on top of [Vagrant + CoreOS](https://github.com/pires/kubernetes-vagrant-coreos-cluster))
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
NAME                      CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
elasticsearch             10.100.202.107                 9200/TCP   10m
elasticsearch-discovery   10.100.99.125    <none>        9300/TCP   10m
kubernetes                10.100.0.1       <none>        443/TCP    21h
NAME                      DESIRED          CURRENT       AGE
es-client                 1                1             5m
es-data                   1                1             4m
es-master                 1                1             7m
NAME                      READY            STATUS        RESTARTS   AGE
es-client-5b1oc           1/1              Running       0          5m
es-data-0s6eg             1/1              Running       0          4m
es-master-tile7           1/1              Running       0          7m
```

```
$ kubectl logs -f es-master-tile7
(...)
[2016-06-08 15:07:22,363][INFO ][node                     ] [Stranger] version[2.3.3], pid[172], build[b9e4a6a/2016-04-21T16:03:47Z]
[2016-06-08 15:07:22,370][INFO ][node                     ] [Stranger] initializing ...
[2016-06-08 15:07:23,373][INFO ][plugins                  ] [Stranger] modules [reindex, lang-expression, lang-groovy], plugins [cloud-kubernetes], sites []
[2016-06-08 15:07:23,452][INFO ][env                      ] [Stranger] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [14.1gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2016-06-08 15:07:23,455][INFO ][env                      ] [Stranger] heap size [1015.6mb], compressed ordinary object pointers [true]
[2016-06-08 15:07:28,088][INFO ][node                     ] [Stranger] initialized
[2016-06-08 15:07:28,089][INFO ][node                     ] [Stranger] starting ...
[2016-06-08 15:07:28,233][INFO ][transport                ] [Stranger] publish_address {10.244.101.2:9300}, bound_addresses {10.244.101.2:9300}
[2016-06-08 15:07:28,239][INFO ][discovery                ] [Stranger] myesdb/6c9o-8CyStefdhCfmsGkIg
[2016-06-08 15:07:32,714][INFO ][cluster.service          ] [Stranger] new_master {Stranger}{6c9o-8CyStefdhCfmsGkIg}{10.244.101.2}{10.244.101.2:9300}{data=false, master=true}, reason: zen-disco-join(elected_as_master, [0] joins received)
[2016-06-08 15:07:32,721][INFO ][node                     ] [Stranger] started
[2016-06-08 15:07:32,763][INFO ][gateway                  ] [Stranger] recovered [0] indices into cluster_state
[2016-06-08 15:09:16,291][INFO ][cluster.service          ] [Stranger] added {{Tower}{Er6hmt5yTlO3N4HhpWl-Tg}{10.244.19.2}{10.244.19.2:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{Tower}{Er6hmt5yTlO3N4HhpWl-Tg}{10.244.19.2}{10.244.19.2:9300}{data=false, master=false}])
[2016-06-08 15:10:39,119][INFO ][cluster.service          ] [Stranger] added {{Skywalker}{bY9BsKYmRhqcXpcqMDFKvw}{10.244.64.2}{10.244.64.2:9300}{master=false},}, reason: zen-disco-join(join from node[{Skywalker}{bY9BsKYmRhqcXpcqMDFKvw}{10.244.64.2}{10.244.64.2:9300}{master=false}])
```

As you can assert, the cluster is up and running. Easy, wasn't it?

### Scale

Scaling each type of node to handle your cluster is as easy as:

```
kubectl scale --replicas 3 rc/es-master
kubectl scale --replicas 2 rc/es-client
kubectl scale --replicas 2 rc/es-data
```

Did it work?

```
$ kubectl get rc,pods
NAME              DESIRED   CURRENT   AGE
es-client         2         2         7m
es-data           2         2         6m
es-master         3         3         9m
NAME              READY     STATUS    RESTARTS   AGE
es-client-5b1oc   1/1       Running   0          7m
es-client-t44y2   1/1       Running   0          29s
es-data-0s6eg     1/1       Running   0          6m
es-data-3i5kh     1/1       Running   0          15s
es-master-ctfjz   1/1       Running   0          1m
es-master-tile7   1/1       Running   0          9m
es-master-tk14l   1/1       Running   0          1m
```

Let's take another look at the logs of one of the Elasticsearch `master` nodes:

```
$ kubectl logs -f es-master-tile7
(...)
[2016-06-08 15:07:22,363][INFO ][node                     ] [Stranger] version[2.3.3], pid[172], build[b9e4a6a/2016-04-21T16:03:47Z]
[2016-06-08 15:07:22,370][INFO ][node                     ] [Stranger] initializing ...
[2016-06-08 15:07:23,373][INFO ][plugins                  ] [Stranger] modules [reindex, lang-expression, lang-groovy], plugins [cloud-kubernetes], sites []
[2016-06-08 15:07:23,452][INFO ][env                      ] [Stranger] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [14.1gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2016-06-08 15:07:23,455][INFO ][env                      ] [Stranger] heap size [1015.6mb], compressed ordinary object pointers [true]
[2016-06-08 15:07:28,088][INFO ][node                     ] [Stranger] initialized
[2016-06-08 15:07:28,089][INFO ][node                     ] [Stranger] starting ...
[2016-06-08 15:07:28,233][INFO ][transport                ] [Stranger] publish_address {10.244.101.2:9300}, bound_addresses {10.244.101.2:9300}
[2016-06-08 15:07:28,239][INFO ][discovery                ] [Stranger] myesdb/6c9o-8CyStefdhCfmsGkIg
[2016-06-08 15:07:32,714][INFO ][cluster.service          ] [Stranger] new_master {Stranger}{6c9o-8CyStefdhCfmsGkIg}{10.244.101.2}{10.244.101.2:9300}{data=false, master=true}, reason: zen-disco-join(elected_as_master, [0] joins received)
[2016-06-08 15:07:32,721][INFO ][node                     ] [Stranger] started
[2016-06-08 15:07:32,763][INFO ][gateway                  ] [Stranger] recovered [0] indices into cluster_state
[2016-06-08 15:09:16,291][INFO ][cluster.service          ] [Stranger] added {{Tower}{Er6hmt5yTlO3N4HhpWl-Tg}{10.244.19.2}{10.244.19.2:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{Tower}{Er6hmt5yTlO3N4HhpWl-Tg}{10.244.19.2}{10.244.19.2:9300}{data=false, master=false}])
[2016-06-08 15:10:39,119][INFO ][cluster.service          ] [Stranger] added {{Skywalker}{bY9BsKYmRhqcXpcqMDFKvw}{10.244.64.2}{10.244.64.2:9300}{master=false},}, reason: zen-disco-join(join from node[{Skywalker}{bY9BsKYmRhqcXpcqMDFKvw}{10.244.64.2}{10.244.64.2:9300}{master=false}])
[2016-06-08 15:15:46,512][INFO ][cluster.service          ] [Stranger] added {{Norman Osborn}{Mxptb3y3Qp6R6xq9eddEzg}{10.244.19.3}{10.244.19.3:9300}{data=false, master=true},}, reason: zen-disco-join(join from node[{Norman Osborn}{Mxptb3y3Qp6R6xq9eddEzg}{10.244.19.3}{10.244.19.3:9300}{data=false, master=true}])
[2016-06-08 15:15:47,184][INFO ][cluster.service          ] [Stranger] added {{Deathlok}{OQEV0LTSQh2Q1k7WVNCUBw}{10.244.64.3}{10.244.64.3:9300}{data=false, master=true},}, reason: zen-disco-join(join from node[{Deathlok}{OQEV0LTSQh2Q1k7WVNCUBw}{10.244.64.3}{10.244.64.3:9300}{data=false, master=true}])
[2016-06-08 15:16:12,750][INFO ][cluster.service          ] [Stranger] added {{Hitman}{KW69CqVrQwyFbB1mbndK5w}{10.244.101.3}{10.244.101.3:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{Hitman}{KW69CqVrQwyFbB1mbndK5w}{10.244.101.3}{10.244.101.3:9300}{data=false, master=false}])
[2016-06-08 15:16:34,865][INFO ][cluster.service          ] [Stranger] added {{Trapster}{vXWqivMrRKefxWaf_FJW6g}{10.244.19.4}{10.244.19.4:9300}{master=false},}, reason: zen-disco-join(join from node[{Trapster}{vXWqivMrRKefxWaf_FJW6g}{10.244.19.4}{10.244.19.4:9300}{master=false}])
```

### Access the service

*Don't forget* that services in Kubernetes are only acessible from containers in the cluster. For different behavior you should [configure the creation of an external load-balancer](http://kubernetes.io/v1.1/docs/user-guide/services.html#type-loadbalancer). While it's supported within this example service descriptor, its usage is out of scope of this document, for now.

```
$ kubectl get svc elasticsearch
NAME            CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
elasticsearch   10.100.202.107                 9200/TCP   13m
```

From any host on your cluster (that's running `kube-proxy`), run:

```
curl http://10.100.202.107:9200
```

You should see something similar to the following:

```json
{
  "name" : "Hitman",
  "cluster_name" : "myesdb",
  "version" : {
    "number" : "2.3.3",
    "build_hash" : "b9e4a6acad4008027e4038f6abed7f7dba346f94",
    "build_timestamp" : "2016-06-02T16:03:47Z",
    "build_snapshot" : false,
    "lucene_version" : "5.5.0"
  },
  "tagline" : "You Know, for Search"
}
```

Or if you want to see cluster information:

```
curl http://10.100.202.107:9200/_cluster/health?pretty
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

*Note:* If you are running Elasticsearch in a non-default namespace then you need to create two service accounts for both the default namespace and the custom one; this is especially important if the ability to scale data nodes is a requirement!
