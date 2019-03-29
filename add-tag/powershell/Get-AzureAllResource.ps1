<#
    DISCLAIMER
    ----------
    This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys' fees, that arise or result from the use or distribution of the Sample Code.
#>
[CmdletBinding()]
param
(
    [Parameter(Position=0, Mandatory=$false)]
    [string]$LogFilePath = ".\Get-AzureAllResource.log"
)

#------------------------------------------------------#
#                        関数定義
#------------------------------------------------------#
function Write-Log
{
    [CmdletBinding()]
    Param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]$Message,
        [Parameter(Position=1, Mandatory=$false)]
        [string]$FilePath = $LogFilePath
    )
    if (-not(Test-Path -Path $FilePath))
    {
        New-Item -Path $FilePath -ItemType file -Force | Out-Null
    }
    Out-File -InputObject $Message -FilePath $FilePath -Append | Out-Null
}

function Write-VerboseLog
{
    [CmdletBinding()]
    Param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]$Message
    )
    $Message = ("{0}[VERB]{1}" -f (Get-Date -Format "yyyy/MM/dd HH:mm:ss"), $Message)
    Write-Verbose $Message
    Write-Log $Message
}

function Write-DebugLog
{
    [CmdletBinding()]
    Param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]$Message
    )
    $Message = ("{0}[DEBG]{1}" -f (Get-Date -Format "yyyy/MM/dd HH:mm:ss"), $Message)
    Write-Debug $Message
    Write-Log $Message
}

function Write-InfoLog
{
    [CmdletBinding()]
    Param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]$Message
    )
    $Message = ("{0}[INFO]{1}" -f (Get-Date -Format "yyyy/MM/dd HH:mm:ss"), $Message)
    Write-Output $Message
    Write-Log $Message
}

# エラー情報をログに出力します。
function Write-Error
{
    Write-InfoLog $Error
    $Error.Clear() | Out-Null
    Write-InfoLog "例外が発生しました。"
}

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version latest
Get-AzContext

$resources = Get-AzResource | Select-Object Name, ResourceGroupName, ResourceId, Location, ResourceType, Tags

foreach($r in $resources){
    Write-VerboseLog ("リソース グループ:{0}, リソース名:{1}" -f $r.ResourceGroupName, $r.Name)
    if($null -eq $r.Tags -or $r.Tags.Keys.Count -eq 0){
        Write-VerboseLog "タグがありません"
        $r.Tags = $null
        continue
    }
    $tags = "["
    foreach($k in $r.Tags.Keys){
        $tags += "{" + $k + ":" + $r.Tags[$k] + "}"
    }
    $tags += "]"
    $r.Tags = $tags
    Write-VerboseLog ("タグ:{0}" -f $r.Tags)
}
$resources | Export-Csv -Path .\resources_list.csv -Encoding Default -NoTypeInformation
