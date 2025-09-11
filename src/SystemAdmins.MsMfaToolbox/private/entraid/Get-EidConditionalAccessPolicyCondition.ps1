function Get-EidConditionalAccessPolicyCondition
{
    <#
    .SYNOPSIS
        Get Entra conditional access policy conditions.
    .DESCRIPTION
        Get conditions from a conditional access policy (trusted locations, device platforms, client apps, etc.).
    .PARAMETER PolicyId
        Guid format such as "0ee5b3dc-f9ce-4414-b93b-aea03ef7e108" (without quotes).
    .EXAMPLE
       Get-EidConditionalAccessPolicyCondition -PolicyId "0ee5b3dc-f9ce-4414-b93b-aea03ef7e108";
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
        $customProgress = Write-CustomProgress -Activity $MyInvocation.MyCommand.Name -CurrentOperation ('Retrieving Entra conditional access policy conditions for policy ({0})' -f $PolicyId);

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

        # Get conditions.
        $devicePlatforms = $entraConditionalAccessPolicy.Conditions.Platforms
        $clientAppsTypes = $entraConditionalAccessPolicy.Conditions.ClientAppTypes;
        $devices = $entraConditionalAccessPolicy.Conditions.Devices;
        $authenticationFlows = $entraConditionalAccessPolicy.Conditions.AdditionalProperties.authenticationFlows;

        # Create custom object.
        $result = [PSCustomObject]@{
            'DevicePlatforms'     = [PSCustomObject]@{
                'IsConfigured'     = $false;
                'IncludePlatform'  = $devicePlatforms.IncludePlatforms;
                'ExcludePlatform'  = $devicePlatforms.ExcludePlatforms;
                'TargetedPlatform' = @();
            };
            'ClientApps'          = [PSCustomObject]@{
                'IsConfigured'                = $false;
                'Browser'                     = $false;
                'MobileAppsAndDesktopClients' = $false;
                'ExchangeActiveSyncClients'   = $false;
                'OtherClients'                = $false;
            };
            'FilterForDevices'    = [PSCustomObject]@{
                'IsConfigured' = $false;
                'Exclude'      = $false;
                'Include'      = $false;
                'Query'        = $null;
            };
            'AuthenticationFlows' = [PSCustomObject]@{
                'IsConfigured'           = $false;
                'DeviceCodeFlow'         = $false;
                'AuthenticationTransfer' = $false;
            };
        };
    }
    process
    {
        # If either include platform or exclude platform is not null or empty, set IsConfigured to true.
        if ($devicePlatforms.IncludePlatforms.Count -gt 0 -or $devicePlatforms.ExcludePlatforms.Count -gt 0)
        {
            # Set IsConfigured to true.
            $result.DevicePlatforms.IsConfigured = $true;
        }

        # Foreach client app type.
        foreach ($clientAppType in $clientAppsTypes)
        {
            # Based on client app type.
            switch ($clientAppType)
            {
                # Browser.
                'browser'
                {
                    # Set Browser to true.
                    $result.ClientApps.Browser = $true;
                    $result.ClientApps.IsConfigured = $true;
                }
                # Mobile apps and desktop clients.
                'mobileAppsAndDesktopClients'
                {
                    # Set MobileAppsAndDesktopClients to true.
                    $result.ClientApps.MobileAppsAndDesktopClients = $true;
                    $result.ClientApps.IsConfigured = $true;
                }
                # Exchange ActiveSync clients.
                'exchangeActiveSync'
                {
                    # Set ExchangeActiveSyncClients to true.
                    $result.ClientApps.ExchangeActiveSyncClients = $true;
                    $result.ClientApps.IsConfigured = $true;
                }
                # Other clients.
                'other'
                {
                    # Set OtherClients to true.
                    $result.ClientApps.OtherClients = $true;
                    $result.ClientApps.IsConfigured = $true;
                }
            };
        }

        # If filter for devices is configured.
        if ($devices.DeviceFilter.Mode -eq 'include')
        {
            # Set IsConfigured to true.
            $result.FilterForDevices.IsConfigured = $true;

            # Set Include to true.
            $result.FilterForDevices.Include = $true;

            # Set Query.
            $result.FilterForDevices.Query = $devices.DeviceFilter.Rule;
        }
        # Else if filter for devices is configured to exclude.
        elseif ($devices.DeviceFilter.Mode -eq 'exclude')
        {
            # Set IsConfigured to true.
            $result.FilterForDevices.IsConfigured = $true;

            # Set Exclude to true.
            $result.FilterForDevices.Exclude = $true;

            # Set Query.
            $result.FilterForDevices.Query = $devices.DeviceFilter.Rule;
        }

        # If authentication flows is configured.
        if ($null -ne $authenticationFlows.transferMethods)
        {
            # Split transfer methods.
            $transferMethods = $authenticationFlows.transferMethods -split ',';

            # Foreach transfer method.
            foreach ($transferMethod in $transferMethods)
            {
                # Based on transfer method.
                switch ($transferMethod)
                {
                    # Device code flow.
                    'deviceCodeFlow'
                    {
                        # Set DeviceCodeFlow to true.
                        $result.AuthenticationFlows.DeviceCodeFlow = $true;
                        $result.AuthenticationFlows.IsConfigured = $true;
                    }

                    # Authentication transfer.
                    'authenticationTransfer'
                    {
                        # Set AuthenticationTransfer to true.
                        $result.AuthenticationFlows.AuthenticationTransfer = $true;
                        $result.AuthenticationFlows.IsConfigured = $true;
                    }
                };
            };
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