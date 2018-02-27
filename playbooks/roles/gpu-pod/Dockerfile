FROM nvidia/cuda:9.1-devel-centos7
RUN yum install -y cuda-samples-9-1.x86_64
RUN cd /usr/local/cuda-9.1/samples/1_Utilities/deviceQuery && make
