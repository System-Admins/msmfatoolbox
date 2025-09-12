function Get-EidConditionalAccessPolicyGrant
{
    <#
    .SYNOPSIS
        Get Entra conditional access policy grants.
    .DESCRIPTION
        Get grants from a conditional access policy (e.g. MFA, compliant device, etc.).
    .PARAMETER PolicyId
        Guid format such as "0ee5b3dc-f9ce-4414-b93b-aea03ef7e108" (without quotes).
    .EXAMPLE
       Get-EidConditionalAccessPolicyGrant -PolicyId "0ee5b3dc-f9ce-4414-b93b-aea03ef7e108";
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
        $customProgress = Write-CustomProgress -Activity $MyInvocation.MyCommand.Name -CurrentOperation ('Retrieving Entra conditional access policy grants for policy ({0})' -f $PolicyId);

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

        # Get grant controls.
        $grantControls = $entraConditionalAccessPolicy.GrantControls;

        # Create custom object.
        $result = [PSCustomObject]@{
            'BlockAccess'                      = $false;
            'GrantAccess'                      = $false;
            'RequireMfa'                       = $false;
            'RequireAuthenticationStrength'    = $false;
            'AuthenticationStrength'           = [PSCustomObject]@{
                'RegularMFA'        = $false;
                'PasswordlessMFA'   = $false;
                'PhishResistantMFA' = $false;
            };
            'RequireDeviceCompliance'          = $false;
            'RequireHybridAzureADJoinedDevice' = $false;
            'RequireAppProtectionPolicy'       = $false;
            'RequireAllControls'               = $false;
            'RequireOneOfControls'             = $false;
        };
    }
    process
    {
        # If MFA is required.
        if ($grantControls.BuiltInControls -contains 'mfa')
        {
            # Set RequireMfa to true.
            $result.RequireMfa = $true;
        }

        # If authentication strength MFA is required.
        if ($grantControls.AuthenticationStrength.Id -eq '00000000-0000-0000-0000-000000000002')
        {
            # Set RequireAuthenticationStrength to true.
            $result.RequireAuthenticationStrength = $true;

            # Set RegularMFA to true.
            $result.AuthenticationStrength.RegularMFA = $true;
        }

        # If authentication strength passwordless MFA is required.
        if ($grantControls.AuthenticationStrength.Id -eq '00000000-0000-0000-0000-000000000003')
        {
            # Set RequireAuthenticationStrength to true.
            $result.RequireAuthenticationStrength = $true;

            # Set passwordless MFA to true.
            $result.AuthenticationStrength.PasswordlessMFA = $true;
        }

        # If authentication strength phish resistant MFA is required.
        if ($grantControls.AuthenticationStrength.Id -eq '00000000-0000-0000-0000-000000000004')
        {
            # Set RequireAuthenticationStrength to true.
            $result.RequireAuthenticationStrength = $true;

            # Set PhishResistantMFA to true.
            $result.AuthenticationStrength.PhishResistantMFA = $true;
        }

        # If device compliance is required.
        if ($grantControls.BuiltInControls -contains 'compliantDevice')
        {
            # Set RequireDeviceCompliance to true.
            $result.RequireDeviceCompliance = $true;
        }

        # If hybrid Azure AD joined device is required.
        if ($grantControls.BuiltInControls -contains 'domainJoinedDevice')
        {
            # Set RequireHybridAzureADJoinedDevice to true.
            $result.RequireHybridAzureADJoinedDevice = $true;
        }

        # If app protection policy is required.
        if ($grantControls.BuiltInControls -contains 'compliantApplication')
        {
            # Set RequireAppProtectionPolicy to true.
            $result.RequireAppProtectionPolicy = $true;
        }

        # If only one control is required.
        if ($grantControls.Operator -eq 'OR')
        {
            # Set RequireOneOfControls to true.
            $result.RequireOneOfControls = $true;
        }

        # If all controls are required.
        if ($grantControls.Operator -eq 'AND')
        {
            # Set RequireAllControls to true.
            $result.RequireAllControls = $true;
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