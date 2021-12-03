# Chaos Mesh Breakage Testing 

## Intro
Chaos Mesh is an open source cloud-native breakage testing tool. It's widely configurable and capable of moking various types of fault scenarios. With Chaos Mesh you can easily simulate abnormalities in your K8s cluster that may occur in the reality to find potential issues in the system.

## Chaos Mesh Overview
Chaos Mesh is built on several K8s CRDs (Custom Resource Definition). The CRDs are mostly controllers for each different fault type. This controllers are used in experiments, and experiments are organized in workflows.

It also gathers three main components:
- Chaos Dashboard: Is a set of web interfaces which provides a friendly way to observe and implement experiments and workflows.
- Chaos Controller Manager: The core logical component of Chaos Mesh gathers controllers of various types.
- Chaos Daemon: Is the main executive component which hacks into the targeted namespace and it's deployed as a DaemonSet. 

## Installation

### Requirements
Current Chaos Mesh version 2.0.4 only supports Kubernetes versions prior to 1.22.0.

### Step 1:
First of all we need to add chaos-mesh repo to our helm repository:

    helm repo add chaos-mesh https://charts.chaos-mesh.org

### Step 2:
Create a namespace to install Chaos Mesh:

    kubectl create ns chaos-testing

### Step 3:
We will install a specific Chaos Mesh version for each kind of container runtime:

**`Docker`**:
    
    helm install chaos-mesh chaos-mesh/chaos-mesh -n=chaos-testing --set dashboard.securityMode=false --version 2.0.3

**`Containerd`**:
    
    helm install chaos-mesh chaos-mesh/chaos-mesh -n=chaos-testing --set dashboard.securityMode=false,chaosDaemon.runtime=containerd,chaosDaemon.socketPath=/run/containerd/containerd.sock --version 2.0.3

**`k3s`**:
    
    helm install chaos-mesh chaos-mesh/chaos-mesh -n=chaos-testing --set dashboard.securityMode=false,chaosDaemon.runtime=containerd,chaosDaemon.socketPath=/run/k3s/containerd/containerd.sock --version 2.0.3

### Verify the installation:
To check the running status of Chaos Mesh, execute this:

    kubectl get pods -n chaos-testing

The expected output is this:
```
NAME                                        READY   STATUS    RESTARTS   AGE
chaos-controller-manager-69fd5c46c8-xlqpc   1/1     Running   0          2d5h
chaos-daemon-jb8xh                          1/1     Running   0          2d5h
chaos-dashboard-98c4c5f97-tx5ds             1/1     Running   0          2d5h
```

## UI overview
Access the UI from it's nodeport issuing: `kubectl get svc -n chaos-testing`.

 ![Import window](./images/chaosdash.png)

From the ui, we can:
- Get an overall status from the main dashboard.
- Create/manage/schedule experiments.
- Create/manage/schedule workflows.
- Watch events.
- See the archived experiments.

## Experiments, Workflows & Events
Chaos Mesh primarily creates and manages experiments. This experiments are tasks/procedures based on fault injections. Then, the experiments can be arranged in workflows, and both of them can be scheduled. As a result of running experiments or workflows, events may be triggered. Experiments and workflows can be defined from the provided web-ui or through yaml manifests.

## Fault Injection
Chaos Mesh experiments main feature is fault injection. A real world distributed system might experiment various types of fault. Chaos Mesh provides three comprehensive and fine-grained fault types:
- Basic resource faults:
    - PodChaos: simulates Pod failures, such as Pod node restart, Pod's persistent unavailablility, and certain container failures in a specific Pod.
    - NetworkChaos: simulates network failures, such as network latency, packet loss, packet disorder, and network partitions.
    - DNSChaos: simulates DNS failures, such as the parsing failure of DNS domain name and the wrong IP address returned.
    - HTTPChaos: simulates HTTP communication failures, such as HTTP communication latency.
    - StressChaos: simulates CPU race or memory race.
    - IOChaos: simulates the I/O failure of an application file, such as I/O delays, read and write failures.
    - TimeChaos: simulates the time jump exception.
    - KernelChaos: simulates kernel failures, such as an exception of the application memory allocation.
- Platform faults:
    - AWSChaos: simulates AWS platform failures, such as the AWS node restart.
    - GCPChaos: simulates GCP platform failures, such as the GCP node restart.
- Application faults:
    - JVMChaos: simulates JVM application failures, such as the function call delay.

## Examples
This folder includes a set of manifests in order to achieve a basic breakage testing of our deployed services.

- Random pod failure: This experiment simulates a random pod failure in the sd namespace. To execute this experiment issue:
    `kubectl apply -f rand-pod-failure.yaml`

- Random container failure: One container in the sd services spectrum will be killed randomly. Run the experiment with:
    `kubectl apply -f rand-container-failure.yaml`

- Bandwidth limitation: The provided example will limit the UI's bandwith to 128 bps for 5 minutes. To apply this experiment:
    `kubectl apply -f sd-ui-bandwidth-limitation.yaml`

- Stress test: This kind of test creates cpu/memory stressors in order to constraint pod resources. The provided example will create a load of the 80% of the cpu and retreive 1gb of ram from each pod. Run it with the following command:
    `kubectl apply -f stress-test.yaml` 

**`Note`:** The examples are meant to run under sd namespace. Please, change the sd occurences in the manifest in order to adapt them to your Service Director namespace. 

This is just a demonstration. In order to create complex experiments/workflows, please, refer to the official Chaos Mesh [documentation](https://chaos-mesh.org/docs/).
