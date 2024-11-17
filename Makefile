DEV ?= $(shell pwd)/.dev
CONTROLLER_GEN_VERSION ?= 0.16.5
HELM_VERSION ?= 3.16.1
KUBERNETES_VERSION ?= 1.30.4
MINIKUBE_VERSION ?= 1.34.0

os = $(shell go env GOOS)
arch = $(shell go env GOARCH)

controller_gen = $(DEV)/controller-gen
controller_gen_url = https://github.com/kubernetes-sigs/controller-tools/releases/download/v$(CONTROLLER_GEN_VERSION)/controller-gen-$(os)-$(arch)
helm = $(DEV)/helm
helm_url = https://get.helm.sh/helm-v$(HELM_VERSION)-$(os)-$(arch).tar.gz
kubectl = $(DEV)/kubectl
kubectl_url = https://dl.k8s.io/release/v$(KUBERNETES_VERSION)/bin/$(os)/$(arch)/kubectl
minikube = $(DEV)/minikube
minikube_url = https://github.com/kubernetes/minikube/releases/download/v$(MINIKUBE_VERSION)/minikube-$(os)-$(arch)

.PHONY: default
default:

.PHONY: clean
clean:
	# delete dev directory
	rm -rf $(DEV)

.PHONY: generate-controller-rbac
generate-controller-rbac: $(controller_gen)
	# generate controller rbac
	$(controller_gen) rbac:roleName=__rolename__ paths=./internal/controller/... output:stdout > ./charts/gamekube/templates/controller/_rbac.yaml

.PHONY: generate-crds
generate-crds: $(controller_gen)
	# generate crds manifest
	$(controller_gen) crd paths=./... output:stdout > ./charts/gamekube/templates/_crds.yaml

.PHONY: generate-deepcopy
generate-deepcopy: $(controller_gen)
	# generate deepcopy
	$(controller_gen) object paths=./pkg/api/gamekube.dev/v1

.PHONY: generate-server-rbac
generate-server-rbac: $(controller_gen)
	# generate server rbac
	$(controller_gen) rbac:roleName=__rolename__ paths=./internal/server/... output:stdout > ./charts/gamekube/templates/server/_rbac.yaml

.PHONY: download-tools
download-tools:

define create-download-tool-from-binary
download-tools: download-$(1)
.PHONY: download-$(1)
download-$(1): $$($(1))
$$($(1)): | $$(DEV)
	# download $(1)
	curl -o $$($(1)) -fsSL $$($(1)_url)
	# make $(1) executable
	chmod +x $$($(1))
endef

define create-download-tool-from-archive
download-tools: download-$(1)
.PHONY: download-$(1)
download-$(1): $$($(1))
$$($(1)): | $$(DEV)
	# clean extract directory
	rm -rf $$(DEV)/.tmp
	# create extract directory
	mkdir -p $$(DEV)/.tmp
	# download $(1) archive
	curl -o $$(DEV)/.tmp/archive.tar.gz -fsSL $$($(1)_url)
	# extract $(1)
	tar xvzf $$(DEV)/.tmp/archive.tar.gz --strip-components $(2) -C $$(DEV)/.tmp
	# move $(1)
	mv $$(DEV)/.tmp/$(1) $$($(1))
	# clean extract directory
	rm -rf $$(DEV)/.tmp
endef

$(eval $(call create-download-tool-from-binary,controller_gen))
$(eval $(call create-download-tool-from-binary,kubectl))
$(eval $(call create-download-tool-from-binary,minikube))
$(eval $(call create-download-tool-from-archive,helm,1))

$(DEV):
	# create dev directory
	mkdir -p $(DEV)
