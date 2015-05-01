FROM pires/docker-elasticsearch

MAINTAINER pjpires@gmail.com

# Override elasticsearch.yml config, otherwise plug-in install will fail
ADD elasticsearch.yml /elasticsearch/config/elasticsearch.yml
ADD logging.yml /elasticsearch/config/logging.yml

# Install Kubernetes discovery plug-in
RUN /elasticsearch/bin/plugin --install io.fabric8/elasticsearch-cloud-kubernetes/1.1.1 --verbose
