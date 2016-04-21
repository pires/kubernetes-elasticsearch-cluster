# kubernetes-elasticsearch-cluster
Elasticsearch (2.3.1) cluster on top of Kubernetes made easy.

Elasticsearch best-practices recommend to separate nodes in three roles:
* `Master` nodes - intended for clustering management only, no data, no HTTP API
* `Client` nodes - intended for client usage, no data, with HTTP API
* `Data` nodes - intended for storing and indexing your data, no HTTP API

Given this, I'm hereby making possible for you to scale as needed. For instance, a good strong scenario could be 3 master, 2 client, 5 data nodes.

*Attention:* As of the moment, Kubernetes pod descriptors use an `emptyDir` for storing data in each data node container. This is meant to be for the sake of simplicity and should be adapted according to your storage needs.

## Pre-requisites

* Kubernetes cluster (tested with v1.2.2 on top of [Vagrant + CoreOS](https://github.com/pires/kubernetes-vagrant-coreos-cluster))
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
elasticsearch             10.100.146.186                 9200/TCP   4m
elasticsearch-discovery   10.100.248.172   <none>        9300/TCP   4m
kubernetes                10.100.0.1       <none>        443/TCP    17m
NAME                      DESIRED          CURRENT       AGE
es-client                 1                1             2m
es-data                   1                1             1m
es-master                 1                1             4m
NAME                      READY            STATUS        RESTARTS   AGE
es-client-ztaj2           1/1              Running       0          2m
es-data-7jfd8             1/1              Running       0          1m
es-master-q1rgy           1/1              Running       0          4m
```

```
$ kubectl logs es-master-q1rgy
[2016-04-21 15:21:32,388][INFO ][node                     ] [Fin Fang Foom] version[2.3.1], pid[172], build[bd98092/2016-04-04T12:25:05Z]
[2016-04-21 15:21:32,392][INFO ][node                     ] [Fin Fang Foom] initializing ...
[2016-04-21 15:21:33,454][INFO ][plugins                  ] [Fin Fang Foom] modules [reindex, lang-expression, lang-groovy], plugins [cloud-kubernetes], sites []
[2016-04-21 15:21:33,501][INFO ][env                      ] [Fin Fang Foom] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [14.3gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2016-04-21 15:21:33,503][INFO ][env                      ] [Fin Fang Foom] heap size [1015.6mb], compressed ordinary object pointers [true]
[2016-04-21 15:21:38,178][INFO ][node                     ] [Fin Fang Foom] initialized
[2016-04-21 15:21:38,180][INFO ][node                     ] [Fin Fang Foom] starting ...
[2016-04-21 15:21:38,289][INFO ][transport                ] [Fin Fang Foom] publish_address {10.244.23.2:9300}, bound_addresses {10.244.23.2:9300}
[2016-04-21 15:21:38,299][INFO ][discovery                ] [Fin Fang Foom] myesdb/LbWPedczQZen3MASM6RAfg
[2016-04-21 15:21:42,788][INFO ][cluster.service          ] [Fin Fang Foom] new_master {Fin Fang Foom}{LbWPedczQZen3MASM6RAfg}{10.244.23.2}{10.244.23.2:9300}{data=false, master=true}, reason: zen-disco-join(elected_as_master, [0] joins received)
[2016-04-21 15:21:42,796][INFO ][node                     ] [Fin Fang Foom] started
[2016-04-21 15:21:42,833][INFO ][gateway                  ] [Fin Fang Foom] recovered [0] indices into cluster_state
[2016-04-21 15:23:04,980][INFO ][cluster.service          ] [Fin Fang Foom] added {{Logan}{FtB17iiOQDmV4A1AZJO0yA}{10.244.50.2}{10.244.50.2:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{Logan}{FtB17iiOQDmV4A1AZJO0yA}{10.244.50.2}{10.244.50.2:9300}{data=false, master=false}])
[2016-04-21 15:24:25,732][INFO ][cluster.service          ] [Fin Fang Foom] added {{Hoder}{mLKMmHjNQm-4CTpsdMcl7w}{10.244.80.2}{10.244.80.2:9300}{master=false},}, reason: zen-disco-join(join from node[{Hoder}{mLKMmHjNQm-4CTpsdMcl7w}{10.244.80.2}{10.244.80.2:9300}{master=false}])
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
NAME                      DESIRED          CURRENT       AGE
es-client                 2                2             5m
es-data                   2                2             3m
es-master                 3                3             6m
NAME                      READY            STATUS        RESTARTS   AGE
es-client-lp6rp           1/1              Running       0          1m
es-client-ztaj2           1/1              Running       0          5m
es-data-03iqm             1/1              Running       0          20s
es-data-7jfd8             1/1              Running       0          3m
es-master-genz7           1/1              Running       0          1m
es-master-q1rgy           1/1              Running       0          6m
es-master-v4toi           1/1              Running       0          1m
```

Let's take another look at the logs of one of the Elasticsearch `master` nodes:
```
$ kubectl logs es-master-q1rgy
[2016-04-21 15:21:32,388][INFO ][node                     ] [Fin Fang Foom] version[2.3.1], pid[172], build[bd98092/2016-04-04T12:25:05Z]
[2016-04-21 15:21:32,392][INFO ][node                     ] [Fin Fang Foom] initializing ...
[2016-04-21 15:21:33,454][INFO ][plugins                  ] [Fin Fang Foom] modules [reindex, lang-expression, lang-groovy], plugins [cloud-kubernetes], sites []
[2016-04-21 15:21:33,501][INFO ][env                      ] [Fin Fang Foom] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [14.3gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2016-04-21 15:21:33,503][INFO ][env                      ] [Fin Fang Foom] heap size [1015.6mb], compressed ordinary object pointers [true]
[2016-04-21 15:21:38,178][INFO ][node                     ] [Fin Fang Foom] initialized
[2016-04-21 15:21:38,180][INFO ][node                     ] [Fin Fang Foom] starting ...
[2016-04-21 15:21:38,289][INFO ][transport                ] [Fin Fang Foom] publish_address {10.244.23.2:9300}, bound_addresses {10.244.23.2:9300}
[2016-04-21 15:21:38,299][INFO ][discovery                ] [Fin Fang Foom] myesdb/LbWPedczQZen3MASM6RAfg
[2016-04-21 15:21:42,788][INFO ][cluster.service          ] [Fin Fang Foom] new_master {Fin Fang Foom}{LbWPedczQZen3MASM6RAfg}{10.244.23.2}{10.244.23.2:9300}{data=false, master=true}, reason: zen-disco-join(elected_as_master, [0] joins received)
[2016-04-21 15:21:42,796][INFO ][node                     ] [Fin Fang Foom] started
[2016-04-21 15:21:42,833][INFO ][gateway                  ] [Fin Fang Foom] recovered [0] indices into cluster_state
[2016-04-21 15:23:04,980][INFO ][cluster.service          ] [Fin Fang Foom] added {{Logan}{FtB17iiOQDmV4A1AZJO0yA}{10.244.50.2}{10.244.50.2:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{Logan}{FtB17iiOQDmV4A1AZJO0yA}{10.244.50.2}{10.244.50.2:9300}{data=false, master=false}])
[2016-04-21 15:24:25,732][INFO ][cluster.service          ] [Fin Fang Foom] added {{Hoder}{mLKMmHjNQm-4CTpsdMcl7w}{10.244.80.2}{10.244.80.2:9300}{master=false},}, reason: zen-disco-join(join from node[{Hoder}{mLKMmHjNQm-4CTpsdMcl7w}{10.244.80.2}{10.244.80.2:9300}{master=false}])
[2016-04-21 15:25:47,015][INFO ][cluster.service          ] [Fin Fang Foom] added {{Black King}{YCb01N39Simcop6p4iUryw}{10.244.50.3}{10.244.50.3:9300}{data=false, master=true},}, reason: zen-disco-join(join from node[{Black King}{YCb01N39Simcop6p4iUryw}{10.244.50.3}{10.244.50.3:9300}{data=false, master=true}])
[2016-04-21 15:25:47,250][INFO ][cluster.service          ] [Fin Fang Foom] added {{May "Mayday" Parker}{wbSTBy7xSDCYHCF_nV6-qg}{10.244.80.3}{10.244.80.3:9300}{data=false, master=true},}, reason: zen-disco-join(join from node[{May "Mayday" Parker}{wbSTBy7xSDCYHCF_nV6-qg}{10.244.80.3}{10.244.80.3:9300}{data=false, master=true}])
[2016-04-21 15:26:19,744][INFO ][cluster.service          ] [Fin Fang Foom] added {{Baron Blood}{F9JbdF1sTcWwT70skUsJ2Q}{10.244.23.3}{10.244.23.3:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{Baron Blood}{F9JbdF1sTcWwT70skUsJ2Q}{10.244.23.3}{10.244.23.3:9300}{data=false, master=false}])
[2016-04-21 15:27:15,024][INFO ][cluster.service          ] [Fin Fang Foom] added {{Morpheus}{orXM2EuMSzqyNN1Lx-LZ1g}{10.244.23.4}{10.244.23.4:9300}{master=false},}, reason: zen-disco-join(join from node[{Morpheus}{orXM2EuMSzqyNN1Lx-LZ1g}{10.244.23.4}{10.244.23.4:9300}{master=false}])
```

### Access the service

*Don't forget* that services in Kubernetes are only acessible from containers in the cluster. For different behavior you should [configure the creation of an external load-balancer](http://kubernetes.io/v1.1/docs/user-guide/services.html#type-loadbalancer). While it's supported within this example service descriptor, its usage is out of scope of this document, for now.

```
$ kubectl get svc/elasticsearch
NAME            CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
elasticsearch   10.100.146.186                 9200/TCP   7m
```

From any host on your cluster (that's running `kube-proxy`), run:

```
curl http://10.100.146.186:9200
```

You should see something similar to the following:

```json
{
  "name" : "Baron Blood",
  "cluster_name" : "myesdb",
  "version" : {
    "number" : "2.3.1",
    "build_hash" : "bd980929010aef404e7cb0843e61d0665269fc39",
    "build_timestamp" : "2016-04-04T12:25:05Z",
    "build_snapshot" : false,
    "lucene_version" : "5.5.0"
  },
  "tagline" : "You Know, for Search"
}
```

Or if you want to see cluster information:

```
curl http://10.100.146.186:9200/_cluster/health?pretty
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
