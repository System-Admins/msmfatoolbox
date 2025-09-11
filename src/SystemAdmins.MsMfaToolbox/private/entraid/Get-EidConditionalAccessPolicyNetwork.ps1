function Get-EidConditionalAccessPolicyNetwork
{
    <#
    .SYNOPSIS
        Get Entra conditional access policy network.
    .DESCRIPTION
        Get networks from a conditional access policy (trusted locations etc.).
    .PARAMETER PolicyId
        Guid format such as "0ee5b3dc-f9ce-4414-b93b-aea03ef7e108" (without quotes).
    .EXAMPLE
       Get-EidConditionalAccessPolicyNetwork -PolicyId "0ee5b3dc-f9ce-4414-b93b-aea03ef7e108";
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
        $customProgress = Write-CustomProgress -Activity $MyInvocation.MyCommand.Name -CurrentOperation ('Retrieving Entra conditional access policy networks for policy ({0})' -f $PolicyId);

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

        # Get locations.
        $locations = $entraConditionalAccessPolicy.Conditions.Locations;

        # Create custom object.
        $result = [PSCustomObject]@{
            'IncludeAllTrustedLocations'  = $false;
            'IncludeAnyNetworkOrLocation' = $false;
            'IncludeLocations'            = @();
            'ExcludeAllTrustedLocations'  = $false;
            'ExcludeLocations'            = @();
            'TargetedLocations'           = @();
        };
    }
    process
    {

        # If include locations is one and is 'all trusted' or 'all'.
        if ($locations.IncludeLocations -notcontains 'AllTrusted' -or $locations.IncludeLocations -notcontains 'All')
        {
            # Foreach include location.
            foreach ($includeLocation in $locations.IncludeLocations)
            {
                # Create custom object.
                $location = [PSCustomObject]@{
                    'Id'          = $includeLocation;
                    'DisplayName' = $null;
                };

                # If ID is '00000000-0000-0000-0000-000000000000'.
                if ($includeLocation -eq '00000000-0000-0000-0000-000000000000')
                {
                    # Set display name.
                    $location.DisplayName = 'Multifactor authentication trusted IPs';
                }
                # Else if ID is custom.
                else
                {
                    # Foreach named location policy.
                    foreach ($entraNamedLocationPolicy in $entraNamedLocationPolicies)
                    {
                        # If ID is equal to named location policy ID.
                        if ($includeLocation -eq $entraNamedLocationPolicy.Id)
                        {
                            # Set display name.
                            $location.DisplayName = $entraNamedLocationPolicy.DisplayName;
                        }
                    }
                }

                # Add location to result.
                $result.IncludeLocations += $location;
            }
        }

        # If all trusted locations is set.
        if ($locations.IncludeLocations.Count -eq 1 -and $locations.IncludeLocations -contains 'AllTrusted')
        {
            # Set include all trusted locations to true.
            $result.IncludeAllTrustedLocations = $true;
        }

        # If any network or location is set.
        if ($locations.IncludeLocations.Count -gt 0 -and $locations.IncludeLocations -contains 'All')
        {
            # Set include any network or location to true.
            $result.IncludeAnyNetworkOrLocation = $true;
        }

        # If exclude locations is one and is 'all trusted networks and locations'.
        if ($locations.ExcludeLocations.Count -eq 1 -and $locations.ExcludeLocations -contains 'AllTrusted')
        {
            # Set exclude all trusted locations to true.
            $result.ExcludeAllTrustedLocations = $true;
        }

        # If include locations is one and is 'all trusted' or 'all'.
        if ($locations.ExcludeLocations -notcontains 'AllTrusted')
        {
            # Foreach exclude location.
            foreach ($excludeLocation in $locations.ExcludeLocations)
            {
                # Create custom object.
                $location = [PSCustomObject]@{
                    'Id'          = $excludeLocation;
                    'DisplayName' = $null;
                };

                # If ID is '00000000-0000-0000-0000-000000000000'.
                if ($excludeLocation -eq '00000000-0000-0000-0000-000000000000')
                {
                    # Set display name.
                    $location.DisplayName = 'Multifactor authentication trusted IPs';
                }
                # Else if ID is custom.
                else
                {
                    # Foreach named location policy.
                    foreach ($entraNamedLocationPolicy in $entraNamedLocationPolicies)
                    {
                        # If ID is equal to named location policy ID.
                        if ($excludeLocation -eq $entraNamedLocationPolicy.Id)
                        {
                            # Set display name.
                            $location.DisplayName = $entraNamedLocationPolicy.DisplayName;
                        }
                    }
                }

                # Add location to result.
                $result.ExcludeLocations += $location;
            }

            # If exclude or include locations is set, targeted locations is set.
            if ($result.ExcludeLocations.Count -gt 0 -or $result.IncludeLocations.Count -gt 0)
            {
                # Remove excluded locations from included locations.
                $result.TargetedLocations = $result.IncludeLocations | Where-Object { $result.ExcludeLocations.Id -notcontains $_.Id }
            }
        }
    }
    end
    {
        # Write to log.
        Write-CustomProgress @customProgress;

        # Return result.
        return $result;
    }
}