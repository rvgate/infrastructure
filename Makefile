default: venv
	./venv/bin/ansible-playbook playbook.yml

venv:
	virtualenv venv -p python3.6
	./venv/bin/pip install -r requirements.txt
