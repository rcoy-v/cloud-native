MAKEFLAGS+=--silent
.PHONY: create destroy scripts tf-fmt

create: scripts
	docker run \
		-it \
		-v $$PWD/scripts:/scripts \
		-v $$PWD/tf:/tf \
		-p 8181:8181 \
		--env-file .envfile \
		--entrypoint /scripts/create.sh \
		rcoy-v/cloud-native

destroy: scripts
	docker run \
		-it \
		-v $$PWD/scripts:/scripts \
		-v $$PWD/tf:/tf \
		-p 8181:8181 \
		--env-file .envfile \
		--entrypoint /scripts/destroy.sh \
		rcoy-v/cloud-native

scripts:
	docker build -t rcoy-v/cloud-native .

tf-fmt:
	docker run -v $$PWD/tf:/tf hashicorp/terraform fmt /tf
