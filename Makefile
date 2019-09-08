default: venv
	./venv/bin/ansible-playbook playbook.yml

test: venv
	./venv/bin/ansible-playbook playbook.yml --check --diff

raspberry: venv
	./venv/bin/ansible-playbook playbook.yml -l raspberry

fedora: venv
	./venv/bin/ansible-playbook playbook.yml -l fedora

venv:
	virtualenv venv -p python3.6
	./venv/bin/pip install -r requirements.txt
