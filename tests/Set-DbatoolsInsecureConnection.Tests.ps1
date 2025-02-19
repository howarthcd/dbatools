$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandpath" -ForegroundColor Cyan
$global:TestConfig = Get-TestConfig

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        [object[]]$params = (Get-Command $CommandName).Parameters.Keys | Where-Object { $_ -notin ('whatif', 'confirm') }
        [object[]]$knownParameters = 'Register', 'SessionOnly', 'Scope'
        $knownParameters += [System.Management.Automation.PSCmdlet]::CommonParameters
        It "Should only contain our specific parameters" {
            (@(Compare-Object -ReferenceObject ($knownParameters | Where-Object { $_ }) -DifferenceObject $params).Count ) | Should Be 0
        }
    }
}


Describe "$commandname Integration Tests" -Tags "IntegrationTests" {
    BeforeEach {
        # Set defaults just for this session
        Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $false -Register
        Set-DbatoolsConfig -FullName sql.connection.encrypt -Value $true -Register
    }
    Context "command actually works" {
        It "Should set the default connection settings to trust all server certificates and not require encrypted connections" {
            $trustcert = Get-DbatoolsConfigValue -FullName sql.connection.trustcert
            $encrypt = Get-DbatoolsConfigValue -FullName sql.connection.encrypt
            $trustcert | Should -BeFalse
            $encrypt | Should -BeTrue

            $null = Set-DbatoolsInsecureConnection
            Get-DbatoolsConfigValue -FullName sql.connection.trustcert | Should -BeTrue
            Get-DbatoolsConfigValue -FullName sql.connection.encrypt | Should -BeFalse
        }
    }
}