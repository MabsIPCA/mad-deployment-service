# Author: MAD Goat Team
# Description: This script is used to run the docker compose file and terraform scripts
# Usage: ./run.sh

cd compose

docker compose -f configurations.yaml -f infrastructure.yaml -f services.yaml up -d

#cd object-storage-deployment/lessons-bucket
#terraform init
#terraform plan
#terraform apply -auto-approve

