# kubernetes-elasticsearch-cluster
Elasticsearch (2.1.1) cluster on top of Kubernetes made easy.

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
NAME                      CLUSTER_IP       EXTERNAL_IP   PORT(S)    SELECTOR                              AGE
elasticsearch             10.100.102.154                 9200/TCP   component=elasticsearch,role=client   4m
elasticsearch-discovery   10.100.106.45    <none>        9300/TCP   component=elasticsearch,role=master   4m
kubernetes                10.100.0.1       <none>        443/TCP    <none>                                13m
CONTROLLER   CONTAINER(S)   IMAGE(S)                                              SELECTOR                              REPLICAS   AGE
es-client    es-client      quay.io/pires/docker-elasticsearch-kubernetes:2.1.1   component=elasticsearch,role=client   1          3m
es-data      es-data        quay.io/pires/docker-elasticsearch-kubernetes:2.1.1   component=elasticsearch,role=data     1          1m
es-master    es-master      quay.io/pires/docker-elasticsearch-kubernetes:2.1.1   component=elasticsearch,role=master   1          4m
NAME              READY     STATUS    RESTARTS   AGE
es-client-xn7ug   1/1       Running   0          3m
es-data-r82w7     1/1       Running   0          1m
es-master-r1ed8   1/1       Running   0          4m
```

```
$ ubectl logs es-master-r1ed8
[s6-init] making user provided files available at /var/run/s6/etc...exited 0.
[s6-init] ensuring user provided files have correct perms...exited 0.
[fix-attrs.d] applying ownership & permissions fixes...
[fix-attrs.d] done.
[cont-init.d] executing container initialization scripts...
[cont-init.d] done.
[services.d] starting services
[services.d] done.
level=info msg="Starting go-dnsmasq server 0.9.8 ..."
level=info msg="Search domains in use: [default.svc.cluster.local. svc.cluster.local. cluster.local.]"
level=info msg="Ready for queries on tcp://127.0.0.1:53 - Nameservers: [10.100.0.10:53 10.0.2.3:53]"
level=info msg="Ready for queries on udp://127.0.0.1:53 - Nameservers: [10.100.0.10:53 10.0.2.3:53]"
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
[2016-01-17 11:26:20,462][INFO ][node                     ] [Lockdown] version[2.1.1], pid[168], build[40e2c53/2015-12-15T13:05:55Z]
[2016-01-17 11:26:20,462][INFO ][node                     ] [Lockdown] initializing ...
[2016-01-17 11:26:20,798][INFO ][plugins                  ] [Lockdown] loaded [cloud-kubernetes], sites []
[2016-01-17 11:26:20,824][INFO ][env                      ] [Lockdown] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [14.2gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2016-01-17 11:26:23,912][INFO ][node                     ] [Lockdown] initialized
[2016-01-17 11:26:23,912][INFO ][node                     ] [Lockdown] starting ...
[2016-01-17 11:26:24,064][INFO ][transport                ] [Lockdown] publish_address {10.244.42.2:9300}, bound_addresses {10.244.42.2:9300}
[2016-01-17 11:26:24,089][INFO ][discovery                ] [Lockdown] myesdb/2ddoVi6ZR72OYSdHXrV6sQ
[2016-01-17 11:26:28,827][INFO ][cluster.service          ] [Lockdown] new_master {Lockdown}{2ddoVi6ZR72OYSdHXrV6sQ}{10.244.42.2}{10.244.42.2:9300}{data=false, master=true}, reason: zen-disco-join(elected_as_master, [0] joins received)
[2016-01-17 11:26:28,833][INFO ][node                     ] [Lockdown] started
[2016-01-17 11:26:28,875][INFO ][gateway                  ] [Lockdown] recovered [0] indices into cluster_state
[2016-01-17 11:28:13,866][INFO ][cluster.service          ] [Lockdown] added {{Snowfall}{9c5FG7kyQGmLMa2QBtI-3Q}{10.244.1.2}{10.244.1.2:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{Snowfall}{9c5FG7kyQGmLMa2QBtI-3Q}{10.244.1.2}{10.244.1.2:9300}{data=false, master=false}])
[2016-01-17 11:29:48,740][INFO ][cluster.service          ] [Lockdown] added {{Quagmire}{hSlYMtFMT_KPI1yPpyj1oA}{10.244.17.2}{10.244.17.2:9300}{master=false},}, reason: zen-disco-join(join from node[{Quagmire}{hSlYMtFMT_KPI1yPpyj1oA}{10.244.17.2}{10.244.17.2:9300}{master=false}])
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
es-client-vmpk4   1/1       Running   0          21s
es-client-xn7ug   1/1       Running   0          5m
es-data-j7bec     1/1       Running   0          19s
es-data-r82w7     1/1       Running   0          3m
es-master-9zia4   1/1       Running   0          1m
es-master-oig0e   1/1       Running   0          1m
es-master-r1ed8   1/1       Running   0          7m
```

Let's take another look of the Elasticsearch master logs:
```
$ kubectl logs es-master-r1ed8
[s6-init] making user provided files available at /var/run/s6/etc...exited 0.
[s6-init] ensuring user provided files have correct perms...exited 0.
[fix-attrs.d] applying ownership & permissions fixes...
[fix-attrs.d] done.
[cont-init.d] executing container initialization scripts...
[cont-init.d] done.
[services.d] starting services
[services.d] done.
level=info msg="Starting go-dnsmasq server 0.9.8 ..."
level=info msg="Search domains in use: [default.svc.cluster.local. svc.cluster.local. cluster.local.]"
level=info msg="Ready for queries on tcp://127.0.0.1:53 - Nameservers: [10.100.0.10:53 10.0.2.3:53]"
level=info msg="Ready for queries on udp://127.0.0.1:53 - Nameservers: [10.100.0.10:53 10.0.2.3:53]"
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
[2016-01-17 11:26:20,462][INFO ][node                     ] [Lockdown] version[2.1.1], pid[168], build[40e2c53/2015-12-15T13:05:55Z]
[2016-01-17 11:26:20,462][INFO ][node                     ] [Lockdown] initializing ...
[2016-01-17 11:26:20,798][INFO ][plugins                  ] [Lockdown] loaded [cloud-kubernetes], sites []
[2016-01-17 11:26:20,824][INFO ][env                      ] [Lockdown] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [14.2gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2016-01-17 11:26:23,912][INFO ][node                     ] [Lockdown] initialized
[2016-01-17 11:26:23,912][INFO ][node                     ] [Lockdown] starting ...
[2016-01-17 11:26:24,064][INFO ][transport                ] [Lockdown] publish_address {10.244.42.2:9300}, bound_addresses {10.244.42.2:9300}
[2016-01-17 11:26:24,089][INFO ][discovery                ] [Lockdown] myesdb/2ddoVi6ZR72OYSdHXrV6sQ
[2016-01-17 11:26:28,827][INFO ][cluster.service          ] [Lockdown] new_master {Lockdown}{2ddoVi6ZR72OYSdHXrV6sQ}{10.244.42.2}{10.244.42.2:9300}{data=false, master=true}, reason: zen-disco-join(elected_as_master, [0] joins received)
[2016-01-17 11:26:28,833][INFO ][node                     ] [Lockdown] started
[2016-01-17 11:26:28,875][INFO ][gateway                  ] [Lockdown] recovered [0] indices into cluster_state
[2016-01-17 11:28:13,866][INFO ][cluster.service          ] [Lockdown] added {{Snowfall}{9c5FG7kyQGmLMa2QBtI-3Q}{10.244.1.2}{10.244.1.2:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{Snowfall}{9c5FG7kyQGmLMa2QBtI-3Q}{10.244.1.2}{10.244.1.2:9300}{data=false, master=false}])
[2016-01-17 11:29:48,740][INFO ][cluster.service          ] [Lockdown] added {{Quagmire}{hSlYMtFMT_KPI1yPpyj1oA}{10.244.17.2}{10.244.17.2:9300}{master=false},}, reason: zen-disco-join(join from node[{Quagmire}{hSlYMtFMT_KPI1yPpyj1oA}{10.244.17.2}{10.244.17.2:9300}{master=false}])
[2016-01-17 11:31:23,537][INFO ][cluster.service          ] [Lockdown] added {{Amber Hunt}{8hwCHEoaSVKZGQ1bYvkamA}{10.244.17.3}{10.244.17.3:9300}{data=false, master=true},}, reason: zen-disco-join(join from node[{Amber Hunt}{8hwCHEoaSVKZGQ1bYvkamA}{10.244.17.3}{10.244.17.3:9300}{data=false, master=true}])
[2016-01-17 11:31:23,681][INFO ][cluster.service          ] [Lockdown] added {{Deathwatch}{I9UfHJBVQbmJc5t4StuHVQ}{10.244.1.3}{10.244.1.3:9300}{data=false, master=true},}, reason: zen-disco-join(join from node[{Deathwatch}{I9UfHJBVQbmJc5t4StuHVQ}{10.244.1.3}{10.244.1.3:9300}{data=false, master=true}])
[2016-01-17 11:32:06,326][INFO ][cluster.service          ] [Lockdown] added {{Tantra}{occNdS1dRfiKMHfCvd-0fQ}{10.244.42.3}{10.244.42.3:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{Tantra}{occNdS1dRfiKMHfCvd-0fQ}{10.244.42.3}{10.244.42.3:9300}{data=false, master=false}])
[2016-01-17 11:32:08,813][INFO ][cluster.service          ] [Lockdown] added {{Vector}{NoNXvKIcRYuzpA_-ypjSIQ}{10.244.1.4}{10.244.1.4:9300}{master=false},}, reason: zen-disco-join(join from node[{Vector}{NoNXvKIcRYuzpA_-ypjSIQ}{10.244.1.4}{10.244.1.4:9300}{master=false}])
```

### Access the service

*Don't forget* that services in Kubernetes are only acessible from containers in the cluster. For different behavior you should [configure the creation of an external load-balancer](http://kubernetes.io/v1.1/docs/user-guide/services.html#type-loadbalancer). While it's supported within this example service descriptor, its usage is out of scope of this document, for now.

```
$ kubectl get service elasticsearch
NAME            CLUSTER_IP       EXTERNAL_IP   PORT(S)    SELECTOR                              AGE
elasticsearch   10.100.102.154                 9200/TCP   component=elasticsearch,role=client   8m
```

From any host on your cluster (that's running `kube-proxy`), run:

```
curl http://10.100.102.154:9200
```

You should see something similar to the following:

```json
{
  "name" : "Snowfall",
  "cluster_name" : "myesdb",
  "version" : {
    "number" : "2.1.1",
    "build_hash" : "40e2c53a6b6c2972b3d13846e450e66f4375bd71",
    "build_timestamp" : "2015-12-15T13:05:55Z",
    "build_snapshot" : false,
    "lucene_version" : "5.3.1"
  },
  "tagline" : "You Know, for Search"
}
```

Or if you want to see cluster information:

```
curl http://10.100.102.154:9200/_cluster/health?pretty
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
