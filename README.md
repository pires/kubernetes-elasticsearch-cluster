# kubernetes-elasticsearch-cluster
Elasticsearch (1.5.1) cluster on top of Kubernetes made easy.

Elasticsearch best-practices recommend to separate nodes in three roles:
* ```Master``` nodes - intended for clustering management only, no data, no HTTP API
* ```Load-balancer``` nodes - intended for client usage, no data, with HTTP API
* ```Data``` nodes - intended for storing and indexing your data, no HTTP API

Given this, I'm hereby making possible for you to scale as needed. For instance, a good strong scenario could be 3 Masters, 3 Load-balancers, 5 data-nodes.

*Attention:* As of the moment, Kubernetes pod descriptors use an ```emptyDir``` for storing data in each data node container. This is meant to be for the sake of simplicity.

## Pre-requisites

* Docker (test with boot2docker v1.5.0)
* Kubernetes cluster (tested with v0.15.0 on top of [Vagrant + CoreOS](https://github.com/pires/kubernetes-vagrant-coreos-cluster))
* ```kubectl``` configured to access your cluster master API Server

## Build images (optional)

Providing your own version of [the images automatically built from this repository](https://registry.hub.docker.com/u/pires/elasticsearch) will not be supported. This is an *optional* step. You have been warned.

### Clone repository

```
git clone https://github.com/pires/kubernetes-elasticsearch-cluster.git
cd kubernetes-elasticsearch-cluster
```

### Base image

```
docker build -t pires/elasticsearch:base .
```

### Master

```
cd node-master
docker build -t pires/elasticsearch:master .
```

### Load-balancer

```
cd node-lb
docker build -t pires/elasticsearch:lb .
```

### Data-node

```
cd node-data
docker build -t pires/elasticsearch:data .
```

## Test

### Deploy

```
kubectl create -f elasticsearch-service.yaml
kubectl create -f elasticsearch-master-controller.yaml
kubectl create -f elasticsearch-lb-controller.yaml
kubectl create -f elasticsearch-data-controller.yaml
```

### Validate

I leave to you the steps to validate the provisioned pods, but first step is to wait for containers to be in ```RUNNING``` state and check the logs of the master (as in Elasticsearch):

```
kubectl get pods
```

You should see something like this:

```
POD                                    IP                  CONTAINER(S)           IMAGE(S)                                       HOST                LABELS                                       STATUS
6d8ed69a-a7ec-11e4-ac85-0800272d7481   10.244.31.2         elasticsearch-master   pires/elasticsearch:master   172.17.8.102/       component=elasticsearch,role=master          Running
60cd5145-a7ed-11e4-ac85-0800272d7481   10.244.23.2         elasticsearch-lb       pires/elasticsearch:lb       172.17.8.103/       component=elasticsearch,role=load-balancer   Running
73df38d5-a7ef-11e4-ac85-0800272d7481   10.244.23.3         elasticsearch-data     pires/elasticsearch:data     172.17.8.103/       component=elasticsearch,role=data            Running
```

Copy master pod identifier and check the logs:

```
kubectl log 6d8ed69a-a7ec-11e4-ac85-0800272d7481
```

You should see something like this:

```
2015-01-29T19:29:50.539060177Z [2015-01-29 19:29:50,538][WARN ][common.jna               ] Unable to lock JVM memory (ENOMEM). This can result in part of the JVM being swapped out. Increase RLIMIT_MEMLOCK (ulimit).
2015-01-29T19:29:50.699290311Z [2015-01-29 19:29:50,699][INFO ][node                     ] [Wild Child] version[1.4.4], pid[1], build[927caff/2014-12-16T14:11:12Z]
2015-01-29T19:29:50.699712844Z [2015-01-29 19:29:50,699][INFO ][node                     ] [Wild Child] initializing ...
2015-01-29T19:29:50.732790560Z [2015-01-29 19:29:50,732][INFO ][plugins                  ] [Wild Child] loaded [cloud-kubernetes], sites []
2015-01-29T19:29:57.026558676Z [2015-01-29 19:29:57,026][INFO ][node                     ] [Wild Child] initialized
2015-01-29T19:29:57.030435794Z [2015-01-29 19:29:57,030][INFO ][node                     ] [Wild Child] starting ...
2015-01-29T19:29:57.263863883Z [2015-01-29 19:29:57,263][INFO ][transport                ] [Wild Child] bound_address {inet[/0:0:0:0:0:0:0:0:9300]}, publish_address {inet[/10.244.31.2:9300]}
2015-01-29T19:29:57.289918432Z [2015-01-29 19:29:57,289][INFO ][discovery                ] [Wild Child] elasticsearch-k8s/FGcMtNT7SoOtGB2gdN-dTw
2015-01-29T19:30:00.953174610Z [2015-01-29 19:30:00,953][INFO ][cluster.service          ] [Wild Child] new_master [Wild Child][FGcMtNT7SoOtGB2gdN-dTw][6d8ed69a-a7ec-11e4-ac85-0800272d7481][inet[/10.244.31.2:9300]]{data=false, master=true}, reason: zen-disco-join (elected_as_master)
2015-01-29T19:30:00.978229728Z [2015-01-29 19:30:00,978][INFO ][node                     ] [Wild Child] started
2015-01-29T19:30:01.013945257Z [2015-01-29 19:30:01,013][INFO ][gateway                  ] [Wild Child] recovered [0] indices into cluster_state
2015-01-29T19:36:33.114534119Z [2015-01-29 19:36:33,114][INFO ][cluster.service          ] [Wild Child] added {[Pathway][A0HZ2ecjRlCDL7k2CLgJPg][60cd5145-a7ed-11e4-ac85-0800272d7481][inet[/10.244.23.2:9300]]{data=false, master=false},}, reason: zen-disco-receive(join from node[[Pathway][A0HZ2ecjRlCDL7k2CLgJPg][60cd5145-a7ed-11e4-ac85-0800272d7481][inet[/10.244.23.2:9300]]{data=false, master=false}])
2015-01-29T19:46:43.743491761Z [2015-01-29 19:46:43,743][INFO ][cluster.service          ] [Wild Child] added {[Leap-Frog][wML1_2l6SB-Vc4-fcOIRlQ][73df38d5-a7ef-11e4-ac85-0800272d7481][inet[/10.244.23.3:9300]]{master=false},}, reason: zen-disco-receive(join from node[[Leap-Frog][wML1_2l6SB-Vc4-fcOIRlQ][73df38d5-a7ef-11e4-ac85-0800272d7481][inet[/10.244.23.3:9300]]{master=false}])
```

As you can assert, the cluster is up and running. Easy, wasn't it?

### Scale

Scaling each type of node to handle your cluster is as easy as:

```
kubectl resize --replicas=3 replicationcontrollers elasticsearch-master
kubectl resize --replicas=2 replicationcontrollers elasticsearch-lb
kubectl resize --replicas=5 replicationcontrollers elasticsearch-data
```

### Access the service

*Don't forget* that services in Kubernetes are only acessible from containers in the cluster. For different behavior you should configure the creation of an external-loadbalancer, in your service. That's out of scope of this document, for now.

```
kubectl get service elasticsearch
```

You should see something like this:

```
NAME                LABELS              SELECTOR                                     IP                  PORT
elasticsearch       <none>              component=elasticsearch,role=load-balancer   10.244.225.170      9200
```

From inside one of the containers running in your cluster:

```
curl http://10.244.225.170:9200
```

This should be what you see:

```json
{
  "status" : 200,
  "name" : "Pathway",
  "cluster_name" : "elasticsearch-k8s",
  "version" : {
    "number" : "1.4.4",
    "build_hash" : "927caff6f05403e936c20bf4529f144f0c89fd8c",
    "build_timestamp" : "2014-12-16T14:11:12Z",
    "build_snapshot" : false,
    "lucene_version" : "4.10.3"
  },
  "tagline" : "You Know, for Search"
}
```

Or if you want to see information on all the Elasticsearch nodes:

```
curl http://10.244.225.170:9200/_nodes
```

The output should be too big to include here ;-)
