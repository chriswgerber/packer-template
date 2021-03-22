# === Manage uploading to Artifactory

artifactory_user=$(ORG_GRADLE_PROJECT_artifactoryUsername)
artifactory_password=$(ORG_GRADLE_PROJECT_artifactoryPassword)

artifactory_host=
artifactory_repo=

artifactory_project_prefix=/ansible/roles

artifactory_source_prefix=artifactory//

VERSION?=

just_role_name=$(subst $(artifactory_source_prefix),,$(subst .tgz,,$@))

ifneq ($(VERSION),)
remove_art_prefix=$(addprefix $(VERSION)/,$(subst $(artifactory_source_prefix),,$@))
else
remove_art_prefix=$(subst $(artifactory_source_prefix),,$@)
endif

define UPLOAD_ARTIFACTORY
$(CURL) \
	-X PUT \
	-u $(artifactory_user):$(artifactory_password) \
	-T $^ \
	"$(artifactory_host)/$(artifactory_repo)$(artifactory_project_prefix)/$(just_role_name)/$(remove_art_prefix)"
endef
