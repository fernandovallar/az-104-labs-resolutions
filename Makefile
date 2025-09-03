SHELL := /usr/bin/env bash

env:
	@source scripts/load_env.sh && env | grep -E 'AZURE_|PREFIX|LOCATION|LAB_RG_PREFIX|REUSE_SHARED|SHARED_RG' | sort

login:
	@source scripts/load_env.sh && ./scripts/ensure_subscription.sh

validate:
	@source scripts/load_env.sh && [[ -n "$$LAB" ]] || (echo "Set LAB=NN"; exit 1); \
	./scripts/deploy_bicep.sh validate $$LAB

whatif:
	@source scripts/load_env.sh && [[ -n "$$LAB" ]] || (echo "Set LAB=NN"; exit 1); \
	./scripts/deploy_bicep.sh whatif $$LAB

deploy:
	@source scripts/load_env.sh && [[ -n "$$LAB" ]] || (echo "Set LAB=NN"; exit 1); \
	./scripts/deploy_bicep.sh deploy $$LAB

destroy:
	@source scripts/load_env.sh && [[ -n "$$LAB" ]] || (echo "Set LAB=NN"; exit 1); \
	./scripts/delete_rg.sh $$LAB

shared:
	@source scripts/load_env.sh && ./scripts/shared_bootstrap.sh