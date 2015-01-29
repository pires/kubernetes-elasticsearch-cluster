# Ubuntu 14.04.x + Oracle JRE 8
FROM dockerfile/elasticsearch

MAINTAINER pjpires@gmail.com

# Export HTTP & Transport
EXPOSE 9200 9300

# Override elasticsearch.yml config
ADD elasticsearch.yml /elasticsearch/config/elasticsearch.yml

# Install Kubernetes discovery plug-in
RUN /elasticsearch/bin/plugin --install io.fabric8/elasticsearch-cloud-kubernetes/1.0.1 --verbose
