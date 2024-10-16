# Deployment

**Persona needed**: Devops Engineer

For this guide, we will deploy the Digital human avatar and the Retrieval Augmented Generation pipeline on separate AWS instances. 
NOTE:  The deployment for other CSPs can be found [here](https://docs.nvidia.com/ace/latest/workflows/tokkio/index.html#csp-setup-guides). 

The digital avatar deployment uses a one-click AWS deployment script that automates and abstracts out complexities and completes the AWS instance provisioning, setup and deployment of our application.  It is recommended to have CSP secrets handy to deploy the digital human avatar. 

Note: For deploying RAG with customization, please take a look at the customization(../customize/) section of this guide


## Digital Human Pipeline Deployment

For this workflow, we will be leveraging [NVIDIA ACE](https://developer.nvidia.com/ace) - a suite of technologies for bringing digital humans to life with generative AI.

- [Prerequisites](#prerequisites)
- [Setup for Deployment](#setup-for-deployment)
- [Deploy Infrastructure and Application](#deploy-infrastucture-and-application)
- [Verify the Deployment and UI](#verify-the-deployment-and-ui)

#### Prerequisites

### SSH Key Pair setup
Next, you will need to create an SSH Key Pair, this is needed to access the E2c instances. On a local Ubuntu based machine you may use existing SSH key pair or create a new SSH key pair:

   ```bash
   ssh-keygen -t rsa -b 4096
   ```
This should generate a public and private SSH key pair. The public key should be available as .ssh/id_rsa.pub and the private key would be then available as `.ssh/id_rsa` in your home folder as well. These keys will be needed to set up your one-click deployment of the Digital Human Pipeline.

Refer to the [AWS Setup Guide](https://docs.nvidia.com/ace/latest/workflows/tokkio/text/Tokkio_AWS_CSP_Setup_Guide_automated.html#prerequisites) as well.

After completing the above prereqs, verify that you have the following credentials:

* AWS Access Keys for IAM user
* S3 Bucket: Private S3 bucket to store the references to the resources the one-click deploy script will spin up.
* DynamoDB Table: To manage access to the deployment state.
* Domain and Route53 hosted zone: To deploy the application under.

We will be leveraging the one-click AWS deployment script for deployment that automates and abstracts out complexities and completes the AWS instance provisioning, setup and deployment of our application.

### Setup for Deployment
Ensure you have access to an Ubuntu 20.04 or 22.04 based machine, either VM or workstation with sudo privileges for the user to run the automated deployment scripts.

#### 1. **Download and Extract Deployment Artifacts**:
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

#### 2. **Update Secrets**:
Modify the `secrets.sh` file with the AWS Access keys and other necessary secrets generated in the previous step.

   ```bash
    export _aws_access_key_id='<your_access_key_id>'
    export _aws_secret_access_key='<your_secret_access_key>'
    export _ngc_api_key='<your_ngc_api_key>'
    export _ssh_public_key='<your_ssh_public_key>'
   ```

The `_openai_api_key` is not needed for this Tokkio-RAG workflow but is needed for the Tokkio-QSR workflow.

The `_coturn_password` field is optional if you are using Reverse Proxy as the TURN server.

#### 3. **Prepare Deploy Template**:
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

### **Deploy Infrastructure and Application**
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

### **Verify the Deployment and UI**:
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

## RAG Pipeline Deployment

Follow the steps [here](https://github.com/NVIDIA/GenerativeAIExamples/tree/main/RAG/examples/basic_rag/langchain) to set up the RAG pipeline on the other AWS instance.

## Connect your digital human avatar to domain adapted RAG

Now that you have deployed the digital avatar and the Retrieval-Augmented Generation (RAG) application, the next step is to connect the two pipelines so that they can communicate with one another using the REST API. To do this, we will point the Digital Avatar application to our RAG Server endpoint by doing a helm upgrade.  To do this, we will first pull a helm to update the values.yaml.

From the previous section, we can have our ORAN RAG Server running at `http://localhost:8081` or if using an AWS EC2 instance to deploy it can be running somewhere like `http://52.39.xx.xx:8081`

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
