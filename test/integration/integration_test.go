/*
Copyright 2019 The Kubernetes Authors.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package integration

import (
	"github.com/stretchr/testify/assert"
	"os"
	"os/exec"
	"strings"
	"testing"
)

func TestIntegration(t *testing.T) {
	// Execute the script from project root
	err := os.Chdir("../..")
	assert.NoError(t, err)
	// Change directory back to test/integration in preparation for next test
	defer func() {
		err := os.Chdir("test/integration")
		assert.NoError(t, err)
	}()
	cwd, err := os.Getwd()
	assert.NoError(t, err)
	assert.True(t, strings.HasSuffix(cwd, "csi-driver-smb"))
	cmd := exec.Command("sudo -E env \"PATH=$PATH\" ./test/integration/run-test.sh")
	cmd.Dir = cwd
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		t.Fatalf("Integration test failed %v", err)
	}
}
