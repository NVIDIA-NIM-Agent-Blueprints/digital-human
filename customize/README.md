# Customization - Optional

## Customizing Digital Human
**Persona needed**: Animation/Rendering developer

To customize the digital avatar, please refer to the [Avatar Configurator](https://docs.nvidia.com/ace/latest/modules/avatar_customization/Avatar_Configurator.html#avatar-configurator).  Alternatively you can import a third-party avatar by following the custom avatar guide. More information can be found in the [Avatar Customization](https://docs.nvidia.com/ace/latest/modules/avatar_customization/index.html#avatar-customization) section.


## Customizing RAG
**Persona needed**: Machine learning engineer

### Customizing the dataset

There are 2 methods available for adding data to the Retrieval-Augmented Generation (RAG) knowledge base.

* API
* Batch upload script

#### Option 1: API
Access the API by sending requests to the /documents endpoint at http://localhost:8081/documents. An example cURL command is shown below:

```bash
pathToDocument="/path/to/document.pdf"

curl -X 'POST' \
'http://localhost:8081/documents' \
-H 'accept: application/json' \
-H 'Content-Type: multipart/form-data' \
-F "file=@${pathToDocument};type=application/pdf"
```

#### Option 2: Batch Upload Script
To batch upload documents, data_loader.sh is provided. This script is designed to upload multiple PDF files from a specified directory to a server endpoint. 

```bash
chmod +x data_loader.sh
./data_loader.sh
```

NOTE:  By default, it assumes that the documents are located in the ./data directory, but you can easily modify the script to use any directory of your choice.


## Finetune LLM model
To enhance the performance of the Meta-Llama3-8b-instruct foundation model for our RAG application, leverage NeMo Framework for Parameter Efficient Fine-Tuning (PEFT). After fine tuning we will integrate the LoRA weights and re-deploy the RAG pipeline.


The ```rag_peft.md``` playbook walks through the following steps:

* Download Meta-Llama-3-8B-Instruct in HuggingFace (HF) format
* Convert HF model to NeMo
* Preprocess the dataset
* Run the PEFT fine-tuning script
* Setup LoRA model directory structure and re-deploy


By default, we will use the synthetic dataset created from the O-RAN documentations for our customization. Each datapoint consists of the context, question and answer fields.


Here is a synthetic data point as an example:
```bash
{
    "context": "The O-RAN Alliance aims to drive the industry towards open, interoperable interfaces, and RAN virtualization. This approach allows operators to integrate hardware and software from multiple vendors, fostering competition and innovation. The O-RAN architecture leverages both Near-Real-Time and Non-Real-Time RICs to enable new use cases and improve RAN efficiency. The architecture also includes the O1, O2, and A1 interfaces, each serving different functions within the management and orchestration framework.",
    "question": "What are the main goals of the O-RAN Alliance in terms of industry direction?",
    "answer": "The O-RAN Alliance aims to drive the industry towards open, interoperable interfaces, and RAN virtualization, fostering competition and innovation."
},
```

You can also curate your own customization dataset, and use it for the fine-tuning based on your specific use case.

Note: If you finetuned the model, follow these steps below to deploy it on your local RAG instance


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
   cd digital-human/deploy/
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

