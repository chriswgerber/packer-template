include artifactory.mk

SRC_DIR=$(shell pwd)
PYTHON=$(shell command -v python)
PACKER=$(shell command -v packer)
CURL:=$(shell command -v curl)
BUILD_DIR=build
PACKER_DIR=packer

CLEAN_DIRS=.bundle build bundle .kitchen

# === Packer
PACKER_MANIFESTS+=$(PACKER_DIR)/base-build-manifest.json
BASE_PACKER_TEMPLATE=$(BUILD_DIR)/base-ami.json

PACKER_TEMPLATES+=$(BASE_PACKER_TEMPLATE)
PACKER_TEMPLATES+=$(ECS_PACKER_TEMPLATE)

USER_DATA_FILE=$(BUILD_DIR)/user_data.sh
$(PACKER_TEMPLATES): $(USER_DATA_FILE)

BUILD_COMMAND=$(PACKER) build -on-error=ask


# === Vagrant + Virtualbox
VAGRANT=$(shell command -v vagrant)
VAGRANT_IMAGE="centos/6"
VIRTUAL_BOX=$(shell command -v VirtualBox)
ifneq ($(VIRTUAL_BOX),)
	VAGRANT_FLAGS=--clean --provider virtualbox
endif


# ===  Test Kitchen
BUNDLER=$(shell command -v bundle)
BUNDLER_EXEC=$(BUNDLER) exec

# Set to version of ruby
BUNDLER_GEM_DIR=bundle/ruby/2.4.0/gems
KITCHEN=$(BUNDLER_EXEC) kitchen
KITCHEN_FLAGS=--concurrency
# --log-level=debug
# --destroy=always
AWS_KITCHEN_FILE=.kitchen.aws.yml


define BUNDLER_INSTALL
	$(BUNDLER) install --standalone
endef


define vendor_inspec
	$(BUNDLER_EXEC) inspec vendor $1 --overwrite
endef


$(BUILD_DIR)/%.json: $(PACKER_DIR)/%.yml $(BUILD_DIR)
	$(PYTHON) -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' < $< > $@


$(PACKER_DIR)/%-build-manifest.json: $(BUILD_DIR)/%-ami.json vendor-inspec
	$(BUILD_COMMAND) $<


Gemfile.lock: $(BUNDLER)
	$(call,BUNDLER_INSTALL)


$(BUNDLER_GEM_DIR): Gemfile Gemfile.lock
	$(call,BUNDLER_INSTALL)


BUILD_DEPS=$(VAGRANT_IMAGE) $(BUNDLER_GEM_DIR) $(PACKER_TEMPLATES)


$(VAGRANT_IMAGE):
ifneq ($(VAGRANT),)
ifeq ($(shell $(VAGRANT) box list | grep $(VAGRANT_IMAGE)),)
	$(VAGRANT) box add $(VAGRANT_FLAGS) $(VAGRANT_IMAGE)
endif
endif

# === Ansible + Artifactory
ROLES_DIR=roles

$(BUILD_DIR)/roles.tgz: $(wildcard roles/**/*.yml) | $(ROLES_BUILD_DIR)
	(cd roles || exit; \
	tar -czvf $(SRC_DIR)/$@ roles/;)

$(artifactory_source_prefix)%.tgz: build/$(ROLES_DIR)/%.tgz;
	$(UPLOAD_ARTIFACTORY)

$(ROLES_BUILD_DIR):
	mkdir -p $@


publish: $(ARTIFACTORY_TARBALLS)


$(USER_DATA_FILE): $(BUILD_DIR)
	echo "#!/bin/bash" > $@
	echo "" >> $@
	echo "export AWS_DEFAULT_REGION=$(AWS_DEFAULT_REGION)" >> $@
	echo "export AWS_CFN_STACKNAME=Test-Kitchen" >> $@
	echo "export AWS_CFN_LAUNCH_CONFIG=Test-Kitchen" >> $@


$(BUILD_DIR):
	mkdir -p $@


.PHONY: develop
develop: $(BUILD_DEPS)
	@echo "Templates: $(PACKER_TEMPLATES)"


.PHONY: build-amis
build-amis: $(PACKER_MANIFESTS) | $(BUILD_DIR)


.PHONY: validate
validate: $(BUILD_DEPS)
	$(PACKER) validate $(BASE_PACKER_TEMPLATE)
	$(PACKER) validate $(ECS_PACKER_TEMPLATE)


.PHONY: vendor-inspec
vendor-inspec: $(BUNDLER_GEM_DIR)
	$(call vendor_inspec,test/integration/default)


.PHONY: test
test: $(BUILD_DEPS)
	$(KITCHEN) test $(KITCHEN_FLAGS)


.PHONY: test-aws
test-aws: export KITCHEN_LOCAL_YAML=$(AWS_KITCHEN_FILE)
test-aws: $(BUILD_DEPS)
	$(KITCHEN) test $(KITCHEN_FLAGS)


.PHONY: clean
clean:
	rm -rf $(CLEAN_DIRS)
	$(KITCHEN) destroy $(KITCHEN_FLAGS)
	( \
		KITCHEN_LOCAL_YAML=$(AWS_KITCHEN_FILE); \
		$(KITCHEN) destroy $(KITCHEN_FLAGS); \
	)
