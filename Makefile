DEV ?= $(shell pwd)/.dev
KUBERNETES_VERSION ?= 1.30.4
MINIKUBE_VERSION ?= 1.34.0

os = $(shell go env GOOS)
arch = $(shell go env GOARCH)

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

# downloads all tools
.PHONY: download-tools
download-tools:

# helper function to create a target to download a binary tool
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

$(eval $(call create-download-tool-from-binary,kubectl))
$(eval $(call create-download-tool-from-binary,minikube))

$(DEV):
	# create dev directory
	mkdir -p $(DEV)
