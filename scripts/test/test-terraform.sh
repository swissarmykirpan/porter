#!/usr/bin/env bash

set -euo pipefail
export REGISTRY=${REGISTRY:-$USER}
export REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
export PORTER_HOME=${PORTER_HOME:-$REPO_DIR/bin}
# Run tests in a temp directory
export TEST_DIR=/tmp/porter/terraform
mkdir -p ${TEST_DIR}
pushd ${TEST_DIR}
trap popd EXIT

# Copy terraform assets
cp -r ${REPO_DIR}/build/testdata/bundles/terraform/terraform .

# Copy in the terraform porter manifest
cp ${REPO_DIR}/build/testdata/bundles/terraform/porter.yaml .

# Substitute REGISTRY in for the bundle tag
sed -i "s/getporterci\/porter-terraform/${REGISTRY}\/porter-terraform/g" porter.yaml

${PORTER_HOME}/porter build

${PORTER_HOME}/porter install --insecure --debug --param file_contents='foo!'

echo "Verifying instance output(s) via 'porter instance outputs list' after install"
list_outputs=$(${PORTER_HOME}/porter instance outputs list)
echo "${list_outputs}"
echo "${list_outputs}" | grep -q "file_contents"
echo "${list_outputs}" | grep -q "foo!"

# TODO: enable when status supported
# ${PORTER_HOME}/porter status --debug | grep -q 'content = foo!'

${PORTER_HOME}/porter upgrade --insecure --debug --param file_contents='bar!'

echo "Verifying instance output(s) via 'porter instance output show' after upgrade"
${PORTER_HOME}/porter instance output show file_contents | grep -q "bar!"

# TODO: enable when status supported
# ${PORTER_HOME}/porter status --debug | grep -q 'content = bar!'

cat ${PORTER_HOME}/claims/terraform.json

${PORTER_HOME}/porter uninstall --insecure --debug

${PORTER_HOME}/porter publish
