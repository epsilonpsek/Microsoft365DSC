[CmdletBinding()]
param(
)
$M365DSCTestFolder = Join-Path -Path $PSScriptRoot `
    -ChildPath '..\..\Unit' `
    -Resolve
$CmdletModule = (Join-Path -Path $M365DSCTestFolder `
        -ChildPath '\Stubs\Microsoft365.psm1' `
        -Resolve)
$GenericStubPath = (Join-Path -Path $M365DSCTestFolder `
        -ChildPath '\Stubs\Generic.psm1' `
        -Resolve)
Import-Module -Name (Join-Path -Path $M365DSCTestFolder `
        -ChildPath '\UnitTestHelper.psm1' `
        -Resolve)

$Global:DscHelper = New-M365DscUnitTestHelper -StubModule $CmdletModule `
    -DscResource 'IntuneDeviceEnrollmentPlatformRestriction' -GenericStubModule $GenericStubPath

Describe -Name $Global:DscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:DscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:DscHelper.InitializeScript -NoNewScope

        BeforeAll {
            $secpasswd = ConvertTo-SecureString "Pass@word1" -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential ("tenantadmin@mydomain.com", $secpasswd)

            #Mock -CommandName Update-M365DSCExportAuthenticationResults -MockWith {
             #   return @{}
            #}

            #Mock -CommandName Get-M365DSCExportContentForResource -MockWith {

            #}

            Mock -CommandName Confirm-M365DSCDependencies -MockWith {
            }

            Mock -CommandName New-M365DSCConnection -MockWith {
                return 'Credentials'
            }

            Mock -CommandName Update-MgDeviceManagementDeviceEnrollmentConfiguration -MockWith {
            }

            Mock -CommandName New-MgDeviceManagementDeviceEnrollmentConfiguration -MockWith {
            }

            Mock -CommandName Remove-MgDeviceManagementDeviceEnrollmentConfiguration -MockWith {
            }

            Mock -CommandName Get-MgDeviceManagementDeviceEnrollmentConfigurationAssignment -MockWith {
                return @()
            }
        }

        # Test contexts
        Context -Name "When the restriction doesn't already exist" -Fixture {
            BeforeAll {
                $testParams = @{
                    Identity                                     = "12345-12345-12345-12345-12345_SinglePlatformRestriction";
                    Description                                  = "";
                    DisplayName                                  = "My DSC Restriction";
                    Ensure                                       = "Present"
                    DeviceEnrollmentConfigurationType            = "singlePlatformRestriction";
                    Credential                                   = $Credential;
                    IosRestriction                               = (New-CimInstance -ClassName MSFT_DeviceEnrollmentPlatformRestriction -Property @{
                        platformBlocked = $False
                        personalDeviceEnrollmentBlocked = $False
                    } -ClientOnly);
                }

                Mock -CommandName Get-MgDeviceManagementDeviceEnrollmentConfiguration -MockWith {
                    return $null
                }
            }

            It 'Should return absent from the Get method' {
                (Get-TargetResource @testParams).Ensure | Should -Be 'Absent'
            }

            It 'Should return false from the Test method' {
                Test-TargetResource @testParams | Should -Be $false
            }

            It 'Should create the restriction from the Set method' {
                Set-TargetResource @testParams
                Should -Invoke -CommandName 'New-MgDeviceManagementDeviceEnrollmentConfiguration' -Exactly 1
            }
        }

        Context -Name "When the restriction already exists and is in the Desired State" -Fixture {
            BeforeAll {
                $testParams = @{
                    Identity                                     = "12345-12345-12345-12345-12345_SinglePlatformRestriction"
                    Description                                  = "";
                    DisplayName                                  = "My DSC Restriction";
                    Ensure                                       = "Present"
                    DeviceEnrollmentConfigurationType            = "singlePlatformRestriction"
                    Credential                                   = $Credential;
                    IosRestriction                               = (New-CimInstance -ClassName MSFT_DeviceEnrollmentPlatformRestriction -Property @{
                        platformBlocked = $False
                        personalDeviceEnrollmentBlocked = $False
                    } -ClientOnly)
                }

                Mock -CommandName Get-MgDeviceManagementDeviceEnrollmentConfiguration -MockWith {
                    return @{
                        AdditionalProperties = @{
                            '@odata.type'                       = '#microsoft.graph.deviceEnrollmentPlatformRestrictionConfiguration'
                            PlatformRestriction                 = @{
                                    PersonalDeviceEnrollmentBlocked = $False;
                                    PlatformBlocked                 = $False;
                            }
                            platformType                        = 'ios'
                        }
                        id                                      = "12345-12345-12345-12345-12345_SinglePlatformRestriction"
                        DeviceEnrollmentConfigurationType       = "singlePlatformRestriction"
                        Description                             = "";
                        DisplayName                             = "My DSC Restriction";
                    }
                }
            }

            It "Should return true from the Test method" {
                Test-TargetResource @testParams | Should -Be $true
            }
        }

        Context -Name "When the restriction already exists and is NOT in the Desired State" -Fixture {
            BeforeAll {
                $testParams = @{
                    Identity                                     = "12345-12345-12345-12345-12345_SinglePlatformRestriction"
                    Description                                  = "";
                    DisplayName                                  = "My DSC Restriction";
                    Ensure                                       = "Present"
                    DeviceEnrollmentConfigurationType            = "singlePlatformRestriction"
                    Credential                           = $Credential;
                    iOSRestriction                               = (New-CimInstance -ClassName MSFT_DeviceEnrollmentPlatformRestriction -Property @{
                        platformBlocked = $False
                        personalDeviceEnrollmentBlocked = $False
                    } -ClientOnly)
                }

                Mock -CommandName Get-MgDeviceManagementDeviceEnrollmentConfiguration -MockWith {
                    return @{
                        AdditionalProperties = @{
                            '@odata.type'                       = '#microsoft.graph.deviceEnrollmentPlatformRestrictionConfiguration'
                            PlatformRestriction                 = @{
                                    PersonalDeviceEnrollmentBlocked = $true; #drift
                                    PlatformBlocked                 = $False;
                            }
                            platformType                        = 'ios'
                        }
                        id                                      = "12345-12345-12345-12345-12345_SinglePlatformRestriction"
                        DeviceEnrollmentConfigurationType       = "singlePlatformRestriction"
                        Description                             = "";
                        DisplayName                             = "My DSC Restriction";
                    }
                }
            }

            It "Should return false from the Test method" {
                Test-TargetResource @testParams | Should -Be $false
            }
        }

        Context -Name 'When the restriction exists and it SHOULD NOT' -Fixture {
            BeforeAll {
                $testParams = @{
                    Identity                                     = "12345-12345-12345-12345-12345_SinglePlatformRestriction"
                    Description                                  = "";
                    DisplayName                                  = "My DSC Restriction";
                    Ensure                                       = "Absent"
                    DeviceEnrollmentConfigurationType            = "singlePlatformRestriction"
                    Credential                           = $Credential;
                    iOSRestriction                               = (New-CimInstance -ClassName MSFT_DeviceEnrollmentPlatformRestriction -Property @{
                        platformBlocked = $False
                        personalDeviceEnrollmentBlocked = $False
                    } -ClientOnly)
                }

                Mock -CommandName Get-MgDeviceManagementDeviceEnrollmentConfiguration -MockWith {
                    return @{
                        AdditionalProperties = @{
                            '@odata.type'            = '#microsoft.graph.deviceEnrollmentPlatformRestrictionConfiguration'
                            PlatformRestriction       = @{
                                PersonalDeviceEnrollmentBlocked = $False;
                                PlatformBlocked                 = $False;
                            }
                            platformType                        = 'ios'
                        }
                        id                       = "12345-12345-12345-12345-12345_SinglePlatformRestriction"
                        DeviceEnrollmentConfigurationType            = "singlePlatformRestriction"
                        Description              = "";
                        DisplayName              = "My DSC Restriction";
                    }
                }
            }

            It 'Should return Present from the Get method' {
                (Get-TargetResource @testParams).Ensure | Should -Be 'Present'
            }

            It 'Should return true from the Test method' {
                Test-TargetResource @testParams | Should -Be $false
            }

            It 'Should remove the restriction from the Set method' {
                Set-TargetResource @testParams
                Should -Invoke -CommandName Remove-MgDeviceManagementDeviceEnrollmentConfiguration -Exactly 1
            }
        }

        Context -Name 'ReverseDSC Tests' -Fixture {
            BeforeAll {
                $Global:CurrentModeIsExport = $true
                $Global:PartialExportFileName = "$(New-Guid).partial.ps1"
                $testParams = @{
                    Credential = $Credential
                }

                Mock -CommandName Get-MgDeviceManagementDeviceEnrollmentConfiguration -MockWith {
                    return @{
                        AdditionalProperties                = @{
                            '@odata.type'       = '#microsoft.graph.deviceEnrollmentPlatformRestrictionConfiguration'
                            PlatformRestriction = @{
                                PersonalDeviceEnrollmentBlocked = $False;
                                PlatformBlocked                 = $False;
                            }
                            platformType        = 'ios'
                        }
                        id                                  = "12345-12345-12345-12345-12345_SinglePlatformRestriction"
                        DeviceEnrollmentConfigurationType   = "singlePlatformRestriction"
                        Description                         = "";
                        DisplayName                         = "My DSC Restriction";
                    }
                }
            }

            It 'Should Reverse Engineer resource from the Export method' {
                $result = Export-TargetResource @testParams
                $result | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:DscHelper.CleanupScript -NoNewScope
