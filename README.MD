Steps:
1) Create GCP project, configure billing and set up a limit.
2) Create a VS Code repo, install terraform and create main terraform files.
3) Create bucket for tfstate:
Dans ta console GCP → Cloud Storage → Create bucket.
Nom : my-tfstate-bucket (doit être globalement unique)
Location : EU (ou la même région que ton dataset)
Storage class : Standard (pour un fichier tiny, coût négligeable)
Versioning : facultatif, mais pratique pour historiser les tfstate
💡 Astuce : ce bucket ne contiendra que le tfstate, pas d’autres fichiers volumineux.
3) Makefile, setup gcloud credentials, and then execute terraform commands.
>>> gcloud auth application-default login
>>> gcloud config set project prime-hour-472917-d3
>>> gcloud auth application-default set-quota-project prime-hour-472917-d3

4) Added in terraform the BigQuery table that consumes the weather csv from GCS.
5) Add python code to download weather csv and upload to GCS.