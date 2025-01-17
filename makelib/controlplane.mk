# Copyright 2022 The Upbound Authors. All rights reserved.
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

KIND_CLUSTER_NAME ?= local-dev
CROSSPLANE_NAMESPACE ?= upbound-system

CONTROLPLANE_DUMP_DIRECTORY ?= $(OUTPUT_DIR)/controlplane-dump

controlplane.up: $(UP) $(KUBECTL) $(KIND)
	@$(INFO) setting up controlplane
	@$(KIND) get kubeconfig --name $(KIND_CLUSTER_NAME) >/dev/null 2>&1 || $(KIND) create cluster --name=$(KIND_CLUSTER_NAME)
ifndef CROSSPLANE_ARGS
	@$(INFO) setting up crossplane core without args
	@$(KUBECTL) -n $(CROSSPLANE_NAMESPACE) get cm universal-crossplane-config >/dev/null 2>&1 || $(UP) uxp install $(UXP_VERSION) --namespace=$(CROSSPLANE_NAMESPACE) $(UXP_INSTALL_OPTS)
else
	@$(INFO) setting up crossplane core with args $(CROSSPLANE_ARGS)
	@$(KUBECTL) -n $(CROSSPLANE_NAMESPACE) get cm universal-crossplane-config >/dev/null 2>&1 || $(UP) uxp install $(UXP_VERSION) --namespace=$(CROSSPLANE_NAMESPACE) $(UXP_INSTALL_OPTS) --set "args={${CROSSPLANE_ARGS}}"
endif
controlplane.down: $(UP) $(KUBECTL) $(KIND)
	@$(INFO) deleting controlplane
	@$(KIND) delete cluster --name=$(KIND_CLUSTER_NAME)
	@$(OK) deleting controlplane

controlplane.dump: $(KUBECTL)
	mkdir -p $(CONTROLPLANE_DUMP_DIRECTORY)
	@$(KUBECTL) cluster-info dump --output-directory $(CONTROLPLANE_DUMP_DIRECTORY) --all-namespaces || true
	@$(KUBECTL) get crossplane --all-namespaces > $(CONTROLPLANE_DUMP_DIRECTORY)/all-crossplane.txt || true
	@$(KUBECTL) get crossplane --all-namespaces -o yaml > $(CONTROLPLANE_DUMP_DIRECTORY)/all-crossplane.yaml || true