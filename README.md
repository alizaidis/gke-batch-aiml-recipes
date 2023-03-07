# Reference Architecture for a Batch Processing Platform on GKE

## Purpose

This tutorial provides patterns to setup batch processing platforms on [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/docs/concepts/kubernetes-engine-overview) (GKE). The Base folder contains the basic infrastructure required for all examples in this repository.

## Prerequistes 

1. This tutorial has been tested on [Cloud Shell](https://shell.cloud.google.com) which comes preinstalled with [Google Cloud SDK](https://cloud.google.com/sdk) and [Terraform](https://www.terraform.io/) which are required to complete this tutorial.

2. It is recommended to start the tutorial in a fresh project since the easiest way to clean up once complete is to delete the project. See [here](https://cloud.google.com/resource-manager/docs/creating-managing-projects) for more details.

## Deploy resources using Terraform.

1. Create a working directory, clone this repo and switch to the appropriate subdirectory.

    ```bash
    mkdir ~/gke-tutorial && cd ~/gke-tutorial && export WORKDIR=$(pwd)
    git clone https://github.com/alizaidis/gke-batch-aiml-recipes.git
    cd gke-batch-aiml-recipes/base
    ```

1. Export the `PROJECT_ID` environment variable; replace the value of `YOUR_PROJECT_ID` with that of a fresh project you created for this tutorial. The rest of this step enables the required APIs, creates an IAM policy binding for the Cloud Build service account, creates an Artifact Registry to host the Cloud Build container images and submit a Cloud Build job to create the required Google Cloud resources. For more details see `build.sh` in the `base` directory.
   
   ```bash
   export PROJECT_ID=YOUR_PROJECT_ID
   ./build.sh
   ```

## Clean up

1. The easiest way to prevent continued billing for the resources that you created for this tutorial is to delete the project you created for the tutorial. Run the following commands from Cloud Shell:

   ```bash
    gcloud config unset project
    echo y | gcloud projects delete $PROJECT_ID
    rm -rf $WORKDIR
    ```
2. If the project needs to be left intact, the second option is to destroy the infrastructure created for this tutorial using Cloud Build.

   ```bash
    gcloud builds submit \
     --config cloudbuild-destroy.yaml \
     --async
    rm -rf $WORKDIR
    ```