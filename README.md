# AZ-104 Labs via Bicep/CLI

- Lab01 uses Bash + az CLI (Entra ID identities).
- Lab02–Lab14 use Bicep (+ az deployment).
- Default is **isolated** per-lab resource groups: `${LAB_RG_PREFIX}-NN`.
- To reuse shared resources across labs, set `REUSE_SHARED=1` and run `make shared`.

## Quickstart
1. `cp .env.example .env` and edit values.
2. `make env login`
3. For isolated run: `make deploy LAB=04`
4. For shared baseline: `make shared` then `make deploy LAB=06`
5. Cleanup a lab: `make destroy LAB=04`


# AZ-104 Labs via Bicep/CLI
This repository is my personal **AZ-104 (Microsoft Azure Administrator)** practice environment.  
Instead of doing the labs through the Azure Portal, I’m implementing them with **Infrastructure as Code**:

- **Lab 01** → shell script with `az` CLI (Entra ID identities).
- **Lab 02 – Lab 14** → Bicep templates (deployed with `az deployment group create`).

Each lab will live in its own folder (`labs/labNN/`) and include a local `README.md` with instructions and run examples.

---

## Scripts Overview

Located in [`scripts/`](./scripts):

- **`load_env.sh`**  
  Loads environment variables from `.env` (subscription, location, naming prefix, etc.) so every script and template uses consistent settings.

- **`ensure_subscription.sh`**  
  Ensures you’re logged in with `az login` and sets the active subscription from `$AZURE_SUBSCRIPTION_ID`.

- **`ensure_rg.sh`**  
  Creates a resource group for a given lab (e.g., `az104-lab04`) if it doesn’t exist, tagged with the lab number and owner prefix.

- **`deploy_bicep.sh`**  
  Wrapper around `az deployment group` that supports three modes:  
  - `validate` → syntax/parameter check  
  - `whatif` → preview resource changes  
  - `deploy` → actually deploys the lab’s `main.bicep`

- **`delete_rg.sh`**  
  Deletes the resource group for a given lab (`make destroy LAB=04`). Useful for cleanup between runs.

- **`shared_bootstrap.sh`**  
  Optional: if `$REUSE_SHARED=1`, creates a shared baseline resource group (e.g., Log Analytics workspace, diagnostics). Lets multiple labs reuse common infra.

---
