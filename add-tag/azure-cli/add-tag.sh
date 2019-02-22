#!/bin/sh
dryrun=NO
debug=YES

debug(){
    [ x$debug = x"YES" ] || return
    date=$(date '+%Y/%m/%d %H:%M:%S')
    echo -n "$date [DEBUG] "
    echo "$@"
}

info(){
    date=$(date '+%Y/%m/%d %H:%M:%S')
    echo -n "$date [INFO] "
    echo "$@"
}
execCmd(){
    info "$@"
    [ x$dryrun = x"NO" ] && "$@"
}

tmpfile=$(tempfile -p $0 -s .txt)
debug "tmpfile is created: $tmpfile"
trap "rm -f $tmpfile" 2

cat config.txt | grep -v '^#' | while read line
do
    rg=$(echo $line | cut -d, -f1)
    tags=$(echo $line | cut -d, -f2- | tr ',' ' ')

    info "Start processing : RG=[$rg]"
    

    # リソースグループの一覧を取得。テーブルのヘッダは飛ばす
    az resource list -g $rg --query [].id --output table | egrep -v '^Result|^-----' > $tmpfile

    # スペースを含んだリソースに対応するために区切りを変更
    BEFORE_IFS=$IFS
    IFS='
'
    for resid in $(cat $tmpfile);
    do
        # 既に設定されているタグを取得(JSON)
        jsonrtag=$(az resource show --id "$resid" --query tags)
        debug $jsonrtag
        # JSON を CLI の引数の形に変換
        IFS=$BEFORE_IFS
        rt=$(echo $jsonrtag | tr -d '"{},' | sed 's/: /=/g')
        # 既に設定されているタグと追加するタグの両方を設定(同じタグ名がある場合は上書き)
        execCmd az resource tag --tags $rt $tags --id "$resid" -o table
    done
    IFS=$BEFORE_IFS
    >$tmpfile


    info "Finish processing : RG=[$rg]"
done

