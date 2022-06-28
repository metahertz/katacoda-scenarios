#!/usr/bin/bash

curl -v "https://app.terraform.io/api/v2/organizations/${ORGID}/subscription" \
-X POST \
-H 'Host: app.terraform.io' \
-H "Authorization: Bearer ${TOKEN}" \
-H 'Connection: keep-alive' \
-H 'Accept: application/vnd.api+json' \
-H 'content-type: application/vnd.api+json' \
-d '{"data":{"attributes":{"contract-apply-limit":null,"contract-start-at":null,"contract-user-limit":null,"hcp-organization-id":null,"is-active":true,"start-at":null,"end-at":null,"stripe-token":null,"is-public-free-tier":false,"is-self-serve-trial":false,"runs-ceiling":1,"agents-ceiling":null},"relationships":{"organization":{"data":{"type":"organizations","id":"${ORGID}"}},"feature-set":{"data":{"type":"feature-sets","id":"fs-KAgUuYHgT6E2JyEy"}}},"type":"subscriptions"}}'