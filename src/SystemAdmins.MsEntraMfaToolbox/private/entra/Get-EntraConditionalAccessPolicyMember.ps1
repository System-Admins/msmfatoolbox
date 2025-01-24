function Get-EntraConditionalAccessPolicyMember
{
    <#
    .SYNOPSIS
        Get Entra conditional access user assignments.
    .DESCRIPTION
        Go through each conditional access policy and get members (recursively) from roles, exclude and include assignments.
    .EXAMPLE
         Get-EntraConditionalAccessPolicyMember;
    #>
    [cmdletbinding()]
    [OutputType([pscustomobject[]])]
    param
    (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Guid -InputObject $_ })]
        [string]$Id
    )

    BEGIN
    {
        # Write to log.
        $customProgress = Write-CustomProgress -Activity $MyInvocation.MyCommand.Name -CurrentOperation 'Get Entra conditional access report';

        # If Id is not null.
        if (-not [string]::IsNullOrEmpty($Id))
        {
            # Get conditional access policy.
            $conditionalAccessPolicies = Get-EntraConditionalAccessPolicy -PolicyId $Id -ErrorAction SilentlyContinue;
        }
        else
        {
            # Get conditional access policies.
            $conditionalAccessPolicies = Get-EntraConditionalAccessPolicy;
        }

        # Result object.
        $policies = @();

        # Get all users.
        $entraUsers = Get-EntraUser -All;
    }
    PROCESS
    {
        # Write to log.
        Write-CustomLog -Message ('Found {0} conditional access policies' -f $conditionalAccessPolicies.Count) -Level 'Verbose';

        # Foreach conditional access policy.
        foreach ($conditionalAccessPolicy in $conditionalAccessPolicies)
        {
            # Object to store the policy.
            $policy = [PSCustomObject]@{
                Id            = $conditionalAccessPolicy.Id;
                Name          = $conditionalAccessPolicy.DisplayName;
                State         = $conditionalAccessPolicy.State;
                ExcludedUsers = @();
                ExcludeAll    = $false;
                IncludedUsers = @();
                IncludeAll    = $false;
                TargetedUsers = @();
            };

            # Get all exclusion groups.
            $excludeGroups = $conditionalAccessPolicy.Conditions.Users.ExcludeGroups;

            # If exclude groups is not empty.
            if ($excludeGroups.Count -gt 0)
            {
                # Foreach exclude group.
                foreach ($excludeGroupId in $excludeGroups)
                {
                    # Get all users in the group.
                    $policy.ExcludedUsers += Get-EntraGroupMemberRecursive -Id $excludeGroupId;
                }
            }

            # Get all inclusion groups.
            $includeGroups = $conditionalAccessPolicy.Conditions.Users.IncludeGroups;

            # If include groups is not empty.
            if ($includeGroups.Count -gt 0)
            {
                # Foreach include group.
                foreach ($includeGroupId in $includeGroups)
                {
                    # Get all users in the group.
                    $policy.IncludedUsers += Get-EntraGroupMemberRecursive -Id $includeGroupId;
                }
            }

            # Get exclude users.
            $excludeUsers = $conditionalAccessPolicy.Conditions.Users.ExcludeUsers;

            # If exclude users states to include all.
            if ($excludeUsers -contains 'All')
            {
                # Get all users.
                $policy.ExcludedUsers = ($entraUsers).UserPrincipalName;

                # Set include all to true.
                $policy.ExcludeAll = $true;
            }
            # Otherwise goe through all exclude users.
            elseif ($excludeUsers.Count -gt 0)
            {
                # Foreach exclude user.
                foreach ($excludeUser in $excludeUsers)
                {
                    # Get user.
                    $user = $entraUsers | Where-Object { $_.Id -eq $excludeUser };

                    # If user is not null.
                    if ($null -ne $user)
                    {
                        # Add to include users.
                        $policy.ExcludedUsers += $user.UserPrincipalName;
                    }
                }
            }

            # Get include users.
            $includeUsers = $conditionalAccessPolicy.Conditions.Users.IncludeUsers;

            # If include users states to include all.
            if ($includeUsers -contains 'All')
            {
                # Get all users.
                $policy.IncludedUsers = ($entraUsers).UserPrincipalName;

                # Set include all to true.
                $policy.IncludeAll = $true;
            }
            # Otherwise go through all include users.
            elseif ($includeUsers.Count -gt 0)
            {
                # Foreach include user.
                foreach ($includeUser in $includeUsers)
                {
                    # Get user.
                    $user = $entraUsers | Where-Object { $_.Id -eq $includeUser };

                    # If user is not null.
                    if ($null -ne $user)
                    {
                        # Add to include users.
                        $policy.IncludedUsers += $user.UserPrincipalName;
                    }
                }
            }

            # Get all excluded roles.
            $excludeRoles = $conditionalAccessPolicy.Conditions.Users.ExcludeRoles;

            # If exclude roles is not empty.
            if ($excludeRoles.Count -gt 0)
            {
                # Foreach exclude role.
                foreach ($excludeRole in $excludeRoles)
                {
                    # Get all users in the role.
                    $policy.ExcludedUsers += (Get-EntraRoleMemberRecursive -Id $excludeRole).Members;
                }
            }

            # Get all included roles.
            $includeRoles = $conditionalAccessPolicy.Conditions.Users.IncludeRoles;

            # If include roles is not empty.
            if ($includeRoles.Count -gt 0)
            {
                # Foreach include role.
                foreach ($includeRole in $includeRoles)
                {
                    # Get all users in the role.
                    $policy.includedUsers += (Get-EntraRoleMemberRecursive -Id $includeRole).Members;
                }
            }

            # Remove duplicates.
            $policy.ExcludedUsers = $policy.ExcludedUsers | Sort-Object -Unique;
            $policy.IncludedUsers = $policy.IncludedUsers | Sort-Object -Unique;

            # Only get users that are not also in exclude.
            $policy.TargetedUsers = $policy.IncludedUsers | Where-Object { $policy.ExcludedUsers -notcontains $_ };

            # Add to result.
            $policies += $policy;
        }
    }
    END
    {
        # Write to log.
        Write-CustomProgress @customProgress;

        # Return result.
        return $policies;
    }
}