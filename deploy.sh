eval $(cat .vars)

echo "[01] Submit image"
gcloud builds submit --tag gcr.io/$PROJECT_ID/django-cloudrun

echo "[02] Performing Migration"
gcloud builds submit --config cloudmigrate.yaml     --substitutions _REGION=$REGION,_DATABASE_INSTANCE=$DATABASE_INSTANCE


echo "[03] Deploying Web"
gcloud run deploy django-cloudrun-api --platform managed --region $REGION --image gcr.io/$PROJECT_ID/django-cloudrun --add-cloudsql-instances ${PROJECT_ID}:${REGION}:${DATABASE_INSTANCE} --command make --args server --allow-unauthenticated
gcloud run services describe django-cloudrun-api   --platform managed   --region $REGION    --format "value(status.url)"
