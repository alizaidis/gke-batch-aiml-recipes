[[ ! "${PROJECT_ID}" ]] && echo -e "Please export PROJECT_ID variable (\e[95mexport PROJECT_ID=<YOUR POROJECT ID>\e[0m)\nExiting." && exit 0
echo -e "\e[95mPROJECT_ID is set to ${PROJECT_ID}\e[0m"
gcloud config set core/project ${PROJECT_ID}
export PROJECT_NUM=$(gcloud projects describe "${PROJECT_ID}" --format='value(projectNumber)')
export TF_CLOUDBUILD_SA="${PROJECT_NUM}@cloudbuild.gserviceaccount.com"
echo -e "$TF_CLOUDBUILD_SA"
echo -e "\e[95mEnabling required APIs in ${PROJECT_ID}\e[0m"
gcloud --project="${PROJECT_ID}" services enable \
 cloudapis.googleapis.com \
 compute.googleapis.com \
 servicenetworking.googleapis.com \
 iam.googleapis.com \
 cloudbuild.googleapis.com \
 artifactregistry.googleapis.com \
 container.googleapis.com \
 cloudtrace.googleapis.com \
 monitoring.googleapis.com \
 logging.googleapis.com \
 storage.googleapis.com \
 mesh.googleapis.com \
 cloudresourcemanager.googleapis.com

echo -e "\e[95mAssigning Cloudbuild Service Account roles/owner in ${PROJECT_ID}\e[0m"
gcloud projects add-iam-policy-binding "${PROJECT_ID}" --member serviceAccount:"${TF_CLOUDBUILD_SA}" --role roles/owner

echo -e "\e[95mStarting Cloudbuild to create infrastructure...\e[0m"

[[ $(gcloud artifacts repositories list | grep "platform-installer") ]] || \
gcloud artifacts repositories create platform-installer --repository-format=docker --location=us-west1 --description="Repo for platform installer container images built by Cloud Build."

gcloud builds submit --config cloudbuild-create.yaml --async

echo -e "\e[95mYou can view the Cloudbuild status through https://console.cloud.google.com/cloud-build\e[0m"
