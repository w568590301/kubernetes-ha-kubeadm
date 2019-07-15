#!/bin/bash

target=target
declare -A kvs=()

function replace_files() {
    local file=$1
    if [ -f $file ];then
        echo "$file"
        for key in ${!kvs[@]}
        do
            value=${kvs[$key]}
            value=${value//\//\\\/}
            sed -i "s/{{$key}}/${value}/g" $file
        done
        return 0
    fi
    if [ -d $file ];then
        for f in `ls $file`
        do
            replace_files "${file}/${f}"
        done
    fi
    return 0
}

rm -fr $target
mkdir -p $target

cp -r configs $target
cp -r scripts $target
cp -r addons $target
cd $target

echo "====替换变量列表===="
while read line;do
    if [ "${line:0:1}" == "#" -o "${line:0:1}" == "" ];then
        continue;
    fi
    key=${line/=*/}
    value=${line#*=}
    echo "$key=$value"
    kvs["$key"]="$value"
done < ../global-config.properties

echo -e "\n====替换脚本===="
replace_files scripts

echo -e "\n====替换配置文件===="
replace_files configs
replace_files addons

echo "配置生成成功，位置: `pwd`"
