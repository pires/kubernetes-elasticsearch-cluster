# kubernetes-elasticsearch-cluster
Elasticsearch (5.2.2) cluster on top of Kubernetes made easy.

Elasticsearch best-practices recommend to separate nodes in three roles:
* `Master` nodes - intended for clustering management only, no data, no HTTP API
* `Client` nodes - intended for client usage, no data, with HTTP API
* `Data` nodes - intended for storing and indexing your data, no HTTP API

Given this, I'm going to demonstrate how to provision a (near, as storage is still an issue) production grade scenario consisting of 3 master, 2 client and 2 data nodes.

## (Very) Important notes

* By default, `ES_JAVA_OPTS` is set to `-Xms256m -Xmx256m`. This is a *very low* value but many users, i.e. `minikube` users, were having issues with pods getting killed because hosts were out of memory.
You can change this yourself in the deployment descriptors available in this repository.

* As of the moment, Kubernetes pod descriptors use an `emptyDir` for storing data in each data node container. This is meant to be for the sake of simplicity and should be adapted according to your storage needs.

* The [stateful](stateful) directory contains an example which deploys the data pods as a `StatefulSet`. These use a `volumeClaimTemplates` to provision persistent storage for each pod.

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
NAME                          CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
svc/elasticsearch             10.100.18.90     <pending>     9200:30565/TCP   32m
svc/elasticsearch-discovery   10.100.132.130   <none>        9300/TCP         32m
svc/kubernetes                10.100.0.1       <none>        443/TCP          43m

NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/es-client   2         2         2            2           1m
deploy/es-data     2         2         2            2           1m
deploy/es-master   3         3         3            3           4m

NAME                            READY     STATUS    RESTARTS   AGE
po/es-client-2651269046-rm5bh   1/1       Running   0          1m
po/es-client-2651269046-v0375   1/1       Running   0          1m
po/es-data-2710897177-3p30t     1/1       Running   0          1m
po/es-data-2710897177-hrzmk     1/1       Running   0          1m
po/es-master-507722841-mfv5l    1/1       Running   0          4m
po/es-master-507722841-nrvnc    1/1       Running   0          4m
po/es-master-507722841-x3nzk    1/1       Running   0          4m
```

```
$ kubectl logs -f po/es-master-507722841-mfv5l
[2017-03-01T21:51:20,984][INFO ][o.e.n.Node               ] [] initializing ...
[2017-03-01T21:51:21,333][INFO ][o.e.e.NodeEnvironment    ] [3abL8FY] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [13.5gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2017-03-01T21:51:21,335][INFO ][o.e.e.NodeEnvironment    ] [3abL8FY] heap size [247.5mb], compressed ordinary object pointers [true]
[2017-03-01T21:51:21,347][INFO ][o.e.n.Node               ] node name [3abL8FY] derived from node ID [3abL8FYRSXecEw16r_FHsg]; set [node.name] to override
[2017-03-01T21:51:21,359][INFO ][o.e.n.Node               ] version[5.2.2], pid[13], build[f9d9b74/2017-02-24T17:26:45.835Z], OS[Linux/4.9.9-coreos-r1/amd64], JVM[Oracle Corporation/OpenJDK 64-Bit Server VM/1.8.0_111/25.111-b14]
[2017-03-01T21:51:34,605][INFO ][o.e.p.PluginsService     ] [3abL8FY] loaded module [aggs-matrix-stats]
[2017-03-01T21:51:34,619][INFO ][o.e.p.PluginsService     ] [3abL8FY] loaded module [ingest-common]
[2017-03-01T21:51:34,621][INFO ][o.e.p.PluginsService     ] [3abL8FY] loaded module [lang-expression]
[2017-03-01T21:51:34,621][INFO ][o.e.p.PluginsService     ] [3abL8FY] loaded module [lang-groovy]
[2017-03-01T21:51:34,622][INFO ][o.e.p.PluginsService     ] [3abL8FY] loaded module [lang-mustache]
[2017-03-01T21:51:34,622][INFO ][o.e.p.PluginsService     ] [3abL8FY] loaded module [lang-painless]
[2017-03-01T21:51:34,622][INFO ][o.e.p.PluginsService     ] [3abL8FY] loaded module [percolator]
[2017-03-01T21:51:34,623][INFO ][o.e.p.PluginsService     ] [3abL8FY] loaded module [reindex]
[2017-03-01T21:51:34,623][INFO ][o.e.p.PluginsService     ] [3abL8FY] loaded module [transport-netty3]
[2017-03-01T21:51:34,623][INFO ][o.e.p.PluginsService     ] [3abL8FY] loaded module [transport-netty4]
[2017-03-01T21:51:34,625][INFO ][o.e.p.PluginsService     ] [3abL8FY] no plugins loaded
[2017-03-01T21:51:35,426][WARN ][o.e.d.s.g.GroovyScriptEngineService] [groovy] scripts are deprecated, use [painless] scripts instead
[2017-03-01T21:51:45,337][INFO ][o.e.n.Node               ] initialized
[2017-03-01T21:51:45,337][INFO ][o.e.n.Node               ] [3abL8FY] starting ...
[2017-03-01T21:51:45,676][WARN ][i.n.u.i.MacAddressUtil   ] Failed to find a usable hardware address from the network interfaces; using random bytes: 56:f2:bd:6e:4c:b0:b9:bd
[2017-03-01T21:51:45,915][INFO ][o.e.t.TransportService   ] [3abL8FY] publish_address {10.244.57.3:9300}, bound_addresses {10.244.57.3:9300}
[2017-03-01T21:51:45,943][INFO ][o.e.b.BootstrapChecks    ] [3abL8FY] bound or publishing to a non-loopback or non-link-local address, enforcing bootstrap checks
[2017-03-01T21:51:51,084][WARN ][o.e.d.z.UnicastZenPing   ] [3abL8FY] timed out after [5s] resolving host [elasticsearch-discovery]
[2017-03-01T21:51:54,131][INFO ][o.e.c.s.ClusterService   ] [3abL8FY] new_master {3abL8FY}{3abL8FYRSXecEw16r_FHsg}{4wbiiYaYT5Wy0jcghGRArg}{10.244.57.3}{10.244.57.3:9300}, added {{5UCruB1}{5UCruB10TvGfXjw16NlOPw}{20reg1VUTQeNsu5BMcuiKg}{10.244.4.2}{10.244.4.2:9300},}, reason: zen-disco-elected-as-master ([1] nodes joined)[{5UCruB1}{5UCruB10TvGfXjw16NlOPw}{20reg1VUTQeNsu5BMcuiKg}{10.244.4.2}{10.244.4.2:9300}]
[2017-03-01T21:51:54,206][INFO ][o.e.n.Node               ] [3abL8FY] started
[2017-03-01T21:51:54,342][INFO ][o.e.g.GatewayService     ] [3abL8FY] recovered [0] indices into cluster_state
[2017-03-01T21:51:54,377][INFO ][o.e.c.s.ClusterService   ] [3abL8FY] added {{I9TVnBn}{I9TVnBnCQMK942M_sSN-Bg}{6w7fYzniRgiPg59NHOpw4A}{10.244.100.2}{10.244.100.2:9300},}, reason: zen-disco-node-join[{I9TVnBn}{I9TVnBnCQMK942M_sSN-Bg}{6w7fYzniRgiPg59NHOpw4A}{10.244.100.2}{10.244.100.2:9300}]
[2017-03-01T21:52:57,010][INFO ][o.e.c.s.ClusterService   ] [3abL8FY] added {{u3LSDKo}{u3LSDKoFR42ZqL4PeR3Zdw}{aqqAlhCjSIK56sn28DLdOg}{10.244.4.3}{10.244.4.3:9300},}, reason: zen-disco-node-join[{u3LSDKo}{u3LSDKoFR42ZqL4PeR3Zdw}{aqqAlhCjSIK56sn28DLdOg}{10.244.4.3}{10.244.4.3:9300}]
[2017-03-01T21:53:29,438][INFO ][o.e.c.s.ClusterService   ] [3abL8FY] added {{ckMzgPT}{ckMzgPTbSC2pLmxj6OuAPw}{mXpSkg-FSs-PRuR2fA6hIw}{10.244.22.2}{10.244.22.2:9300},}, reason: zen-disco-node-join[{ckMzgPT}{ckMzgPTbSC2pLmxj6OuAPw}{mXpSkg-FSs-PRuR2fA6hIw}{10.244.22.2}{10.244.22.2:9300}]
[2017-03-01T21:53:38,118][INFO ][o.e.c.s.ClusterService   ] [3abL8FY] added {{Oys65WA}{Oys65WAgT1ydEJ9Nzlxe0g}{gvgZdE9lQTuOewkYfdGBVQ}{10.244.22.3}{10.244.22.3:9300},}, reason: zen-disco-node-join[{Oys65WA}{Oys65WAgT1ydEJ9Nzlxe0g}{gvgZdE9lQTuOewkYfdGBVQ}{10.244.22.3}{10.244.22.3:9300}]
```

As you can assert, the cluster is up and running. Easy, wasn't it?

### Access the service

*Don't forget* that services in Kubernetes are only acessible from containers in the cluster. For different behavior you should [configure the creation of an external load-balancer](http://kubernetes.io/v1.1/docs/user-guide/services.html#type-loadbalancer). While it's supported within this example service descriptor, its usage is out of scope of this document, for now.

```
$ kubectl get svc elasticsearch
NAME            CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
elasticsearch   10.100.18.90   <pending>     9200:30565/TCP   33m
```

From any host on your cluster (that's running `kube-proxy`), run:

```
curl http://10.100.18.90:9200
```

You should see something similar to the following:

```json
{
  "name" : "gA5RwhW",
  "cluster_name" : "myesdb",
  "cluster_uuid" : "_na_",
  "version" : {
    "number" : "5.2.2",
    "build_hash" : "f9d9b74",
    "build_date" : "2017-02-24T17:26:45.835Z",
    "build_snapshot" : false,
    "lucene_version" : "6.4.1"
  },
  "tagline" : "You Know, for Search"
}
```

Or if you want to see cluster information:

```
curl http://10.100.18.90:9200/_cluster/health?pretty
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
