SHELL := /bin/bash

.PHONY: all
all: lambda

.PHONY: requirements
requirements: requirements-to-freeze.txt
	@python3 -c 'print("Updating requirements.txt...")'
	@docker run --rm -v $$(pwd):/usr/src/app/ python:3.8 /bin/bash -c "python -m pip install --upgrade pip && pip install -r /usr/src/app/requirements-to-freeze.txt && pip freeze > /usr/src/app/requirements.txt"

.PHONY: clean-python
clean-python:
	@# Prepending each recipe with - to continue regardless of errors per
	@# https://www.gnu.org/software/make/manual/html_node/Errors.html
	@-find . -type d -name '__pycache__' -exec rm -rf {} +
	@-find . -type d -name '.mypy_cache' -exec rm -rf {} +
	@-find . -type d -name '.pytest_cache' -exec rm -rf {} +
	@-find . -type f -name '*.pyc' -delete

.PHONY: clean
clean: clean-python

.PHONY: lambda
lambda: clean
	@docker run --rm -v $$(pwd):/usr/src/app/ python:3.8 /bin/bash -c "cd /usr/src/app/ && apt-get update && apt-get -y --no-install-recommends install zip && python -m pip install --upgrade pip && zip function.zip lambda_function.py && pip install --target ./package -r requirements.txt && cd package && zip -r9 ../function.zip ."

.PHONY: deploy
deploy: lambda
	@docker run --rm --env-file <(env | grep AWS_) -v $$(pwd):/usr/src/app/ -v $${HOME}/.aws:/root/.aws seiso/easy_infra:latest-terraform-aws aws lambda update-function-code --function-name release_monitor --zip-file fileb:///usr/src/app/function.zip
