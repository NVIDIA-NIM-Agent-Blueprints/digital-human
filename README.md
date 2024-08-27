<h2><img align="center" src="https://github.com/user-attachments/assets/cbe0d62f-c856-4e0b-b3ee-6184b7c4d96f">NIM Agent Blueprint: Digital Human for Customer Service</h2>
<p align="center">
 <img width="800" alt="dht" src="https://github.com/user-attachments/assets/64bd6115-035c-4b2f-88d4-ba8f2c2b29ac">

</p>

Create a digital human for customer service that combines NVIDIA NIM, ACE Microservices, Omniverse RTX rendering, and NeMo Retriever.\
\
This blueprint repository serves as a starting point for the developers to showcase how an LLM or a RAG application can be easily connected to a digital human pipeline. The digital human and the Retrieval-Augmented Generation (RAG) applications are deployed separately. The RAG application is responsible for generating the text content of the interaction and Tokkio customer service workflow is providing a solution to enable avatar live interaction. Those two entities are separated and communicate using the REST API. The users can develop their requirements and tune the app based on their needs. Included in this workflow are steps to setup and connect both components of the customer service pipeline.


## Get Started

* [Prerequisites](#prerequisites)
    * Ensure that system requirements are fulfilled.
    * Setup NVIDIA GPU Cloud (NGC) API key, Cloud Service Provider and SSH Key Pair.
* [Deploy](/deploy/)
    * Start by launching the Digital Human Pipeline Deployment to interact with the digital human.
    * Next, deploy the RAG pipeline to connect the digital human to a knowledge base.
* [Customize](/customize/) 
    * Connect your Digital Human Pipeline to domain-adapted RAG.
    * (Optional) Further customize with Parameter Efficient Fine-Tuning (PEFT) and Low-Rank Adaptation (LoRA).
* [Evaluate](/evaluate/)
    * Assess RAG and PEFT using metrics like ROUGE, BLEU, Ragas, and LLM-as-a-judge.

## Prerequisites
### 1. **System Requirements:**
- Access to an Ubuntu 20.04 or 22.04 based machine, either VM or workstation with sudo privileges for the user to run the automated deployment scripts. 
- Python version 3.10.12 or later

#### 1.1 **Docker Installation**
Install [Docker Engine and Docker Compose](https://docs.docker.com/engine/install/ubuntu/).
#### 1.2 **NVIDIA GPU Driver Version**
Verify NVIDIA GPU driver version 535 or later is installed.

```console
    $ nvidia-smi --query-gpu=driver_version --format=csv,noheader
    535.129.03

    $ nvidia-smi -q -d compute

    ==============NVSMI LOG==============

    Timestamp                                 : Sun Nov 26 21:17:25 2023
    Driver Version                            : 535.129.03
    CUDA Version                              : 12.2

    Attached GPUs                             : 1
    GPU 00000000:CA:00.0
        Compute Mode                          : Default
```

   Refer to the [NVIDIA Linux driver installation instructions](https://docs.nvidia.com/datacenter/tesla/tesla-installation-notes/index.html) for more information.
#### 1.3 **NVIDIA Container Toolkit**
   Install the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html).

   Verify the toolkit is installed and configured as the default container runtime.

```console
    $ cat /etc/docker/daemon.json
    {
        "default-runtime": "nvidia",
        "runtimes": {
            "nvidia": {
                "path": "/usr/bin/nvidia-container-runtime",
                "runtimeArgs": []
            }
        }
    }

    $ sudo docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi -L
    GPU 0: NVIDIA A100 80GB PCIe (UUID: GPU-d8ce95c1-12f7-3174-6395-e573163a2ace)
```

#### 1.4 **GPU Requirements**
For minimum GPU requirements, refer to:  https://build.nvidia.com/nvidia/digital-humans-for-customer-service/blueprintcard

### 2. **NVIDIA GPU Cloud (NGC) API key:**
NGC API Key is required to access resources within this repository. 
1. Navigate to https://build.nvidia.com/nvidia/digital-humans-for-customer-service and click "Download Blueprint"
2. Login / Sign up if needed and "Generate your API Key"
3. Use this API Key as credentials for "NGC_API_KEY"
4. Log in to the NVIDIA container registry using the following command:

    ```console
    docker login nvcr.io
    ```

    Once prompted, you can use `$oauthtoken` as the username and your `NGC_API_Key` as the password.

    Then, export the `NGC_API_KEY`

   ```console
   export NGC_API_KEY=<ngc-api-key>
   ```

Refer to [Accessing And Pulling an NGC Container Image via the Docker CLI](https://docs.nvidia.com/ngc/gpu-cloud/ngc-catalog-user-guide/index.html#accessing_registry) for more information.

### 3. **Cloud Service Provider Setup:**
The Digital human for customer service blueprint includes easy deployment scripts for major cloud service providers, it is recommended to have CSP secrets handy to deploy the digital human application. The RAG application can be deployment locally with docker compose using provided customization and deployment scripts.

We will cover the digital human application setup and deployment steps for [AWS](https://docs.nvidia.com/ace/latest/workflows/tokkio/text/Tokkio_AWS_CSP_Setup_Guide_automated.html#). The Setup for other CSPs can be found [here](https://docs.nvidia.com/ace/latest/workflows/tokkio/index.html#csp-setup-guides).

We will be leveraging the one-click aws deployment script for deployment that automates and abstracts out complexities and completes the AWS instance provisioning, setup and deployment of our application.
#### 3.1 **Digital Human Application - AWS Setup**:
Follow the [AWS CSP Setup Guide](https://docs.nvidia.com/ace/latest/workflows/tokkio/text/Tokkio_AWS_CSP_Setup_Guide_automated.html#prerequisites) to configure your AWS environment for the Tokkio application.

After going through the provisioning steps, you should have the following credentials:
- **AWS Access Keys for IAM user:** This procurement will give the `Access key ID` and `Secret access key` credentials. Refer to the [AWS Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html) for detailed instructions.
- **S3 Bucket:** Private S3 bucket to store the references to the resources the one-click deploy script will spin up.
- **DynamoDB Table:** To manage access to the deployment state.
- **Domain and Route53 hosted zone:** To deploy the application under.

### 4. **SSH Key Pair:**
This is needed to access the instances we are going to setup. On the local Ubuntu based machine you may use existing SSH key pair or create a new [SSH key pair](https://help.ubuntu.com/community/SSH/OpenSSH/Keys#Generating_RSA_Keys):
```bash
ssh-keygen -t rsa -b 4096
```
This should generate a public and private SSH key pair. The public key should be available as `.ssh/id_rsa.pub` and the private key would be then available as `.ssh/id_rsa` in your home folder as well. These keys will be needed to setup your one-click deployment of the [Digital Human Pipeline](./deploy/README.md#digital-human-pipeline-deployment). 

# Next Steps
After ensuring all the prerequisites are satisfied, please proceed to the [Digital Human Pipeline Deployment](/deploy/#contents) and [RAG Pipeline Deployment](/deploy/#contents).
