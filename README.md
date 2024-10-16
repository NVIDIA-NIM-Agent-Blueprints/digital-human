<h2><img align="center" src="https://github.com/user-attachments/assets/cbe0d62f-c856-4e0b-b3ee-6184b7c4d96f">NIM Agent Blueprint: Digital Human for Customer Service</h2>

The Digital Human for Customer Service NVIDIA NIM™ Agent Blueprint is powered by NVIDIA Tokkio, a workflow based on ACE technologies, to bring enterprise applications to life with a 3D animated digital human interface. With approachable, human-like interactions, customer service applications can provide more engaging user experience compared to traditional customer service options.

This blueprint is powered by a suite of easy to use and performance-optimized NVIDIA NIM<sup>TM</sup> inference microservices, for avatar animation, speech AI, and generative AI.  The avatar is rendered using the Omniverse RTX microservice, animated with the Audio2Face NIM, and has a responsive speech interface with the NVIDIA Riva NIM and ElevenLabs integrations.   

## Why digital humans?
Digital humans will revolutionize industries from customer service, to advertising and gaming.  The possibilities for digital humans are endless.  With an approachable, human-like interface, customer service applications can provide better user experiences with faster resolutions than generative AI powered applications with just a text or speech interface.  Check out this youtube video. This digital humans blueprint highlights how to use NVIDIA hardware and software to bring the $125B digital human market to life.  80% of conversational offerings will embed generative AI by 2025, up from 20% in 2024*.  And 75% of conversational AI customer-facing business applications will have emotion AI by 2030, up from less than 10% in 2024<sup>*</sup>

\*Gartner – Emerging Tech: Navigating the Hurdles of Digital Humans

## About this blueprint
This blueprint serves as a starting point for a team of developers to showcase how an LLM or a RAG application can be connected to a digital human pipeline. The digital avatar and the Retrieval-Augmented Generation (RAG) applications are deployed separately. 

The RAG application is responsible for generating the text context to question-answer interactions and the digital human live avatar, leverages a Tokkio customer service pipeline. Since these two entities are separated, they communicate with one another using the REST API. Developers can build upon this blueprint, by customizing the RAG application and digital avatar based on their specific use case. 

<p align="center">
 <img width="800" alt="dht" src="https://github.com/user-attachments/assets/64bd6115-035c-4b2f-88d4-ba8f2c2b29ac">
</p>

## Software Components
The RAG-based AI digital human provides a reference to build an enterprise-ready generative AI solution with minimal effort. It contains the following software components:

* ACE Tokkio Customer Service
  * 3D Animation Pipeline - [Audio2Face NIM](https://build.nvidia.com/nvidia/audio2face)
  * Audio Pipeline - [Parakeet-ctc-1.1b.asr NIM](https://build.nvidia.com/nvidia/parakeet-ctc-1_1b-asr) and ElevenLabs TTS
* Response RAG Generation (Inference)
  * LLM - [Llama-3-8B-instruct NIM](https://build.nvidia.com/meta/llama3-8b)
  * NeMo Retriever embedding - [NV-Embed-QA-v5 NIM](https://build.nvidia.com/nvidia/nv-embedqa-e5-v5)
  * NeMo Retriever reranking - [Rerank-Mistral-4b-v3 NIM](https://build.nvidia.com/nvidia/nv-rerankqa-mistral-4b-v3)
* RAG Text Retriever - LangChain
* RAG Unstructured Data (PDF) Ingestion - Milvus Database (Vector GPU-optimized)

## Target audience
Setting up the digital human pipelines, as well as customization, requires a technical team with expertise in different areas of the software stack.

### Persona-1: Devops engineer
To deploy this blueprint, you must be comfortable deploying applications/helm charts on Kubernetes, creating resources on cloud service provider platforms and have general deployment expertise.


### Persona-2: GenAI developer/ Machine learning engineer
Since this blueprint will require customization for your specific use case, you should have necessary technical expertise to take the existing blueprint and change it to suit your needs. This includes, but is not limited to changing the RAG pipeline for your specific dataset and fine tuning the LLMs if needed.

NOTE:  Please refer to the customization section for additional information.  

### Persona-3: (Optional) Animation/Rendering developer 
Tokkio allows you to customize your live avatar with the Avatar Configurator or alternatively you can import a third-party avatar by following the custom avatar guide. More information can be found in the Avatar Customization section. If you are looking to customize the avatar away from the default one then you would need an engineer comfortable in above.


## Get Started

#### Get Started
The Digital human blueprint has two components, the digital avatar deployment and the Retrieval Augmented Generation pipeline. 

* [Prerequisites](#prerequisites)
* [Deployment](/deploy/)
* [Customization](/customize/)
* [Evaluation]((/evaluate/))


## Prerequisites

* NVIDIA AI Enterprise or Developer License: NVIDIA NIM for LLMs are available for self-hosting under the NVIDIA AI Enterprise (NVAIE) License.
* Sign up for NVAIE license. An NGC API key is required to access NGC resources.
  * To obtain a key, navigate to Blueprint experience on NVIDIA API Catalog.
  * Login / Sign up if needed and "Generate your API Key".

### Digital Avatar

#### Hardware requirements
Supported NVIDIA GPU hardware:

* T4
* A10
* L4
* L40S

A minimum of 2 GPUs are required for 1 stream and 4 GPUs for 3 streams. For this blueprint guide, we will deploy the digital avatar pipeline on [AWS](https://docs.aws.amazon.com/dlami/latest/devguide/gpu.html) using a g5.12xlarge machine.  The blueprint requires at least a 8 core CPU, 64GB of system memory and 500GB of disk space.

NOTE:  If you are setting this up on GCP or Azure. Please checkout the GPU instance types for the corresponding providers. 

#### System requirements
Ubuntu 20.04 or 22.04 based machine, with sudo privileges for the user to run the automated deployment scripts.

NOTE:  In an upcoming step, you will use one click scripts in the Digital Avatar deployment instructions to set up everything else.

### Retrieval Augmented Generation (RAG) pipeline
#### Hardware requirements

##### Option 1: RAG without customization
To familiarize yourself with the digital human blueprint, you can leverage a non-GPU accelerated AWS EC2 instance.  By default, the blueprint uses the NVIDIA API Catalog hosted endpoints for LLM, embedding and reranking models.  Therefore all that is required is an instance with at least 8 cores and 64GB memory.  A public IP address is also required to connect to the digital human avatar.

##### Option-2: RAG with customization
Once you familiarize yourself with the blueprint, you may want to further customize based upon your own use case which requires you to host your own LLM, embedding and reranking models.  In this case you will need access to a GPU accelerated AWS EC2 instance with 8 cores, 64GB memory and 2X A100 or L40s GPUs.  For this option, deploy the RAG pipeline on AWS using a g5.12xlarge machine.  A public IP address is required to connect to the digital human avatar.

#### System requirements
Ubuntu 20.04 or 22.04 based machine, with sudo privileges
