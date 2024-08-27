# Contents
- [Connect your Digital Human Pipeline to Domain Adapted RAG](#connect-your-digital-human-pipeline-to-domain-adapted-rag)
- [PEFT (LoRA) Customization with NeMo Framework 24.05 (Optional)](#peft-lora-customization-with-nemo-framework-2405)

# Connect your Digital Human Pipeline to Domain Adapted RAG

The Tokkio LLM-RAG sample application provides a reference for the users to showcase how an LLM or a RAG can be easily connected to the Tokkio pipeline. In this example, Tokkio and the RAG are deployed separately and are communicating using the REST API. 
Refer to the detailed documentation: [Tokkio-LLM-RAG-Bot Documentation](https://docs.nvidia.com/ace/latest/workflows/tokkio/text/Tokkio_LLM_RAG_Bot.html)

From the previous section, we can have our ORAN RAG Server running at `http://localhost:8081` or if using an AWS EC2 instance to deploy it can be running somewhere like `http://52.39.xx.xx:8081`

Refer to [Deploy Section](/deploy) to deploy your own Digital Human Pipeline. (If not done already)

With your baseline Avatar UI setup running on the AWS instance and functioning properly, we now need to point the app to our RAG Server endpoint by doing a `helm upgrade`.

### 1. **Fetch the Helm Chart**:
On the AWS Instance, first verify that all the pods are up and running.
```
kubectl get pods
```
We can then fetch the `ucs-tokkio-audio-video-llm-app` from NVIDIA GPU Cloud.
```bash
helm fetch https://helm.ngc.nvidia.com/nvidia/ucs-ms/charts/ucs-tokkio-audio-video-llm-app-4.1.0.tgz
```
### 2. **Extract the Chart Package**:
```bash
tar -xzf ucs-tokkio-audio-video-llm-app-4.1.0.tgz

#Files inside the app
cd ucs-tokkio-audio-video-llm-app/
ls -l
    app_info.yaml
    Chart.yaml
    values.yaml
  
```

### 3. **Edit the Values File to add RAG Endpoint**:

Make a copy of the `values.yaml` > `new_values.yaml`

```bash
cp values.yaml new_values.yaml

#make edits to the file
nano new_values.yaml
```

In the `new_values.yaml` file, update the `RAG_ENDPOINT` under `ace-agent-plugin-server` section:

```bash
ace-agent-plugin-server:
  applicationSpecs:
    deployment:
      containers:
        container:
          env:
          - name: HOME
            value: /bot
          - name: RAG_ENDPOINT
            value: http://52.39.xx.xx:8081
  configNgcPath: nvidia/ucs-ms/tokkio_plugin_llm_rag:4.0.1
```
Also, update the RAG Server Address and Port under `egress` for `ace-agent-plugin-server`:
```bash
  egress:
    rag-server:
      address: 52.39.xx.xx
      port: 8081
```
**Note**: Make sure the RAG endpoint is accessible from Tokkio ec2 instance. If the RAG endpoint was deployed on an ec2 machine this can be done by <a href="https://docs.aws.amazon.com/finspace/latest/userguide/step5-config-inbound-rule.html">updating</a> the <a href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security-groups.html">security groups.</a> 

### 4. **Upgrade the Helm Release**:
Apply the changes to reflect in your already deployed helm chart by upgrading the Helm release with the `new_values.yaml` file.

```bash
helm upgrade --values <path_to_new_values.yaml> <release_name> <chart_name>
```
You can get the chart name and release name by using `helm ls` on your instance. 

Example helm upgrade command:

```bash
helm upgrade --values ucs-tokkio-audio-video-llm-app/new_values.yaml tokkio-app ucs-tokkio-audio-video-llm-app
```

### 5. **Verify the Deployment**:
Check that all pods are up and running to ensure the deployment was successful.

```bash
ubuntu@ip-10-0-0-135:~$  kubectl get pods
NAME                                                        READY   STATUS    RESTARTS   AGE
a2f-a2f-deployment-6d9f4d6ddd-n6gc9                         1/1     Running   0          71m
ace-agent-chat-controller-deployment-0                      1/1     Running   0          71m
ace-agent-chat-engine-deployment-687b4868c-dx7z8            1/1     Running   0          71m
ace-agent-plugin-server-deployment-7f7b7f848f-58l9z         1/1     Running   0          71m
anim-graph-sdr-envoy-sdr-deployment-5c9c8d58c6-dh7qx        3/3     Running   0          71m
chat-controller-sdr-envoy-sdr-deployment-77975fc6bf-tw9b4   3/3     Running   0          71m
ds-sdr-envoy-sdr-deployment-79676f5775-64knd                3/3     Running   0          71m
ds-visionai-ds-visionai-deployment-0                        2/2     Running   0          71m
ia-animation-graph-microservice-deployment-0                1/1     Running   0          71m
ia-omniverse-renderer-microservice-deployment-0             1/1     Running   0          71m
ia-omniverse-renderer-microservice-deployment-1             1/1     Running   0          71m
ia-omniverse-renderer-microservice-deployment-2             1/1     Running   0          71m
mongodb-mongodb-bc489b954-jw45w                             1/1     Running   0          71m
occupancy-alerts-api-app-cfb94cb7b-lnnff                    1/1     Running   0          71m
occupancy-alerts-app-5b97f578d8-wtjws                       1/1     Running   0          71m
redis-redis-5cb5cb8596-gncxk                                1/1     Running   0          71m
redis-timeseries-redis-timeseries-55d476db56-2shpt          1/1     Running   0          71m
renderer-sdr-envoy-sdr-deployment-5d4d99c778-qm8sz          3/3     Running   0          71m
riva-speech-57dbbc9dbf-dmzpp                                1/1     Running   0          71m
tokkio-cart-manager-deployment-55476f746b-7xbrg             1/1     Running   0          71m
tokkio-ingress-mgr-deployment-7cc446758f-bz6kz              3/3     Running   0          71m
tokkio-menu-api-deployment-748c8c6574-z8jdz                 1/1     Running   0          71m
tokkio-ui-server-deployment-55fcbdd9f4-qwmtw                1/1     Running   0          71m
tokkio-umim-action-server-deployment-74977db6d6-sp682       1/1     Running   0          71m
triton0-766cdf66b8-6dsmq                                    1/1     Running   0          71m
vms-vms-bc7455786-6w7cz                                     1/1     Running   0          71m
```

### 6. **Spin up the UI**:
Navigate to the UI using the URL provided in the deployment output to interact with the updated Tokkio-ORAN Digital Human Avatar.

`https://<ui_sub_domain>.<base_domain>`

You're ready to ask ORAN questions to your Avatar!

Here are sample questions to test your Avatar's O-RAN knowledge:

```
Question 1: List the LLS configurations for O-RAN S-plane.

Answer:
The LLS (Lower Layer Split) configurations for S-plane are as follows:
1. LLS-C1: This configuration is generally the main synchronization option for a direct connection between O-DU (Open RAN Distributed Unit) and O-RU (Open RAN Radio Unit). It may also be considered as an alternative or complement to LLS-C4 in certain deployment scenarios.
2. LLS-C2: This configuration, along with LLS-C3, is used for fronthaul focused tests for S-Plane in the current version of the specification. These tests use the ITU-T G.8275.1 profile, which supports Full Timing Support. However, LLS-C2 is not specifically mentioned as a main sync option for a direct connection between O-DU and O-RU.
3. LLS-C3: Similar to LLS-C2, this configuration is also used for fronthaul focused tests for S-Plane in the current version of the specification. It supports Full Timing Support along with LLS-C2 when using the ITU-T G.8275.1 profile. It is also one of the configurations mentioned for certain deployment scenarios, like the synchronization network between O-DU and O-RU.
4. LLS-C4: This configuration is considered for future versions of the specification and is mentioned as an alternative or complement to LLS-C1 or LLS-C2/LLS-C3. It is also seen as a main sync option for a direct connection between O-DU and O-RU, as well as for the synchronization network between O-DU and O-RU. However, testing the S-Plane with LLS-C4 is still under future study.
It's important to note that the applicability of each LLS configuration depends on the specific O-RAN deployment scenario.
```
```
Question 2: What are the open interfaces in O-RAN architecture?

Answer:
The O-RAN architecture includes several open interfaces that enable interoperability and flexibility in the deployment and operation of Radio Access Networks (RAN). These open interfaces include:
1. A1 Interface: This interface is used for policy-driven guidance of Near-RT RIC applications/functions. It enables communication between the Non-RT RIC in the SMO (Service Management and Orchestration) framework and the Near-RT RIC in the RAN.
2. O1 Interface: This interface connects the SMO to the Near-RT RIC, one or more O-CU-CPs (Central Unit - Central Processing Unit), one or more O-CU-UPs (Central Unit - User Plane), and one or more O-DUs (Distributed Unit). It is used for FCAPS (Fault, Configuration, Accounting, Performance, and Security) support.
3. O2 Interface: This interface is used between the SMO and the O-Cloud to provide platform resources and workload management.
4. E2 Interface: This interface connects the Near-RT RIC and one or more O-CU-CPs, O-CU-UPs, O-DUs, and O-eNBs (base stations). It is used for control and user plane data exchanges between the Near-RT RIC and these RAN functions.
5. Open Fronthaul Interfaces: These interfaces include the CUS-Plane Interface between O-RU (Radio Unit) and O-DU for control plane data exchanges, and the M-Plane Interface between O-RU and O-DU as well as between O-RU and SMO for management plane data exchanges.
6. Y1 Interface: This interface is used for RAN analytics services exposed by the Near-RT RIC to be consumed by Y1 consumers.
These open interfaces, along with the use of open-source software, enable transparency, common control, interoperability of secure protocols and security features, supply chain security through diversity, and enhanced intelligence through AI and ML in the O-RAN architecture.
```

# PEFT (LoRA) Customization with NeMo Framework 24.05

We can enhance the performance of the Meta-Llama3-8b-instruct foundation model for our RAG application by leveraging the NeMo Framework for Parameter Efficient Fine-Tuning (PEFT). After this step, we will integrate the LoRA weights and [re-deploy](../deploy/README.md#rag-pipeline-deployment) the RAG pipeline.

The `rag_peft.md` playbook walks through the following steps:
1. Download Meta-Llama-3-8B-Instruct in HuggingFace (HF) format
2. Convert HF model to NeMo
3. Preprocess the dataset
4. Run the PEFT fine-tuning script
5. Setup LoRA model directory structure and re-deploy

By default, we will use the [synthetic dataset](../data/synthetic_dataset.jsonl) created from the [O-RAN documentations](https://www.o-ran.org/specifications) for our customization. Each datapoint consists of the `context`, `question` and `answer` fields.

Here is a synthetic data point as an example:
```bash
{
    "context": "The O-RAN Alliance aims to drive the industry towards open, interoperable interfaces, and RAN virtualization. This approach allows operators to integrate hardware and software from multiple vendors, fostering competition and innovation. The O-RAN architecture leverages both Near-Real-Time and Non-Real-Time RICs to enable new use cases and improve RAN efficiency. The architecture also includes the O1, O2, and A1 interfaces, each serving different functions within the management and orchestration framework.",
    "question": "What are the main goals of the O-RAN Alliance in terms of industry direction?",
    "answer": "The O-RAN Alliance aims to drive the industry towards open, interoperable interfaces, and RAN virtualization, fostering competition and innovation."
},
```
You can also curate your own customization dataset, and use it for the fine-tuning based on you specific use case.
