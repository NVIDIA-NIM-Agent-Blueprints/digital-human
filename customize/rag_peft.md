# PEFT (LoRA) Customization with NeMo Framework 24.05

This playbook aims to demonstrate how to adapt and customize the [Meta-Llama3-8b-instruct](https://huggingface.co/meta-llama/Meta-Llama-3-8B-Instruct) foundation model to improve performance on our RAG use case. We will preprocess the dataset and use NeMo Framework for parameter efficient fine-tuning (PEFT) of model. Finally, we will setup the directory structure to load our PEFT weights with NIMs.

Table of Contents:
1. Download Meta-Llama-3-8B-Instruct in HuggingFace (HF) format
2. Convert HF model to NeMo
3. Preprocess the dataset
4. Run the PEFT fine-tuning script
5. Setup LoRA Model Directory Structure

References:

- [Overview - NVIDIA Docs](https://docs.nvidia.com/nemo-framework/user-guide/latest/overview.html)
- [NVIDIA NeMo Framework PEFT with Llama2 and Mixtral-8x7B](https://docs.nvidia.com/nemo-framework/user-guide/latest/playbooks/nemoframeworkpeft.html#nemo-framework-peft-playbook) 

**Note:** Please cd into `digital-human/customize` folder before proceeding to the steps below.

# 1. Download Meta-Llama-3-8B-Instruct in HuggingFace Format

If you have the Llama3-8B-Instruct model in your machine, please proceed to the next step, i.e., conversion of the model to NeMo. 

Else, please continue to follow these instructions to download the model from HuggingFace:

Make sure you have access to the gated model [Meta-Llama-3-8B-Instruct](https://huggingface.co/meta-llama/Meta-Llama-3-8B-Instruct).
To request access, click on the [model link](https://huggingface.co/meta-llama/Meta-Llama-3-8B-Instruct) and submit your application. After the application has been approved, we can clone the model with the following commands. 

```bash
git lfs install
git clone https://huggingface.co/meta-llama/Meta-Llama-3-8B-Instruct
```

When prompted, enter the `Username`, i.e., your HuggingFace account and `Password`, i.e., your [Huggingface access token](https://huggingface.co/settings/tokens). You might have to enter these details twice and this step takes about 5-10 minutes.

# 2. Convert HF Model to NeMo

The NeMo container includes modules to support the conversion of Hugging Face (HF) format to NeMo format. To use the NeMo docker container, we will first login to `nvcr.io`.
```
docker login nvcr.io
```
Once prompted, you can use `$oauthtoken` as the username and your[ NGC Personal API Key](https://org.ngc.nvidia.com/setup/personal-keys) as the password.


We can run the container and load our dataset using the following command. Note that you may have to update which GPU device(s) are available.

```bash
docker run --gpus '"device=0"' --shm-size=2g --net=host --ulimit memlock=-1 --rm -it -v ${PWD}:/workspace -w /workspace -v ${PWD}/../data/:/workspace/data nvcr.io/nvidia/nemo:24.05 bash
```

The previous command will open a bash shell within the container. Using this shell, we will convert the Huggingface model into a .nemo model. 

```bash
python /opt/NeMo/scripts/checkpoint_converters/convert_llama_hf_to_nemo.py --input_name_or_path=./Meta-Llama-3-8B-Instruct/ --output_path=llama3-8b-instruct.nemo
```

You may receive a warning that `MegatronGPTModel() does not have field.name:` Please ignore these comments as it will not affect the model conversion.

**We will continue to work inside this container for the rest of this notebook**. Since we load the current directory inside the container, all the files created inside the docker can be accessed even after the container is stopped. 


# 3. Preprocess Dataset

We will use the `workspace/data/synthetic_dataset.jsonl` to train our model. Each datapoint in this dataset includes three fields: question, retrieved context and the ground truth answer.
An example datapoint is shown below. 

```json
{
        "context": "Split Option 7-2x: O-RU: RF, IF, PHY-LOW (Downlink and uplink digital processing, baseband signal conversion to/from RF signal) O-CU & O-DU: PHY-HIGH, MAC, RLC, PDCP (Downlink and uplink baseband processing, supply system synchronization clock, signalling processing, OM function, interface with core network) Split Option 8: O-RU8: Downlink baseband signal convert to RF signal, uplink RF signal convert to baseband signal, interface with the fronthaul gateway O-CU &O-DU8: Downlink and uplink baseband processing, supply system synchronization clock, signalling processing, OM function, interface with core network and the fronthaul gateway Fronthaul gateway: Downlink broadcasting, uplink combining, power supply for O-RU8, cascade with other fronthaul gateway, synchronization clock Transmission media(b) From O-DU to Fronthaul gateway: Fiber; From Fronthaul gateway to O-RU: Fiber or Optical Electric Composite Cable From (O-DU&O-CU) to O-RU: Fiber or Optical Electric Composite Cable From (O-DU&O-CU) and core network: Fiber or Optical Electric Composite Cable; Trusted or Untrusted transport Duplex(b) Deployment location Cell Coverage MIMO Configuration(b) User distribution(c) Fronthaul Latency TDD, FDD Indoor Omni SU-MIMO/MU-MIMO; up to 4TX/4RX 20-200 Split Option 6: TBD Split Option 7-2x: fronthaul dependent (refer to [6]) Split Option 8: 150us Synchronization(b) Power Supply Mode(b) Notes: GNSS, IEEE-1588v2, BDS POE or by optical electric composite cables",
        "question": "What are the power supply modes for O-RU in Split Option 8?",
        "answer": "The power supply modes for O-RU in Split Option 8 are Power Over Ethernet (POE) or by optical electric composite cables."
}
```

To process this dataset to the format NeMo expects (input-output pairs), and to add suitable prompt for our use case, we use the following script.  

```bash
cat > preprocess_to_jsonl.py << "EOF" 
import json
import random

def load_dataset(fname):
    json_data = []
    file = open(fname, "r")
    json_data = [line for line in json.load(file)]
    return json_data
    
def preprocess_dataset(dataset):
    processed_dataset = []
    ## The "input" to the generator LLM for RAG includes the context and question
    ## The "output" from the generator LLM is the answer to the question, based on context
    ## Note: The RAG system prompt given to our generator LLM is passed using the run_peft.sh script in the next step, during the PEFT process
    for data in dataset:
        data_input = "Context: " + data["context"] + "\n\nQuestion: " + data["question"].strip() + "\n"
        data_output = data["answer"]
        processed_dataset.append({"input": data_input, "output": data_output})
    return processed_dataset


def write_jsonl(dataset, dataset_division=None, shuffle=False):
    ## You can mention the division of datapoints for each dataset, or use the default division of 60:20:20 respectively

    if dataset_division == None:
        number_data = len(dataset)
        number_training_data = int(number_data*0.6)
        number_val_data = int((number_data-number_training_data)*0.2)
        number_test_data = number_data - number_training_data - number_val_data
    else:
        number_training_data = dataset_division[0]
        number_val_data = dataset_division[1]
        number_test_data = dataset_division[2]
    
    if shuffle:
        random.shuffle(dataset)

    with open('data/train_set.jsonl', 'w') as f:
        for o in dataset[:number_training_data]:
            f.write(json.dumps(o)+"\n")
    with open('data/val_set.jsonl', 'w') as f:
        for o in dataset[number_training_data: number_training_data+number_val_data]:
            f.write(json.dumps(o)+"\n")
    with open('data/test_set.jsonl', 'w') as f:
        for o in dataset[number_training_data+number_val_data:]:
            f.write(json.dumps(o)+"\n")

## Load our synthetic dataset containing triplets of question, answer and context
dataset = load_dataset("data/synthetic_dataset.jsonl")

## Preprocess the dataset into input-output pairs for training with NeMo
processed_dataset = preprocess_dataset(dataset)

## Divide the preprocessed dataset into training, validation and testing datasets
write_jsonl(processed_dataset, [680,80,80])
EOF

python preprocess_to_jsonl.py
```

After running this script, we can see three files, namely `train_set.jsonl`, `test_set.jsonl` and `val_set.jsonl` inside the `workspace/data` folder. Each datapoint consists of an `input` field and an `output` field. The `input` field contains the RAG context along with the user query, and the `output` field contains a the answer to the user query based on the given context:

```json
{
    "input": "\nContext: \u00a9 2022 by the O-RAN ALLIANCE e.V. Your use is subject to the copyright statement on the cover page of this specification 20 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 O-RAN.WG7.DCS.0-v04.00 Table 3.3.2-2: Descriptions of Attributes for the FR1 Enterprise Microcell Architecture Attributes Description Reference Figure Interface(a) Functionality(b) Figure 2.1.1-1: Base Station Architecture deploying lower level split without protocol translation Open fronthaul interface Split Option 7-2x: O-RU: RF, IF, PHY-LOW (Downlink and uplink digital processing, baseband signal conversion to/from RF signal) O-CU & O-DU: PHY-HIGH, MAC, RLC, PDCP (Downlink and uplink baseband processing, supply system synchronization clock, signalling processing, OM function, interface with core network) Split Option 8: O-RU: Downlink baseband signal convert to RF signal, uplink RF signal convert to baseband signal, interface with O-DU O-CU &O-DU: Downlink and uplink baseband processing, supply system synchronization clock, signalling processing, OM function, interface with core network and O-RU. Transmission media(b) Duplex(b) Deployment location Cell Coverage MIMO(b) User distribution(c) Fronthaul Latency Synchronization(b) Power Supply Mode(b) Notes: Fiber TDD Outdoor Omni; Sectorized SU-MIMO/MU-MIMO; up to 8TX/8RX >300 Split Option 7-2x: fronthaul dependent (refer to [6]) Split Option 8: 150us GNSS or IEEE-1588v2 DC/AC\n\nFiber, wireless to fiber TDD Outdoor Omni; Sectorized SU-MIMO/MU-MIMO; up to 2TX/2RX >300 Not Applicable GNSS or IEEE-1588v2 DC/AC (a) The option noted here is for reference, and do not preclude other options. (b) The number of users distribution refers to the active users in one base station, and the options are for reference. Table 3.3.2-4: Descriptions of Attributes for the FR2 Outdoor Microcell Architecture Attributes Description Reference Figure Figure 2.1.1-1: Base Station Architecture deploying lower level split without protocol translation Interface(a) Functionality(b) Transmission media(b) Duplex(b) Deployment location F1 interface between O-CU/O-DU (Split Option 2) Open fronthaul interface (WG4) between O-DU/O-RU (Option 7-2x) O-DU/O-RU: Downlink and uplink baseband processing, supply system synchronization clock, scheduling, signalling processing, OM function, interface with core network and, Downlink baseband signal convert to RF signal, uplink RF signal convert to baseband signal Fiber, wireless to fiber TDD Small cell, Outdoor, Urban/Suburban Cell Coverage MIMO Configuration(b) User distribution(c) Fronthaul Latency Synchronization(b) Power Supply Mode(b) Notes: Sectorized SU-MIMO/MU-MIMO; up to 4TX/4RX >100 Split Option 7-2x: fronthaul dependent (refer to [6]) GNSS or IEEE-1588v2 AC or POE or by optical electric composite cables\n\nSplit Option 7-2x: O-RU: RF, IF, PHY-LOW (Downlink and uplink digital processing, baseband signal conversion to/from RF signal) O-CU & O-DU: PHY-HIGH, MAC, RLC, PDCP (Downlink and uplink baseband processing, supply system synchronization clock, signalling processing, OM function, interface with core network) Split Option 8: O-RU8: Downlink baseband signal convert to RF signal, uplink RF signal convert to baseband signal, interface with the fronthaul gateway O-CU &O-DU8: Downlink and uplink baseband processing, supply system synchronization clock, signalling processing, OM function, interface with core network and the fronthaul gateway Fronthaul gateway: Downlink broadcasting, uplink combining, power supply for O-RU8, cascade with other fronthaul gateway, synchronization clock Transmission media(b) From O-DU to Fronthaul gateway: Fiber; From Fronthaul gateway to O-RU: Fiber or Optical Electric Composite Cable From (O-DU&O-CU) to O-RU: Fiber or Optical Electric Composite Cable From (O-DU&O-CU) and core network: Fiber or Optical Electric Composite Cable; Trusted or Untrusted transport Duplex(b) Deployment location Cell Coverage MIMO Configuration(b) User distribution(c) Fronthaul Latency TDD, FDD Indoor Omni SU-MIMO/MU-MIMO; up to 4TX/4RX 20-200 Split Option 6: TBD Split Option 7-2x: fronthaul dependent (refer to [6]) Split Option 8: 150us Synchronization(b) Power Supply Mode(b) Notes: GNSS, IEEE-1588v2, BDS POE or by optical electric composite cables\n\nQuestion: What is the fronthaul latency for Split Option 8 in the FR1 Enterprise Microcell Architecture?\n", 
    "output": "The fronthaul latency for Split Option 8 in the FR1 Enterprise Microcell Architecture is 150us."
}
```

# 4. Run the PEFT Fine-Tuning Script


We will use the [`megatron_gpt_finetuning_config.yaml`](https://github.com/NVIDIA/NeMo/blob/main/examples/nlp/language_modeling/conf/megatron_gpt_config.yaml) file in the NeMo container to configure the parameters and run the PEFT training jobs with P-Tuning and LoRA techniques.

We create a shell script to run the fine-tuning. The environment variables specified at the top of the script assume you are at `/workspace`. This script also contains all the environment variables for successful execution.  You might need to change these environment variables, depending on the dataset you are using, model size and required training configurations. You can find some examples of different configurations of `TP_SIZE`, `PP_SIZE` and others in this [link](https://docs.nvidia.com/nemo-framework/user-guide/latest/playbooks/nemoframeworkpeft.html#nemo-framework-peft-playbook).

Note: We use the model prompt template from [Meta Llama 3 Model Card](https://llama.meta.com/docs/model-cards-and-prompt-formats/meta-llama-3/), and override the default model prompt template from `megatron_gpt_finetuning_config.yaml` to suit our RAG use case.

In our example, we save this script as `run_peft.sh` and run the script:

```bash
cat > run_peft.sh << "EOF"
# This is the nemo model we are fine-tuning and should point to the llama3-8b-instruct.nemo as created in the checkpoint conversion script.
MODEL="llama3-8b-instruct.nemo"

# This is the directory where your dataset is saved. 
DATASET_DIRECTORY="data"

# These are the training datasets (in our case we only have one)
TRAIN_DS="${DATASET_DIRECTORY}/train_set.jsonl"

# These are the validation datasets (in our case we only have one)
VALID_DS="${DATASET_DIRECTORY}/val_set.jsonl"

# These are the test datasets (in our case we only have one)
TEST_DS="${DATASET_DIRECTORY}/test_set.jsonl"

# These are the names of the test datasets
TEST_NAMES="${DATASET_DIRECTORY}"

# This is the PEFT scheme that we will be using. Set to "ptuning" for P-Tuning instead of LoRA
PEFT_SCHEME="lora"

# This is the concat sampling probability. This depends on the number of files being passed in the train set and the sampling probability for each file. In our case, we have one training file. Note sum of concat sampling probabilities should be 1.0. For example, with two entries in TRAIN_DS, CONCAT_SAMPLING_PROBS might be "[0.3,0.7]". For three entries, CONCAT_SAMPLING_PROBS might be "[0.3,0.1,0.6]"
# Note: Your entry must contain a value greater than 0.0 for each file
CONCAT_SAMPLING_PROBS="[1.0]"

# This system prompt should be same as the rag_prompt used in digital-human/deploy/prompt.yaml
SYSTEM_PROMPT="You are a helpful and friendly intelligent AI assistant bot named ORAN Chatbot, deployed by the World-Wide Field Operations Sales team at NVIDIA. You are an expert in ORAN standard specifications and in explaining it to field experts and customers. The context given below will provide some technical documentation and whitepapers to help you answer the question. Based on this context, answer the following question related to ORAN standards, processes and specs. If the context provided does not include information about the question from the user, reply saying that you do not know. Remember to describe everything in detail by using the knowledge provided, or reply that you do not know the answer. Do not fabricate any responses. Note that you have the ability to reference images and tables as well, so if the user asks to show a table or image, you can reference it when replying. Be VERY CAREFUL when referencing numbers and performance metrics. If asked about numbers or performance, put a clear disclaimer that states your figures may be incorrect. And think step by step when replying, because your math understanding is relatively poor."

# This prompt template is based on the Llama 3 Model card, as described above
PROMPT_TEMPLATE="<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n\n${SYSTEM_PROMPT}<|eot_id|><|start_header_id|>user<|end_header_id|>\n\n{input}<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n\n{output}"

# Tensor parallel size. Tensor parallelism splits the computation of individual operations (e.g., matrix multiplications) across multiple GPUs. It is particularly useful for operations on large tensors.
TP_SIZE=1

# Pipeline parallel size. Pipeline parallelism divides the neural network into different stages, where each stage runs on a different GPU. Each GPU processes a different part of the model.
PP_SIZE=1

python3 \
/opt/NeMo/examples/nlp/language_modeling/tuning/megatron_gpt_finetuning.py \
    trainer.devices=1 \
    trainer.num_nodes=1 \
    trainer.precision=16 \
    trainer.max_epochs=5 \
    trainer.val_check_interval=200 \
    model.megatron_amp_O2=False \
    ++model.mcore_gpt=True \
    model.tensor_model_parallel_size=${TP_SIZE} \
    model.pipeline_model_parallel_size=${PP_SIZE} \
    model.micro_batch_size=1 \
    model.global_batch_size=16 \
"model.data.train_ds.prompt_template='${PROMPT_TEMPLATE}'"\
    model.optim.lr=1e-4 \
    model.restore_from_path=${MODEL} \
    model.data.train_ds.num_workers=0 \
    model.data.validation_ds.num_workers=0 \
    model.data.train_ds.file_names=[${TRAIN_DS}] \
    model.data.train_ds.concat_sampling_probabilities=${CONCAT_SAMPLING_PROBS} \
    model.data.validation_ds.file_names=[${VALID_DS}] \
    model.peft.peft_scheme=${PEFT_SCHEME} \
    model.peft.lora_tuning.target_modules=[attention_qkv] \
    exp_manager.checkpoint_callback_params.mode=min
EOF

bash run_peft.sh
```

Please note that this step will take about some time based on the above parameters and dataset. Documentation and more info for the above configurations can be found in [here](https://github.com/NVIDIA/NeMo/blob/main/examples/nlp/language_modeling/conf/megatron_gpt_config.yaml).

 
After successful training, the PEFT weights will be stored in `workspace/nemo_experiments/megatron_gpt_peft_lora_tuning/checkpoints` folder, under the name of `megatron_gpt_peft_lora_tuning.nemo`

Once this has been completed, we can stop the NeMo Framework container.

```bash
exit
```

# 5. Setup LoRA Model Directory Structure

To load the PEFT model weights in NIM, we need to create a `loras` directory, with the following example model directory structure. 

```bash
loras
├── llama3-8b-math
│   └── llama3_8b_math.nemo
├── llama3-8b-math-hf
│   ├── adapter_config.json
│   └── adapter_model.bin
├── llama3-8b-squad
│   └── squad.nemo
└── llama3-8b-squad-hf
    ├── adapter_config.json
    └── adapter_model.safetensors
```
The above directory example would load four LoRA models, namely, `llama3-8b-math`, `llama3-8b-math-hf`, `llama3-8b-squad`, and `llama3-8b-squad-hf`. For more information, please refer to our [PEFT documentation](https://docs.nvidia.com/nim/large-language-models/latest/peft.html).

For our use case, we trained one LoRA model. We can name it `lora-nemo-fw`, and copy our PEFT .nemo model from checkpoints to the `loras` directory. 

```bash
mkdir -p loras/lora-nemo-fw
cp nemo_experiments/megatron_gpt_peft_lora_tuning/checkpoints/megatron_gpt_peft_lora_tuning.nemo loras/lora-nemo-fw/lora-nemo-fw.nemo
chmod -R 777 loras
```

Finally, please verify that your `loras` directory looks like this:

```bash
loras/
└── lora-nemo-fw
    └── lora-nemo-fw.nemo
```

Now we can load these PEFT weights using NIMs for our RAG deployment. To load these weights, change the `LLM_MODEL_NAME` in `digital-human/deploy/.env` from `meta/llama3-8b-instruct` to your PEFT weights, i.e., `lora-nemo-fw`:
```
LLM_MODEL_NAME=lora-nemo-fw
```

Finally, we can re-deploy the docker compose to run with our PEFT weights. Please refer to the `/deploy` sub-module for deployment.
