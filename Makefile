default: venv
	./venv/bin/ansible-playbook playbook.yml

test: venv
	./venv/bin/ansible-playbook playbook.yml --check --diff

raspberry: venv
	./venv/bin/ansible-playbook playbook.yml -l raspberry

fedora: venv
	./venv/bin/ansible-playbook playbook.yml -l fedora

venv:
	virtualenv venv -p python3.9
	./venv/bin/pip install -r requirements.txt

decrypt:
	ansible-vault decrypt group_vars/*
	ansible-vault decrypt inventory.yml

encrypt:
	ansible-vault encrypt group_vars/*
	ansible-vault encrypt inventory.yml
