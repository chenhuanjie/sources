#!/usr/bin/env bash
source ~/.bash_profile > /dev/null 2>&1;
source ~/.bashrc > /dev/null 2>&1;
svn_path=`grep "^path=" ~/.script/svn_update_checker.lock | cut -d'=' -f2-100`;
last_notify=`grep "^last=" ~/.script/svn_update_checker.lock | cut -d'=' -f2-100`;
svn_username=`grep "^user=" ~/.script/svn_update_checker.lock | cut -d'=' -f2-100`;
svn_password=`grep "^passwd=" ~/.script/svn_update_checker.lock | cut -d'=' -f2-100`;
if [ ! -d $svn_path ]; then
    echo "path ${svn_path} doesn't exists"; exit 1;
fi;
cd $svn_path;
local_info=`svn info --username $svn_username --password $svn_password`;
if [ $? -ne 0 ]; then
    echo "error occured when trying to get local svn info at ${svn_path}.";
    echo "please check local svn repository path is right and you have the right access.";
    exit -1;
fi;
remote_url=`(echo "${local_info}" | grep -i "^repository root" | cut -d' ' -f3)`;
remote_info=`svn info "${remote_url}" --username $svn_username --password $svn_password`;
if [ $? -ne 0 ]; then
    echo "error occured when trying to get remote svn info at ${remote_url}.";
    echo "please check remote svn repository URL is right and you have the right access.";
    exit -1;
fi;
local_version=`(echo "${local_info}" | grep -i "^revision" | cut -d' ' -f2)`
remote_version=`(echo "${remote_info}" | grep -i "^revision" | cut -d' ' -f2)`
if [[ remote_version -eq last_notify ]]; then exit 0; fi;
if [[ local_version -ne remote_version ]]; then
    /usr/bin/osascript -e "display notification \"your current svn repository is behind remote server by $((remote_version-local_version)) versions\" with title \"svn update checker\"";
fi;
new_info=`(
    cat ~/.script/svn_update_checker.lock | awk -F'=' '{if($1!="last") print $0}';
    echo "last=${remote_version}";
)`;
echo "${new_info}" > ~/.script/svn_update_checker.lock;
