#Requires -Version 7.0 -RunAsAdministrator
#------------------------------------------------------------------------------
# FILE:         action.ps1
# CONTRIBUTOR:  Jeff Lill
# COPYRIGHT:    Copyright (c) 2005-2021 by neonFORGE LLC.  All rights reserved.
#
# The contents of this repository are for private use by neonFORGE, LLC. and may not be
# divulged or used for any purpose by other organizations or individuals without a
# formal written and signed agreement with neonFORGE, LLC.

# Verify that we're running on a properly configured neonFORGE GitHub runner 
# and import the deployment and action scripts from neonCLOUD.

# NOTE: This assumes that the required [$NC_ROOT/Powershell/*.ps1] files
#       in the current clone of the repo on the runner are up-to-date
#       enough to be able to obtain secrets and use GitHub Action functions.
#       If this is not the case, you'll have to manually pull the repo 
#       first on the runner.

$ncRoot = $env:NC_ROOT

if ([System.String]::IsNullOrEmpty($ncRoot) -or ![System.IO.Directory]::Exists($ncRoot))
{
    throw "Runner Config: neonCLOUD repo is not present."
}

$ncPowershell = [System.IO.Path]::Combine($ncRoot, "Powershell")

Push-Location $ncPowershell | Out-Null
. ./includes.ps1
Pop-Location | Out-Null

# Fetch the inputs

$accounts = Get-ActionInput "accounts" $true

try
{
    # [accounts] should be passed with one or more comma separated logins formatted like  
    # 
    #       SERVER:CREDENTIAL
    #
    # where:
    #
    #       SERVER      - specifies the registry (typically docker.io or ghcr.io)
    #       CREDENTIAL  - specifies the name of the 1Password login (typically DOCKER_LOGIN or GITHUB_PAT)

    $accounts = $accounts.Split(",")

    ForEach (var $account in $accounts)
    {
        $account = $account.Trim();
        $fields  = $account.Split(":", 2)

        if ($fields.Length -ne 2)
        {
            Write-ActionWarning $"Invalid login: $account"
            Continue
        }

        Login-Docker $fields[0].Trim() $fields[1].Trim()
    }
}
catch
{
    Write-ActionException $_
    exit 1
}
