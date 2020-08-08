MAKEFLAGS+=--silent
.PHONY: create destroy docker script
.PHONY: tf-fmt tf-apply tf-plan tf-destroy

define script
	docker run \
    		-it \
    		-v $$PWD/scripts:/scripts \
    		-v $$PWD/tf:/tf \
    		-v $$HOME/.oci:/root/.oci \
    		-w /tf \
    		--env-file .envfile \
    		--entrypoint /scripts/$(1).sh \
    		rcoy-v/cloud-native
endef

create: docker
	$(call script,create)

destroy: docker
	$(call script,destroy)

docker:
	docker build -t rcoy-v/cloud-native .

tf-fmt:
	docker run -v $$PWD/tf:/tf hashicorp/terraform fmt /tf

tf-plan: docker
	$(call script,tf-plan)

tf-apply: docker
	$(call script,tf-apply)

tf-destroy: docker
	$(call script,tf-destroy)
