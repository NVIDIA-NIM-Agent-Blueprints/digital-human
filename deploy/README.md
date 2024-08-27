# Contents
- [Digital Human Pipeline Deployment](#digital-human-pipeline-deployment)
- [RAG Pipeline Deployment](#rag-pipeline-deployment)

# Digital Human Pipeline Deployment

For this workflow, we will be leveraging [NVIDIA ACE](https://developer.nvidia.com/ace) - a suite of technologies for bringing digital humans to life with generative AI.

This guide provides step-by-step instructions to set up and deploy the [Digital Human Pipeline](https://docs.nvidia.com/ace/latest/workflows/tokkio/text/Tokkio_LLM_RAG_Bot.html) workflow using the NVIDIA ACE repository.

## Sections
- [Prerequisites](#prerequisites)
- [Setup for Deployment](#setup-for-deployment)
- [Deploy Infrastructure and Application](#deploy-infrastucture-and-application)
- [Verify the Deployment and UI](#verify-the-deployment-and-ui)

## Prerequisites
Refer to the [Prerequisite Section](../README.md#prerequisites) to confirm the prerequisites are setup correctly. Refer to the [AWS Setup Guide](https://docs.nvidia.com/ace/latest/workflows/tokkio/text/Tokkio_AWS_CSP_Setup_Guide_automated.html#) as well.

We will be leveraging the one-click AWS deployment script for deployment that automates and abstracts out complexities and completes the AWS instance provisioning, setup and deployment of our application.

## Setup for Deployment
Ensure you have access to an Ubuntu 20.04 or 22.04 based machine, either VM or workstation with sudo privileges for the user to run the automated deployment scripts.

### 1. **Download and Extract Deployment Artifacts**:
On your local Ubuntu based system, Clone the ACE Repository and navigate to one-click script for AWS. 
   ```bash
   git clone https://github.com/NVIDIA/ACE.git
   cd ACE/workflows/tokkio/scripts/one-click/aws
   ```
This directory has our the deployment terraform scripts and `secrets.sh` for completing the deployment.
   ```bash
   ls -l
    deploy-spec
    deploy-template.yml
    secrets.sh
    tokkio-deploy

   ```

### 2. **Update Secrets**:
Modify the `secrets.sh` file with the AWS Access keys and other necessary secrets generated in the previous step.

   ```bash
    export _aws_access_key_id='<your_access_key_id>'
    export _aws_secret_access_key='<your_secret_access_key>'
    export _ngc_api_key='<your_ngc_api_key>'
    export _ssh_public_key='<your_ssh_public_key>'
   ```

The `_openai_api_key` is not needed for this Tokkio-RAG workflow but is needed for the Tokkio-QSR workflow.

The `_coturn_password` field is optional if you are using Reverse Proxy as the TURN server.

### 3. **Prepare Deploy Template**:
The `deploy-template.yml` file is used to compile the infrastructure specification needed to setup the project/environment.

You can have multiple template files and create multiple unique environments per template file that are identified by the unique ID `project_name`.

Update the `deploy-template.yml` with your specific AWS Configurations in the below sections:
- **metadata**
    - **`project_name`**: Unique identification of the environment. E.g. `tokkio-oran-bot`
    - **`template_version`**: 0.4.0
- **backend**
   - **`dynamodb_table`**: DynamoDB table name that was created in prerequisite step. E.g. `tokkio-table`
   - **`bucket`**: S3 bucket name that was created in prerequisite step. E.g. `tokkio-bucket`
   - **`region`**: The region the prerequisites were setup for. E.g. `us-west-2`
- **provider**
    - **`region`**: Same as specified in backend. `us-west-2`
- **spec**
    - **`vpc_cidr_block`**: This represents the private CIDR range in which the base, turn and app resources will be created. E.g. 0.0.0.0/24 [AWS VPC Calculator](https://nuvibit.com/vpc-subnet-calculator/)
    - **`dev_access_ipv4_cidr_blocks`**: CIDR ranges from where SSH access should be allowed.
    - **`user_access_ipv4_cidr_blocks`**: CIDR ranges from where application UI and API will be allowed access.
    - **`base_domain`**: Domain name should be configured with the DNS hosted zone under which the apps will be registered. E.g. `tokkio-oran-aws.nvidia.com`
    - **`api_sub_domain`**: Subdomain to be used for the API. E.g. `tokkio-oran-bot-api`
    - **`ui_sub_domain`**: Subdomain to be used for the UI. E.g. `tokkio-oran-bot-ui`
    - **`turn_server_provider`**: Chose between `rp` for using reverse proxy configuration or `coturn` for coturn server configuration. 
    - **`app_instance_type`**: Default options are
        - `g5.12xlarge` - 4xA10 GPUs
        - `g4dn.12xlarge` - 4xT4 GPUs
    - **`api_settings`**:
        - `chart_name`: This points to the helm chart that will be pulled from NGC and installed.
        For this tokkio-llm workflow, the chart name would be `ucs-tokkio-audio-video-llm-app`
    - **`ui_settings`**: 
        - `application_type`: Chose `custom` for tokkio-llm workflow. Default application type is `qsr`.

For further explanations of all the entries in this yaml file, please refer to the [AWS Documentation](https://docs.nvidia.com/ace/latest/workflows/tokkio/text/Tokkio_AWS_CSP_Setup_Guide_automated.html).

You can find example `deploy-template.yml` files in the [ACE Repository](https://github.com/NVIDIA/ACE/tree/main/workflows/tokkio/scripts/one-click/aws/examples).

## **Deploy Infrastructure and Application**
After the updates to the `secrets.sh` and `deploy-template.yml`, we can then deploy the tokkio-llm app. 

```
bash tokkio-deploy preview
```
This command installs `terraform` to complete the instance provisioning and other steps for the user and shows a preview of the changes staged to be made. 

Output of `preview` should be in this format:

```
app_infra = {
  "api_endpoint" = "https://<api_sub_domain>.<base_domain>"
  "elasticsearch_endpoint" = "https://elastic-<project_name>.<base_domain>"
  "grafana_endpoint" = "https://grafana-<project_name>..<base_domain>"
  "kibana_endpoint" = "https://kibana-<project_name>..<base_domain>"
  "private_ips" = [
  (known after apply)
  ]
  "ui_endpoint" = "https://<ui_sub_domain>.<base_domain>"
 }
bastion_infra = {
  "private_ip" = (known after apply)
  "public_ip" = (known after apply)
}
rp_infra = {
  "private_ip" = (known after apply)
  "public_ip" = (known after apply)
}
```

Example `bash tokkio-deploy preview` output:

```
Plan: 86 to add, 0 to change, 0 to destroy

Changes to Outputs:

app_infra = {
  "api_endpoint" = "https://tokkio-oran-bot-api.tokkio-oran-aws.nvidia.com"
  "elasticsearch_endpoint" = "https://elastic-tokkio-oran-bot.tokkio-oran-aws.nvidia.com"
  "grafana_endpoint" = "https://grafana-ntokkio-oran-bot.tokkio-oran-aws.nvidia.com"
  "kibana_endpoint" = "https://kibana-tokkio-oran-bot.tokkio-oran-aws.nvidia.com"
  "private_ips" = [
    (known after apply)
  ]
  "ui_endpoint" = "https://tokkio-oran-bot-ui.tokkio-oran-aws.nvidia.com"
}
bastion_infra = {
  "private_ip" = (known after apply)
  "public_ip" = (known after apply)
}
rp_infra = {
  "private_ip" = (known after apply)
  "public_ip" = (known after apply)
}

```

Install the changes showed in preview based on `deploy-template.yml`:
```bash
bash tokkio-deploy install
```
***

## **Verify the Deployment and UI**:
On successful deployment of the Infra, you will get output displayed in the below format:

```
Apply complete! Resources: <nn> added, <nn> changed, <nn> destroyed

Outputs:

app_infra = {
  "api_endpoint" = "https://<api_sub_domain>.<base_domain>"
  "elasticsearch_endpoint" = "https://elastic-<project_name>.<base_domain>"
  "grafana_endpoint" = "https://grafana-<project_name>..<base_domain>"
  "kibana_endpoint" = "https://kibana-<project_name>..<base_domain>"
  "private_ips" = [
  "<private_ip_of_app_instace>",
  ]
  "ui_endpoint" = "https://<ui_sub_domain>.<base_domain>"
 }
bastion_infra = {
  "private_ip" = "<bastion_instance_private_ip>"
  "public_ip" = "<bastion_instance_public_ip>"
}
rp_infra = {
  "private_ip" = "<rp_instance_private_ip>"
  "public_ip" = "<rp_instance_public_ip>"
}

```

Use ssh command in below format to log into Application instance.

```bash
ssh -i <path-to-pem-file> -o StrictHostKeyChecking=no -o ProxyCommand="ssh -i <path-to-pem-file>  -W %h:%p -o StrictHostKeyChecking=no ubuntu@<bastion-instance-public-ip>" ubuntu@<app-instance-private-ip>
```
The `pem` file referred here is the private key associated with the public SSH key created in the Prerequisites section: `./ssh/id_rsa`

Example SSH login command:
```bash
ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ProxyCommand="ssh -i ~/.ssh/id_rsa  -W %h:%p -o StrictHostKeyChecking=no ubuntu@52.39.xx.xx" ubuntu@10.0.0.xxx
```

Once you are able to login into the AWS instance, run the below command to see the Kubernetes pods' status. 

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
It may take up-to an hour for the pods to turn into `Running` state. 

Once all the pods are running you can access the UI with the help of the URL printed in output attribute `ui_endpoint`. 

You can display the install command output on your local terminal by using the below command:

```bash
bash tokkio-deploy show-results

app_infra = {
    "ui_endpoint" = "https://<ui_sub_domain>.<base_domain>"
}
```
Access UI at `https://<ui_sub_domain>.<base_domain>`
You're ready to interact with your Avatar!

# RAG Pipeline Deployment

This example showcases a LangChain based RAG pipeline that deploys the NIM for LLMs microservice to host a TensorRT optimized LLM and the NeMo Retriever Embedding microservice. Milvus is deployed as the vector database to store embeddings and generate responses to queries.

The knowledge base used in this RAG deployment is based on the [O-RAN (Open Radio Access Network) ALLIANCE](https://www.o-ran.org) specifications. These specifications define open, interoperable standards and interfaces that transform traditional radio access networks into more flexible, virtualized, and cloud-native systems. The technical documentation (PDFs) of these specifications can be found [here](https://specifications.o-ran.org/specifications). For this example, you should download these PDFs into the `./data` directory. However, this pipeline is flexible and can also be used with other data from different domains or your own data for RAG.

By default, this RAG deployment uses `meta/llama3-8b-instruct` without PEFT. If you [customized the model with PEFT and LoRA](../customize/rag_peft.md), make sure to update `LLM_MODEL_NAME` to `lora-nemo-fw` in the `.env` file to use the LoRA weights.

## Sections
- [Prerequisites](#prerequisites-1)
- [Deploy the RAG Pipeline](#deploy-the-rag-pipeline)
- [Load Data into the Knowledge Base](#load-data-into-the-knowledge-base)
- [Ask a question!](#ask-a-question)

## Prerequisites

A minimum of two NVIDIA datacenter GPUs (such as A100, H100, or L40S models) are required.
- One GPU is needed for the inference container.
- One GPU is needed for the embedding container.
- In addition, Milvus requires at least one GPU by default.

## Deploy the RAG Pipeline

1. Complete the [Common Prerequisites](../README.md#common-prerequisites). 

1. Log in to the NVIDIA container registry using the following command:

    ```console
    docker login nvcr.io
    ```

    Once prompted, you can use `$oauthtoken` as the username and your `NGC_API_Key` as the password.

    Then, export the `NGC_API_KEY`

   ```console
   export NGC_API_KEY=<ngc-api-key>
   ```

1. Deploy the RAG pipeline.

   ```console
   USERID=$(id -u) docker compose --profile local-nim --profile milvus up -d
   ```

   <i>Example Output</i>

   ```console
   CONTAINER ID   NAMES                                   STATUS
   32515fcb8ad2   rag-playground                          Up 26 minutes
   d60e0cee49f7   rag-application-text-chatbot-langchain  Up 27 minutes
   02c8062f15da   nemo-retriever-embedding-microservice   Up 27 minutes (healthy)
   7bd4d94dc7a7   nemollm-inference-microservice          Up 27 minutes
   55135224e8fd   milvus-standalone                       Up 48 minutes (healthy)
   5844248a08df   milvus-minio                            Up 48 minutes (healthy)
   c42df344bb25   milvus-etcd                             Up 48 minutes (healthy)
   ```

1. Open your browser and interact with the RAG Playground at <http://localhost:3001/orgs/nvidia/models/text-qa-chatbot>.

1. Check out the API specs at <http://localhost:8081/docs>.

   > **Note:** Accessing the UI and endpoints: 
   >
   > The examples in this documentation use `localhost:port` to access the UI and endpoints.
   >
   > If you are running the application on a remote machine:
   >
   > - You may need to set up port forwarding to access the services on your local machine. Open a Terminal on your local machine and use the following command to set up port forwarding:
   >
   >   ```
   >   ssh -L local_port:localhost:remote_port username@remote_host
   >   ```
   >
   > - Alternatively, replace `localhost` with the actual IP address of the remote machine.
   >   For example: If the remote machine's IP is `12.34.56.78`, use `12.34.56.78:port` instead of `localhost:port`.
   >
   > Ensure you have the necessary permissions and have configured any relevant firewalls or security groups to allow access to the specified ports.

## Load Data into the Knowledge Base

There are 3 methods available for adding data to the Retrieval-Augmented Generation (RAG) knowledge base.

1. Access the RAG Playground at <http://localhost:3001/orgs/nvidia/models/text-qa-chatbot>. In the Knowledge Base section, select "Drag and drop a file" to upload your PDF documents.

1. Alternatively, use the API by sending requests to the `/documents` endpoint at http://localhost:8081/documents. Below is an example cURL command for this method:

   ```bash
   pathToDocument="/path/to/document.pdf"

   curl -X 'POST' \
   'http://localhost:8081/documents' \
   -H 'accept: application/json' \
   -H 'Content-Type: multipart/form-data' \
   -F "file=@${pathToDocument};type=application/pdf"
   ```

   To batch upload documents, `data_loader.sh` is provided. This script is designed to upload multiple PDF files from a specified directory to a server endpoint in one go. By default, it assumes that the documents are located in the `./data` directory, but you can easily modify the script to use any directory of your choice.

   ```bash
   chmod +x data_loader.sh
   ./data_loader.sh
   ```

1. A third option is to use the provided data loader in `data_loader.ipynb`. This method requires installation of the `requests` library via pip:

   ```bash
   pip install requests
   ```

   This notebook includes examples for uploading both individual documents and entire directories of PDFs.

## Ask a question!

Now that the knowledge base has been populated, you can engage with the RAG-powered AI assistant in 2 different ways.

1. Utilize the RAG Playground interface:
   - Navigate to http://localhost:3001/orgs/nvidia/models/text-qa-chatbot
   - Locate the Demo section to engage with the conversational AI
   - To enable RAG functionality, ensure the "Use Knowledge Base" option is selected
   - To disable RAG, deselect the "Use Knowledge Base" option

1. Use the API by sending requests to the `/generate` endpoint at http://localhost:8081/generate. Below is an example cURL command for this method:

   ```bash
   curl -X 'POST' \
   'http://localhost:8081/generate' \
   -H 'accept: application/json' \
   -H 'Content-Type: application/json' \
   -d '{
   "messages": [
      {
         "role": "user",
         "content": "I am going to Paris, what should I see?"
      }
   ],
   "use_knowledge_base": true,
   "temperature": 0.2,
   "top_p": 0.7,
   "max_tokens": 1024,
   "stop": []
   }'
   ```

   To enable RAG functionality, set `"use_knowledge_base": true` as shown in the example above. Set it to `false` to disable RAG.

# Next Steps

After launching both the Digital Human Pipeline and RAG Pipeline, proceed to [Connecting Your Digital Human Pipeline to Domain Adapted RAG](../customize/README.md#connect-your-digital-human-pipeline-to-domain-adapted-rag).
