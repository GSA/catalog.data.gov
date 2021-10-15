
# Output documentation for top-level targets
# Thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help
help: ## This help
	@echo With the exception of \"madness\", these targets are expected to be invoked within a cflinuxfs3 container:
	@echo "    $$ docker run -v \`pwd\`:\`pwd\` -w \`pwd\` -e HOME=\`pwd\`  -e TERM -it --rm cloudfoundry/cflinuxfs3:latest bash"
	@echo "    # make <target>"
	@echo
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

all: prep install test  ## Prepare the build environment, build the package, install it, and test the result

prep: ## Prep the environment for building .deb packages
	apt update
	apt-get install equivs -y

clean: ## Uninstall the package and remove any built or intermediate files
	@-dpkg -r cflinuxfs3-fhs-fixup
	@-rm -f cflinuxfs3-fhs-fixup*.deb
	@-rm -fr /usr/share/man/*

cflinuxfs3-fhs-fixup_1.0_all.deb: cflinuxfs3-fhs-fixup.ctl ## Build the .deb package
	equivs-build cflinuxfs3-fhs-fixup.ctl

install: cflinuxfs3-fhs-fixup_1.0_all.deb  ## Install the built .deb package
	dpkg -i cflinuxfs3-fhs-fixup_1.0_all.deb

test:  ## Test whether missing directories have been recreated
	@if [ "$(shell find /usr/share/man | wc -l)" -gt "1" ]; then echo "test: success!"; fi;
	@if [ "$(shell find /usr/share/man | wc -l)" -le "1" ]; then echo "test: failure!"; fi;

madness: ## Same as `all`, but invoked outside of a cflinuxfs3 container
	docker run -v `pwd`:`pwd` -w `pwd` -e HOME=`pwd`  -e TERM -it --rm cloudfoundry/cflinuxfs3:latest make all

