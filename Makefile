MAKEFLAGS+=--silent
.PHONY: create destroy docker shell tf-fmt build-app push-app

define script
	docker run \
		-it \
		-v $$PWD/scripts:/usr/src/app/scripts\
		-v $$PWD/tf:/usr/src/app/tf \
		-v $$PWD/k8s:/usr/src/app/k8s \
		-v $$PWD/app:/usr/src/app/app \
		-v $$PWD/app.yaml:/usr/src/app/app.yaml \
		-v $$PWD/artillery.yaml:/usr/src/app/artillery.yaml \
		-p 8181:8181 \
		-p 3000:3000 \
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
	$(call script,shell)

tf-fmt:
	docker run -v $$PWD/tf:/tf hashicorp/terraform fmt /tf

build-app:
	faas-cli build -f app.yaml

push-app: build-app
	faas-cli push -f app.yaml
