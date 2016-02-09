# kubernetes-elasticsearch-cluster
Elasticsearch (2.2.0) cluster on top of Kubernetes made easy.

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
elasticsearch             10.100.172.134                 9200/TCP   component=elasticsearch,role=client   3m
elasticsearch-discovery   10.100.248.2     <none>        9300/TCP   component=elasticsearch,role=master   3m
kubernetes                10.100.0.1       <none>        443/TCP    <none>                                18m
CONTROLLER   CONTAINER(S)   IMAGE(S)                                              SELECTOR                              REPLICAS   AGE
es-client    es-client      quay.io/pires/docker-elasticsearch-kubernetes:2.2.0   component=elasticsearch,role=client   1          2m
es-data      es-data        quay.io/pires/docker-elasticsearch-kubernetes:2.2.0   component=elasticsearch,role=data     1          2m
es-master    es-master      quay.io/pires/docker-elasticsearch-kubernetes:2.2.0   component=elasticsearch,role=master   1          3m
NAME              READY     STATUS    RESTARTS   AGE
es-client-h3u53   1/1       Running   0          2m
es-data-p2kia     1/1       Running   0          2m
es-master-14i22   1/1       Running   0          3m
```

```
$ kubectl logs es-master-14i22
[s6-init] making user provided files available at /var/run/s6/etc...exited 0.
[s6-init] ensuring user provided files have correct perms...exited 0.
[fix-attrs.d] applying ownership & permissions fixes...
[fix-attrs.d] done.
[cont-init.d] executing container initialization scripts...
[cont-init.d] done.
[services.d] starting services
level=info msg="Starting go-dnsmasq server 0.9.8 ..."
level=info msg="Search domains in use: [default.svc.cluster.local. svc.cluster.local. cluster.local.]"
level=info msg="Ready for queries on tcp://127.0.0.1:53 - Nameservers: [10.100.0.10:53 10.0.2.3:53]"
level=info msg="Ready for queries on udp://127.0.0.1:53 - Nameservers: [10.100.0.10:53 10.0.2.3:53]"
[services.d] done.
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
[2016-02-09 16:57:53,483][INFO ][node                     ] [New Goblin] version[2.2.0], pid[172], build[8ff36d1/2016-01-27T13:32:39Z]
[2016-02-09 16:57:53,483][INFO ][node                     ] [New Goblin] initializing ...
[2016-02-09 16:57:54,172][INFO ][plugins                  ] [New Goblin] modules [lang-expression, lang-groovy], plugins [cloud-kubernetes], sites []
[2016-02-09 16:57:54,194][INFO ][env                      ] [New Goblin] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [14.2gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2016-02-09 16:57:54,194][INFO ][env                      ] [New Goblin] heap size [1015.6mb], compressed ordinary object pointers [true]
[2016-02-09 16:57:57,508][INFO ][node                     ] [New Goblin] initialized
[2016-02-09 16:57:57,513][INFO ][node                     ] [New Goblin] starting ...
[2016-02-09 16:57:57,589][WARN ][common.network           ] [New Goblin] _non_loopback_ is deprecated as it picks an arbitrary interface. specify explicit scope(s), interface(s), address(es), or hostname(s) instead
[2016-02-09 16:57:57,666][WARN ][common.network           ] [New Goblin] _non_loopback_ is deprecated as it picks an arbitrary interface. specify explicit scope(s), interface(s), address(es), or hostname(s) instead
[2016-02-09 16:57:57,679][INFO ][transport                ] [New Goblin] publish_address {10.244.12.2:9300}, bound_addresses {10.244.12.2:9300}
[2016-02-09 16:57:57,686][INFO ][discovery                ] [New Goblin] myesdb/7tXPp-tqSdu8qZ_ZUcm7pg
[2016-02-09 16:57:57,695][WARN ][common.network           ] [New Goblin] _non_loopback_ is deprecated as it picks an arbitrary interface. specify explicit scope(s), interface(s), address(es), or hostname(s) instead
[2016-02-09 16:58:00,536][WARN ][common.network           ] [New Goblin] _non_loopback_ is deprecated as it picks an arbitrary interface. specify explicit scope(s), interface(s), address(es), or hostname(s) instead
[2016-02-09 16:58:02,066][WARN ][common.network           ] [New Goblin] _non_loopback_ is deprecated as it picks an arbitrary interface. specify explicit scope(s), interface(s), address(es), or hostname(s) instead
[2016-02-09 16:58:02,090][INFO ][cluster.service          ] [New Goblin] new_master {New Goblin}{7tXPp-tqSdu8qZ_ZUcm7pg}{10.244.12.2}{10.244.12.2:9300}{data=false, master=true}, reason: zen-disco-join(elected_as_master, [0] joins received)
[2016-02-09 16:58:02,093][INFO ][node                     ] [New Goblin] started
[2016-02-09 16:58:02,150][INFO ][gateway                  ] [New Goblin] recovered [0] indices into cluster_state
[2016-02-09 16:58:39,353][INFO ][cluster.service          ] [New Goblin] added {{Coach}{SHRr7XACQsuyHKP3rSxCOw}{10.244.14.2}{10.244.14.2:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{Coach}{SHRr7XACQsuyHKP3rSxCOw}{10.244.14.2}{10.244.14.2:9300}{data=false, master=false}])
[2016-02-09 16:59:16,448][INFO ][cluster.service          ] [New Goblin] added {{Ghaur}{vcNdokVgSPeYALQ5jtMOKw}{10.244.75.2}{10.244.75.2:9300}{master=false},}, reason: zen-disco-join(join from node[{Ghaur}{vcNdokVgSPeYALQ5jtMOKw}{10.244.75.2}{10.244.75.2:9300}{master=false}])
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
es-client-1tumx   1/1       Running   0          21s
es-client-h3u53   1/1       Running   0          4m
es-data-16wii     1/1       Running   0          15s
es-data-p2kia     1/1       Running   0          3m
es-master-14i22   1/1       Running   0          4m
es-master-cov7v   1/1       Running   0          41s
es-master-hskr3   1/1       Running   0          41s
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
level=info msg="Starting go-dnsmasq server 0.9.8 ..."
level=info msg="Search domains in use: [default.svc.cluster.local. svc.cluster.local. cluster.local.]"
level=info msg="Ready for queries on tcp://127.0.0.1:53 - Nameservers: [10.100.0.10:53 10.0.2.3:53]"
level=info msg="Ready for queries on udp://127.0.0.1:53 - Nameservers: [10.100.0.10:53 10.0.2.3:53]"
[services.d] done.
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
log4j:WARN No such property [maxBackupIndex] in org.apache.log4j.DailyRollingFileAppender.
[2016-02-09 16:57:53,483][INFO ][node                     ] [New Goblin] version[2.2.0], pid[172], build[8ff36d1/2016-01-27T13:32:39Z]
[2016-02-09 16:57:53,483][INFO ][node                     ] [New Goblin] initializing ...
[2016-02-09 16:57:54,172][INFO ][plugins                  ] [New Goblin] modules [lang-expression, lang-groovy], plugins [cloud-kubernetes], sites []
[2016-02-09 16:57:54,194][INFO ][env                      ] [New Goblin] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [14.2gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2016-02-09 16:57:54,194][INFO ][env                      ] [New Goblin] heap size [1015.6mb], compressed ordinary object pointers [true]
[2016-02-09 16:57:57,508][INFO ][node                     ] [New Goblin] initialized
[2016-02-09 16:57:57,513][INFO ][node                     ] [New Goblin] starting ...
[2016-02-09 16:57:57,589][WARN ][common.network           ] [New Goblin] _non_loopback_ is deprecated as it picks an arbitrary interface. specify explicit scope(s), interface(s), address(es), or hostname(s) instead
[2016-02-09 16:57:57,666][WARN ][common.network           ] [New Goblin] _non_loopback_ is deprecated as it picks an arbitrary interface. specify explicit scope(s), interface(s), address(es), or hostname(s) instead
[2016-02-09 16:57:57,679][INFO ][transport                ] [New Goblin] publish_address {10.244.12.2:9300}, bound_addresses {10.244.12.2:9300}
[2016-02-09 16:57:57,686][INFO ][discovery                ] [New Goblin] myesdb/7tXPp-tqSdu8qZ_ZUcm7pg
[2016-02-09 16:57:57,695][WARN ][common.network           ] [New Goblin] _non_loopback_ is deprecated as it picks an arbitrary interface. specify explicit scope(s), interface(s), address(es), or hostname(s) instead
[2016-02-09 16:58:00,536][WARN ][common.network           ] [New Goblin] _non_loopback_ is deprecated as it picks an arbitrary interface. specify explicit scope(s), interface(s), address(es), or hostname(s) instead
[2016-02-09 16:58:02,066][WARN ][common.network           ] [New Goblin] _non_loopback_ is deprecated as it picks an arbitrary interface. specify explicit scope(s), interface(s), address(es), or hostname(s) instead
[2016-02-09 16:58:02,090][INFO ][cluster.service          ] [New Goblin] new_master {New Goblin}{7tXPp-tqSdu8qZ_ZUcm7pg}{10.244.12.2}{10.244.12.2:9300}{data=false, master=true}, reason: zen-disco-join(elected_as_master, [0] joins received)
[2016-02-09 16:58:02,093][INFO ][node                     ] [New Goblin] started
[2016-02-09 16:58:02,150][INFO ][gateway                  ] [New Goblin] recovered [0] indices into cluster_state
[2016-02-09 16:58:39,353][INFO ][cluster.service          ] [New Goblin] added {{Coach}{SHRr7XACQsuyHKP3rSxCOw}{10.244.14.2}{10.244.14.2:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{Coach}{SHRr7XACQsuyHKP3rSxCOw}{10.244.14.2}{10.244.14.2:9300}{data=false, master=false}])
[2016-02-09 16:59:16,448][INFO ][cluster.service          ] [New Goblin] added {{Ghaur}{vcNdokVgSPeYALQ5jtMOKw}{10.244.75.2}{10.244.75.2:9300}{master=false},}, reason: zen-disco-join(join from node[{Ghaur}{vcNdokVgSPeYALQ5jtMOKw}{10.244.75.2}{10.244.75.2:9300}{master=false}])
[2016-02-09 17:01:42,936][INFO ][cluster.service          ] [New Goblin] added {{Brain Drain}{T_m5o4MBRXuGXr1WYS2ADg}{10.244.75.3}{10.244.75.3:9300}{data=false, master=true},}, reason: zen-disco-join(join from node[{Brain Drain}{T_m5o4MBRXuGXr1WYS2ADg}{10.244.75.3}{10.244.75.3:9300}{data=false, master=true}])
[2016-02-09 17:01:43,308][INFO ][cluster.service          ] [New Goblin] added {{Smasher}{ThswtxIrSa6oNKRXQo0TCg}{10.244.14.3}{10.244.14.3:9300}{data=false, master=true},}, reason: zen-disco-join(join from node[{Smasher}{ThswtxIrSa6oNKRXQo0TCg}{10.244.14.3}{10.244.14.3:9300}{data=false, master=true}])
[2016-02-09 17:02:04,303][INFO ][cluster.service          ] [New Goblin] added {{Tzabaoth}{qenlK1gNTAWf76-XLK4wyw}{10.244.12.3}{10.244.12.3:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{Tzabaoth}{qenlK1gNTAWf76-XLK4wyw}{10.244.12.3}{10.244.12.3:9300}{data=false, master=false}])
[2016-02-09 17:02:10,601][INFO ][cluster.service          ] [New Goblin] added {{Urthona}{XsdnXJC1SuecU-iPC9lssw}{10.244.12.4}{10.244.12.4:9300}{master=false},}, reason: zen-disco-join(join from node[{Urthona}{XsdnXJC1SuecU-iPC9lssw}{10.244.12.4}{10.244.12.4:9300}{master=false}])
```

### Access the service

*Don't forget* that services in Kubernetes are only acessible from containers in the cluster. For different behavior you should [configure the creation of an external load-balancer](http://kubernetes.io/v1.1/docs/user-guide/services.html#type-loadbalancer). While it's supported within this example service descriptor, its usage is out of scope of this document, for now.

```
$ kubectl get service elasticsearch
NAME            CLUSTER_IP       EXTERNAL_IP   PORT(S)    SELECTOR                              AGE
elasticsearch   10.100.172.134                 9200/TCP   component=elasticsearch,role=client   5m
```

From any host on your cluster (that's running `kube-proxy`), run:

```
curl http://10.100.172.134:9200
```

You should see something similar to the following:

```json
{
  "name" : "Tzabaoth",
  "cluster_name" : "myesdb",
  "version" : {
    "number" : "2.2.0",
    "build_hash" : "8ff36d139e16f8720f2947ef62c8167a888992fe",
    "build_timestamp" : "2016-01-27T13:32:39Z",
    "build_snapshot" : false,
    "lucene_version" : "5.4.1"
  },
  "tagline" : "You Know, for Search"
}
```

Or if you want to see cluster information:

```
curl http://10.100.172.134:9200/_cluster/health?pretty
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
