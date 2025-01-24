function Get-EntraGroupMemberRecursive
{
    <#
    .SYNOPSIS
        Get Entra group transitive members recursively.
    .DESCRIPTION
        Get recursive group members from a group ID and returns the userprincipalname(s).
    .PARAMETER Id
        Guid format such as "0ee5b3dc-f9ce-4414-b93b-aea03ef7e108" (without quotes).
    .EXAMPLE
        Get-EntraGroupMemberRecursive -Id "0ee5b3dc-f9ce-4414-b93b-aea03ef7e108";
    #>
    [cmdletbinding()]
    [OutputType([System.Collections.ArrayList])]
    param
    (
        # Backup path.
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Guid -InputObject $_ })]
        [string]$Id
    )

    BEGIN
    {
        # Write to log.
        $customProgress = Write-CustomProgress -Activity $MyInvocation.MyCommand.Name -CurrentOperation ('Get Entra group transitive members ({0})' -f $Id);

        # Object array to store the group members.
        $groupMembers = New-Object -TypeName System.Collections.ArrayList;

        # Write to log.
        Write-CustomLog -Message ("Getting transitive members from group '{0}'" -f $Id) -Level 'Verbose';
    }
    PROCESS
    {
        # Get transitive group member IDs in the group.
        $groupTransitiveMembers = Get-MgGroupTransitiveMember -GroupId $Id -All;

        # Foreach member.
        foreach ($groupTransitiveMember in $groupTransitiveMembers)
        {
            # If userPrincipalName is empty.
            if ($null -eq $groupTransitiveMember.AdditionalProperties.userPrincipalName)
            {
                # Skip.
                continue;
            }

            # Add to array.
            $null = $groupMembers.Add($groupTransitiveMember.AdditionalProperties.userPrincipalName);
        }

        # Write to log.
        Write-CustomLog -Message ("There is {0} members in the group with ID '{1}'" -f $groupMembers.Count, $Id) -Level 'Verbose';
    }
    END
    {
        # Write to log.
        Write-CustomProgress @customProgress;

        # Return result.
        return $groupMembers;
    }
}