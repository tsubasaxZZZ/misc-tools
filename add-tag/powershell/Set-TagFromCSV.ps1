[CmdletBinding()]
param
(
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$LogFilePath = ".\Set-TagFromCSV.log",
    [Parameter(Position = 1, Mandatory = $true)]
    [ValidateScript( {Test-Path $_})]
    [string]$DataFilePath,
    [Parameter(Position = 3, Mandatory = $false)]
    [switch]$Force

)

#------------------------------------------------------#
#                        関数定義
#------------------------------------------------------#
function Write-Log {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Message,
        [Parameter(Position = 1, Mandatory = $false)]
        [string]$FilePath = $LogFilePath
    )
    if (-not(Test-Path -Path $FilePath)) {
        New-Item -Path $FilePath -ItemType file -Force | Out-Null
    }
    Out-File -InputObject $Message -FilePath $FilePath -Append | Out-Null
}

function Write-VerboseLog {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Message
    )
    $Message = ("{0}[VERB]{1}" -f (Get-Date -Format "yyyy/MM/dd HH:mm:ss"), $Message)
    Write-Verbose $Message
    Write-Log $Message
}

function Write-DebugLog {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Message
    )
    $Message = ("{0}[DEBG]{1}" -f (Get-Date -Format "yyyy/MM/dd HH:mm:ss"), $Message)
    Write-Debug $Message
    Write-Log $Message
}

function Write-InfoLog {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Message
    )
    $Message = ("{0}[INFO]{1}" -f (Get-Date -Format "yyyy/MM/dd HH:mm:ss"), $Message)
    Write-Output $Message
    Write-Log $Message
}

# エラー情報をログに出力します。
function Write-Error {
    Write-InfoLog $Error
    $Error.Clear() | Out-Null
    #Write-InfoLog "例外が発生しました。"
}

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version latest
Get-AzContext

$resources = Import-Csv -Encoding Default -Path $DataFilePath

# CSV を一行ごとにループ
foreach ($r in $resources) {
    # 追加したいタグのキーを取得する
    # CSV のヘッダーのうち、既定のヘッダー名は取得しない(=追加するタグのキーのみを取得する)で配列化
    $tagKeys = @()
    $sourceKeys = $r | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
    foreach ($k in $sourceKeys) {
        if ($k -eq "Location" -or
            $k -eq "Name" -or
            $k -eq "ResourceGroupName" -or
            $k -eq "ResourceID" -or
            $k -eq "ResourceType" -or 
            $k -eq "Tags" -or
            $k -eq "OPE"
        ) {
            continue
        }
        $tagKeys += $k
    }

    # Ope に何も指定されていない場合はスキップ
    if (!$r.Ope) {
        continue
    }

    # Azure のリソースを取得
    $target = Get-AzResource -ResourceName $r.Name -ResourceGroupName $r.ResourceGroupName
    $addTags = @{}
        
    # 既にタグがある場合はそれを使う
    if ($target.Tags) {
        $addTags = $target.Tags
    }

    # OPE の分岐
    switch ($r.Ope) {
        # タグの追加
        "A" {
            # 追加するタグキーを走査
            foreach ($tagKey in $tagKeys) {
                # CSV でタグが指定されている場合
                if ($r.$tagKey) {
                    $addTags[$tagKey] = $r.$tagKey
                }
            }
            Write-InfoLog ("リソース:{0} に タグ:{1} を付与します。" -f $target.Name, ($addTags.Keys -join ","))
        }
        # タグの削除
        "D" {
            # 削除するタグキーを走査
            foreach ($tagKey in $tagKeys) {
                # 列名($tagKey)を削除するタグとする
                $addTags.Remove($tagKey)
            }
            Write-InfoLog ("リソース:{0} から タグ:{1} を削除します。" -f $target.Name, ($tagKeys -join ","))
        }
    }

    # タグの設定
    try {
        if ($Force) {
            Write-InfoLog (Set-AzResource -Tag $addTags -ResourceId $target.ResourceId -Force)
        }
        else {
            Write-InfoLog (Set-AzResource -Tag $addTags -ResourceId $target.ResourceId)
        }
    }
    catch {
        Write-InfoLog("例外が発生しました:ResourceID=[{0}], Tag=[{1}]" -f $target.ResourceId, ($addTags.Keys -join ","))
        Write-Error
    }

}