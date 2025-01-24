function Get-EntraRoleMemberRecursive
{
    <#
    .SYNOPSIS
        Get Entra role transitive members recursively.
    .DESCRIPTION
        Get recursive role members from a ID and returns the userprincipalname(s).
    .PARAMETER GroupId
        Guid format such as "0ee5b3dc-f9ce-4414-b93b-aea03ef7e108" (without quotes).
    .EXAMPLE
        Get-EntraRoleMemberRecursive -Id "0ee5b3dc-f9ce-4414-b93b-aea03ef7e108";
    #>
    [cmdletbinding()]
    [OutputType([System.Collections.ArrayList])]
    param
    (
        # Backup path.
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Guid -InputObject $_ })]
        [string]$Id
    )

    BEGIN
    {
        # Write to log.
        $customProgress = Write-CustomProgress -Activity $MyInvocation.MyCommand.Name -CurrentOperation ('Get Entra role transitive members');

        # Object array to store the role members.
        $results = New-Object -TypeName System.Collections.ArrayList;
    }
    PROCESS
    {
        # If ID is empty.
        if ([string]::IsNullOrEmpty($Id))
        {
            # Get all roles.
            $roles = Get-MgDirectoryRole -All;
        }
        # Else get role by id.
        else
        {
            $roles = Get-MgDirectoryRoleByRoleTemplateId -RoleTemplateId $Id -ErrorAction SilentlyContinue;
        }

        # Foreach role.
        foreach ($role in $roles)
        {
            # Create object.
            $result = [PSCustomObject]@{
                Id             = $role.Id;
                RoleTemplateId = $role.RoleTemplateId;
                DisplayName    = $role.DisplayName;
                Members        = @();
            };

            # Write to log.
            Write-CustomLog -Message ("Getting transitive members from role '{0}'" -f $role.RoleTemplateId) -Level 'Verbose';

            # Get all users with the role.
            $roleMembers = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id -All;

            # Foreach member.
            foreach ($roleMember in $roleMembers)
            {
                $result.Members += $roleMember.AdditionalProperties.userPrincipalName;
            }

            # Add to results.
            $null = $results.Add($result);
        }
    }
    END
    {
        # Write to log.
        Write-CustomProgress @customProgress;

        # Return result.
        return $results;
    }
}