function Get-EidConditionalAccessPolicyUser
{
    <#
    .SYNOPSIS
        Get Entra conditional access policy user assignments.
    .DESCRIPTION
        Get user assignments from a conditional access policy ID information about users that are excluded and included.
    .PARAMETER PolicyId
        Guid format such as "0ee5b3dc-f9ce-4414-b93b-aea03ef7e108" (without quotes).
    .EXAMPLE
       Get-EidConditionalAccessPolicyUser -PolicyId "0ee5b3dc-f9ce-4414-b93b-aea03ef7e108";
    #>
    [cmdletbinding()]
    [OutputType([PSCustomObject])]
    param
    (
        # Backup path.
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Guid -InputObject $_ })]
        [string]$PolicyId
    )

    begin
    {
        # Write to log.
        $customProgress = Write-CustomProgress -Activity $MyInvocation.MyCommand.Name -CurrentOperation ('Retrieving Entra conditional access policy user assignments for policy ({0})' -f $PolicyId);

        # Get conditional access policy by id.
        $entraConditionalAccessPolicy = Get-EntraConditionalAccessPolicy `
            -PolicyId $PolicyId `
            -ErrorAction SilentlyContinue;

        # If policy is null.
        if ($null -eq $entraConditionalAccessPolicy)
        {
            # Write to log.
            Write-CustomLog -Message ("No conditional access policy found with ID '{0}'" -f $PolicyId) -Level 'Verbose';

            # Throw exception.
            throw "No conditional access policy found with ID '$PolicyId'";
        }

        # All users object.
        $entraUsers = $null;

        # Create custom object.
        $result = [PSCustomObject]@{
            'IncludeAllUsers'                   = $false;
            'IncludeUsers'                      = @();
            'IncludeGuestsOrExternalUsersTypes' = @();
            'IncludeAllGuestsOrExternalUsers'   = $false;
            'IncludeRoles'                      = @();
            'IncludeGroups'                     = @();
            'IncludeTransitiveUsers'            = @();
            'ExcludeUsers'                      = @();
            'ExcludeGuestsOrExternalUsersTypes' = @();
            'ExcludeAllGuestsOrExternalUsers'   = $false;
            'ExcludeRoles'                      = @();
            'ExcludeGroups'                     = @();
            'ExcludeTransitiveUsers'            = @();
            'TargetedUsers'                     = @();
        };

        # Get all Entra roles.
        $entraRoles = Get-EntraDirectoryRoleDefinition -All;

        # Get users conditions.
        $users = $entraConditionalAccessPolicy.Conditions.Users;
    }
    process
    {
        # If include users is set to 'All'.
        if ($users.IncludeUsers.Count -eq 1 -and $users.IncludeUsers -contains 'All')
        {
            # Set include all users to true.
            $result.'IncludeAllUsers' = $true;

            # Get all users.
            $entraUsers = (Get-EntraUser -All -Property UserPrincipalName).UserPrincipalName;
        }
        # Else if specific users are included.
        elseif ($users.IncludeUsers.Count -eq 1 -and $users.IncludeUsers -notcontains 'All')
        {
            # Foreach included user.
            foreach ($userId in $users.IncludeUsers)
            {
                # Get user.
                $entraUser = Get-EntraUser `
                    -ObjectId $userId `
                    -ErrorAction SilentlyContinue;

                # If user is null.
                if ($null -eq $entraUser)
                {
                    # Write to log.
                    Write-CustomLog -Message ("No user found with ID '{0}'" -f $userId) -Level 'Verbose';

                    # Continue to next user.
                    continue;
                }

                # Add to result.
                $result.'IncludeUsers' += [PSCustomObject]@{
                    Id                = $entraUser.Id;
                    UserPrincipalName = $entraUser.UserPrincipalName;
                    DisplayName       = $entraUser.DisplayName;
                };
            }
        }

        # If guests and external users are included.
        if ($users.IncludeGuestsOrExternalUsers.GuestOrExternalUserTypes.Count -gt 0)
        {
            # Foreach included guest or external user type.
            foreach ($guestOrExternalUserType in $users.IncludeGuestsOrExternalUsers.GuestOrExternalUserTypes)
            {
                # Add to result.
                $result.'IncludeGuestsOrExternalUsersTypes' += $guestOrExternalUserType;
            }
        }

        # If all guests and external users are included.
        if ($users.IncludeGuestsOrExternalUsers.ExternalTenants.MembershipKind -eq 'All')
        {
            # Set include all guests or external users to true.
            $result.'IncludeAllGuestsOrExternalUsers' = $true;
        }

        # Foreach included roles.
        foreach ($includeRole in $users.IncludeRoles)
        {
            # Foreach Entra role.
            foreach ($entraRole in $entraRoles)
            {
                # If the role ID matches the included role ID.
                if ($entraRole.ObjectId -eq $includeRole)
                {
                    # Add to result.
                    $result.'IncludeRoles' += [PSCustomObject]@{
                        DisplayName = $entraRole.DisplayName;
                        ObjectId    = $entraRole.ObjectId;
                        Id          = $entraRole.Id;
                    };
                }
            }
        }

        # If included groups are set.
        if ($users.IncludeGroups.Count -gt 0)
        {
            # Foreach included group.
            foreach ($groupId in $users.IncludeGroups)
            {
                # Get group.
                $entraGroup = Get-EntraGroup -ObjectId $groupId;

                # Add to result.
                $result.'IncludeGroups' += [PSCustomObject]@{
                    Id          = $entraGroup.Id;
                    DisplayName = $entraGroup.DisplayName;
                };
            }
        }

        # If excluded users are set.
        if ($users.ExcludeUsers.Count -gt 0)
        {
            # Foreach excluded user.
            foreach ($userId in $users.ExcludeUsers)
            {
                # Get user.
                $entraUser = Get-EntraUser `
                    -ObjectId $userId `
                    -ErrorAction SilentlyContinue;

                # If user is null.
                if ($null -eq $entraUser)
                {

                    # Add to result.
                    $result.'ExcludeUsers' += [PSCustomObject]@{
                        Id                = $entraUser.Id;
                        UserPrincipalName = $entraUser.UserPrincipalName;
                        DisplayName       = $entraUser.DisplayName;
                    };
                }
            }
        }

        # If guests and external users are excluded.
        if ($users.ExcludeGuestsOrExternalUsers.GuestOrExternalUserTypes.Count -gt 0)
        {
            # Foreach excluded guest or external user type.
            foreach ($guestOrExternalUserType in $users.ExcludeGuestsOrExternalUsers.GuestOrExternalUserTypes)
            {
                # Add to result.
                $result.'ExcludeGuestsOrExternalUsersTypes' += $guestOrExternalUserType;
            }
        }

        # If all guests and external users are excluded.
        if ($users.ExcludeGuestsOrExternalUsers.ExternalTenants.MembershipKind -eq 'All')
        {
            # Set exclude all guests or external users to true.
            $result.'ExcludeAllGuestsOrExternalUsers' = $true;
        }

        # Foreach excluded roles.
        foreach ($excludeRole in $users.ExcludeRoles)
        {
            # Foreach Entra role.
            foreach ($entraRole in $entraRoles)
            {
                # If the role ID matches the excluded role ID.
                if ($entraRole.ObjectId -eq $excludeRole)
                {
                    # Add to result.
                    $result.'ExcludeRoles' += [PSCustomObject]@{
                        DisplayName = $entraRole.DisplayName;
                        ObjectId    = $entraRole.ObjectId;
                        Id          = $entraRole.Id;
                    };
                }
            }
        }

        # If excluded groups are set.
        if ($users.ExcludeGroups.Count -gt 0)
        {
            # Foreach excluded group.
            foreach ($groupId in $users.ExcludeGroups)
            {
                # Get group.
                $entraGroup = Get-EntraGroup -ObjectId $groupId;

                # Add to result.
                $result.'ExcludeGroups' += [PSCustomObject]@{
                    Id          = $entraGroup.Id;
                    DisplayName = $entraGroup.DisplayName; ;
                };
            }
        }

        # Foreach group in IncludeGroups
        foreach ($includeGroup in $result.IncludeGroups)
        {
            # Get transitive members of the group.
            $includeGroupTransitiveMembers = Get-EidGroupTransitiveMember -Id $includeGroup.Id;

            # Foreach transitive member.
            foreach ($includeGroupTransitiveMember in $includeGroupTransitiveMembers)
            {
                # Add to result.
                $result.IncludeTransitiveUsers += $includeGroupTransitiveMember
            }
        }

        # Foreach user in the IncludeUsers.
        foreach ($includeUser in $result.IncludeUsers)
        {
            # Add to IncludeTransitiveUsers
            $result.IncludeTransitiveUsers += $includeUser.UserPrincipalName;
        }

        # Foreach Entra users (if any).
        foreach ($entraUser in $entraUsers)
        {
            # Add to IncludeTransitiveUsers
            $result.IncludeTransitiveUsers += $entraUser;
        }

        # Foreach group in ExcludeGroups.
        foreach ($excludeGroup in $result.ExcludeGroups)
        {
            # Get transitive members of the group.
            $excludeGroupTransitiveMembers = Get-EidGroupTransitiveMember -Id $excludeGroup.Id;

            # Foreach transitive member.
            foreach ($excludeGroupTransitiveMember in $excludeGroupTransitiveMembers)
            {
                # Add to result.
                $result.ExcludeTransitiveUsers += $excludeGroupTransitiveMember
            }
        }

        # Foreach user in the ExcludeUsers.
        foreach ($excludeUser in $result.ExcludeUsers)
        {
            # Add to ExcludeTransitiveUsers
            $result.ExcludeTransitiveUsers += $excludeUser.UserPrincipalName;
        }

        # Foreach role in IncludeRoles.
        foreach ($includeRole in $result.IncludeRoles)
        {
            # Get members of the role.
            $eidRoleMemberRecursive = Get-EidRoleMemberRecursive -Id $includeRole.ObjectId;

            # Foreach member.
            foreach ($includeRoleMember in $eidRoleMemberRecursive.Members)
            {
                # Add to result.
                $result.IncludeTransitiveUsers += $includeRoleMember;
            }
        }

        # Foreach role in ExcludeRoles.
        foreach ($excludeRole in $result.ExcludeRoles)
        {
            # Get members of the role.
            $eidRoleMemberRecursive = Get-EidRoleMemberRecursive -Id $excludeRole.ObjectId;

            # Foreach member.
            foreach ($excludeRoleMember in $eidRoleMemberRecursive.Members)
            {
                # Add to result.
                $result.ExcludeTransitiveUsers += $excludeRoleMember;
            }
        }

        # Remove duplicates from IncludeTransitiveUsers and ExcludeTransitiveUsers.
        $result.IncludeTransitiveUsers = $result.IncludeTransitiveUsers | Sort-Object -Unique;
        $result.ExcludeTransitiveUsers = $result.ExcludeTransitiveUsers | Sort-Object -Unique;

        # Get targeted users by removing excluded users from included users.
        $result.TargetedUsers = $result.IncludeTransitiveUsers | Where-Object { $_ -notin $result.ExcludeTransitiveUsers };

    }
    end
    {
        # Write to log.
        Write-CustomProgress @customProgress;

        # Return result.
        return $result;
    }
}