# kubernetes-elasticsearch-cluster
Elasticsearch (5.1.1) cluster on top of Kubernetes made easy.

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

* Kubernetes cluster with **alpha features enabled** (tested with v1.5.1 on top of [Vagrant + CoreOS](https://github.com/pires/kubernetes-vagrant-coreos-cluster))
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
svc/elasticsearch             10.100.18.90     <pending>     9200:30565/TCP   50m
svc/elasticsearch-discovery   10.100.132.130   <none>        9300/TCP         50m
svc/kubernetes                10.100.0.1       <none>        443/TCP          59m

NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/es-client   2         2         2            2           1m
deploy/es-data     2         2         2            2           42s
deploy/es-master   3         3         3            3           4m

NAME                            READY     STATUS    RESTARTS   AGE
po/es-client-4262732819-42rwb   1/1       Running   0          1m
po/es-client-4262732819-6b784   1/1       Running   0          1m
po/es-data-3541237351-3jljw     1/1       Running   0          42s
po/es-data-3541237351-vmrgj     1/1       Running   0          42s
po/es-master-2236168375-87ntb   1/1       Running   0          4m
po/es-master-2236168375-hs8fx   1/1       Running   0          4m
po/es-master-2236168375-jjzpw   1/1       Running   0          4m
```

```
$ kubectl logs -f po/es-master-2236168375-jjzpw
[2017-01-10T13:02:32,631][INFO ][o.e.n.Node               ] [] initializing ...
[2017-01-10T13:02:32,818][INFO ][o.e.e.NodeEnvironment    ] [YRkHkWd] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [13.7gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2017-01-10T13:02:32,821][INFO ][o.e.e.NodeEnvironment    ] [YRkHkWd] heap size [247.5mb], compressed ordinary object pointers [true]
[2017-01-10T13:02:32,828][INFO ][o.e.n.Node               ] node name [YRkHkWd] derived from node ID [YRkHkWd2RfO7AwLPXyhujQ]; set [node.name] to override
[2017-01-10T13:02:32,840][INFO ][o.e.n.Node               ] version[5.1.1], pid[11], build[5395e21/2016-12-06T12:36:15.409Z], OS[Linux/4.8.15-coreos/amd64], JVM[Oracle Corporation/OpenJDK 64-Bit Server VM/1.8.0_111/25.111-b14]
[2017-01-10T13:02:35,077][INFO ][o.e.p.PluginsService     ] [YRkHkWd] loaded module [aggs-matrix-stats]
[2017-01-10T13:02:35,077][INFO ][o.e.p.PluginsService     ] [YRkHkWd] loaded module [ingest-common]
[2017-01-10T13:02:35,078][INFO ][o.e.p.PluginsService     ] [YRkHkWd] loaded module [lang-expression]
[2017-01-10T13:02:35,078][INFO ][o.e.p.PluginsService     ] [YRkHkWd] loaded module [lang-groovy]
[2017-01-10T13:02:35,078][INFO ][o.e.p.PluginsService     ] [YRkHkWd] loaded module [lang-mustache]
[2017-01-10T13:02:35,081][INFO ][o.e.p.PluginsService     ] [YRkHkWd] loaded module [lang-painless]
[2017-01-10T13:02:35,082][INFO ][o.e.p.PluginsService     ] [YRkHkWd] loaded module [percolator]
[2017-01-10T13:02:35,082][INFO ][o.e.p.PluginsService     ] [YRkHkWd] loaded module [reindex]
[2017-01-10T13:02:35,083][INFO ][o.e.p.PluginsService     ] [YRkHkWd] loaded module [transport-netty3]
[2017-01-10T13:02:35,083][INFO ][o.e.p.PluginsService     ] [YRkHkWd] loaded module [transport-netty4]
[2017-01-10T13:02:35,085][INFO ][o.e.p.PluginsService     ] [YRkHkWd] no plugins loaded
[2017-01-10T13:02:35,555][WARN ][o.e.d.s.g.GroovyScriptEngineService] [groovy] scripts are deprecated, use [painless] scripts instead
[2017-01-10T13:02:41,656][INFO ][o.e.n.Node               ] initialized
[2017-01-10T13:02:41,656][INFO ][o.e.n.Node               ] [YRkHkWd] starting ...
[2017-01-10T13:02:42,345][INFO ][o.e.t.TransportService   ] [YRkHkWd] publish_address {10.244.104.2:9300}, bound_addresses {10.244.104.2:9300}
[2017-01-10T13:02:42,372][INFO ][o.e.b.BootstrapCheck     ] [YRkHkWd] bound or publishing to a non-loopback or non-link-local address, enforcing bootstrap checks
[2017-01-10T13:02:55,113][INFO ][o.e.c.s.ClusterService   ] [YRkHkWd] new_master {YRkHkWd}{YRkHkWd2RfO7AwLPXyhujQ}{Zbnfgf-KTLGgudA7UE5twg}{10.244.104.2}{10.244.104.2:9300}, added {{fj3iw4Y}{fj3iw4Y1RVi-nL1lIsXPtQ}{yF3Bfo3IQL-YfokyDTxSDQ}{10.244.45.2}{10.244.45.2:9300},{qjwZtTB}{qjwZtTBYRiOM2oz-Gapfag}{FuAW-dwsTPOPRZZUYmXCoQ}{10.244.101.2}{10.244.101.2:9300},}, reason: zen-disco-elected-as-master ([2] nodes joined)[{fj3iw4Y}{fj3iw4Y1RVi-nL1lIsXPtQ}{yF3Bfo3IQL-YfokyDTxSDQ}{10.244.45.2}{10.244.45.2:9300}, {qjwZtTB}{qjwZtTBYRiOM2oz-Gapfag}{FuAW-dwsTPOPRZZUYmXCoQ}{10.244.101.2}{10.244.101.2:9300}]
[2017-01-10T13:02:55,261][INFO ][o.e.n.Node               ] [YRkHkWd] started
[2017-01-10T13:02:55,371][INFO ][o.e.g.GatewayService     ] [YRkHkWd] recovered [0] indices into cluster_state
[2017-01-10T13:05:55,017][INFO ][o.e.c.s.ClusterService   ] [YRkHkWd] added {{OXvJf4E}{OXvJf4EPRQm0qXO3jXFezQ}{5qkKCoLdQUCpXU0627Aghw}{10.244.39.3}{10.244.39.3:9300},}, reason: zen-disco-node-join[{OXvJf4E}{OXvJf4EPRQm0qXO3jXFezQ}{5qkKCoLdQUCpXU0627Aghw}{10.244.39.3}{10.244.39.3:9300}]
[2017-01-10T13:05:55,501][INFO ][o.e.c.s.ClusterService   ] [YRkHkWd] added {{m_HYFOL}{m_HYFOLwRauyE7ACaiKlwQ}{_TkBJ0PuR1eB8F6ShVYwDQ}{10.244.45.3}{10.244.45.3:9300},}, reason: zen-disco-node-join[{m_HYFOL}{m_HYFOLwRauyE7ACaiKlwQ}{_TkBJ0PuR1eB8F6ShVYwDQ}{10.244.45.3}{10.244.45.3:9300}]
[2017-01-10T13:06:29,344][INFO ][o.e.c.s.ClusterService   ] [YRkHkWd] added {{TwKmCsx}{TwKmCsxDSwi-VLvZ2Fi9-A}{qFq2GG15Tly_j3EYvjMkUQ}{10.244.101.3}{10.244.101.3:9300},}, reason: zen-disco-node-join[{TwKmCsx}{TwKmCsxDSwi-VLvZ2Fi9-A}{qFq2GG15Tly_j3EYvjMkUQ}{10.244.101.3}{10.244.101.3:9300}]
[2017-01-10T13:06:30,838][INFO ][o.e.c.s.ClusterService   ] [YRkHkWd] added {{DgJsL0p}{DgJsL0pAQeSfOxIcHLVOvA}{CfGlrnnNTNKkMHeIzOxuEA}{10.244.45.4}{10.244.45.4:9300},}, reason: zen-disco-node-join[{DgJsL0p}{DgJsL0pAQeSfOxIcHLVOvA}{CfGlrnnNTNKkMHeIzOxuEA}{10.244.45.4}{10.244.45.4:9300}]
```

As you can assert, the cluster is up and running. Easy, wasn't it?

### Access the service

*Don't forget* that services in Kubernetes are only acessible from containers in the cluster. For different behavior you should [configure the creation of an external load-balancer](http://kubernetes.io/v1.1/docs/user-guide/services.html#type-loadbalancer). While it's supported within this example service descriptor, its usage is out of scope of this document, for now.

```
$ kubectl get svc elasticsearch
NAME            CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
elasticsearch   10.100.18.90   <pending>     9200:30565/TCP   50m
```

From any host on your cluster (that's running `kube-proxy`), run:

```
curl http://10.100.18.90:9200
```

You should see something similar to the following:

```json
{
  "name" : "m_HYFOL",
  "cluster_name" : "myesdb",
  "cluster_uuid" : "LRe1dWqzSGSP5oURwLlzxQ",
  "version" : {
    "number" : "5.1.1",
    "build_hash" : "5395e21",
    "build_date" : "2016-12-06T12:36:15.409Z",
    "build_snapshot" : false,
    "lucene_version" : "6.3.0"
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
