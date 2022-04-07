#!/usr/bin/env bash

# Login to Kubernetes Cluster.
if [ -n "$CLUSTER_ROLE_ARN" ]; then
    aws eks \
        --region ${AWS_REGION} \
        update-kubeconfig --name ${CLUSTER_NAME} \
        --role-arn=${CLUSTER_ROLE_ARN}
else
    aws eks \
        --region ${AWS_REGION} \
        update-kubeconfig --name ${CLUSTER_NAME} 
fi

# Helm rollback

####################
# Dependency Update
####################
# Verify local or remote repository
if [  -z  ${HELM_CHART_NAME} ]; then
    HELM_CHART_NAME=${DEPLOY_CHART_PATH%/*}
fi
if [ ! -z "$HELM_REPOSITORY" ]; then
    #Verify basic auth
    if [ ! -z ${REPO_USERNAME} ] && [ ! -z ${REPO_PASSWORD} ]; then
        echo "Executing: helm repo add  --username="${REPO_USERNAME}" --password="${REPO_PASSWORD}" ${HELM_CHART_NAME} ${HELM_REPOSITORY}"
        helm repo add  --username="${REPO_USERNAME}" --password="${REPO_PASSWORD}" ${HELM_CHART_NAME} ${HELM_REPOSITORY}
    else
        echo "Executing: helm repo add ${HELM_CHART_NAME} ${HELM_REPOSITORY}"
        helm repo add ${HELM_CHART_NAME} ${HELM_REPOSITORY}
    fi
else
    echo "Executing: helm dependency update ${DEPLOY_CHART_PATH}"
    helm dependency update ${DEPLOY_CHART_PATH}
fi

####################
# Helm rollback
####################

ROLLBACK_COMMAND="helm rollback"
if [ -n "$DEPLOY_NAMESPACE" ]; then
    ROLLBACK_COMMAND="${ROLLBACK_COMMAND} -n ${DEPLOY_NAMESPACE}"
fi

if [ -n "$DEBUG" ]; then
    ROLLBACK_COMMAND="${ROLLBACK_COMMAND} --debug"
fi

if [ -n "$DRY_RUN" ]; then
    ROLLBACK_COMMAND="${ROLLBACK_COMMAND} --dry-run"
fi

ROLLBACK_COMMAND="${ROLLBACK_COMMAND} ${DEPLOY_NAME}"
    
echo "Executing: ${ROLLBACK_COMMAND}"
${ROLLBACK_COMMAND}