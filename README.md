# openshift-psap
OpenShift Performance-Sensitive Application Platform Artifacts

* Master is the latest version of OpenShift (possibly not publicly released yet).  Each public release will have a branch.  Make sure to use the branch corresponding to the version of OpenShift that you're running.

```git clone -b ocp39 https://github.com/redhat-performance/openshift-psap```

* Edit the inventory/inventory.example and replace the master and fast_nodes with node names in your cluster.

## Ansible Roles

### nvidia-driver-install
This role will pull down the latest 3rd party NVIDIA driver and install it.

### nvidia-container-runtime-hook
This role will install the nvidia-container-runtime-hook which is used to mount libraries from the host into a pod whose dockerfile has certain environment variables.

### nvidia-device-plugin
This role will deploy the NVIDIA device-plugin daemonset, which allows you to schedule GPU pods.  After deploying, run:
```oc describe node x.x.x.x | grep -A15 Capacity```.  You should see nvidia.com/gpu=N where N is the number of GPUs in the system.

### gpu-pod
This role will create a new pod that leverages Taints and Tolerations to run on the fastnode pool.  It consumes a GPU.  The pod sleeps indefinitely.  To test your GPU pod:
Also included is a basic Dockerfile that is based on the NVIDIA CUDA 9.1 CentOS7 image and includes the deviceQuery binary used below.

Run the deviceQuery command.  This demonstrates that the process in the pod has access to the GPU hardware.  If it did not, the Result at the bottom would indicate FAIL.
```
# oc rsh gpu-pod /usr/local/cuda-9.1/samples/1_Utilities/deviceQuery/deviceQuery
/usr/local/cuda-9.1/samples/1_Utilities/deviceQuery/deviceQuery Starting...

 CUDA Device Query (Runtime API) version (CUDART static linking)

Detected 1 CUDA Capable device(s)

Device 0: "Tesla M60"
  CUDA Driver Version / Runtime Version          9.1 / 9.1
  CUDA Capability Major/Minor version number:    5.2
  Total amount of global memory:                 7619 MBytes (7988903936 bytes)
  (16) Multiprocessors, (128) CUDA Cores/MP:     2048 CUDA Cores
  GPU Max Clock rate:                            1178 MHz (1.18 GHz)
  Memory Clock rate:                             2505 Mhz
  Memory Bus Width:                              256-bit
  L2 Cache Size:                                 2097152 bytes
  Maximum Texture Dimension Size (x,y,z)         1D=(65536), 2D=(65536, 65536), 3D=(4096, 4096, 4096)
  Maximum Layered 1D Texture Size, (num) layers  1D=(16384), 2048 layers
  Maximum Layered 2D Texture Size, (num) layers  2D=(16384, 16384), 2048 layers
  Total amount of constant memory:               65536 bytes
  Total amount of shared memory per block:       49152 bytes
  Total number of registers available per block: 65536
  Warp size:                                     32
  Maximum number of threads per multiprocessor:  2048
  Maximum number of threads per block:           1024
  Max dimension size of a thread block (x,y,z): (1024, 1024, 64)
  Max dimension size of a grid size    (x,y,z): (2147483647, 65535, 65535)
  Maximum memory pitch:                          2147483647 bytes
  Texture alignment:                             512 bytes
  Concurrent copy and kernel execution:          Yes with 2 copy engine(s)
  Run time limit on kernels:                     No
  Integrated GPU sharing Host Memory:            No
  Support host page-locked memory mapping:       Yes
  Alignment requirement for Surfaces:            Yes
  Device has ECC support:                        Enabled
  Device supports Unified Addressing (UVA):      Yes
  Supports Cooperative Kernel Launch:            No
  Supports MultiDevice Co-op Kernel Launch:      No
  Device PCI Domain ID / Bus ID / location ID:   0 / 0 / 30
  Compute Mode:
     < Default (multiple host threads can use ::cudaSetDevice() with device simultaneously) >

deviceQuery, CUDA Driver = CUDART, CUDA Driver Version = 9.1, CUDA Runtime Version = 9.1, NumDevs = 1
Result = PASS
```

The gpu-pod role also includes a caffe2 Multi-GPU jupyter notebook demo.  Deploy the caffe2 environment like so:

```ansible-playbook -i inventory/inv playbooks/gpu-pod.yaml```

To access the jupyter webserver run the ```get_url.sh`` script on the master.

```
playbooks/gpu-pod/get_url.sh
```

get_url.sh will output a route and token.

Use the token to authenticate to route:
http://<route>/notebooks/caffe2/caffe2/python/tutorials/Multi-GPU_Training.ipynb?token=<token>

### tuned-setup
This role will demonstrate use of the tuned tuning profile delivery mechanism to partition your node into two sections; housekeeping and isolated cores.  These cores are de-jittered (as much as possible) from kernel activity and will not run userspace threads unless those threads have their affinity explicitly defined.

The ansible inventory includes several variables use to configure tuned:

* ```isolated_cores``` the list of cores to be de-jittered.
* ```nr_hugepages``` the number of 2Mi hugepages to be allocated.

### tandt-setup
This role will demonstrate use of Taints and Tolerations to carve out a "node pool" called fastnode.  Pods without matching tolerations will not be scheduled to this isolated pool.

### node-feature-discovery-setup
This role will demonstrate the use of the node-feature-discovery Kubernetes Incubator project to discovery hardware characteristics (such as CPU capabilities) on the node.  node-feature-discovery then labels the nodes for use in scheduling decisions.  This role deploys NFD as a daemonset.  For more information about NFD, see the following [link](https://github.com/kubernetes-incubator/node-feature-discovery)

Here is what the daemonset looks like when deployed:

```
# oc get ds -n node-feature-discovery
NAME                     DESIRED   CURRENT   READY     UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
node-feature-discovery   3         3         3         3            3           <none>          5m
```
```
And here are the labels that NFD has added to each node:

# oc describe node ip-172-31-4-25.us-west-2.compute.internal | grep incubator
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-ADX=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-AESNI=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-AVX=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-AVX2=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-BMI1=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-BMI2=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-CLMUL=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-CMOV=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-CX16=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-ERMS=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-F16C=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-FMA3=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-HLE=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-HTT=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-LZCNT=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-MMX=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-MMXEXT=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-NX=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-POPCNT=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-RDRAND=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-RDSEED=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-RDTSCP=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-RTM=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-SSE=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-SSE2=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-SSE3=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-SSE4.1=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-SSE4.2=true
                    node.alpha.kubernetes-incubator.io/nfd-cpuid-SSSE3=true
                    node.alpha.kubernetes-incubator.io/node-feature-discovery.version=v0.1.0-40-g58c9f11
```

### cpumanager-hugepages
This role will creates a pod that runs on the de-jittered cores created by the tuned profile.

* It uses taints and tolerations to steer the pods towards a node in the fastnode pool.
* It enables the CPUManager feature gate in the kubelet.
* It enables the HugePages feature gate in the kubelet and the apiserver.
* It deploys a pod that consumes 2 exclusive cores, 2GB of regular memory and (100) 2Mi HugePages.
* It then runs map_hugetlb application to actually consume the HugePages.

### sysctl
This role will create a pod that uses both safe and unsafe sysctls.  Unsafe sysctls are those known to not be namespaced in the kernel, thus their usage in containerized environments may affect other containers on the same host.

* It uses taints and toleration to steer the pods towards a node in the fastnode pool.
* "Safe" sysctls are enabled by default.
* "Unsafe" sysctls are enabled by enabling experimental unsafe-sysctls support in the kubelet.
* It launches a pod that changes both safe and unsafe sysctls and verifies that those values were updated correctly.

```
# oc exec -it sysctl-pod sysctl kernel.shm_rmid_forced net.core.somaxconn kernel.shmmni
kernel.shm_rmid_forced = 1 # This sysctl is in the "safe" whitelist.  default is 0.
net.core.somaxconn = 10000 # This sysctl (all of net.*) is in the "unsafe" list.  default is 128.
kernel.shmmni = 8192 # This sysctl is also in the "unsafe" list.  default is 4096.
```
