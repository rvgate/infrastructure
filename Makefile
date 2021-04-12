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
	ansible-vault decrypt inventory/group_vars/all.yml
	ansible-vault decrypt inventory/hosts
	ansible-vault decrypt roles/base/files/aws-credentials.ini
	ansible-vault decrypt roles/cicd/defaults/main.yml
	ansible-vault decrypt roles/pihole/defaults/main.yml

encrypt:
	ansible-vault encrypt inventory/group_vars/all.yml
	ansible-vault encrypt inventory/hosts
	ansible-vault encrypt roles/base/files/aws-credentials.ini
	ansible-vault encrypt roles/cicd/defaults/main.yml
	ansible-vault encrypt roles/pihole/defaults/main.yml
