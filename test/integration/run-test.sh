#!/bin/bash

# Copyright 2020 The Kubernetes Authors.
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

set -eo pipefail

GO111MODULE=off go get github.com/rexray/gocsi/csc

apt update && apt install cifs-utils procps -y

function cleanup {
  echo 'pkill -f smbplugin'
  pkill -f smbplugin
}

readonly CSC_BIN="$GOBIN/csc"
volumeid="volumetest"
endpoint='tcp://127.0.0.1:10000'
staging_target_path='/tmp/stagingtargetpath'
target_path='/tmp/targetpath'
cloud='AzurePublicCloud'

echo "Begin to run integration test on $cloud..."

# Run CSI driver as a background service
_output/smbplugin --endpoint "$endpoint" --nodeid CSINode -v=5 &
trap cleanup EXIT

if [[ "$cloud" == 'AzureChinaCloud' ]]; then
  sleep 25
else
  sleep 5
fi

# set secret for csc node stage
export X_CSI_SECRETS=username=username,"password=test"

# Begin to run CSI functions one by one
if [[ "$cloud" != 'AzureChinaCloud' ]]; then
  # azure file mount/unmount on travis VM does not work against AzureChinaCloud
  echo "stage volume test:"
  "$CSC_BIN" node stage --endpoint "$endpoint" --cap 1,block --staging-target-path "$staging_target_path" --vol-context=source="//0.0.0.0/Downloads" "$volumeid"
  sleep 2

  echo 'Mount volume test:'
  "$CSC_BIN" node publish --endpoint "$endpoint" --cap 1,block --staging-target-path "$staging_target_path" --target-path "$target_path" "$volumeid"
  sleep 2

  echo 'Unmount volume test:'
  "$CSC_BIN" node unpublish --endpoint "$endpoint" --target-path "$target_path" "$volumeid"
  sleep 2

  echo "unstage volume test:"
  "$CSC_BIN" node unstage --endpoint "$endpoint" --staging-target-path "$staging_target_path" "$volumeid"
  sleep 2
fi



"$CSC_BIN" identity plugin-info --endpoint "$endpoint"
"$CSC_BIN" node get-info --endpoint "$endpoint"

echo "Integration test on $cloud is complete."