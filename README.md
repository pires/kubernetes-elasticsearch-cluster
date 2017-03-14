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
NAME                          CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
svc/elasticsearch             10.100.71.108   <pending>     9200:31651/TCP   4m
svc/elasticsearch-discovery   10.100.53.60    <none>        9300/TCP         4m
svc/kubernetes                10.100.0.1      <none>        443/TCP          24m

NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/es-client   2         2         2            2           56s
deploy/es-data     2         2         2            2           55s
deploy/es-master   3         3         3            3           4m

NAME                            READY     STATUS    RESTARTS   AGE
po/es-client-1098028550-1915s   1/1       Running   0          55s
po/es-client-1098028550-8mkhw   1/1       Running   0          55s
po/es-data-1376153705-mn0g8     1/1       Running   0          55s
po/es-data-1376153705-q56ms     1/1       Running   0          55s
po/es-master-1414048425-9c1px   1/1       Running   0          4m
po/es-master-1414048425-sqk5j   1/1       Running   0          4m
po/es-master-1414048425-zc9t1   1/1       Running   0          4m
```

```
$ kubectl logs po/es-master-1414048425-9c1px
[2017-03-14T19:02:36,162][INFO ][o.e.n.Node               ] [es-master-1414048425-9c1px] initializing ...
[2017-03-14T19:02:36,370][INFO ][o.e.e.NodeEnvironment    ] [es-master-1414048425-9c1px] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [13.5gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2017-03-14T19:02:36,371][INFO ][o.e.e.NodeEnvironment    ] [es-master-1414048425-9c1px] heap size [247.5mb], compressed ordinary object pointers [true]
[2017-03-14T19:02:36,375][INFO ][o.e.n.Node               ] [es-master-1414048425-9c1px] node name [es-master-1414048425-9c1px], node ID [WbRRfEJgSZezPoiiSzACaw]
[2017-03-14T19:02:36,384][INFO ][o.e.n.Node               ] [es-master-1414048425-9c1px] version[5.2.2], pid[11], build[f9d9b74/2017-02-24T17:26:45.835Z], OS[Linux/4.10.1-coreos/amd64], JVM[Oracle Corporation/OpenJDK 64-Bit Server VM/1.8.0_111/25.111-b14]
[2017-03-14T19:02:40,974][INFO ][o.e.p.PluginsService     ] [es-master-1414048425-9c1px] loaded module [aggs-matrix-stats]
[2017-03-14T19:02:40,975][INFO ][o.e.p.PluginsService     ] [es-master-1414048425-9c1px] loaded module [ingest-common]
[2017-03-14T19:02:40,975][INFO ][o.e.p.PluginsService     ] [es-master-1414048425-9c1px] loaded module [lang-expression]
[2017-03-14T19:02:40,975][INFO ][o.e.p.PluginsService     ] [es-master-1414048425-9c1px] loaded module [lang-groovy]
[2017-03-14T19:02:40,975][INFO ][o.e.p.PluginsService     ] [es-master-1414048425-9c1px] loaded module [lang-mustache]
[2017-03-14T19:02:40,976][INFO ][o.e.p.PluginsService     ] [es-master-1414048425-9c1px] loaded module [lang-painless]
[2017-03-14T19:02:40,976][INFO ][o.e.p.PluginsService     ] [es-master-1414048425-9c1px] loaded module [percolator]
[2017-03-14T19:02:40,976][INFO ][o.e.p.PluginsService     ] [es-master-1414048425-9c1px] loaded module [reindex]
[2017-03-14T19:02:40,977][INFO ][o.e.p.PluginsService     ] [es-master-1414048425-9c1px] loaded module [transport-netty3]
[2017-03-14T19:02:40,977][INFO ][o.e.p.PluginsService     ] [es-master-1414048425-9c1px] loaded module [transport-netty4]
[2017-03-14T19:02:40,979][INFO ][o.e.p.PluginsService     ] [es-master-1414048425-9c1px] no plugins loaded
[2017-03-14T19:02:41,678][WARN ][o.e.d.s.g.GroovyScriptEngineService] [groovy] scripts are deprecated, use [painless] scripts instead
[2017-03-14T19:02:49,823][INFO ][o.e.n.Node               ] [es-master-1414048425-9c1px] initialized
[2017-03-14T19:02:49,823][INFO ][o.e.n.Node               ] [es-master-1414048425-9c1px] starting ...
[2017-03-14T19:02:50,244][WARN ][i.n.u.i.MacAddressUtil   ] Failed to find a usable hardware address from the network interfaces; using random bytes: 2b:61:80:c4:3d:26:cb:d6
[2017-03-14T19:02:50,414][INFO ][o.e.t.TransportService   ] [es-master-1414048425-9c1px] publish_address {10.244.23.3:9300}, bound_addresses {10.244.23.3:9300}
[2017-03-14T19:02:50,431][INFO ][o.e.b.BootstrapChecks    ] [es-master-1414048425-9c1px] bound or publishing to a non-loopback or non-link-local address, enforcing bootstrap checks
[2017-03-14T19:02:53,772][INFO ][o.e.c.s.ClusterService   ] [es-master-1414048425-9c1px] detected_master {es-master-1414048425-sqk5j}{Dx97PIjIRLKP-bNKJSD3QQ}{izN8ilSxRO6EY7TFpg2awQ}{10.244.31.2}{10.244.31.2:9300}, added {{es-master-1414048425-sqk5j}{Dx97PIjIRLKP-bNKJSD3QQ}{izN8ilSxRO6EY7TFpg2awQ}{10.244.31.2}{10.244.31.2:9300},{es-master-1414048425-zc9t1}{F3Y0AfkFSh-0FsHTJDPuJQ}{rTnFmVvVTISsfZ2Wxk3JcQ}{10.244.80.2}{10.244.80.2:9300},}, reason: zen-disco-receive(from master [master {es-master-1414048425-sqk5j}{Dx97PIjIRLKP-bNKJSD3QQ}{izN8ilSxRO6EY7TFpg2awQ}{10.244.31.2}{10.244.31.2:9300} committed version [3]])
[2017-03-14T19:02:53,917][INFO ][o.e.n.Node               ] [es-master-1414048425-9c1px] started
[2017-03-14T19:05:30,551][INFO ][o.e.c.s.ClusterService   ] [es-master-1414048425-9c1px] added {{es-data-1376153705-q56ms}{HHS97wT1Tla0pUseDu418Q}{iP4gynUfQj21nQIlXHPmvw}{10.244.31.3}{10.244.31.3:9300},}, reason: zen-disco-receive(from master [master {es-master-1414048425-sqk5j}{Dx97PIjIRLKP-bNKJSD3QQ}{izN8ilSxRO6EY7TFpg2awQ}{10.244.31.2}{10.244.31.2:9300} committed version [4]])
[2017-03-14T19:05:30,760][INFO ][o.e.c.s.ClusterService   ] [es-master-1414048425-9c1px] added {{es-client-1098028550-8mkhw}{LiT0U2UjSNWXQQam9ay7Ig}{VcNQ20Q6TUKDEpwe_5ZSfA}{10.244.23.4}{10.244.23.4:9300},}, reason: zen-disco-receive(from master [master {es-master-1414048425-sqk5j}{Dx97PIjIRLKP-bNKJSD3QQ}{izN8ilSxRO6EY7TFpg2awQ}{10.244.31.2}{10.244.31.2:9300} committed version [5]])
[2017-03-14T19:05:42,669][INFO ][o.e.c.s.ClusterService   ] [es-master-1414048425-9c1px] added {{es-client-1098028550-1915s}{JlSHpfbqQvKe-fgRz6u0uA}{c7C8Da9hRG-CABDEQ8NysQ}{10.244.80.3}{10.244.80.3:9300},}, reason: zen-disco-receive(from master [master {es-master-1414048425-sqk5j}{Dx97PIjIRLKP-bNKJSD3QQ}{izN8ilSxRO6EY7TFpg2awQ}{10.244.31.2}{10.244.31.2:9300} committed version [6]])
[2017-03-14T19:05:44,652][INFO ][o.e.c.s.ClusterService   ] [es-master-1414048425-9c1px] added {{es-data-1376153705-mn0g8}{M8nx_q1URb-ILfyCOdHp7g}{Y99IfbPsTQKVWPddMAJtog}{10.244.80.4}{10.244.80.4:9300},}, reason: zen-disco-receive(from master [master {es-master-1414048425-sqk5j}{Dx97PIjIRLKP-bNKJSD3QQ}{izN8ilSxRO6EY7TFpg2awQ}{10.244.31.2}{10.244.31.2:9300} committed version [7]])
```

As you can assert, the cluster is up and running. Easy, wasn't it?

### Access the service

*Don't forget* that services in Kubernetes are only acessible from containers in the cluster. For different behavior you should [configure the creation of an external load-balancer](http://kubernetes.io/v1.1/docs/user-guide/services.html#type-loadbalancer). While it's supported within this example service descriptor, its usage is out of scope of this document, for now.

```
$ kubectl get svc elasticsearch
NAME            CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
elasticsearch   10.100.71.108   <pending>     9200:31651/TCP   4m
```

From any host on your cluster (that's running `kube-proxy`), run:

```
curl http://10.100.71.108:9200
```

You should see something similar to the following:

```json
{
  "name" : "es-client-1098028550-8mkhw",
  "cluster_name" : "myesdb",
  "cluster_uuid" : "yEh9VWBsQc2yzptFH6DP2A",
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
curl http://10.100.71.108:9200/_cluster/health?pretty
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
