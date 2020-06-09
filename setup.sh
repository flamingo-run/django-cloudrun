echo "[01] Setting up variables"
PROJECT_ID=daher-sandbox
REGION=us-central1
PROJECT_NAME=django-cloudrun
DATABASE_INSTANCE=django-cloudrun-db
DATABASE_NAME=django_cloudrun
DJPASS=$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c10)
DATABASE_USER=djuser
ADMIN_PASSWORD=$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c10)
GS_BUCKET_NAME=${PROJECT_NAME}-media
PROJECTNUM=$(gcloud projects describe ${PROJECT_ID} --format 'value(projectNumber)')
CLOUDRUN=${PROJECTNUM}-compute@developer.gserviceaccount.com
CLOUDBUILD=${PROJECTNUM}@cloudbuild.gserviceaccount.com
gcloud config set project $PROJECT_ID


echo "[02] Enabling Services"
gcloud services enable   run.googleapis.com   sql-component.googleapis.com   sqladmin.googleapis.com   compute.googleapis.com   cloudbuild.googleapis.com   secretmanager.googleapis.com


echo "[03] Setting up Database"
gcloud sql instances create $DATABASE_INSTANCE --project $PROJECT_ID --database-version POSTGRES_11 --tier db-f1-micro --region $REGION 
gcloud sql databases create $DATABASE_NAME --instance $DATABASE_INSTANCE
gcloud sql users create $DATABASE_USER --instance $DATABASE_INSTANCE --password $DJPASS


echo "[04] Setting up Cloud Storage"
gsutil mb -l ${REGION} gs://${GS_BUCKET_NAME}
echo DATABASE_URL=\"postgres://${DATABASE_USER}:${DJPASS}@//cloudsql/${PROJECT_ID}:${REGION}:${DATABASE_INSTANCE}/${DATABASE_NAME}\" > .env
echo GS_BUCKET_NAME=\"${GS_BUCKET_NAME}\" >> .env


echo "[05] Setting up secrets"
echo SECRET_KEY=\"$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c10)\" >> .env
gcloud secrets create django_settings --replication-policy automatic
gcloud secrets versions add django_settings --data-file .env
gcloud secrets add-iam-policy-binding django_settings   --member serviceAccount:${CLOUDRUN} --role roles/secretmanager.secretAccessor
gcloud secrets add-iam-policy-binding django_settings   --member serviceAccount:${CLOUDBUILD} --role roles/secretmanager.secretAccessor
gcloud projects add-iam-policy-binding ${PROJECT_ID}     --member serviceAccount:${CLOUDBUILD} --role roles/cloudsql.client
gcloud secrets create admin_password --replication-policy automatic
echo -n "${ADMIN_PASSWORD}" | gcloud secrets versions add admin_password --data-file=-
gcloud secrets add-iam-policy-binding admin_password   --member serviceAccount:${CLOUDBUILD} --role roles/secretmanager.secretAccessor


echo "[06] Setting up Cloud Build"
gcloud builds submit --tag gcr.io/$PROJECT_ID/django-cloudrun
