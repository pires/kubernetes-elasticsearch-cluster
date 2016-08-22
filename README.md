# kubernetes-elasticsearch-cluster
Elasticsearch (2.3.4) cluster on top of Kubernetes made easy.

Elasticsearch best-practices recommend to separate nodes in three roles:
* `Master` nodes - intended for clustering management only, no data, no HTTP API
* `Client` nodes - intended for client usage, no data, with HTTP API
* `Data` nodes - intended for storing and indexing your data, no HTTP API

Given this, I'm hereby making possible for you to scale as needed. For instance, a good strong scenario could be 3 master, 2 client, 5 data nodes.

*Attention:* As of the moment, Kubernetes pod descriptors use an `emptyDir` for storing data in each data node container. This is meant to be for the sake of simplicity and should be adapted according to your storage needs.

## Pre-requisites

* Kubernetes cluster (tested with v1.3.5 on top of [Vagrant + CoreOS](https://github.com/pires/kubernetes-vagrant-coreos-cluster))
* `kubectl` configured to access your cluster master API Server

## Build images (optional)

Providing your own version of [the images automatically built from this repository](https://github.com/pires/docker-elasticsearch-kubernetes) will not be supported. This is an *optional* step. You have been warned.

## Test

### Deploy

```
kubectl create -f es-discovery-svc.yaml
kubectl create -f es-svc.yaml
kubectl create -f es-master.yaml
```

Wait until `es-master` is provisioned, and

```
kubectl create -f es-client.yaml
```

Wait until `es-client` is provisioned, and

```
kubectl create -f es-data.yaml
```

Wait until `es-data` is provisioned.

Now, I leave up to you how to validate the cluster, but a first step is to wait for containers to be in the `Running` state and check Elasticsearch master logs:

```
$ kubectl get svc,deployment,pods
NAME                         CLUSTER-IP       EXTERNAL-IP   PORT(S)      AGE
elasticsearch                10.100.166.126   <pending>     9200/TCP     36m
elasticsearch-discovery      10.100.103.179   <none>        9300/TCP     36m
kubernetes                   10.100.0.1       <none>        443/TCP      42m
NAME                         DESIRED          CURRENT       UP-TO-DATE   AVAILABLE   AGE
es-client                    1                1             1            1           1m
es-data                      1                1             1            1           51s
es-master                    1                1             1            1           8m
NAME                         READY            STATUS        RESTARTS     AGE
es-client-1532011931-ik7ld   1/1              Running       0            1m
es-data-2129027932-9wyey     1/1              Running       0            51s
es-master-3368190183-4ux7v   1/1              Running       0            8m
```

```
$ kubectl logs -f es-master-3368190183-4ux7v
[2016-08-22 11:50:46,704][INFO ][node                     ] [The Destroyer] version[2.3.5], pid[11], build[90f439f/2016-07-27T10:36:52Z]
[2016-08-22 11:50:46,705][INFO ][node                     ] [The Destroyer] initializing ...
[2016-08-22 11:50:47,764][INFO ][plugins                  ] [The Destroyer] modules [reindex, lang-expression, lang-groovy], plugins [cloud-kubernetes], sites []
[2016-08-22 11:50:47,824][INFO ][env                      ] [The Destroyer] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [13.5gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2016-08-22 11:50:47,825][INFO ][env                      ] [The Destroyer] heap size [503.6mb], compressed ordinary object pointers [true]
[2016-08-22 11:50:52,800][INFO ][node                     ] [The Destroyer] initialized
[2016-08-22 11:50:52,800][INFO ][node                     ] [The Destroyer] starting ...
[2016-08-22 11:50:53,053][INFO ][transport                ] [The Destroyer] publish_address {10.244.72.2:9300}, bound_addresses {10.244.72.2:9300}
[2016-08-22 11:50:53,067][INFO ][discovery                ] [The Destroyer] myesdb/eO4Xb_xQSBGUvchOvMR_jA
[2016-08-22 11:50:58,757][INFO ][cluster.service          ] [The Destroyer] new_master {The Destroyer}{eO4Xb_xQSBGUvchOvMR_jA}{10.244.72.2}{10.244.72.2:9300}{data=false, master=true}, reason: zen-disco-join(elected_as_master, [0] joins received)
[2016-08-22 11:50:58,767][INFO ][node                     ] [The Destroyer] started
[2016-08-22 11:50:58,806][INFO ][gateway                  ] [The Destroyer] recovered [0] indices into cluster_state
[2016-08-22 11:57:33,414][INFO ][cluster.service          ] [The Destroyer] added {{St. John Allerdyce}{6gSJOytcRXG_zYkBksGDEA}{10.244.74.2}{10.244.74.2:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{St. John Allerdyce}{6gSJOytcRXG_zYkBksGDEA}{10.244.74.2}{10.244.74.2:9300}{data=false, master=false}])
[2016-08-22 11:58:21,927][INFO ][cluster.service          ] [The Destroyer] added {{Amergin}{JdCvogNSR5KDuawdIP5QDQ}{10.244.83.2}{10.244.83.2:9300}{master=false},}, reason: zen-disco-join(join from node[{Amergin}{JdCvogNSR5KDuawdIP5QDQ}{10.244.83.2}{10.244.83.2:9300}{master=false}])
```

As you can assert, the cluster is up and running. Easy, wasn't it?

### Scale

Scaling each type of node to handle your cluster is as easy as:

```
kubectl scale deployment es-master --replicas 3
kubectl scale deployment es-client --replicas 2
kubectl scale deployment es-data --replicas 2
```

Did it work?

```
$ kubectl get deployments,pods
NAME                         DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
es-client                    2         2         2            2           3m
es-data                      2         2         2            2           3m
es-master                    3         3         3            3           10m
NAME                         READY     STATUS    RESTARTS     AGE
es-client-1532011931-ik7ld   1/1       Running   2            3m
es-client-1532011931-ps1ly   1/1       Running   0            1m
es-data-2129027932-3asba     1/1       Running   1            1m
es-data-2129027932-9wyey     1/1       Running   0            3m
es-master-3368190183-4ux7v   1/1       Running   0            10m
es-master-3368190183-n7tcq   1/1       Running   0            1m
es-master-3368190183-v8yxv   1/1       Running   0            1m
```

Let's take another look at the logs of one of the Elasticsearch `master` nodes:

```
$ kubectl logs -f es-master-3368190183-4ux7v
[2016-08-22 11:50:46,704][INFO ][node                     ] [The Destroyer] version[2.3.5], pid[11], build[90f439f/2016-07-27T10:36:52Z]
[2016-08-22 11:50:46,705][INFO ][node                     ] [The Destroyer] initializing ...
[2016-08-22 11:50:47,764][INFO ][plugins                  ] [The Destroyer] modules [reindex, lang-expression, lang-groovy], plugins [cloud-kubernetes], sites []
[2016-08-22 11:50:47,824][INFO ][env                      ] [The Destroyer] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [13.5gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2016-08-22 11:50:47,825][INFO ][env                      ] [The Destroyer] heap size [503.6mb], compressed ordinary object pointers [true]
[2016-08-22 11:50:52,800][INFO ][node                     ] [The Destroyer] initialized
[2016-08-22 11:50:52,800][INFO ][node                     ] [The Destroyer] starting ...
[2016-08-22 11:50:53,053][INFO ][transport                ] [The Destroyer] publish_address {10.244.72.2:9300}, bound_addresses {10.244.72.2:9300}
[2016-08-22 11:50:53,067][INFO ][discovery                ] [The Destroyer] myesdb/eO4Xb_xQSBGUvchOvMR_jA
[2016-08-22 11:50:58,757][INFO ][cluster.service          ] [The Destroyer] new_master {The Destroyer}{eO4Xb_xQSBGUvchOvMR_jA}{10.244.72.2}{10.244.72.2:9300}{data=false, master=true}, reason: zen-disco-join(elected_as_master, [0] joins received)
[2016-08-22 11:50:58,767][INFO ][node                     ] [The Destroyer] started
[2016-08-22 11:50:58,806][INFO ][gateway                  ] [The Destroyer] recovered [0] indices into cluster_state
[2016-08-22 11:57:33,414][INFO ][cluster.service          ] [The Destroyer] added {{St. John Allerdyce}{6gSJOytcRXG_zYkBksGDEA}{10.244.74.2}{10.244.74.2:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{St. John Allerdyce}{6gSJOytcRXG_zYkBksGDEA}{10.244.74.2}{10.244.74.2:9300}{data=false, master=false}])
[2016-08-22 11:58:21,927][INFO ][cluster.service          ] [The Destroyer] added {{Amergin}{JdCvogNSR5KDuawdIP5QDQ}{10.244.83.2}{10.244.83.2:9300}{master=false},}, reason: zen-disco-join(join from node[{Amergin}{JdCvogNSR5KDuawdIP5QDQ}{10.244.83.2}{10.244.83.2:9300}{master=false}])
[2016-08-22 12:04:31,859][INFO ][cluster.service          ] [The Destroyer] added {{Beta Ray Bill}{oO8X5HIZQbeIb4guf8Yh_w}{10.244.74.2}{10.244.74.2:9300}{data=false, master=true},}, reason: zen-disco-join(join from node[{Beta Ray Bill}{oO8X5HIZQbeIb4guf8Yh_w}{10.244.74.2}{10.244.74.2:9300}{data=false, master=true}])
[2016-08-22 12:04:32,034][INFO ][cluster.service          ] [The Destroyer] added {{Tiger Shark}{T59rILwORPGvjmszgSBaCA}{10.244.83.3}{10.244.83.3:9300}{data=false, master=true},}, reason: zen-disco-join(join from node[{Tiger Shark}{T59rILwORPGvjmszgSBaCA}{10.244.83.3}{10.244.83.3:9300}{data=false, master=true}])
[2016-08-22 12:05:50,791][INFO ][cluster.service          ] [The Destroyer] added {{Doug and Jerry}{4j8AK5lvQPeXLGUeP7G17w}{10.244.74.3}{10.244.74.3:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{Doug and Jerry}{4j8AK5lvQPeXLGUeP7G17w}{10.244.74.3}{10.244.74.3:9300}{data=false, master=false}])

```

### Access the service

*Don't forget* that services in Kubernetes are only acessible from containers in the cluster. For different behavior you should [configure the creation of an external load-balancer](http://kubernetes.io/v1.1/docs/user-guide/services.html#type-loadbalancer). While it's supported within this example service descriptor, its usage is out of scope of this document, for now.

```
$ kubectl get svc elasticsearch
NAME            CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
elasticsearch   10.100.166.126   <pending>     9200/TCP   11m
```

From any host on your cluster (that's running `kube-proxy`), run:

```
curl http://10.100.166.126:9200
```

You should see something similar to the following:

```json
{
  "name" : "Doug and Jerry",
  "cluster_name" : "myesdb",
  "version" : {
    "number" : "2.3.5",
    "build_hash" : "e455fd0c13dceca8dbbdbb1665d068ae55dabe3f",
    "build_timestamp" : "2016-07-27T11:24:31Z",
    "build_snapshot" : false,
    "lucene_version" : "5.5.0"
  },
  "tagline" : "You Know, for Search"
}
```

Or if you want to see cluster information:

```
curl http://10.100.166.126:9200/_cluster/health?pretty
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