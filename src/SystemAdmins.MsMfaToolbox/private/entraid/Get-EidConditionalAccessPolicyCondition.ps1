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
        # Policy ID.
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
                'IsConfigured'       = $false;
                'IncludeAllPlatform' = $false;
                'IncludePlatform'    = $devicePlatforms.IncludePlatforms;
                'ExcludePlatform'    = $devicePlatforms.ExcludePlatforms;
                'TargetedPlatform'   = @();
            };
            'UserRiskLevels'      = [PSCustomObject]@{
                'IsConfigured' = $false;
                'Low'          = $false;
                'Medium'       = $false;
                'High'         = $false;
            };
            'SignInRiskLevels'    = [PSCustomObject]@{
                'IsConfigured' = $false;
                'Low'          = $false;
                'Medium'       = $false;
                'High'         = $false;
            };
            'ClientApps'          = [PSCustomObject]@{
                'IsConfigured'                = $false;
                'Browser'                     = $false;
                'MobileAppsAndDesktopClients' = $false;
                'ExchangeActiveSyncClients'   = $false;
                'OtherClients'                = $false;
                'ExcludedClientApps'          = @();
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

            # Get targeted platforms by removing excluded platforms from the included platforms.
            $result.DevicePlatforms.TargetedPlatform = $devicePlatforms.IncludePlatforms | Where-Object { $devicePlatforms.ExcludePlatforms -notcontains $_ };
        }

        # If platform is set to include all.
        if ($devicePlatforms.IncludePlatforms -contains 'all')
        {
            # Set IsConfigured to true.
            $result.DevicePlatforms.IsConfigured = $true;

            # Set IncludeAllPlatform to true.
            $result.DevicePlatforms.IncludeAllPlatform = $true;
        }

        # If user risk levels is configured.
        if ($null -ne $entraConditionalAccessPolicy.Conditions.UserRiskLevels)
        {
            # Foreach user risk level.
            foreach ($userRiskLevel in $entraConditionalAccessPolicy.Conditions.UserRiskLevels)
            {
                # Based on user risk level.
                switch ($userRiskLevel)
                {
                    'low'
                    {
                        # Set Low to true.
                        $result.UserRiskLevels.Low = $true;

                        # Set IsConfigured to true.
                        $result.UserRiskLevels.IsConfigured = $true;
                    }
                    'medium'
                    {
                        # Set Medium to true.
                        $result.UserRiskLevels.Medium = $true;

                        # Set IsConfigured to true.
                        $result.UserRiskLevels.IsConfigured = $true;
                    }
                    'high'
                    {
                        # Set High to true.
                        $result.UserRiskLevels.High = $true;

                        # Set IsConfigured to true.
                        $result.UserRiskLevels.IsConfigured = $true;

                    }
                }
            }
        }

        # If sign-in risk levels is configured.
        if ($null -ne $entraConditionalAccessPolicy.Conditions.SignInRiskLevels)
        {
            # Foreach sign-in risk level.
            foreach ($signInRiskLevel in $entraConditionalAccessPolicy.Conditions.SignInRiskLevels)
            {
                # Based on sign-in risk level.
                switch ($signInRiskLevel)
                {
                    'low'
                    {
                        # Set Low to true.
                        $result.SignInRiskLevels.Low = $true;

                        # Set IsConfigured to true.
                        $result.SignInRiskLevels.IsConfigured = $true;
                    }
                    'medium'
                    {
                        # Set Medium to true.
                        $result.SignInRiskLevels.Medium = $true;

                        # Set IsConfigured to true.
                        $result.SignInRiskLevels.IsConfigured = $true;
                    }
                    'high'
                    {
                        # Set High to true.
                        $result.SignInRiskLevels.High = $true;

                        # Set IsConfigured to true.
                        $result.SignInRiskLevels.IsConfigured = $true;

                    }
                }
            }
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

        # If client apps is configured.
        if ($true -eq $result.ClientApps.IsConfigured)
        {
            # If Browser is false.
            if ($false -eq $result.ClientApps.Browser)
            {
                # Add to ExcludedClientApps.
                $result.ClientApps.ExcludedClientApps += 'browser';
            }

            # If MobileAppsAndDesktopClients is false.
            if ($false -eq $result.ClientApps.MobileAppsAndDesktopClients)
            {
                # Add to ExcludedClientApps.
                $result.ClientApps.ExcludedClientApps += 'mobileAppsAndDesktopClients';
            }

            # If ExchangeActiveSyncClients is false.
            if ($false -eq $result.ClientApps.ExchangeActiveSyncClients)
            {
                # Add to ExcludedClientApps.
                $result.ClientApps.ExcludedClientApps += 'exchangeActiveSync';
            }

            # If OtherClients is false.
            if ($false -eq $result.ClientApps.OtherClients)
            {
                # add to ExcludedClientApps
                $result.ClientApps.ExcludedClientApps += 'other';
            }
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