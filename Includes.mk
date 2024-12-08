define bin-target-for-binary

bins: bin-$(1)

.PHONY: bin-$(1)
bin-$(1): $(path_bin)/$(1)

$(path_bin)/$(1): $(path_bin)
	# download $(1)
	curl -o $(path_bin)/$(1) -fsSL $(bin_url_$(1))
	# make $(1) executable
	chmod +x $(path_bin)/$(1)

endef

define bin-target-for-tar-gz-archive

bins: bin-$(1)

.PHONY: bin-$(1)
bin-$(1): $(path_bin)/$(1)

$(path_bin)/$(1): $(path_bin) $(path_tmp)
	# clean extract directory
	rm -rf $(path_tmp)/extract $(path_tmp)/archive.tar.gz && mkdir -p $(path_tmp)/extract
	# download $(1) archive
	curl -o $(path_tmp)/archive.tar.gz -fsSL $(bin_url_$(1))
	# extract $(1)
	tar xvzf $(path_tmp)/archive.tar.gz --strip-components $(2) -C $(path_tmp)/extract
	# move $(1)
	mv $(path_tmp)/extract/$(1) $(path_bin)/$(1)
	# clean extract directory
	rm -rf $(path_tmp)/extract $(path_tmp)/archive.tar.gz

endef
