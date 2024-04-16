#!/bin/bash

set -eo pipefail

usage() {
  echo ''
  echo 'Usage : bootstrap-workflow-task.sh -o <organization> -n <repo-name> -t <template-folder> -w <workflow-task-type> -e <environment> -p <aws-profile>'
  echo '-organization       | -o <organization>        Github organization or handle, in which the repo is going to be created '
  echo '-repo-name          | -n <repo-name>           The new repo name '
  echo '-template           | -t <template-folder>     The template folder'
  echo '-workflow-task-type | -w <workflow-task-type>  Workflow task type. "container" or "function"'
  echo '-environment        | -e <environment>         Strato Environment Name'
  echo '-region             | -r <aws-region>          The target AWS region. Defaults to [us-west-2]'
  echo '-profile            | -p <aws-profile>         Name of the AWS profile'
  echo ''
  exit 1
}

REGION='us-west-2'

while [[ "$1" != "" ]]; do
  case $1 in
  -organization|-o )
    shift
    GITHUB_ORGANIZATION=$1
    ;;
  -repo-name|-n )
    shift
    REPO_NAME=$1
    ;;
  -template|-t)
    shift
    TEMPLATE_FOLDER=$1
    ;;
  -workflow-task-type|-w)
    shift
    WORKFLOW_TASK_TYPE=$1
    ;;
  -environment|-e )
    shift
    ENVIRONMENT=$1
    ;;
  -region|-r )
    shift
    REGION=$1
    ;;
  -profile|-p ) shift
    PROFILE=$1
    ;;
  -github-token|-g ) shift
    GH_TOKEN=$1
    ;;    
  esac
  shift
done

if [[ "${GITHUB_ORGANIZATION}" = "" || "${REPO_NAME}" = "" || "${TEMPLATE_FOLDER}" = "" || "${ENVIRONMENT}" = "" || "${PROFILE}" = "" || ! ("${WORKFLOW_TASK_TYPE}" == "container" || "${WORKFLOW_TASK_TYPE}" == "function") ]]; then
  usage
fi

########################### Prerequisites ###########################
# Function to install Terraform
install_terraform() {
    local os=$1
    local terraform_version="1.5.5"
    echo "Installing Terraform v$terraform_version..."

    if [ "$os" == "Darwin" ]; then
        local url="https://releases.hashicorp.com/terraform/$terraform_version/terraform_${terraform_version}_darwin_amd64.zip"
    elif [ "$os" == "Linux" ]; then
        local url="https://releases.hashicorp.com/terraform/$terraform_version/terraform_${terraform_version}_linux_amd64.zip"
    else
        echo "Unsupported operating system."
        exit 1
    fi

    curl -O "$url"
    unzip "terraform_${terraform_version}_$(echo $os | tr '[:upper:]' '[:lower:]')_amd64.zip"
    sudo mv terraform /usr/local/bin/
    rm "terraform_${terraform_version}_$(echo $os | tr '[:upper:]' '[:lower:]')_amd64.zip"
    echo "Terraform v$terraform_version installed successfully."
}

install_gh() {
    local os=$1
    local gh_version="2.39.2" # You can update this to the desired version

    echo "Installing GitHub CLI (gh) version $gh_version..."

    # Download and install GitHub CLI for macOS or Linux
    if [ "$os" == "Darwin" ]; then
        local url="https://github.com/cli/cli/releases/download/v$gh_version/gh_${gh_version}_macOS_amd64.tar.gz"
        curl -L $url | tar xz
        sudo mv gh_${gh_version}_macOS_amd64/bin/gh /usr/bin/
    elif [ "$os" == "Linux" ]; then
        local url="https://github.com/cli/cli/releases/download/v$gh_version/gh_${gh_version}_linux_amd64.tar.gz"
        curl -L $url | tar xz
        sudo mv gh_${gh_version}_linux_amd64/bin/gh /usr/bin/
    else
        echo "Unsupported operating system."
        exit 1
    fi

    echo "GitHub CLI installed successfully."
}

ensure_brew() {
  if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
}

# Check the operating system
os_type=$(uname)

if ! command -v gh &> /dev/null; then
    install_gh "$os_type"
fi

# Check if Terraform is installed and the version is 1.5.5
if command -v terraform &> /dev/null; then
    installed_version=$(terraform -version | head -n 1 | awk '{print $2}' | cut -d'v' -f2)
    if [ "$installed_version" != "1.5.5" ]; then
        echo "Terraform is installed, but not v1.5.5."
        install_terraform "$os_type"
    fi
else
    echo "Terraform is not installed."
    install_terraform "$os_type"
fi

if [[ "$os_type" == "Darwin" ]]; then
  if ! which gsed &> /dev/null; then
    ensure_brew
    brew install gnu-sed
  fi
fi

export GSED=$(which gsed 2>/dev/null || which sed)

if ! ${GSED} --version 2>&1 | grep -q GNU; then
    echo "Need GNU sed."
    exit 1
fi
########################### End Prerequisites ###########################

REPO_NAME="$(tr '[:upper:]' '[:lower:]' <<< strato-${REPO_NAME})"

gh repo create ${GITHUB_ORGANIZATION}/${REPO_NAME} --private --template "strato-earth/workflow-task-template"
sleep 3
git clone git@github.com:${GITHUB_ORGANIZATION}/${REPO_NAME}.git

pushd "${REPO_NAME}"

if [[ ! -d templates/$TEMPLATE_FOLDER ]]; then
  echo "Template folder doesn't exists!"
  exit 1
fi
pwd

cp -a templates/$TEMPLATE_FOLDER/. .

if [[ "${WORKFLOW_TASK_TYPE}" = "container" ]]; then
  scripts/create-ecr-repo.sh -n "${REPO_NAME}" -e "${ENVIRONMENT}" -r $REGION -p ${PROFILE}
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile ${PROFILE} | jq -r '.Account')
ARTIFACTS_BUCKET=$(aws --profile "${PROFILE}" --region "$REGION" ssm get-parameter --name "/strato/${ENVIRONMENT}/config/workflow_task_artifacts_bucket" --query "Parameter.Value" --output text)

scripts/create-github-oidc.sh -o "${GITHUB_ORGANIZATION}" -n "${REPO_NAME}" -e "${ENVIRONMENT}" -r $REGION -p ${PROFILE} -b $ARTIFACTS_BUCKET -w "${WORKFLOW_TASK_TYPE}"

gh secret set -a actions BUILD_ARTIFACTS_AWS_ACCOUNT_ID --body $AWS_ACCOUNT_ID
gh secret set -a actions BUILD_S3_ARTIFACTS_BUCKET --body $ARTIFACTS_BUCKET
if [[ "${GH_TOKEN}" != "" ]]; then
  gh secret set -a actions GH_TOKEN --body $GH_TOKEN
fi

rm -rf templates scripts/strato/bootstrap-workflow-task.sh scripts/strato/bootstrap-workflow-task-in-existing-repo.sh scripts/strato/create-ecr-repo.sh scripts/strato/create-github-oidc.sh scripts/strato/mount-efs.sh scripts/strato/umount-efs.sh scripts/strato/start-ops-session.sh

set +e
${GSED} -r -i "s;executable1;${REPO_NAME};g" $(egrep "executable1" --exclude-dir=node_modules * -r|cut -f1 -d:|sort -u|egrep -v $(basename $0))
${GSED} -i "s/BUILD_ENVIRONMENT/$ENVIRONMENT/g" .github/workflows/build.yml
set -e

mv scripts/strato/pre-commit .git/hooks/

if [ -f "scripts/install-dependencies.sh" ]; then
  scripts/install-dependencies.sh
fi

git add .
git commit -m "chore: Initial Commit"
git push

popd