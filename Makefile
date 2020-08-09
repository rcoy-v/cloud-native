MAKEFLAGS+=--silent
.PHONY: create destroy docker shell tf-fmt

define script
	docker run \
		-it \
		-v $$PWD/scripts:/usr/src/app/scripts\
		-v $$PWD/tf:/usr/src/app/tf \
		-v $$PWD/k8s:/usr/src/app/k8s \
		-v $$PWD/app:/usr/src/app/app \
		-v $$PWD/app.yaml:/usr/src/app/app.yaml \
		-p 8181:8181 \
		--env-file .envfile \
		--entrypoint /usr/src/app/scripts/$(1).sh \
		rcoy-v/cloud-native-scripts
endef

create: docker
	$(call script,create)

destroy: docker
	$(call script,destroy)

docker:
	docker build -t rcoy-v/cloud-native-scripts scripts

shell: docker
	docker run \
		-it \
		-v $$PWD/scripts:/usr/src/app/scripts\
		-v $$PWD/tf:/usr/src/app/tf \
		-v $$PWD/k8s:/usr/src/app/k8s \
		-v $$PWD/app:/usr/src/app/app \
		-v $$PWD/app.yaml:/usr/src/app/app.yaml \
		-p 8181:8181 \
		--env-file .envfile \
		--entrypoint bash \
		rcoy-v/cloud-native-scripts

tf-fmt:
	docker run -v $$PWD/tf:/tf hashicorp/terraform fmt /tf
