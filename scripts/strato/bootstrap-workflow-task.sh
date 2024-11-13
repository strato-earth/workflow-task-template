#!/bin/bash

set -exo pipefail

usage() {
  echo ''
  echo 'Usage : bootstrap-workflow-task.sh -o <organization> -n <repo-name> -t <template-folder> -v <runtime-version> -w <workflow-task-type> -e <environment> -p <aws-profile>'
  echo '-organization       | -o <organization>        Github organization or handle, in which the repo is going to be created '
  echo '-repo-name          | -n <repo-name>           The new repo name '
  echo '-template           | -t <template-folder>     The template folder'
  echo '-version            | -v <runtime-version>     Runtime version'
  echo '-environment        | -e <environment>         Strato Environment Name'
  echo '-region             | -r <aws-region>          The target AWS region. Defaults to [us-west-2]'
  echo '-profile            | -p <aws-profile>         Name of the AWS profile'
  echo ''
  exit 1
}

REGION='us-west-2'
RUNTIME_VERSION='latest'

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
  -version|-v)
    shift
    RUNTIME_VERSION=$1
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

if [[ "${GITHUB_ORGANIZATION}" = "" || "${REPO_NAME}" = "" || "${TEMPLATE_FOLDER}" = "" || "${ENVIRONMENT}" = "" || "${PROFILE}" = "" ]]; then
  usage
fi

########################### Prerequisites ###########################
# Function to install OpenTofu
install_opentofu() {
    # Download the installer script:
    curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh

    # Grant execution permissions:
    chmod +x install-opentofu.sh

    # Please inspect the downloaded script at this point.

    # Run the installer:
    ./install-opentofu.sh --install-method standalone

    # Remove the installer:
    rm install-opentofu.sh
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

# Check if OpenTofu is installed
if ! command -v tofu &> /dev/null; then
    echo "OpenTofu is not installed."
    install_opentofu
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

if [[ ! -d templates/$TEMPLATE_FOLDER/v/$RUNTIME_VERSION ]]; then
  echo "Template folder $TEMPLATE_FOLDER, for version $RUNTIME_VERSION doesn't exists!"
  exit 1
fi
pwd

cp -a templates/$TEMPLATE_FOLDER/v/$RUNTIME_VERSION/. .

WORKFLOW_TASKS_REPOS_SSM_KEY="/strato/${ENVIRONMENT}/config/workflow_tasks_repos"
EXISTING_WORKFLOW_TASKS=$(aws --profile "${PROFILE}" --region "$REGION" ssm get-parameter --name "$WORKFLOW_TASKS_REPOS_SSM_KEY" --query "Parameter.Value" --output text 2>/dev/null || echo "")
IFS=',' read -ra TASKS_ARRAY <<< "$EXISTING_WORKFLOW_TASKS"
TASKS_ARRAY+=("$GITHUB_ORGANIZATION/$REPO_NAME")
UNIQUE_TASKS=($(echo "${TASKS_ARRAY[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
NEW_WORKFLOW_TASKS=$(IFS=','; echo "${UNIQUE_TASKS[*]}")

aws --profile "${PROFILE}" --region "$REGION" ssm put-parameter --name "$WORKFLOW_TASKS_REPOS_SSM_KEY" --value "$NEW_WORKFLOW_TASKS" --type "String" --overwrite

scripts/strato/update-workflow-tasks.sh -e "${ENVIRONMENT}" -r $REGION -p ${PROFILE}

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile ${PROFILE} | jq -r '.Account')
ARTIFACTS_BUCKET=$(aws --profile "${PROFILE}" --region "$REGION" ssm get-parameter --name "/strato/${ENVIRONMENT}/config/workflow-master/workflow_task_artifacts_bucket" --query "Parameter.Value" --output text)

gh secret set -a actions BUILD_ARTIFACTS_AWS_ACCOUNT_ID --body $AWS_ACCOUNT_ID
gh secret set -a actions BUILD_S3_ARTIFACTS_BUCKET --body $ARTIFACTS_BUCKET
if [[ "${GH_TOKEN}" != "" ]]; then
  gh secret set -a actions GH_TOKEN --body $GH_TOKEN
fi

if [ -f pre-commit ]; then
  mv pre-commit .git/hooks/
fi
mkdir -p .github/workflows
mv github/build.yml .github/workflows/build.yml
rm -rf templates infrastructure github scripts docker

set +e
${GSED} -r -i "s;executable1;${REPO_NAME};g" $(egrep "executable1" --exclude-dir=node_modules * -r|cut -f1 -d:|sort -u|egrep -v $(basename $0))
${GSED} -i "s/BUILD_ENVIRONMENT/$ENVIRONMENT/g" .github/workflows/build.yml
set -e

git add .
git commit -m "chore: Initial Commit"
git push

popd