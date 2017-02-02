# kubernetes-elasticsearch-cluster
Elasticsearch (5.2.0) cluster on top of Kubernetes made easy.

Elasticsearch best-practices recommend to separate nodes in three roles:
* `Master` nodes - intended for clustering management only, no data, no HTTP API
* `Client` nodes - intended for client usage, no data, with HTTP API
* `Data` nodes - intended for storing and indexing your data, no HTTP API

Given this, I'm going to demonstrate how to provision a (near, as storage is still an issue) production grade scenario consisting of 3 master, 2 client and 2 data nodes.

## (Very) Important notes

* By default, `ES_JAVA_OPTS` is set to `-Xms256m -Xmx256m`. This is a *very low* value but many users, i.e. `minikube` users, were having issues with pods getting killed because hosts were out of memory.
You can change this yourself in the deployment descriptors available in this repository.

* As of the moment, Kubernetes pod descriptors use an `emptyDir` for storing data in each data node container. This is meant to be for the sake of simplicity and should be adapted according to your storage needs.

## Pre-requisites

* Kubernetes cluster with **alpha features enabled** (tested with v1.5.2 on top of [Vagrant + CoreOS](https://github.com/pires/kubernetes-vagrant-coreos-cluster))
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

Wait until `es-master` deployment is provisioned, and

```
kubectl create -f es-client.yaml
kubectl create -f es-data.yaml
```
Now, I leave up to you how to validate the cluster, but a first step is to wait for containers to be in the `Running` state and check Elasticsearch master logs:

```
$ kubectl get svc,deployment,pods
NAME                          CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
svc/elasticsearch             10.100.203.98   <pending>     9200:32057/TCP   4m
svc/elasticsearch-discovery   10.100.131.27   <none>        9300/TCP         4m
svc/kubernetes                10.100.0.1      <none>        443/TCP          12m

NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/es-client   2         2         2            2           2m
deploy/es-data     2         2         2            2           2m
deploy/es-master   3         3         3            3           4m

NAME                            READY     STATUS    RESTARTS   AGE
po/es-client-583869315-11mjj    1/1       Running   0          2m
po/es-client-583869315-q9wsj    1/1       Running   0          2m
po/es-data-903871959-ctbsj      1/1       Running   0          2m
po/es-data-903871959-mw0tj      1/1       Running   0          2m
po/es-master-2173384742-40g9j   1/1       Running   0          4m
po/es-master-2173384742-d2m7j   1/1       Running   0          4m
po/es-master-2173384742-q7ckf   1/1       Running   0          4m
```

```
$ kubectl logs -f po/es-master-2173384742-40g9j
[2017-02-01T09:34:15,118][INFO ][o.e.n.Node               ] [] initializing ...
[2017-02-01T09:34:15,538][INFO ][o.e.e.NodeEnvironment    ] [5gNfx3_] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [13.7gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2017-02-01T09:34:15,539][INFO ][o.e.e.NodeEnvironment    ] [5gNfx3_] heap size [247.5mb], compressed ordinary object pointers [true]
[2017-02-01T09:34:15,545][INFO ][o.e.n.Node               ] node name [5gNfx3_] derived from node ID [5gNfx3_GSrmZiChMKhBgIQ]; set [node.name] to override
[2017-02-01T09:34:15,551][INFO ][o.e.n.Node               ] version[5.2.0], pid[13], build[24e05b9/2017-01-24T19:52:35.800Z], OS[Linux/4.8.17-coreos/amd64], JVM[Oracle Corporation/OpenJDK 64-Bit Server VM/1.8.0_111/25.111-b14]
[2017-02-01T09:34:19,676][INFO ][o.e.p.PluginsService     ] [5gNfx3_] loaded module [aggs-matrix-stats]
[2017-02-01T09:34:19,676][INFO ][o.e.p.PluginsService     ] [5gNfx3_] loaded module [ingest-common]
[2017-02-01T09:34:19,676][INFO ][o.e.p.PluginsService     ] [5gNfx3_] loaded module [lang-expression]
[2017-02-01T09:34:19,677][INFO ][o.e.p.PluginsService     ] [5gNfx3_] loaded module [lang-groovy]
[2017-02-01T09:34:19,677][INFO ][o.e.p.PluginsService     ] [5gNfx3_] loaded module [lang-mustache]
[2017-02-01T09:34:19,678][INFO ][o.e.p.PluginsService     ] [5gNfx3_] loaded module [lang-painless]
[2017-02-01T09:34:19,678][INFO ][o.e.p.PluginsService     ] [5gNfx3_] loaded module [percolator]
[2017-02-01T09:34:19,690][INFO ][o.e.p.PluginsService     ] [5gNfx3_] loaded module [reindex]
[2017-02-01T09:34:19,691][INFO ][o.e.p.PluginsService     ] [5gNfx3_] loaded module [transport-netty3]
[2017-02-01T09:34:19,691][INFO ][o.e.p.PluginsService     ] [5gNfx3_] loaded module [transport-netty4]
[2017-02-01T09:34:19,693][INFO ][o.e.p.PluginsService     ] [5gNfx3_] no plugins loaded
[2017-02-01T09:34:20,717][WARN ][o.e.d.s.g.GroovyScriptEngineService] [groovy] scripts are deprecated, use [painless] scripts instead
[2017-02-01T09:34:34,927][INFO ][o.e.n.Node               ] initialized
[2017-02-01T09:34:34,927][INFO ][o.e.n.Node               ] [5gNfx3_] starting ...
[2017-02-01T09:34:35,136][WARN ][i.n.u.i.MacAddressUtil   ] Failed to find a usable hardware address from the network interfaces; using random bytes: 15:8d:90:01:27:3f:55:d8
[2017-02-01T09:34:35,271][INFO ][o.e.t.TransportService   ] [5gNfx3_] publish_address {10.244.56.2:9300}, bound_addresses {10.244.56.2:9300}
[2017-02-01T09:34:35,287][INFO ][o.e.b.BootstrapChecks    ] [5gNfx3_] bound or publishing to a non-loopback or non-link-local address, enforcing bootstrap checks
[2017-02-01T09:34:38,548][INFO ][o.e.c.s.ClusterService   ] [5gNfx3_] new_master {5gNfx3_}{5gNfx3_GSrmZiChMKhBgIQ}{VV-TQnHBRFCwU_AK_aHKpA}{10.244.56.2}{10.244.56.2:9300}, added {{V4ZOb1u}{V4ZOb1ugSwu_1JjxaihuCw}{NLKOlJN4SNeUWCrfR8Q_MA}{10.244.44.2}{10.244.44.2:9300},}, reason: zen-disco-elected-as-master ([1] nodes joined)[{V4ZOb1u}{V4ZOb1ugSwu_1JjxaihuCw}{NLKOlJN4SNeUWCrfR8Q_MA}{10.244.44.2}{10.244.44.2:9300}]
[2017-02-01T09:34:38,667][INFO ][o.e.n.Node               ] [5gNfx3_] started
[2017-02-01T09:34:38,843][INFO ][o.e.g.GatewayService     ] [5gNfx3_] recovered [0] indices into cluster_state
[2017-02-01T09:34:40,766][INFO ][o.e.c.s.ClusterService   ] [5gNfx3_] added {{s0DFRMx}{s0DFRMxOR9GvMPhdoRj-Og}{sm0_EP7kTBOvkpBNFgpFrA}{10.244.9.2}{10.244.9.2:9300},}, reason: zen-disco-node-join[{s0DFRMx}{s0DFRMxOR9GvMPhdoRj-Og}{sm0_EP7kTBOvkpBNFgpFrA}{10.244.9.2}{10.244.9.2:9300}]
[2017-02-01T09:36:02,176][INFO ][o.e.c.s.ClusterService   ] [5gNfx3_] added {{EVWrdUh}{EVWrdUh6SI2vLz5qYCO11g}{TNbwoaOnTFq3q8ZMW2oedw}{10.244.56.3}{10.244.56.3:9300},}, reason: zen-disco-node-join[{EVWrdUh}{EVWrdUh6SI2vLz5qYCO11g}{TNbwoaOnTFq3q8ZMW2oedw}{10.244.56.3}{10.244.56.3:9300}]
[2017-02-01T09:36:28,567][INFO ][o.e.c.s.ClusterService   ] [5gNfx3_] added {{9Qyjemc}{9QyjemcWQJKTR5zQoj23Rg}{p0pLUaTtTmCOCleEb2BnOA}{10.244.44.4}{10.244.44.4:9300},}, reason: zen-disco-node-join[{9Qyjemc}{9QyjemcWQJKTR5zQoj23Rg}{p0pLUaTtTmCOCleEb2BnOA}{10.244.44.4}{10.244.44.4:9300}]
[2017-02-01T09:36:29,169][INFO ][o.e.c.s.ClusterService   ] [5gNfx3_] added {{civ5bHu}{civ5bHuWTKOzFLyRuBDexQ}{MsOr_2peTkClI-RuE6XjZQ}{10.244.44.3}{10.244.44.3:9300},}, reason: zen-disco-node-join[{civ5bHu}{civ5bHuWTKOzFLyRuBDexQ}{MsOr_2peTkClI-RuE6XjZQ}{10.244.44.3}{10.244.44.3:9300}]
[2017-02-01T09:36:40,953][INFO ][o.e.c.s.ClusterService   ] [5gNfx3_] added {{IfNeRsV}{IfNeRsVzQT6Gqds3BLt0Pw}{LnxQsC_xRy60EBXFCaww_Q}{10.244.67.3}{10.244.67.3:9300},}, reason: zen-disco-node-join[{IfNeRsV}{IfNeRsVzQT6Gqds3BLt0Pw}{LnxQsC_xRy60EBXFCaww_Q}{10.244.67.3}{10.244.67.3:9300}]
```

As you can assert, the cluster is up and running. Easy, wasn't it?

### Access the service

*Don't forget* that services in Kubernetes are only acessible from containers in the cluster. For different behavior you should [configure the creation of an external load-balancer](http://kubernetes.io/v1.1/docs/user-guide/services.html#type-loadbalancer). While it's supported within this example service descriptor, its usage is out of scope of this document, for now.

```
$ kubectl get svc elasticsearch
NAME            CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
elasticsearch   10.100.203.98   <pending>     9200:32057/TCP   7m
```

From any host on your cluster (that's running `kube-proxy`), run:

```
curl http://10.100.203.98:9200
```

You should see something similar to the following:

```json
{
  "name" : "IfNeRsV",
  "cluster_name" : "myesdb",
  "cluster_uuid" : "tLXdVPqCRsax2Hm9VCSFjQ",
  "version" : {
    "number" : "5.2.0",
    "build_hash" : "24e05b9",
    "build_date" : "2017-01-24T19:52:35.800Z",
    "build_snapshot" : false,
    "lucene_version" : "6.4.0"
  },
  "tagline" : "You Know, for Search"
}
```

Or if you want to see cluster information:

```
curl http://10.100.203.98:9200/_cluster/health?pretty
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

## Clean up with Curator

Additionally, you can run a [CronJob](http://kubernetes.io/docs/user-guide/cron-jobs/) that will periodically run [Curator](https://github.com/elastic/curator) to clean up your indices (or do other actions on your cluster).

```
kubectl create -f es-curator-config.yaml
kubectl create -f es-curator.yaml
```

Please, confirm the job has been created.

```
$ kubectl get cronjobs
NAME      SCHEDULE    SUSPEND   ACTIVE    LAST-SCHEDULE
curator   1 0 * * *   False     0         <none>
```

The job is configured to run once a day at _1 minute past midnight and delete indices that are older than 3 days_.

**Notes**

- You can change the schedule by editing the cron notation in `es-curator.yaml`.
- You can change the action (e.g. delete older than 3 days) by editing the `es-curator-config.yaml`.
- The definition of the `action_file.yaml` is quite self-explaining for simple set-ups. For more advanced configuration options, please consult the [Curator Documentation](https://www.elastic.co/guide/en/elasticsearch/client/curator/current/index.html).

If you want to remove the curator job, just run:

```
kubectl delete cronjob curator
kubectl delete configmap curator-config
``` 

## FAQ
### Why does `NUMBER_OF_MASTERS` differ from number of master-replicas?
The default value for this environment variable is 2, meaning a cluster will need a minimum of 2 master nodes to operate. If you have 3 masters and one dies, the cluster still works. Minimum master nodes are usually `n/2 + 1`, where `n` is the number of master nodes in a cluster. If you have 5 master nodes, you should have a minimum of 3, less than that and the cluster _stops_. If you scale the number of masters, make sure to update the minimum number of master nodes through the Elasticsearch API as setting environment variable will only work on cluster setup. More info: https://www.elastic.co/guide/en/elasticsearch/guide/1.x/_important_configuration_changes.html#_minimum_master_nodes


### How can I customize `elasticsearch.yaml`?
Read a different config file by settings env var `path.conf=/path/to/my/config/`. Another option would be to build your own image from  [this repository](https://github.com/pires/docker-elasticsearch-kubernetes)
