default: venv
	poetry run ansible-playbook playbook.yml

test: venv
	poetry run ansible-playbook playbook.yml --check --diff

raspberry: venv
	poetry run ansible-playbook playbook.yml -l raspberry

fedora: venv
	poetry run ansible-playbook playbook.yml -l fedora

venv:
	poetry install

decrypt:
	poetry run ansible-vault decrypt group_vars/*
	poetry run ansible-vault decrypt inventory.yml

encrypt:
	poetry run ansible-vault encrypt group_vars/*
	poetry run ansible-vault encrypt inventory.yml
