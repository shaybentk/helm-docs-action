#!/usr/bin/env bash
#
# Copyright 2021 The helm-docs Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o pipefail
set -o errtrace


if [ -z "${INPUT_GIT_PUSH_USER_NAME}" ]; then
    INPUT_GIT_PUSH_USER_NAME="github-actions[bot]"
fi

if [ -z "${INPUT_GIT_PUSH_USER_EMAIL}" ]; then
    INPUT_GIT_PUSH_USER_EMAIL="github-actions[bot]@users.noreply.github.com"
fi

git_setup() {
    # When the runner maps the $GITHUB_WORKSPACE mount, it is owned by the runner
    # user while the created folders are owned by the container user, causing this
    # error. Issue description here: https://github.com/actions/checkout/issues/766
    git config --global --add safe.directory /github/workspace

    git config --global user.name "${INPUT_GIT_PUSH_USER_NAME}"
    git config --global user.email "${INPUT_GIT_PUSH_USER_EMAIL}"
    git fetch --depth=1 origin +refs/tags/*:refs/tags/* || true
}

git_add() {
    local file
    file="$1"
    git add "${file}"
    if [ "$(git status --porcelain | grep "$file" | grep -c -E '([MA]\W).+')" -eq 1 ]; then
        echo "::debug Added ${file} to git staging area"
    else
        echo "::debug No change in ${file} detected"
    fi
}

git_status() {
    git status --porcelain | grep -c -E '([MA]\W).+' || true
}

git_commit() {
    if [ "$(git_status)" -eq 0 ]; then
        echo "::debug No files changed, skipping commit"
        exit 0
    fi

    echo "::debug Following files will be committed"
    git status -s

    local args=(
        -m "${INPUT_GIT_COMMIT_MESSAGE}"
    )

    if [ "${INPUT_GIT_PUSH_SIGN_OFF}" = "true" ]; then
        args+=("-s")
    fi

    git commit "${args[@]}"
}

update_doc() {
    local working_dir
    working_dir="$1"
    echo "::debug working_dir=${working_dir}"

    helm-docs --chart-to-generate ${working_dir}
    success=$?

    if [ $success -ne 0 ]; then
        exit $success
    fi

    if [  $success -eq 0 ]; then
        git_add "${working_dir}/${OUTPUT_FILE}"
    fi

}

# go to github repo
cd "${GITHUB_WORKSPACE}"

git_setup


if [ -n "${INPUT_CHART}" ]; then
  for project_dir in ${INPUT_CHART} ; do
      update_doc "${project_dir}"
    done
fi
  if  [ -n "${INPUT_WORKING_DIR}" ]; then
    #Split INPUT_WORKING_DIR by commas
    for project_dir in ${INPUT_WORKING_DIR//,/ }; do
        update_doc "${project_dir}"
    done
  fi


# always set num_changed output
set +e
num_changed=$(git_status)
set -e
echo "num_changed=${num_changed}" >> $GITHUB_OUTPUT

if [ "${INPUT_GIT_PUSH}" = "true" ]; then
    git_commit
    git push
else
    if [ "${INPUT_FAIL_ON_DIFF}" = "true" ] && [ "${num_changed}" -ne 0 ]; then
        echo "::error ::Uncommitted change(s) has been found!"
        exit 1
    fi
fi

exit 0
