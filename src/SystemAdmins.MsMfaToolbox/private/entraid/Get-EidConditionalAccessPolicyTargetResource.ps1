function Get-EidConditionalAccessPolicyTargetResource
{
    <#
    .SYNOPSIS
        Get Entra conditional access policy targeted resources.
    .DESCRIPTION
        Get target resources from a conditional access policy about service principals, user actions etc..
    .PARAMETER PolicyId
        Guid format such as "0ee5b3dc-f9ce-4414-b93b-aea03ef7e108" (without quotes).
    .EXAMPLE
       Get-EidConditionalAccessPolicyTargetResource -PolicyId "0ee5b3dc-f9ce-4414-b93b-aea03ef7e108";
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
        $customProgress = Write-CustomProgress -Activity $MyInvocation.MyCommand.Name -CurrentOperation ('Retrieving Entra conditional access policy target resources for policy ({0})' -f $PolicyId);

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

        # Create custom object to hold results.
        $result = [PSCustomObject]@{
            'IncludeAllApplications'      = $false;
            'IncludeApplications'         = @();
            'RegisterSecurityInformation' = $false;
            'RegisterOrJoinDevices'       = $false;
            'AuthenticationContext'       = $false;
            'ExcludeApplications'         = @();
            'TargetedApplications'        = @();
        };
    }
    process
    {
        # If all resources is selected.
        if ($entraConditionalAccessPolicy.Conditions.Applications.IncludeApplications.Count -eq 1 -and $entraConditionalAccessPolicy.Conditions.Applications.IncludeApplications -contains 'All')
        {
            # Set all resources to true.
            $result.'IncludeAllApplications' = $true;
        }

        # Foreach include application.
        foreach ($includeApplication in $entraConditionalAccessPolicy.Conditions.Applications.IncludeApplications)
        {
            # If application is empty.
            if ($includeApplication -eq 'None' -or $result.'AllResources' -eq $true)
            {
                # Skip.
                continue;
            }

            # Create custom object to hold application details.
            $applicationDetails = [PSCustomObject]@{
                'AppId'       = $null;
                'DisplayName' = $null;
                'ObjectId'    = $null;
                'Type'        = $null;
            };

            # If app is a GUID.
            if (Test-Guid -InputObject $includeApplication)
            {
                # Get service principal.
                $servicePrincipal = Get-EntraServicePrincipal -Filter "AppId eq '$includeApplication'";

                # If service principal found.
                if ($null -ne $servicePrincipal)
                {
                    # Populate application details.
                    $applicationDetails.'AppId' = $servicePrincipal.AppId;
                    $applicationDetails.'DisplayName' = $servicePrincipal.DisplayName;
                    $applicationDetails.'ObjectId' = $servicePrincipal.Id;
                    $applicationDetails.'Type' = 'ServicePrincipal';
                }
            }
            # Else the application is a collection of built-in apps.
            else
            {
                # Populate application details.
                $applicationDetails.'AppId' = $null;
                $applicationDetails.'DisplayName' = $includeApplication;
                $applicationDetails.'ObjectId' = $null;
                $applicationDetails.'Type' = 'BuiltInCollection';
            }

            # Add to included applications.
            $result.'IncludeApplications' += $applicationDetails;
        }

        # If 'Register security information' is set.
        if ($entraConditionalAccessPolicy.Conditions.Applications.IncludeUserActions -contains 'urn:user:registersecurityinfo')
        {
            # Set to true.
            $result.'RegisterSecurityInformation' = $true;
        }

        # If 'Register or join devices' is set.
        if ($entraConditionalAccessPolicy.Conditions.Applications.IncludeUserActions -contains 'urn:user:registerdevice')
        {
            # Set to true.
            $result.'RegisterOrJoinDevices' = $true;
        }

        # If 'Authentication context' is set.
        if ($entraConditionalAccessPolicy.Conditions.Applications.IncludeAuthenticationContextClassReferences.Count -gt 0)
        {
            # Set to true.
            $result.'AuthenticationContext' = $true;
        }

        # Foreach exclude application.
        foreach ($excludeApplication in $entraConditionalAccessPolicy.Conditions.Applications.ExcludeApplications)
        {
            # If application is empty.
            if ($excludeApplication -eq 'None')
            {
                # Skip.
                continue;
            }

            # Create custom object to hold application details.
            $applicationDetails = [PSCustomObject]@{
                'AppId'       = $null;
                'DisplayName' = $null;
                'ObjectId'    = $null;
                'Type'        = $null;
            };

            # If app is a GUID.
            if (Test-Guid -InputObject $excludeApplication)
            {
                # Get service principal.
                $servicePrincipal = Get-EntraServicePrincipal -Filter "AppId eq '$excludeApplication'";

                # If service principal found.
                if ($null -ne $servicePrincipal)
                {
                    # Populate application details.
                    $applicationDetails.'AppId' = $servicePrincipal.AppId;
                    $applicationDetails.'DisplayName' = $servicePrincipal.DisplayName;
                    $applicationDetails.'ObjectId' = $servicePrincipal.Id;
                    $applicationDetails.'Type' = 'ServicePrincipal';
                }
            }
            # Else the application is a collection of built-in apps.
            else
            {
                # Populate application details.
                $applicationDetails.'AppId' = $null;
                $applicationDetails.'DisplayName' = $excludeApplication;
                $applicationDetails.'ObjectId' = $null;
                $applicationDetails.'Type' = 'BuiltInCollection';
            }

            # Add to excluded applications.
            $result.'ExcludeApplications' += $applicationDetails;
        }

        # If include all applications is set to false.
        if ($result.'IncludeAllApplications' -eq $false)
        {

            # Get all excluded application, that are not built-in collections.
            $excludedAppIds = $result.'ExcludeApplications' | Where-Object { $null -ne $_.AppId -and $_.Type -ne 'BuiltInCollection' } | Select-Object -ExpandProperty AppId;

            # Get all included application, that are not built-in collections.
            $includedAppIds = $result.'IncludeApplications' | Where-Object { $null -ne $_.AppId -and $_.Type -ne 'BuiltInCollection' } | Select-Object -ExpandProperty AppId;

            # Get all excluded applications, that are built-in collections.
            $excludedBuiltInCollections = $result.'ExcludeApplications' | Where-Object { $_.Type -eq 'BuiltInCollection' } | Select-Object -ExpandProperty DisplayName;

            # Get all included applications, that are built-in collections.
            $includedBuiltInCollections = $result.'IncludeApplications' | Where-Object { $_.Type -eq 'BuiltInCollection' } | Select-Object -ExpandProperty DisplayName;

            # Remove excluded app ids from included app ids.
            $targetedAppIds = $includedAppIds | Where-Object { $excludedAppIds -notcontains $_ };

            # Remove excluded built-in collections from included built-in collections.
            $targetedBuiltInCollections = $includedBuiltInCollections | Where-Object { $excludedBuiltInCollections -notcontains $_ };

            # Foreach targeted app id.
            foreach ($targetedAppId in $targetedAppIds)
            {
                # Get app from included applications.
                $app = $result.'IncludeApplications' | Where-Object { $_.AppId -eq $targetedAppId };

                # Add to targeted applications.
                $result.'TargetedApplications' += $app;
            }

            # Foreach targeted built-in collection.
            foreach ($targetedBuiltInCollection in $targetedBuiltInCollections)
            {
                # Get app from included applications.
                $app = $result.'IncludeApplications' | Where-Object { $_.Type -eq 'BuiltInCollection' -and $_.DisplayName -eq $targetedBuiltInCollection };

                # Add to targeted applications.
                $result.'TargetedApplications' += $app;
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