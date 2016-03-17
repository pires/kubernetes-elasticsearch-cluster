# kubernetes-elasticsearch-cluster
Elasticsearch (2.2.1) cluster on top of Kubernetes made easy.

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
NAME                      CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
elasticsearch             10.100.45.242                 9200/TCP   2m
elasticsearch-discovery   10.100.32.42    <none>        9300/TCP   2m
kubernetes                10.100.0.1      <none>        443/TCP    16m
NAME                      DESIRED         CURRENT       AGE
es-client                 1               1             1m
es-data                   1               1             1m
es-master                 1               1             2m
NAME                      READY           STATUS        RESTARTS   AGE
es-client-faz0j           1/1             Running       0          1m
es-data-ggcnf             1/1             Running       0          1m
es-master-ngb67           1/1             Running       0          2m
```

```
$ kubectl logs es-master-ngb67
[2016-03-17 18:13:18,220][INFO ][node                     ] [Ms. Steed] version[2.2.1], pid[173], build[d045fc2/2016-03-09T09:38:54Z]
[2016-03-17 18:13:18,222][INFO ][node                     ] [Ms. Steed] initializing ...
[2016-03-17 18:13:19,160][INFO ][plugins                  ] [Ms. Steed] modules [lang-expression, lang-groovy], plugins [cloud-kubernetes], sites []
[2016-03-17 18:13:19,198][INFO ][env                      ] [Ms. Steed] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [14.1gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2016-03-17 18:13:19,199][INFO ][env                      ] [Ms. Steed] heap size [1015.6mb], compressed ordinary object pointers [true]
[2016-03-17 18:13:23,317][INFO ][node                     ] [Ms. Steed] initialized
[2016-03-17 18:13:23,322][INFO ][node                     ] [Ms. Steed] starting ...
[2016-03-17 18:13:23,437][INFO ][transport                ] [Ms. Steed] publish_address {10.244.66.2:9300}, bound_addresses {10.244.66.2:9300}
[2016-03-17 18:13:23,453][INFO ][discovery                ] [Ms. Steed] myesdb/sCP2pgSJT4iP4CyUlfZ_nQ
[2016-03-17 18:13:27,982][INFO ][cluster.service          ] [Ms. Steed] new_master {Ms. Steed}{sCP2pgSJT4iP4CyUlfZ_nQ}{10.244.66.2}{10.244.66.2:9300}{data=false, master=true}, reason: zen-disco-join(elected_as_master, [0] joins received)
[2016-03-17 18:13:27,991][INFO ][node                     ] [Ms. Steed] started
[2016-03-17 18:13:28,059][INFO ][gateway                  ] [Ms. Steed] recovered [0] indices into cluster_state
[2016-03-17 18:14:20,690][INFO ][cluster.service          ] [Ms. Steed] added {{Stinger}{-AUBFBNAQ5W9ywX3dJQ1Ow}{10.244.23.2}{10.244.23.2:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{Stinger}{-AUBFBNAQ5W9ywX3dJQ1Ow}{10.244.23.2}{10.244.23.2:9300}{data=false, master=false}])
[2016-03-17 18:14:27,816][INFO ][cluster.service          ] [Ms. Steed] added {{Scarecrow}{_L8Vlz6iTiaxxRVeMis-8Q}{10.244.29.2}{10.244.29.2:9300}{master=false},}, reason: zen-disco-join(join from node[{Scarecrow}{_L8Vlz6iTiaxxRVeMis-8Q}{10.244.29.2}{10.244.29.2:9300}{master=false}])
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
NAME                      DESIRED         CURRENT       AGE
es-client                 2               2             3m
es-data                   2               2             3m
es-master                 3               3             4m
NAME                      READY           STATUS        RESTARTS   AGE
es-client-a1fgb           1/1             Running       0          39s
es-client-faz0j           1/1             Running       0          3m
es-data-ggcnf             1/1             Running       0          3m
es-data-quklg             1/1             Running       0          22s
es-master-2axzd           1/1             Running       0          1m
es-master-j8n2v           1/1             Running       0          1m
es-master-ngb67           1/1             Running       0          3m
```

Let's take another look at the logs of one of the Elasticsearch `master` nodes:
```
$ kubectl logs es-master-ngb67
[2016-03-17 18:13:18,220][INFO ][node                     ] [Ms. Steed] version[2.2.1], pid[173], build[d045fc2/2016-03-09T09:38:54Z]
[2016-03-17 18:13:18,222][INFO ][node                     ] [Ms. Steed] initializing ...
[2016-03-17 18:13:19,160][INFO ][plugins                  ] [Ms. Steed] modules [lang-expression, lang-groovy], plugins [cloud-kubernetes], sites []
[2016-03-17 18:13:19,198][INFO ][env                      ] [Ms. Steed] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [14.1gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2016-03-17 18:13:19,199][INFO ][env                      ] [Ms. Steed] heap size [1015.6mb], compressed ordinary object pointers [true]
[2016-03-17 18:13:23,317][INFO ][node                     ] [Ms. Steed] initialized
[2016-03-17 18:13:23,322][INFO ][node                     ] [Ms. Steed] starting ...
[2016-03-17 18:13:23,437][INFO ][transport                ] [Ms. Steed] publish_address {10.244.66.2:9300}, bound_addresses {10.244.66.2:9300}
[2016-03-17 18:13:23,453][INFO ][discovery                ] [Ms. Steed] myesdb/sCP2pgSJT4iP4CyUlfZ_nQ
[2016-03-17 18:13:27,982][INFO ][cluster.service          ] [Ms. Steed] new_master {Ms. Steed}{sCP2pgSJT4iP4CyUlfZ_nQ}{10.244.66.2}{10.244.66.2:9300}{data=false, master=true}, reason: zen-disco-join(elected_as_master, [0] joins received)
[2016-03-17 18:13:27,991][INFO ][node                     ] [Ms. Steed] started
[2016-03-17 18:13:28,059][INFO ][gateway                  ] [Ms. Steed] recovered [0] indices into cluster_state
[2016-03-17 18:14:20,690][INFO ][cluster.service          ] [Ms. Steed] added {{Stinger}{-AUBFBNAQ5W9ywX3dJQ1Ow}{10.244.23.2}{10.244.23.2:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{Stinger}{-AUBFBNAQ5W9ywX3dJQ1Ow}{10.244.23.2}{10.244.23.2:9300}{data=false, master=false}])
[2016-03-17 18:14:27,816][INFO ][cluster.service          ] [Ms. Steed] added {{Scarecrow}{_L8Vlz6iTiaxxRVeMis-8Q}{10.244.29.2}{10.244.29.2:9300}{master=false},}, reason: zen-disco-join(join from node[{Scarecrow}{_L8Vlz6iTiaxxRVeMis-8Q}{10.244.29.2}{10.244.29.2:9300}{master=false}])
[2016-03-17 18:15:46,712][INFO ][cluster.service          ] [Ms. Steed] added {{Lament}{h8iIs5pDS66OwvNgcvAhxw}{10.244.29.3}{10.244.29.3:9300}{data=false, master=true},}, reason: zen-disco-join(join from node[{Lament}{h8iIs5pDS66OwvNgcvAhxw}{10.244.29.3}{10.244.29.3:9300}{data=false, master=true}])
[2016-03-17 18:15:46,923][INFO ][cluster.service          ] [Ms. Steed] added {{Ghost Girl}{XdV8zMZTQuyte6LrFBYDEA}{10.244.23.3}{10.244.23.3:9300}{data=false, master=true},}, reason: zen-disco-join(join from node[{Ghost Girl}{XdV8zMZTQuyte6LrFBYDEA}{10.244.23.3}{10.244.23.3:9300}{data=false, master=true}])
[2016-03-17 18:16:20,864][INFO ][cluster.service          ] [Ms. Steed] added {{Brian Braddock}{1lN4WhErRW2GHBEUtlqtLQ}{10.244.66.3}{10.244.66.3:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{Brian Braddock}{1lN4WhErRW2GHBEUtlqtLQ}{10.244.66.3}{10.244.66.3:9300}{data=false, master=false}])
[2016-03-17 18:16:38,127][INFO ][cluster.service          ] [Ms. Steed] added {{Shiva}{DggeYkKvQQGid0dG5cd_Yg}{10.244.66.4}{10.244.66.4:9300}{master=false},}, reason: zen-disco-join(join from node[{Shiva}{DggeYkKvQQGid0dG5cd_Yg}{10.244.66.4}{10.244.66.4:9300}{master=false}])
```

### Access the service

*Don't forget* that services in Kubernetes are only acessible from containers in the cluster. For different behavior you should [configure the creation of an external load-balancer](http://kubernetes.io/v1.1/docs/user-guide/services.html#type-loadbalancer). While it's supported within this example service descriptor, its usage is out of scope of this document, for now.

```
$ kubectl get service elasticsearch
NAME                      CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
elasticsearch             10.100.45.242                 9200/TCP   5m
```

From any host on your cluster (that's running `kube-proxy`), run:

```
curl http://10.100.45.242:9200
```

You should see something similar to the following:

```json
{
  "name" : "Stinger",
  "cluster_name" : "myesdb",
  "version" : {
    "number" : "2.2.1",
    "build_hash" : "d045fc29d1932bce18b2e65ab8b297fbf6cd41a1",
    "build_timestamp" : "2016-03-09T09:38:54Z",
    "build_snapshot" : false,
    "lucene_version" : "5.4.1"
  },
  "tagline" : "You Know, for Search"
}
```

Or if you want to see cluster information:

```
curl http://10.100.45.242:9200/_cluster/health?pretty
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
