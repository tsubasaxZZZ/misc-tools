[CmdletBinding()]
param
(
    [Parameter(Position=0, Mandatory=$false)]
    [string]$LogFilePath = ".\Set-TagFromCSV.log",
    [Parameter(Position=1, Mandatory=$true)]
    [ValidateScript({Test-Path $_})]
    [string]$DataFilePath,
    [Parameter(Position=3, Mandatory=$false)]
    [switch]$Force

)

#------------------------------------------------------#
#                        �֐���`
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

# �G���[�������O�ɏo�͂��܂��B
function Write-Error
{
    Write-InfoLog $Error
    $Error.Clear() | Out-Null
    Write-InfoLog "��O���������܂����B"
}

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version latest
Get-AzContext

$resources = Import-Csv -Encoding Default -Path $DataFilePath

foreach ($r in $resources) {
    # �ǉ��������^�O�̃L�[���擾����
    # CSV �̃w�b�_�[�̂����A����̃w�b�_�[���͎擾���Ȃ�(=�ǉ�����^�O�̃L�[�݂̂��擾����)�Ŕz��
    $tagKeys = @()
    $sourceKeys = $r | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
    foreach($k in $sourceKeys){
        if($k -eq "Location" -or
            $k -eq "Name" -or
            $k -eq "ResourceGroupName" -or
            $k -eq "ResourceID" -or
            $k -eq "ResourceType" -or 
            $k -eq "Tags" -or
            $k -eq "OPE"
            ){
                continue
        }
        $tagKeys += $k
    }

    # �^�O�̒ǉ�
    if($r.Ope -eq "A"){
        $target = Get-AzResource -ResourceName $r.Name -ResourceGroupName $r.ResourceGroupName
        $addTags = @{}
        
        # ���Ƀ^�O������ꍇ�͂�����g��
        if($target.Tags){
            $addTags = $target.Tags
        }
        
        # �ǉ�����^�O�L�[�𑖍�
        foreach($tagKey in $tagKeys){
            # CSV �Ń^�O���w�肳��Ă���ꍇ
            if($r.$tagKey){
                $addTags[$tagKey] = $r.$tagKey
            }
        }
        Write-InfoLog ("���\�[�X:{0} �� �^�O:{1} ��t�^���܂��B" -f $target.Name, ($addTags.Keys -join ","))
        if($Force){
            Set-AzResource -Tag $addTags -ResourceId $target.ResourceId -Force
        }else {
            Set-AzResource -Tag $addTags -ResourceId $target.ResourceId
        }
    }
}