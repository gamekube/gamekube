include Includes.mk

CONTROLLER_GEN_VERSION ?= 0.16.5
HELM_VERSION ?= 3.16.1
HELM_DOCS_VERSION ?= 1.14.2
KUBERNETES_VERSION ?= 1.30.4
KUSTOMIZE_VERSION ?= 5.5.0
MINIKUBE_VERSION ?= 1.34.0
TMPDIR ?= /tmp

fact_arch = $(shell go env GOARCH)
fact_altarch = $(fact_arch)
ifeq ($(fact_altarch),amd64)
	fact_altarch = x86_64
endif
fact_os = $(shell go env GOOS)

path_dot_dev = $(shell pwd)/.dev
path_bin = $(path_dot_dev)/bin
path_kubeconfig = $(path_dot_dev)/kubeconfig.yaml
path_minikube = $(path_dot_dev)/minikube
path_tmp = $(TMPDIR)

bin_url_controller-gen = https://github.com/kubernetes-sigs/controller-tools/releases/download/v$(CONTROLLER_GEN_VERSION)/controller-gen-$(fact_os)-$(fact_arch)
bin_url_helm = https://get.helm.sh/helm-v$(HELM_VERSION)-$(fact_os)-$(fact_arch).tar.gz
bin_url_helm-docs = https://github.com/norwoodj/helm-docs/releases/download/v$(HELM_DOCS_VERSION)/helm-docs_$(HELM_DOCS_VERSION)_$(fact_os)_$(fact_altarch).tar.gz
bin_url_kubectl = https://dl.k8s.io/release/v$(KUBERNETES_VERSION)/bin/$(fact_os)/$(fact_arch)/kubectl
bin_url_kustomize = https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.5.0/kustomize_v5.5.0_linux_arm64.tar.gz
bin_url_minikube = https://github.com/kubernetes/minikube/releases/download/v$(MINIKUBE_VERSION)/minikube-$(fact_os)-$(fact_arch)

.PHONY: default
default:

.PHONY: targets
targets:
	@LC_ALL=C $(MAKE) -pRrq -f $(firstword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/(^|\n)# Files(\n|$$)/,/(^|\n)# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | grep -E -v -e '^[^[:alnum:]]' -e '^$@$$'

.PHONY: clean
clean:
	# remove .dev directory
	rm -rf $(path_dot_dev)

.PHONY: bins
bins:

$(eval $(call bin-target-for-binary,controller-gen))
$(eval $(call bin-target-for-tar-gz-archive,helm,1))
$(eval $(call bin-target-for-tar-gz-archive,helm-docs,0))
$(eval $(call bin-target-for-binary,kubectl))
$(eval $(call bin-target-for-tar-gz-archive,kustomize,0))
$(eval $(call bin-target-for-binary,minikube))

.PHONY: cluster-create
cluster-create: $(path_bin)/minikube $(path_minikube)
	# start minikube cluster
	env KUBECONFIG=$(path_kubeconfig) MINIKUBE_HOME=$(path_minikube) $(path_bin)/minikube start --force --kubernetes-version "v$(KUBERNETES_VERSION)"

.PHONY: cluster-destroy
cluster-destroy: $(path_bin)/minikube
	# remove minikube cluster
	env KUBECONFIG=$(path_kubeconfig) MINIKUBE_HOME=$(path_minikube) $(path_bin)/minikube delete || true
	# delete minikube folder
	rm -rf $(path_minikube)
	# delete kubeconfig
	rm -rf $(path_kubeconfig)

.PHONY: codegen
codegen: codegen-crds codegen-deepcopy codegen-rbac

.PHONY: codegen-crds
codegen-crds: $(path_bin)/controller-gen
	# generate crds
	$(path_bin)/controller-gen crd paths=./... output:stdout > ./charts/gamekube/templates/_crds.yaml

.PHONY: codegen-objects
codegen-objects: $(path_bin)/controller-gen
	# generate objects
	$(path_bin)/controller-gen object paths=./...

.PHONY: codegen-rbac
codegen-rbac: codegen-controller-rbac codegen-server-rbac

.PHONY: codegen-controller-rbac
codegen-controller-rbac: $(path_bin)/controller-gen
	# generate controller rbac
	$(path_bin)/controller-gen rbac:roleName=__roleName__ paths=./internal/controller/... output:stdout > ./charts/gamekube/templates/controller/_rbac.yaml

.PHONY: codegen-server-rbac
codegen-server-rbac: $(path_bin)/controller-gen
	# generate server rbac
	$(path_bin)/controller-gen rbac:roleName=__roleName__ paths=./internal/server/... output:stdout > ./charts/gamekube/templates/server/_rbac.yaml

$(path_bin): $(path_dot_dev)
	# create bin directory
	mkdir -p $(path_bin)

$(path_dot_dev): 
	# create .dev directory
	mkdir -p $(path_dot_dev)

$(path_minikube):  $(path_dot_dev)
	# create minikube directory
	mkdir -p $(path_minikube)

$(path_tmp):
	# create tmp directory
	mkdir -p $(path_tmp)