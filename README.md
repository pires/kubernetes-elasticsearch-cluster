# kubernetes-elasticsearch-cluster
Elasticsearch (2.4.1) cluster on top of Kubernetes made easy.

Elasticsearch best-practices recommend to separate nodes in three roles:
* `Master` nodes - intended for clustering management only, no data, no HTTP API
* `Client` nodes - intended for client usage, no data, with HTTP API
* `Data` nodes - intended for storing and indexing your data, no HTTP API

Given this, I'm hereby making possible for you to scale as needed. For instance, a good strong scenario could be 3 master, 2 client, 5 data nodes.

## (Very) Important notes

* By default, `ES_HEAP_SIZE` is set to `256MB`. This is a *very low* value but many users, i.e. `minikube` users, were having issues with pods getting killed because hosts were out of memory. You can change this yourself in the deployment descriptors available in this repository.

* As of the moment, Kubernetes pod descriptors use an `emptyDir` for storing data in each data node container. This is meant to be for the sake of simplicity and should be adapted according to your storage needs.

## Pre-requisites

* Kubernetes cluster (tested with v1.4.3 on top of [Vagrant + CoreOS](https://github.com/pires/kubernetes-vagrant-coreos-cluster))
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
NAME                          CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
svc/elasticsearch             10.100.59.70     <pending>     9200/TCP   3m
svc/elasticsearch-discovery   10.100.206.207   <none>        9300/TCP   3m
svc/kubernetes                10.100.0.1       <none>        443/TCP    17h
NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/es-client   1         1         1            1           2m
deploy/es-data     1         1         1            1           51s
deploy/es-master   1         1         1            1           3m
NAME                            READY     STATUS    RESTARTS   AGE
po/es-client-893446138-z6v0v    1/1       Running   0          2m
po/es-data-2462033339-dfede     1/1       Running   0          51s
po/es-master-3681665862-0p6wc   1/1       Running   0          3m
```

```
$ kubectl logs -f es-master-3681665862-0p6wc
[2016-10-19 10:27:31,629][INFO ][node                     ] [Cottonmouth] version[2.4.1], pid[11], build[c67dc32/2016-09-27T18:57:55Z]
[2016-10-19 10:27:31,630][INFO ][node                     ] [Cottonmouth] initializing ...
[2016-10-19 10:27:32,844][INFO ][plugins                  ] [Cottonmouth] modules [reindex, lang-expression, lang-groovy], plugins [cloud-kubernetes], sites []
[2016-10-19 10:27:32,923][INFO ][env                      ] [Cottonmouth] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [13.1gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2016-10-19 10:27:32,924][INFO ][env                      ] [Cottonmouth] heap size [247.6mb], compressed ordinary object pointers [true]
[2016-10-19 10:27:38,469][INFO ][node                     ] [Cottonmouth] initialized
[2016-10-19 10:27:38,475][INFO ][node                     ] [Cottonmouth] starting ...
[2016-10-19 10:27:38,666][INFO ][transport                ] [Cottonmouth] publish_address {10.244.36.2:9300}, bound_addresses {10.244.36.2:9300}
[2016-10-19 10:27:38,676][INFO ][discovery                ] [Cottonmouth] myesdb/B1gZ7EA0T1C0HBmQHqa-9w
[2016-10-19 10:27:43,837][INFO ][cluster.service          ] [Cottonmouth] new_master {Cottonmouth}{B1gZ7EA0T1C0HBmQHqa-9w}{10.244.36.2}{10.244.36.2:9300}{data=false, master=true}, reason: zen-disco-join(elected_as_master, [0] joins received)
[2016-10-19 10:27:43,854][INFO ][node                     ] [Cottonmouth] started
[2016-10-19 10:27:43,912][INFO ][gateway                  ] [Cottonmouth] recovered [0] indices into cluster_state
[2016-10-19 10:29:01,809][INFO ][cluster.service          ] [Cottonmouth] added {{Steve Rogers}{lgXWvPt-TbKF8ZoWsH0QwQ}{10.244.95.2}{10.244.95.2:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{Steve Rogers}{lgXWvPt-TbKF8ZoWsH0QwQ}{10.244.95.2}{10.244.95.2:9300}{data=false, master=false}])
[2016-10-19 10:30:32,536][INFO ][cluster.service          ] [Cottonmouth] added {{Man-Thing}{9ZKhq0u5R4-Ry1mhEwcFJA}{10.244.18.2}{10.244.18.2:9300}{master=false},}, reason: zen-disco-join(join from node[{Man-Thing}{9ZKhq0u5R4-Ry1mhEwcFJA}{10.244.18.2}{10.244.18.2:9300}{master=false}])
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
NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/es-client   2         2         2            2           5m
deploy/es-data     2         2         2            2           4m
deploy/es-master   3         3         3            3           6m
NAME                            READY     STATUS    RESTARTS   AGE
po/es-client-893446138-rdb9y    1/1       Running   0          1m
po/es-client-893446138-z6v0v    1/1       Running   0          5m
po/es-data-2462033339-dfede     1/1       Running   0          4m
po/es-data-2462033339-scgek     1/1       Running   0          30s
po/es-master-3681665862-0p6wc   1/1       Running   0          6m
po/es-master-3681665862-rljxr   1/1       Running   0          1m
po/es-master-3681665862-zkhwi   1/1       Running   0          1m
```

Let's take another look at the logs of one of the Elasticsearch `master` nodes:

```
$ kubectl logs -f es-master-3681665862-0p6wc
[2016-10-19 10:27:31,629][INFO ][node                     ] [Cottonmouth] version[2.4.1], pid[11], build[c67dc32/2016-09-27T18:57:55Z]
[2016-10-19 10:27:31,630][INFO ][node                     ] [Cottonmouth] initializing ...
[2016-10-19 10:27:32,844][INFO ][plugins                  ] [Cottonmouth] modules [reindex, lang-expression, lang-groovy], plugins [cloud-kubernetes], sites []
[2016-10-19 10:27:32,923][INFO ][env                      ] [Cottonmouth] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [13.1gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2016-10-19 10:27:32,924][INFO ][env                      ] [Cottonmouth] heap size [247.6mb], compressed ordinary object pointers [true]
[2016-10-19 10:27:38,469][INFO ][node                     ] [Cottonmouth] initialized
[2016-10-19 10:27:38,475][INFO ][node                     ] [Cottonmouth] starting ...
[2016-10-19 10:27:38,666][INFO ][transport                ] [Cottonmouth] publish_address {10.244.36.2:9300}, bound_addresses {10.244.36.2:9300}
[2016-10-19 10:27:38,676][INFO ][discovery                ] [Cottonmouth] myesdb/B1gZ7EA0T1C0HBmQHqa-9w
[2016-10-19 10:27:43,837][INFO ][cluster.service          ] [Cottonmouth] new_master {Cottonmouth}{B1gZ7EA0T1C0HBmQHqa-9w}{10.244.36.2}{10.244.36.2:9300}{data=false, master=true}, reason: zen-disco-join(elected_as_master, [0] joins received)
[2016-10-19 10:27:43,854][INFO ][node                     ] [Cottonmouth] started
[2016-10-19 10:27:43,912][INFO ][gateway                  ] [Cottonmouth] recovered [0] indices into cluster_state
[2016-10-19 10:29:01,809][INFO ][cluster.service          ] [Cottonmouth] added {{Steve Rogers}{lgXWvPt-TbKF8ZoWsH0QwQ}{10.244.95.2}{10.244.95.2:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{Steve Rogers}{lgXWvPt-TbKF8ZoWsH0QwQ}{10.244.95.2}{10.244.95.2:9300}{data=false, master=false}])
[2016-10-19 10:30:32,536][INFO ][cluster.service          ] [Cottonmouth] added {{Man-Thing}{9ZKhq0u5R4-Ry1mhEwcFJA}{10.244.18.2}{10.244.18.2:9300}{master=false},}, reason: zen-disco-join(join from node[{Man-Thing}{9ZKhq0u5R4-Ry1mhEwcFJA}{10.244.18.2}{10.244.18.2:9300}{master=false}])
[2016-10-19 10:32:29,849][INFO ][cluster.service          ] [Cottonmouth] added {{Marduk Kurios}{5_Ds0dGvTqGNLCX6MKjWZQ}{10.244.95.3}{10.244.95.3:9300}{data=false, master=true},}, reason: zen-disco-join(join from node[{Marduk Kurios}{5_Ds0dGvTqGNLCX6MKjWZQ}{10.244.95.3}{10.244.95.3:9300}{data=false, master=true}])
[2016-10-19 10:32:30,299][INFO ][cluster.service          ] [Cottonmouth] added {{Wizard}{5V2ss-97TcmfcFqzMH73jw}{10.244.18.3}{10.244.18.3:9300}{data=false, master=true},}, reason: zen-disco-join(join from node[{Wizard}{5V2ss-97TcmfcFqzMH73jw}{10.244.18.3}{10.244.18.3:9300}{data=false, master=true}])
[2016-10-19 10:32:50,862][INFO ][cluster.service          ] [Cottonmouth] added {{Vavavoom}{LuomxPAjSKuGSEBL1bgKeQ}{10.244.36.3}{10.244.36.3:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{Vavavoom}{LuomxPAjSKuGSEBL1bgKeQ}{10.244.36.3}{10.244.36.3:9300}{data=false, master=false}])
[2016-10-19 10:33:26,239][INFO ][cluster.service          ] [Cottonmouth] added {{Karl Lykos}{BDJolawXRaCNqlBd3IgKig}{10.244.36.4}{10.244.36.4:9300}{master=false},}, reason: zen-disco-join(join from node[{Karl Lykos}{BDJolawXRaCNqlBd3IgKig}{10.244.36.4}{10.244.36.4:9300}{master=false}])

```

### Access the service

*Don't forget* that services in Kubernetes are only acessible from containers in the cluster. For different behavior you should [configure the creation of an external load-balancer](http://kubernetes.io/v1.1/docs/user-guide/services.html#type-loadbalancer). While it's supported within this example service descriptor, its usage is out of scope of this document, for now.

```
$ kubectl get svc elasticsearch
NAME                      CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
elasticsearch             10.100.59.70     <pending>     9200/TCP   7m
```

From any host on your cluster (that's running `kube-proxy`), run:

```
curl http://10.100.59.70:9200
```

You should see something similar to the following:

```json
{
  "name" : "Steve Rogers",
  "cluster_name" : "myesdb",
  "cluster_uuid" : "oEklUx7mRMOBvG7MiAMjEA",
  "version" : {
    "number" : "2.4.1",
    "build_hash" : "c67dc32e24162035d18d6fe1e952c4cbcbe79d16",
    "build_timestamp" : "2016-09-27T18:57:55Z",
    "build_snapshot" : false,
    "lucene_version" : "5.5.2"
  },
  "tagline" : "You Know, for Search"
}
```

Or if you want to see cluster information:

```
curl http://10.100.59.70:9200/_cluster/health?pretty
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
