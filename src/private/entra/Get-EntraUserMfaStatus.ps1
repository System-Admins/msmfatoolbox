function Get-EntraUserMfaStatus
{
    <#
    .SYNOPSIS
        Get the MFA user(s) status from Microsoft Entra.
    .DESCRIPTION
        Retrieve if the user(s) is protected by MFA.
    .PARAMETER UserPrincipalName
        (Optional) The Entra user principal name.
    .EXAMPLE
        Get-EntraUserMfaStatus;
    #>
    [cmdletbinding()]
    [OutputType([pscustomobject[]])]
    param
    (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$UserPrincipalName
    )

    BEGIN
    {
        # Write to log.
        $customProgress = Write-CustomProgress -Activity $MyInvocation.MyCommand.Name -CurrentOperation 'Get Entra user(s) MFA status';

        # If user principal name is null.
        if ([string]::IsNullOrEmpty($UserPrincipalName))
        {
            # Get all users.
            $entraUsers = Get-EntraUser -All;

            # Get all MFA user states.
            $mfaStates = Get-EntraUserMfaState;
        }
        else
        {
            # Get all users.
            $entraUsers = Get-EntraUser | Where-Object { $_.UserPrincipalName -eq $UserPrincipalName };

            # Get all MFA user states.
            $mfaStates = Get-EntraUserMfaState -Id $entraUsers.Id;
        }

        # Get all Entra conditional access policy members.
        $conditionalAccessPolicyMembers = Get-EntraConditionalAccessPolicyMember;

        # Get all Entra conditional access policies that require MFA.
        $conditionalAccessMfaPolicies = Get-EntraConditionalAccessPolicyMfa;

        # Get all Entra applications.
        $entraApplications = Get-EntraApplication -All;

        # Result object.
        $users = @();
    }
    PROCESS
    {
        # Write to log.
        Write-CustomLog -Message ('Found {0} Entra users' -f $entraUsers.Count) -Level 'Verbose';

        # Foreach Entra user.
        foreach ($entraUser in $entraUsers)
        {
            # Add user to result.
            $user = [PSCustomObject]@{
                UserPrincipalName       = $entraUser.UserPrincipalName;
                DisplayName             = $entraUser.DisplayName;
                AccountEnabled          = $entraUser.accountEnabled;
                AccountType             = $entraUser.userType;
                FullMfa                 = $false;
                PartialMfa              = $false;
                ConditionalAccessPolicy = @();
                PerUserMfaState         = '';
                IsMfaCapable            = $false;
                IsMfaRegistered         = $false;
                IsAdmin                 = $false;
                Apps                    = @();
                TargetAllApps           = $false;
            };

            # User conditional access policies.
            $userConditionalAccessPolicies = @();

            # User conditional access policies that require MFA.
            $userConditionalAccessMfaPolicies = @();

            # User MFA state.
            $userMfaState = $null;

            # Foreach conditional access policies that the user is a member of.
            foreach ($conditionalAccessPolicyMember in $conditionalAccessPolicyMembers)
            {
                # If the user is a member of the conditional access policy.
                if ($entraUser.UserPrincipalName -in $conditionalAccessPolicyMember.TargetedUsers)
                {
                    # Add conditional access policy.
                    $userConditionalAccessPolicies += $conditionalAccessPolicyMember;
                }
            }

            # Foreach user conditional access.
            foreach ($userConditionalAccessPolicy in $userConditionalAccessPolicies)
            {
                # Foreach conditional access policies that require MFA.
                foreach ($conditionalAccessMfaPolicy in $conditionalAccessMfaPolicies)
                {
                    # If the two conditional access policies are not the same.
                    if ($userConditionalAccessPolicy.Id -ne $conditionalAccessMfaPolicy.Id)
                    {
                        # Continue to next policy that require MFA.
                        continue;
                    }

                    # Add conditional access policy.
                    $userConditionalAccessMfaPolicies += $conditionalAccessMfaPolicy;
                }
            }

            # Foreach MFA user state.
            foreach ($mfaState in $mfaStates)
            {
                # If the user is protected by MFA.
                if ($entraUser.UserPrincipalName -eq $mfaState.UserPrincipalName)
                {
                    # Set user MFA state.
                    $userMfaState = $mfaState;
                }
            }

            # Set MFA state.
            if ($null -ne $userMfaState)
            {
                # Set properties.
                $user.PerUserMfaState = $userMfaState.PerUserMfaState;
                $user.IsMfaCapable = $userMfaState.IsMfaCapable;
                $user.IsMfaRegistered = $userMfaState.IsMfaRegistered;
                $user.IsAdmin = $userMfaState.IsAdmin;
            }

            # Foreach user conditional access policies that require MFA.
            foreach ($userConditionalAccessMfaPolicy in $userConditionalAccessMfaPolicies)
            {
                # If the policy is not enabled.
                if ($userConditionalAccessMfaPolicy.State -eq 'disabled')
                {
                    # Continue to next policy that require MFA.
                    continue;
                }

                # Add conditional access policy.
                $user.ConditionalAccessPolicy += $userConditionalAccessMfaPolicy.Name;

                # If all apps are targeted.
                if ($true -eq $userConditionalAccessMfaPolicy.AllApps)
                {
                    # Set target all apps.
                    $user.TargetAllApps = $true;
                }

                # Foreach app.
                foreach ($app in $userConditionalAccessMfaPolicy.Apps)
                {
                    # If the app is a GUID.
                    if ($true -eq (Test-Guid -InputObject $app))
                    {
                        # Get application by id.
                        $application = $entraApplications | Where-Object { $_.AppId -eq $app };

                        # Add app.
                        $user.Apps += $application.DisplayName;
                    }
                    # Else built-in app.
                    else
                    {
                        # Add app.
                        $user.Apps += $app;
                    }
                }

                # If MFA or AuthenticationStrength is required.
                if ($true -eq $userConditionalAccessMfaPolicy.MFA -or
                    $true -eq $userConditionalAccessMfaPolicy.AuthenticationStrength)
                {
                    # Set user conditional access require MFA.
                    $user.PartialMfa = $true;
                }

                # If policy requires MFA and is target all apps.
                if (($true -eq $userConditionalAccessMfaPolicy.MFA -or
                        $true -eq $userConditionalAccessMfaPolicy.AuthenticationStrength) -and
                    $true -eq $userConditionalAccessMfaPolicy.AllApps)
                {
                    # Set user conditional access require MFA.
                    $user.FullMfa = $true;
                }
            }

            # Remove target apps duplicates.
            $user.Apps = $user.Apps | Select-Object -Unique;



            # If the user is not protected by MFA.
            if ($false -eq $user.FullMfa)
            {
                # Write to log.
                Write-CustomLog -Message ("User '{0}'' is not protected by MFA in all apps" -f $user.UserPrincipalName) -Level 'Verbose';
            }

            # Add user to result.
            $users += $user;
        }
    }
    END
    {
        # Write to log.
        Write-CustomProgress @customProgress;

        # Return result.
        return $users;
    }
}