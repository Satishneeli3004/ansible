#!/bin/bash
 set -euo pipefail

REPO_NAME="dataset-api" # e.g., admin-api (no registry prefix)
CONTAINER_NAMES="dataset-api-docker-compose" # e.g., "admin-api core-api"

# Hardcoded paths and registry
 ANSIBLE_PLAYBOOK="/home/ubuntu/ansible-playbooks/qa-api-deployment.yaml"
 INVENTORY_FILE="/home/ubuntu/ansible-inventory-files/qa.ini"
 REGISTRY="artifacts.ezee.ai"
 JENKINS_CFG_DIR="/var/lib/jenkins/workspace/QA-ENV-AUTOMATION/QA-ENV-Dataset-api-config"


# copy config files to workspace (overwrite with canonical versions)
 cp -f "$JENKINS_CFG_DIR/Dockerfile" . || true



 echo "//registry.npmjs.org/:_authToken=npm_Token" > .npmrc
 GIT_TAG=$(git describe --tags --exact-match 2>/dev/null || echo "")

if [ -z "$GIT_TAG" ]; then
 # fallback to Jenkins env variables for branch name, sanitize slashes to dashes
 if [ ! -z "$GIT_BRANCH" ]; then
 GIT_TAG=$(echo "$GIT_BRANCH" | sed 's#[\/]#-#g')
 elif [ ! -z "$BRANCH_NAME" ]; then
 GIT_TAG=$(echo "$BRANCH_NAME" | sed 's#[\/]#-#g')
 else
 # fallback to git rev-parse only if all else fails
 GIT_TAG=$(git rev-parse --abbrev-ref HEAD | sed 's#[\/]#-#g')
 fi
 fi

DATE_TIME=$(date +%Y-%m-%d_%H-%M)
 # Compose image tag and full repo name
 IMAGE_TAG="${GIT_TAG}"
 FULL_REPO="${REGISTRY}/${REPO_NAME}/${REPO_NAME}"

echo "Building and pushing image: ${FULL_REPO}:${IMAGE_TAG}"
 sudo docker build -t "${FULL_REPO}:${IMAGE_TAG}" --build-arg NPM_TOKEN="npm_Token" .
 sudo docker push "${FULL_REPO}:${IMAGE_TAG}"

# Convert space-separated container names to YAML list format for Ansible
 #CONTAINER_LIST_YAML=$(echo "${CONTAINER_NAMES}" | sed 's/ \+/", "/g' | sed 's/^/[ "/;s/$/" ]/')

ansible-playbook -i "${INVENTORY_FILE}" "${ANSIBLE_PLAYBOOK}" \
 --extra-vars "container_list='${CONTAINER_LIST_YAML}' new_image_tag='${IMAGE_TAG}' repositoryname='${FULL_REPO}'"
