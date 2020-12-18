#!/bin/bash

while getopts n:k:h:p:c:u:o:d: flag
do
    case "${flag}" in
        h) host=${OPTARG};;
        p) pass=${OPTARG};;
        o) port=${OPTARG};;
        u) username=${OPTARG};;
        c) rcfile=${OPTARG};;   
        d) folder=${OPTARG};;
        k) keyspace=${OPTARG};;
    esac
done

mainCmd="./cqlsh "

if [  -z "$keyspace" -o "$keyspace" = " " ]
then
        echo "keyspace is a compulsory parameter"
        exit
fi

if [  -z "$folder" -o "$folder" = " " ]
then
        echo "backup destination is a compulsory parameter"
        exit
fi

if [ ! -z "$host" -a "$host" != " " ]
then 
        mainCmd="${mainCmd} ${host}"    
fi

if [ ! -z "$port" -a "$port" != " " ]
then
        mainCmd="${mainCmd} ${port}"
fi

if [ ! -z "$pass" -a "$pass" != " " ]
then
        mainCmd="${mainCmd} --password ${pass}"
fi

if [ ! -z "$username" -a "$username" != " " ]
then
        mainCmd="${mainCmd} --username ${username}"
fi

if [ ! -z "$rcfile" -a "$rcfile" != " " ]
then
        mainCmd="${mainCmd} --cqlshrc=${rcfile} --ssl"
fi

findTables="${mainCmd} -e \"use ${keyspace}; describe tables;\""
value=$(eval "$findTables")

today=$(date +"%Y-%m-%d-%H-%M")
directory="${folder}/${today}"
if [ -d $directory ]
then
    rm -r $directory
fi

mkdir -p $directory

findSchema="${findTables} -e \"describe ${keyspace};\" > ${directory}/schema.cql"
eval $findSchema

regex='([a-zA-Z_]+)'
while [[ $value =~ $regex ]]; do
     table="${BASH_REMATCH[1]}"
     cmd="${mainCmd} -e \"use ${keyspace}; COPY ${table}  TO '${directory}/${table}.csv';\""
     echo $cmd
     eval $cmd
     value=${value#*"${BASH_REMATCH[1]}"}  
done

location=$(pwd)
zipCmd="cd ${folder}; zip -r ${today}.zip ${today}/*; cd ${location}"
eval $zipCmd
rm -rf ${directory}

keep=20
discard=$(expr $keep - $(ls $folder |wc -l))
if [ $discard -lt 0 ]; then
  ls $folder -Bt|tail $discard|tr '\n' '\0'|xargs -0 printf "${folder}/%b\0"|xargs -0 rm --
fi
