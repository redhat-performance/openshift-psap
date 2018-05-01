#!/bin/sh
ROUTE=$(oc get routes -n nvidia | grep caffe2 | awk '{print $2}')
TOKEN=$(oc logs -n nvidia pod/caffe2|head -4|grep token=|awk -Ftoken= '{print $2}')                         
echo http://$ROUTE/notebooks/caffe2/caffe2/python/tutorials/Multi-GPU_Training.ipynb?token=$TOKEN          
