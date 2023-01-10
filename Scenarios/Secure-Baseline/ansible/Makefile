.DEFAULT_GOAL := help
.PHONY: help virtualenv kind image deploy

VIRTUALENV ?= "./virtualenv/"
ANSIBLE = $(VIRTUALENV)/bin/ansible-playbook

help:
	@echo GLHF

virtualenv:
	LC_ALL=en_US.UTF-8 python3 -m venv $(VIRTUALENV)
	. $(VIRTUALENV)/bin/activate
	$(VIRTUALENV)/bin/pip install pip --upgrade
	LC_ALL=en_US.UTF-8 ./virtualenv/bin/pip3 install -r requirements.txt
	./virtualenv/bin/ansible-galaxy collection install azure.azcollection --force
	./virtualenv/bin/pip3 install -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements-azure.txt
# ./virtualenv/bin/ansible-galaxy collection install community.okd

#podman.image:
#	podman build -t quay.io/pczar/ansible-aro-lz .

#podman.image.push:
#	docker push quay.io/pczar/ansible-aro-lz

#podman.image.pull:
#	docker pull quay.io/pczar/ansible-aro-lz


create:
	$(ANSIBLE) -v create.yml

create.public:
	$(ANSIBLE) -v create.yml -i ./environment/public/hosts

destroy:
	$(ANSIBLE) -v destroy.yml

delete: destroy

#podman.create:
#	podman run --rm \
#		-v $(HOME)/.azure:/home/ansible/.azure:ro \
#	  -ti quay.io/pczar/ansible-aro-lz \
#		$(ANSIBLE) -v create.yml

