#!/bin/bash

if [ -z "${CC_AGENT_TOKEN_SECRET_KEY:-}" -o -z "${CC_AGENT_TOKEN_KEY_ID:-}" ]; then
    echo "CloudCoreo agent token key and secret key not provided."
    exit 1
fi

if [ -z "${CC_S3_BUCKET:-}" ]; then
    echo "CloudCoreo S3 bucket not provied."
    exit 1
fi

if [ -z "${CC_S3_PREFIX:-}" ]; then
    echo "CloudCoreo S3 prefix not provided."
    exit 1
fi

if [ -z "${CC_REGION:-}" ]; then
    echo "CloudCoreo region is not provided."
    exit 1
fi

if [ -z "${CC_AVAILABILITY_ZONE:-}" ]; then
    echo "CloudCoreo availibility zone is not provided."
    exit 1
fi

if [ -z "${CC_STACK:-}" ]; then
    echo "CloudCoreo stack is not provided."
    exit 1
fi

if [ -z "${CC_KEY:-}" ]; then
    echo "CloudCoreo key is not provided."
    exit 1
fi

# CloudCoreo token key id
AGENT_TOKEN_KEY_ID="$CC_AGENT_TOKEN_KEY_ID"

# CloudCoreo agent secret key
AGENT_SECRET_KEY="$CC_AGENT_TOKEN_SECRET_KEY"

S3_BUCKET="$CC_S3_BUCKET"

# Where "path/to/your/files" is the directory in S3 under which the templates and scripts directories will be placed
S3_PREFIX="$CC_S3_PREFIX"

# Where to place your cluster
REGION="$CC_REGION"
AVAILABILITY_ZONE="$CC_AVAILABILITY_ZONE"

# What you want to call your CloudFormation stack
STACK="$CC_STACK"

# What SSH key you want to allow access to the cluster (must be created ahead of time in your AWS EC2 account)
KEYNAME="$CC_KEY"

# What IP addresses should be able to connect over SSH and over the Kubernetes API
INGRESS=0.0.0.0/0

# Copy the files from your local directory into your S3 bucket
aws s3 mb s3://${S3_BUCKET}
aws s3 sync --acl=public-read ./templates s3://${S3_BUCKET}/${S3_PREFIX}/templates/
aws s3 sync --acl=public-read ./scripts s3://${S3_BUCKET}/${S3_PREFIX}/scripts/

aws cloudformation create-stack \
  --region "$REGION" \
  --stack-name "$STACK" \
  --template-url "https://${S3_BUCKET}.s3.amazonaws.com/${S3_PREFIX}/templates/kubernetes-cluster-with-new-vpc.template" \
  --parameters \
    ParameterKey=AvailabilityZone,ParameterValue="$AVAILABILITY_ZONE" \
    ParameterKey=KeyName,ParameterValue="$KEYNAME" \
    ParameterKey=QSS3BucketName,ParameterValue="$S3_BUCKET" \
    ParameterKey=QSS3KeyPrefix,ParameterValue="$S3_PREFIX" \
    ParameterKey=AdminIngressLocation,ParameterValue="$INGRESS" \
    ParameterKey=AgentTokenKeyID,ParameterValue="$AGENT_TOKEN_KEY_ID" \
    ParameterKey=AgentSecretKey,ParameterValue="$AGENT_SECRET_KEY" \
  --capabilities=CAPABILITY_IAM

