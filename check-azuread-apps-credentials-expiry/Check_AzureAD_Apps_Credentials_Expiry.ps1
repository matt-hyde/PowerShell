# Import the AzureAD modules
Import-Module AzureAD

# Connect to Azure AD using an interactive login prompt
Connect-AzureAD

# Get all Application Registrations in the tenant
$appRegistrations = Get-AzureADApplication

# Set 30 days as the threshold for expiry
$threshold = (Get-Date).AddDays(30)

# Function to check credentials
function CheckCredential {
    param(
        $credential,
        $appName
    )

    # Check if the credential is expired
    if ($credential.EndDate -lt (Get-Date)) {
        # The credential is expired
        Write-Output "The credential for $appName is expired."
    }
    # Check if the credential will expire in the next 30 days
    elseif ($credential.EndDate -lt $threshold) {
        # The credential will expire soon
        Write-Output "The credential for $appName will expire in 30 days."
    }
}

# Iterate over each Application Registration
foreach ($appRegistration in $appRegistrations) {
    # Get the Application Registration's Key Credentials
    $keyCredentials = Get-AzureADApplicationKeyCredential -ObjectId $appRegistration.ObjectId
    # Iterate over each Key Credential
    foreach ($keyCredential in $keyCredentials) {
        CheckCredential -credential $keyCredential -appName $appRegistration.DisplayName
    }

    # Get the Application Registration's Password Credentials
    $passwordCredentials = Get-AzureADApplicationPasswordCredential -ObjectId $appRegistration.ObjectId
    # Iterate over each Password Credential
    foreach ($passwordCredential in $passwordCredentials) {
        CheckCredential -credential $passwordCredential -appName $appRegistration.DisplayName
    }
}