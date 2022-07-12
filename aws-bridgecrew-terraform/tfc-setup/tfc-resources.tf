resource "tfe_organization" "workshopTFEOrg" {
  name  = var.tfc_org_name
  email = "bridgecrew-workshop@bridgecrew.local"
}


resource "null_resource" "enableTrialFeatures" {
  provisioner "local-exec" {
    command     = "./enable-tfc-trial.sh"
    environment = { ORGID = tfe_organization.workshopTFEOrg.id, TOKEN = var.tfc_token }
  }
}


resource "tfe_oauth_client" "workshopGitHubOauth" {
  name             = "tfe-github-integrate-oauth"
  organization     = tfe_organization.workshopTFEOrg.id
  api_url          = "https://api.github.com"
  http_url         = "https://github.com"
  oauth_token      = var.github_pat
  service_provider = "github"
}


resource "tfe_policy_set" "bridgecrewPolicySet" {
  name          = "bridgecrew-policyset"
  description   = "A brand new policy set"
  organization  = tfe_organization.workshopTFEOrg.id
  #policy_ids    = [tfe_sentinel_policy.bridgecrewPolicy.id]
  policies_path = "/tfc_policies"
  workspace_ids = [tfe_workspace.bridgecrewWorkspace.id]
  vcs_repo {
    identifier         = var.terragoat_fork_name
    branch             = "master"
    ingress_submodules = false
    oauth_token_id     = tfe_oauth_client.workshopGitHubOauth.oauth_token_id
  }
  depends_on = [
    null_resource.enableTrialFeatures
  ]
}

resource "tfe_policy_set_parameter" "bcAPIKey" {
  key           = "BC_API_KEY"
  value         = var.bc_api_key
  policy_set_id = tfe_policy_set.bridgecrewPolicySet.id
  sensitive     = true  
  depends_on = [
    null_resource.enableTrialFeatures
  ]
}

resource "tfe_policy_set_parameter" "tfcWorkspaceID" {
  key           = "TFC_WS_ID"
  value         = tfe_workspace.bridgecrewWorkspace.id
  policy_set_id = tfe_policy_set.bridgecrewPolicySet.id
  sensitive     = true
  depends_on = [
    null_resource.enableTrialFeatures
  ]
}

resource "tfe_workspace" "bridgecrewWorkspace" {
  name         = "bridgecrew-workshop"
  organization = tfe_organization.workshopTFEOrg.id
  vcs_repo {
    identifier         = var.terragoat_fork_name
    branch             = "master"
    ingress_submodules = false
    oauth_token_id     = tfe_oauth_client.workshopGitHubOauth.oauth_token_id
  }
}

resource "tfe_variable" "awsAccessKeyId" {
  key          = "AWS_ACCESS_KEY_ID"
  value        = var.awsAccessKeyId
  category     = "env"
  workspace_id = tfe_workspace.bridgecrewWorkspace.id
  description  = "AWS Access Key"
}

resource "tfe_variable" "awsSecretAccessKey" {
  key          = "AWS_SECRET_ACCESS_KEY"
  value        = var.awsSecretAccessKey
  category     = "env"
  workspace_id = tfe_workspace.bridgecrewWorkspace.id
  description  = "AWS Secret Access Key"
  sensitive     = true
}

resource "tfe_variable" "awsSessionToken" {
  key          = "AWS_SESSION_TOKEN"
  value        = var.awsSessionToken
  category     = "env"
  workspace_id = tfe_workspace.bridgecrewWorkspace.id
  description  = "AWS session token"
  sensitive     = true
}