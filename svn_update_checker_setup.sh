#!/usr/bin/env bash
cron_text=`crontab -l`
if [ $? -ne 0 ]; then
    echo 'crontab not work, setup failed'; exit 1;
fi;

read -p "svn path: " svn_path
svn_path=`echo "$svn_path" | awk -v home=$HOME '{sub("^~", home); print $0}'`;
if [ ! -d $svn_path ]; then
    echo "path ${svn_path} doesn't exists"; exit 1;
fi;
read -p "svn username(leave empty if not have): " svn_username
if [ -n "$svn_username" ]; then
    read -p "svn password: " svn_password
    local_info=`svn info "${svn_path}" --username $svn_username --password $svn_password`;
else
    local_info=`svn info "${svn_path}"`;
fi;
if [ $? -ne 0 ]; then
    echo "error occured when trying to get local svn info at ${svn_path}.";
    echo "please check local svn repository path is right and you have the right access.";
    exit -1;
fi;
remote_url=`(echo "${local_info}" | grep -i "^repository root" | cut -d' ' -f3-100)`;
if [ -n "$svn_username" ]; then
    remote_info=`svn info "${remote_url}" --username $svn_username --password $svn_password`;
else
    remote_info=`svn info "${remote_url}"`;
fi;
if [ $? -ne 0 ]; then
    echo "error occured when trying to get remote svn info at ${remote_url}.";
    echo "please check remote svn repository URL is right and you have the right access.";
    exit -1;
fi;
local_version=`(echo "${local_info}" | grep -i "^revision" | cut -d' ' -f2-100)`
remote_version=`(echo "${remote_info}" | grep -i "^revision" | cut -d' ' -f2-100)`
echo "current svn repository status:"
echo "  local path: ${svn_path}"
echo "  local version: ${local_version}"
echo "  remote url: ${remote_url}"
echo "  remote version: ${remote_version}"
read -p "Is this ok? y/[n]: " ensure
if [ "$ensure" != "y" ]; then echo "setup cancelled"; exit 0; fi;

if [ ! -d ~/.script ]; then mkdir ~/.script; fi;
wget -P ~/.script https://github.com/chenhuanjie/sources/releases/download/0.0.6/svn_update_checker.sh;
echo "successfully downloaded checker script";
chmod +x ~/.script/svn_update_checker.sh;
if [ $? -ne 0 ]; then
    echo "error occured downloading, setup cancelled"; exit 1;
fi;
echo "path=${svn_path}" >> ~/.script/svn_update_checker.lock;
if [ -z "$svn_username" ]; then
    echo "user=${svn_username}" >> ~/.script/svn_update_checker.lock;
    echo "passwd=${svn_password}" >> ~/.script/svn_update_checker.lock;
fi;
echo "last=${local_version}" >> ~/.script/svn_update_checker.lock;

echo "$cron_text" | grep "^# svn update checker$" > /dev/null 2>&1;
if [ $? -ne 0 ]; then
    cron_header="# svn update checker";
    cron_script="*/5 * * * * ~/.script/svn_update_checker.sh;";
    (echo "$cron_text"; echo "$cron_header"; echo "$cron_script") | crontab -;
    echo "add crontab task successfully";
else
    echo "crontab task already exists";
fi;
