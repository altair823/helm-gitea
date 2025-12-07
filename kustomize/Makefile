.PHONY: render-base render-dev render-prod clean

CHART_DIR := $(shell pwd)/..
BASE_DIR := base
DEV_DIR := overlays/dev
PROD_DIR := overlays/prod

render-base:
	@echo "Rendering base Helm templates..."
	helm template gitea $(CHART_DIR) \
		--values $(BASE_DIR)/values-base.yaml \
		--namespace gitea \
		--release-name gitea \
		> $(BASE_DIR)/rendered-manifests.yaml
	@echo "Base templates rendered to $(BASE_DIR)/rendered-manifests.yaml"

render-dev: render-base
	@echo "Rendering dev Helm templates..."
	helm template gitea $(CHART_DIR) \
		--values $(DEV_DIR)/values-dev.yaml \
		--namespace gitea-dev \
		--release-name gitea \
		> $(DEV_DIR)/rendered-manifests.yaml
	@echo "Dev templates rendered to $(DEV_DIR)/rendered-manifests.yaml"

render-prod: render-base
	@echo "Rendering prod Helm templates..."
	helm template gitea $(CHART_DIR) \
		--values $(PROD_DIR)/values-prod.yaml \
		--namespace gitea-prod \
		--release-name gitea \
		> $(PROD_DIR)/rendered-manifests.yaml
	@echo "Prod templates rendered to $(PROD_DIR)/rendered-manifests.yaml"

render-all: render-dev render-prod

clean:
	@echo "Cleaning rendered manifests..."
	rm -f $(BASE_DIR)/rendered-manifests.yaml
	rm -f $(DEV_DIR)/rendered-manifests.yaml
	rm -f $(PROD_DIR)/rendered-manifests.yaml
	@echo "Clean complete"

