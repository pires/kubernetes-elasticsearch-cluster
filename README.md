# kubernetes-elasticsearch-cluster
Elasticsearch (5.2.2) cluster on top of Kubernetes made easy.

Links:
* [Important Notes](#important-notes)
* [Pre-Requisites](#pre-requisites)
* [Build-Images(optional)](#build-images)
* [Test (deploying & accessing)](#test)
* [Clean up with Curator](#curator)
* [FAQ](#faq)
* [Troubleshooting](#troubleshooting)



Elasticsearch best-practices recommend to separate nodes in three roles:
* `Master` nodes - intended for clustering management only, no data, no HTTP API
* `Client` nodes - intended for client usage, no data, with HTTP API
* `Data` nodes - intended for storing and indexing your data, no HTTP API

Given this, I'm going to demonstrate how to provision a (near, as storage is still an issue) production grade scenario consisting of 3 master, 2 client and 2 data nodes.

<a id="important-notes">
## (Very) Important notes

* Elasticsearch pods need for an init-container to run in privileged mode, so it can set some VM options. For that to happen, the `kubelet` should be running with args `--allow-privileged`, otherwise
the init-container will fail to run.

* By default, `ES_JAVA_OPTS` is set to `-Xms256m -Xmx256m`. This is a *very low* value but many users, i.e. `minikube` users, were having issues with pods getting killed because hosts were out of memory.
You can change this yourself in the deployment descriptors available in this repository.

* As of the moment, Kubernetes pod descriptors use an `emptyDir` for storing data in each data node container. This is meant to be for the sake of simplicity and should be adapted according to your storage needs.

* The [stateful](stateful) directory contains an example which deploys the data pods as a `StatefulSet`. These use a `volumeClaimTemplates` to provision persistent storage for each pod.

<a id="pre-requisites">
## Pre-requisites

* Kubernetes cluster with **alpha features enabled** (tested with v1.5.2 on top of [Vagrant + CoreOS](https://github.com/pires/kubernetes-vagrant-coreos-cluster))
* `kubectl` configured to access your cluster master API Server

<a id="build-images">
## Build images (optional)

Providing your own version of [the images automatically built from this repository](https://github.com/pires/docker-elasticsearch-kubernetes) will not be supported. This is an *optional* step. You have been warned.

<a id="test">
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
svc/elasticsearch             10.100.131.27   <pending>     9200:31167/TCP   3m
svc/elasticsearch-discovery   10.100.68.199   <none>        9300/TCP         3m
svc/kubernetes                10.100.0.1      <none>        443/TCP          9m

NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/es-client   2         2         2            2           2m
deploy/es-data     2         2         2            2           2m
deploy/es-master   3         3         3            3           3m

NAME                            READY     STATUS    RESTARTS   AGE
po/es-client-2639500660-9f89h   1/1       Running   0          2m
po/es-client-2639500660-t1k8n   1/1       Running   0          2m
po/es-data-3972755415-56hwx     1/1       Running   0          2m
po/es-data-3972755415-9zkfm     1/1       Running   0          2m
po/es-master-2387585559-7tdpx   1/1       Running   0          3m
po/es-master-2387585559-f63q7   1/1       Running   0          3m
po/es-master-2387585559-xw8cz   1/1       Running   0          3m
```

```
$ kubectl logs es-master-2387585559-xw8cz
[2017-04-05T09:36:04,279][INFO ][o.e.n.Node               ] [es-master-2387585559-xw8cz] initializing ...
[2017-04-05T09:36:04,499][INFO ][o.e.e.NodeEnvironment    ] [es-master-2387585559-xw8cz] using [1] data paths, mounts [[/data (/dev/sda9)]], net usable_space [13.6gb], net total_space [15.5gb], spins? [possibly], types [ext4]
[2017-04-05T09:36:04,500][INFO ][o.e.e.NodeEnvironment    ] [es-master-2387585559-xw8cz] heap size [247.5mb], compressed ordinary object pointers [true]
[2017-04-05T09:36:04,504][INFO ][o.e.n.Node               ] [es-master-2387585559-xw8cz] node name [es-master-2387585559-xw8cz], node ID [K9JghurbTUSrEpXxizmPrA]
[2017-04-05T09:36:04,513][INFO ][o.e.n.Node               ] [es-master-2387585559-xw8cz] version[5.3.0], pid[14], build[3adb13b/2017-03-23T03:31:50.652Z], OS[Linux/4.10.4-coreos-r1/amd64], JVM[Oracle Corporation/OpenJDK 64-Bit Server VM/1.8.0_121/25.121-b13]
[2017-04-05T09:36:07,593][INFO ][o.e.p.PluginsService     ] [es-master-2387585559-xw8cz] loaded module [aggs-matrix-stats]
[2017-04-05T09:36:07,593][INFO ][o.e.p.PluginsService     ] [es-master-2387585559-xw8cz] loaded module [ingest-common]
[2017-04-05T09:36:07,603][INFO ][o.e.p.PluginsService     ] [es-master-2387585559-xw8cz] loaded module [lang-expression]
[2017-04-05T09:36:07,613][INFO ][o.e.p.PluginsService     ] [es-master-2387585559-xw8cz] loaded module [lang-groovy]
[2017-04-05T09:36:07,613][INFO ][o.e.p.PluginsService     ] [es-master-2387585559-xw8cz] loaded module [lang-mustache]
[2017-04-05T09:36:07,613][INFO ][o.e.p.PluginsService     ] [es-master-2387585559-xw8cz] loaded module [lang-painless]
[2017-04-05T09:36:07,613][INFO ][o.e.p.PluginsService     ] [es-master-2387585559-xw8cz] loaded module [percolator]
[2017-04-05T09:36:07,613][INFO ][o.e.p.PluginsService     ] [es-master-2387585559-xw8cz] loaded module [reindex]
[2017-04-05T09:36:07,613][INFO ][o.e.p.PluginsService     ] [es-master-2387585559-xw8cz] loaded module [transport-netty3]
[2017-04-05T09:36:07,613][INFO ][o.e.p.PluginsService     ] [es-master-2387585559-xw8cz] loaded module [transport-netty4]
[2017-04-05T09:36:07,623][INFO ][o.e.p.PluginsService     ] [es-master-2387585559-xw8cz] no plugins loaded
[2017-04-05T09:36:17,326][INFO ][o.e.n.Node               ] [es-master-2387585559-xw8cz] initialized
[2017-04-05T09:36:17,328][INFO ][o.e.n.Node               ] [es-master-2387585559-xw8cz] starting ...
[2017-04-05T09:36:17,692][WARN ][i.n.u.i.MacAddressUtil   ] Failed to find a usable hardware address from the network interfaces; using random bytes: e6:60:38:71:02:5a:41:8b
[2017-04-05T09:36:17,933][INFO ][o.e.t.TransportService   ] [es-master-2387585559-xw8cz] publish_address {10.244.6.2:9300}, bound_addresses {10.244.6.2:9300}
[2017-04-05T09:36:17,988][INFO ][o.e.b.BootstrapChecks    ] [es-master-2387585559-xw8cz] bound or publishing to a non-loopback or non-link-local address, enforcing bootstrap checks
[2017-04-05T09:36:21,216][INFO ][o.e.c.s.ClusterService   ] [es-master-2387585559-xw8cz] new_master {es-master-2387585559-xw8cz}{K9JghurbTUSrEpXxizmPrA}{GKs6dCrTRtCYX-96mKjxEA}{10.244.6.2}{10.244.6.2:9300}, added {{es-master-2387585559-7tdpx}{a0HceF7IQAytke5t8xOOuA}{CUu_FnIqQuCSd7wFsQ6jMQ}{10.244.25.3}{10.244.25.3:9300},}, reason: zen-disco-elected-as-master ([1] nodes joined)[{es-master-2387585559-7tdpx}{a0HceF7IQAytke5t8xOOuA}{CUu_FnIqQuCSd7wFsQ6jMQ}{10.244.25.3}{10.244.25.3:9300}]
[2017-04-05T09:36:21,321][INFO ][o.e.n.Node               ] [es-master-2387585559-xw8cz] started
[2017-04-05T09:36:21,469][INFO ][o.e.g.GatewayService     ] [es-master-2387585559-xw8cz] recovered [0] indices into cluster_state
[2017-04-05T09:36:27,306][INFO ][o.e.c.s.ClusterService   ] [es-master-2387585559-xw8cz] added {{es-master-2387585559-f63q7}{h85MLxj1RluSt4Flc4IZiQ}{GMOYzf5uRvuPkRCkzhCDkA}{10.244.52.2}{10.244.52.2:9300},}, reason: zen-disco-node-join[{es-master-2387585559-f63q7}{h85MLxj1RluSt4Flc4IZiQ}{GMOYzf5uRvuPkRCkzhCDkA}{10.244.52.2}{10.244.52.2:9300}]
[2017-04-05T09:37:15,131][INFO ][o.e.c.s.ClusterService   ] [es-master-2387585559-xw8cz] added {{es-client-2639500660-9f89h}{73QynpQ7TuOpwNLObTyN9w}{dVqM03QlTLOR8nnwo5U3KQ}{10.244.25.4}{10.244.25.4:9300},}, reason: zen-disco-node-join[{es-client-2639500660-9f89h}{73QynpQ7TuOpwNLObTyN9w}{dVqM03QlTLOR8nnwo5U3KQ}{10.244.25.4}{10.244.25.4:9300}]
[2017-04-05T09:37:16,326][INFO ][o.e.c.s.ClusterService   ] [es-master-2387585559-xw8cz] added {{es-data-3972755415-56hwx}{1GjUxBERRUKNO_v_xBmYAA}{p47k2DhGSOqc3ffZ7dXXmQ}{10.244.52.3}{10.244.52.3:9300},}, reason: zen-disco-node-join[{es-data-3972755415-56hwx}{1GjUxBERRUKNO_v_xBmYAA}{p47k2DhGSOqc3ffZ7dXXmQ}{10.244.52.3}{10.244.52.3:9300}]
[2017-04-05T09:37:29,922][INFO ][o.e.c.s.ClusterService   ] [es-master-2387585559-xw8cz] added {{es-client-2639500660-t1k8n}{QWejqvjqQ1yqjy5zaCF8UA}{Q4KAOUU0RIeeMt7XKFxSQg}{10.244.6.3}{10.244.6.3:9300},}, reason: zen-disco-node-join[{es-client-2639500660-t1k8n}{QWejqvjqQ1yqjy5zaCF8UA}{Q4KAOUU0RIeeMt7XKFxSQg}{10.244.6.3}{10.244.6.3:9300}]
[2017-04-05T09:37:31,236][INFO ][o.e.c.s.ClusterService   ] [es-master-2387585559-xw8cz] added {{es-data-3972755415-9zkfm}{OGbRr6xYRA-48yz05S2w8Q}{Xm_RnNlBTXmrG-d8c-IBow}{10.244.6.4}{10.244.6.4:9300},}, reason: zen-disco-node-join[{es-data-3972755415-9zkfm}{OGbRr6xYRA-48yz05S2w8Q}{Xm_RnNlBTXmrG-d8c-IBow}{10.244.6.4}{10.244.6.4:9300}]
```

As you can assert, the cluster is up and running. Easy, wasn't it?

### Access the service

*Don't forget* that services in Kubernetes are only acessible from containers in the cluster. For different behavior you should [configure the creation of an external load-balancer](http://kubernetes.io/v1.1/docs/user-guide/services.html#type-loadbalancer). While it's supported within this example service descriptor, its usage is out of scope of this document, for now.

```
$ kubectl get svc elasticsearch
NAME            CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
elasticsearch   10.100.131.27   <pending>     9200:31167/TCP   5m
```

From any host on your cluster (that's running `kube-proxy`), run:

```
curl http://10.100.131.27:9200
```

You should see something similar to the following:

```json
{
  "name" : "es-client-2639500660-t1k8n",
  "cluster_name" : "myesdb",
  "cluster_uuid" : "obAMiJP8QtO2KNjLjlo1hQ",
  "version" : {
    "number" : "5.3.0",
    "build_hash" : "3adb13b",
    "build_date" : "2017-03-23T03:31:50.652Z",
    "build_snapshot" : false,
    "lucene_version" : "6.4.1"
  },
  "tagline" : "You Know, for Search"
}
```

Or if you want to see cluster information:

```
curl http://10.100.131.27:9200/_cluster/health?pretty
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

<a id="#curator">
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

<a id="faq">
## FAQ
### Why does `NUMBER_OF_MASTERS` differ from number of master-replicas?
The default value for this environment variable is 2, meaning a cluster will need a minimum of 2 master nodes to operate. If you have 3 masters and one dies, the cluster still works. Minimum master nodes are usually `n/2 + 1`, where `n` is the number of master nodes in a cluster. If you have 5 master nodes, you should have a minimum of 3, less than that and the cluster _stops_. If you scale the number of masters, make sure to update the minimum number of master nodes through the Elasticsearch API as setting environment variable will only work on cluster setup. More info: https://www.elastic.co/guide/en/elasticsearch/guide/1.x/_important_configuration_changes.html#_minimum_master_nodes


### How can I customize `elasticsearch.yaml`?
Read a different config file by settings env var `path.conf=/path/to/my/config/`. Another option would be to build your own image from  [this repository](https://github.com/pires/docker-elasticsearch-kubernetes)

## Troubleshooting
One of the errors you may come across when running the setup is the following error:

    [2016-11-29T01:28:36,515][WARN ][o.e.b.ElasticsearchUncaughtExceptionHandler] [] uncaught exception in thread [main]
    org.elasticsearch.bootstrap.StartupException: java.lang.IllegalArgumentException: No up-and-running site-local (private) addresses found, got [name:lo (lo), name:eth0 (eth0)]
    	at org.elasticsearch.bootstrap.Elasticsearch.init(Elasticsearch.java:116) ~[elasticsearch-5.0.1.jar:5.0.1]
    	at org.elasticsearch.bootstrap.Elasticsearch.execute(Elasticsearch.java:103) ~[elasticsearch-5.0.1.jar:5.0.1]
    	at org.elasticsearch.cli.SettingCommand.execute(SettingCommand.java:54) ~[elasticsearch-5.0.1.jar:5.0.1]
    	at org.elasticsearch.cli.Command.mainWithoutErrorHandling(Command.java:96) ~[elasticsearch-5.0.1.jar:5.0.1]
    	at org.elasticsearch.cli.Command.main(Command.java:62) ~[elasticsearch-5.0.1.jar:5.0.1]
    	at org.elasticsearch.bootstrap.Elasticsearch.main(Elasticsearch.java:80) ~[elasticsearch-5.0.1.jar:5.0.1]
    	at org.elasticsearch.bootstrap.Elasticsearch.main(Elasticsearch.java:73) ~[elasticsearch-5.0.1.jar:5.0.1]
    Caused by: java.lang.IllegalArgumentException: No up-and-running site-local (private) addresses found, got [name:lo (lo), name:eth0 (eth0)]
    	at org.elasticsearch.common.network.NetworkUtils.getSiteLocalAddresses(NetworkUtils.java:187) ~[elasticsearch-5.0.1.jar:5.0.1]
    	at org.elasticsearch.common.network.NetworkService.resolveInternal(NetworkService.java:246) ~[elasticsearch-5.0.1.jar:5.0.1]
    	at org.elasticsearch.common.network.NetworkService.resolveInetAddresses(NetworkService.java:220) ~[elasticsearch-5.0.1.jar:5.0.1]
    	at org.elasticsearch.common.network.NetworkService.resolveBindHostAddresses(NetworkService.java:130) ~[elasticsearch-5.0.1.jar:5.0.1]
    	at org.elasticsearch.transport.TcpTransport.bindServer(TcpTransport.java:575) ~[elasticsearch-5.0.1.jar:5.0.1]
    	at org.elasticsearch.transport.netty4.Netty4Transport.doStart(Netty4Transport.java:182) ~[?:?]
    	at org.elasticsearch.common.component.AbstractLifecycleComponent.start(AbstractLifecycleComponent.java:68) ~[elasticsearch-5.0.1.jar:5.0.1]
    	at org.elasticsearch.transport.TransportService.doStart(TransportService.java:182) ~[elasticsearch-5.0.1.jar:5.0.1]
    	at org.elasticsearch.common.component.AbstractLifecycleComponent.start(AbstractLifecycleComponent.java:68) ~[elasticsearch-5.0.1.jar:5.0.1]
    	at org.elasticsearch.node.Node.start(Node.java:525) ~[elasticsearch-5.0.1.jar:5.0.1]
    	at org.elasticsearch.bootstrap.Bootstrap.start(Bootstrap.java:211) ~[elasticsearch-5.0.1.jar:5.0.1]
    	at org.elasticsearch.bootstrap.Bootstrap.init(Bootstrap.java:288) ~[elasticsearch-5.0.1.jar:5.0.1]
    	at org.elasticsearch.bootstrap.Elasticsearch.init(Elasticsearch.java:112) ~[elasticsearch-5.0.1.jar:5.0.1]
    	... 6 more
    [2016-11-29T01:28:37,448][INFO ][o.e.n.Node               ] [kIEYQSE] stopping ...
    [2016-11-29T01:28:37,451][INFO ][o.e.n.Node               ] [kIEYQSE] stopped
    [2016-11-29T01:28:37,452][INFO ][o.e.n.Node               ] [kIEYQSE] closing ...
    [2016-11-29T01:28:37,464][INFO ][o.e.n.Node               ] [kIEYQSE] closed

This is related to how the docker container binds to network ports, it defaults to ``_local_``. Please see [the documentation](https://github.com/pires/docker-elasticsearch#environment-variables) for reference of options.

The fix is to add the environment variable NETWORK_HOST to the kubernetes files (es-master.yaml, es-client.yaml, and es-data.yaml), under the spec containers section you will just need to add the following:

    - name: "NETWORK_HOST"
      value: "_eth0_"
