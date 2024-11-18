include Includes.mk

CONTROLLER_GEN_VERSION ?= 0.16.5
HELM_VERSION ?= 3.16.1
KUBERNETES_VERSION ?= 1.30.4
KUSTOMIZE_VERSION ?= 5.5.0
MINIKUBE_VERSION ?= 1.34.0

dot_dev = $(shell pwd)/.dev
dev = $(shell pwd)/dev
os = $(shell go env GOOS)
arch = $(shell go env GOARCH)

controller_gen = $(dot_dev)/controller-gen
controller_gen_url = https://github.com/kubernetes-sigs/controller-tools/releases/download/v$(CONTROLLER_GEN_VERSION)/controller-gen-$(os)-$(arch)
helm = $(dot_dev)/helm
helm_url = https://get.helm.sh/helm-v$(HELM_VERSION)-$(os)-$(arch).tar.gz
kubectl = $(dot_dev)/kubectl
kubectl_url = https://dl.k8s.io/release/v$(KUBERNETES_VERSION)/bin/$(os)/$(arch)/kubectl
kustomize = $(dot_dev)/kustomize
kustomize_build = $(kustomize) build --enable-helm --load-restrictor=LoadRestrictionsNone
kustomize_url = https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.5.0/kustomize_v5.5.0_linux_arm64.tar.gz
minikube = $(dot_dev)/minikube
minikube_url = https://github.com/kubernetes/minikube/releases/download/v$(MINIKUBE_VERSION)/minikube-$(os)-$(arch)

.PHONY: default
default:

.PHONY: clean
clean: delete-minikube-cluster
	# delete dev directory
	rm -rf $(dot_dev)

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

$(eval $(call create-download-tool-from-binary,controller_gen))
$(eval $(call create-download-tool-from-binary,kubectl))
$(eval $(call create-download-tool-from-archive,kustomize,0))
$(eval $(call create-download-tool-from-binary,minikube))
$(eval $(call create-download-tool-from-archive,helm,1))

.PHONY: create-minikube-cluster
create-minikube-cluster: $(helm) $(kubectl) $(kustomize) $(minikube)
	# create minikube cluster
	$(minikube) start --force --kubernetes-version=$(KUBERNETES_VERSION)
	# apply keycloak manifest
	$(kustomize_build) $(dev)/manifests/keycloak | $(kubectl) apply -f -

.PHONY: delete-minikube-cluster
delete-minikube-cluster: $(minikube)
	# delete minikube cluster
	$(minikube) delete || true

$(dot_dev):
	# create .dev directory
	mkdir -p $(dot_dev)
