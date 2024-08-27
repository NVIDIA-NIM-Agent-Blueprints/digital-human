# Evaluation of the Digital Human for Customer Service

This notebook walks through different tools and metrics for evaluation of the following pipeline configurations:
1. Without Knowledge Base
2. With Knowledge Base
3. With Knowledge Base and PEFT weights.

To read more on how to customize your model with PEFT weights, please refer to the [`customize`](../customize) folder. Note that you can utilize this sub-module to compare only the first two configurations as well.

To compare the different pipeline configurations, we will use the following metrics:
1. Recall-Oriented Understudy for Gisting Evaluation ([ROUGE](https://huggingface.co/spaces/evaluate-metric/rouge))
2. Bilingual Evaluation Understudy ([BLEU](https://huggingface.co/spaces/evaluate-metric/bleu))
3. [Ragas](https://docs.ragas.io/)
4. LLM-as-Judge

# Getting started
1. Complete the [Common Prerequisites](../README.md#prerequisites) and [deploy the RAG pipeline](../deploy/README.md#rag-pipeline-deployment).
2. Ensure that [Jupyter Lab](https://jupyterlab.readthedocs.io/en/stable/getting_started/installation.html) is installed in your environment. 

3. Inside your Jupyter Lab environment, install the required libraries for the evaluation scripts with following command:

    ```bash
    pip install -r requirements.txt
    ```
    
    If you wish to install these requirements in a virtual environment, please use the following commands:

    ```bash
    pip install virtualenv 	## if you don't already have virtualenv installed
    python3 -m virtualenv oranbot
    source oranbot/bin/activate
    pip install -r requirements.txt
    ```

4. The default test set for evaluation is the [`/data/test_set.jsonl`] file which is generated when we run the preprocessing script in the [`/customize`](../customize) submodule. 

    Alternatively, you can also evaluate on your curated test set. Please make sure each line in the test set has the following format:

    ```
    {"input": "Context: {GOLD_TRUTH_CONTEXT} \n\nQuestion: {USER_QUESTION}", "output": "{GOLD_TRUTH_ANSWER}"
    ```

Now we are ready to run through the notebook `rag_evals.ipynb`!
