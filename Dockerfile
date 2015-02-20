# Ubuntu 14.04.x + Oracle JRE 8
FROM dockerfile/elasticsearch

MAINTAINER pjpires@gmail.com

# Export HTTP & Transport
EXPOSE 9200 9300

# Install runit
RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe" > /etc/apt/sources.list && \
  apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y runit && \
  apt-get autoremove -y && \
  apt-get autoclean

# Override elasticsearch.yml config, otherwise plug-in install will fail
ADD elasticsearch.yml /elasticsearch/config/elasticsearch.yml

# Install Kubernetes discovery plug-in
RUN /elasticsearch/bin/plugin --install io.fabric8/elasticsearch-cloud-kubernetes/1.0.3 --verbose

ADD run-elasticsearch.sh /etc/service/elasticsearch/run
RUN chmod u+x /etc/service/elasticsearch/run

CMD ["/usr/bin/runsvdir", "-P", "/etc/service"]
