#!/bin/bash

while getopts n:k:h:p:c:u:o:d:s: flag
do
    case "${flag}" in
        h) host=${OPTARG};;
        p) pass=${OPTARG};;
        o) port=${OPTARG};;
        u) username=${OPTARG};;
        c) rcfile=${OPTARG};;   
        d) folder=${OPTARG};;
        k) keyspace=${OPTARG};;
        s) snapshot=${OPTARG};;
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

if [  -z "$snapshot" -o "$snapshot" = " " ]
then
        echo "backup snapshot is a compulsory parameter"
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

directory="${folder}/${snapshot}"

# zipFile=$folder/$snapshot.zip
# if [ ! -f $zipFile ]
#   then
#     echo "The file ${zipFile} does not exist!"
#     exit
#   fi

# rm -rf $folder/$snapshot 2> /dev/null
# location=$(pwd)
# unzipCmd="cd ${folder}; unzip ${zipFile}; cd ${location}"
# eval $unzipCmd

schemaFile=$directory/schema.cql
if [ ! -f "$schemaFile" ]
then
       echo "${schemaFile} does not exist!"
       exit
fi

dropKeyspace="${mainCmd} -e \"drop keyspace ${keyspace}\""
echo $dropKeyspace
output=$(eval "$dropKeyspace")
echo $output >> ../logs/restore.log

createKeyspace="${mainCmd} -e \"SOURCE '${directory}/schema.cql'\" "
echo $createKeyspace
output=$(eval "$createKeyspace")
echo $output >> ../logs/restore.log

regex='\/([a-zA-Z_]+).csv'
for entry in "$directory"/*
do
     value=$entry
     while [[ $value =~ $regex ]]; do
        table="${BASH_REMATCH[1]}"
        cmd="${mainCmd} -e \"use ${keyspace}; COPY ${table}  from '${directory}/${table}.csv'  WITH HEADER = false AND MINBATCHSIZE = 1 AND MAXBATCHSIZE = 1;\""
        echo $cmd
        output=$(eval "$cmd")
        echo $output >> ../logs/restore.log
        value=${value#*"${BASH_REMATCH[1]}"}  
     done
done
