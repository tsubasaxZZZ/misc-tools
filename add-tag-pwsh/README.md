# ツールの概要
このツールは、リソースの CSV エクスポートとタグの付与の2つのツールで構成されています。

# Get-AzureAllResource(CSV エクスポート)
サブスクリプションのすべてのリソースの一覧を CSV にエクスポートします。

## 使い方
1. Azure PowerShell をインストールする
2. ログインする
   1. Login-AzAccount
3. サブスクリプションを選択する
   1. Set-AzContext -SubscriptionId <サブスクリプションID>
4. ツールを実行する
   1. .\Get-AzureAllResource.ps1

resources_list.csv に、リソースの一覧がエクスポートされています。

# Set-TagFromCSV.ps1(タグの付与)
このツールを使う前に、エクスポートした CSV を編集します。

注)Excelを使用する場合、先頭に 0 が付与されていると 0 が消えてしまうため、CSV ファイルをそのまま開くのではなく、インポートすること。

1. エクスポートした CSV に、"OPE" というカラムと、追加したいタグキーのカラムを追加します。
2. タグを追加したいリソースの OPE 列に "A" を入力します。(この A を見て、ツールはタグの追加を行います)
   - sample.csv にサンプルがあります。

## 使い方
1. ツールを実行する(-Force をつけると実行可否を確認しません。初めは -Force をつけることをお勧めします)
   - .\Set-TagFromCSV.ps1 -DataFilePath .\modified.csv -Force
