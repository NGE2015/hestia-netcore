#!/bin/bash
user=$1
domain=$2
ip=$3
home=$4
docroot=$5
prvdot=$(ps -fu $user | grep dotnet | cut -c 12-17)
mkdir "$home/$user/web/$domain/netcoreapp"
chown -R $user:$user "$home/$user/web/$domain/netcoreapp"
kill -9 $prvdot
runuser -l $user -c "nohup /usr/bin/dorun $home $user $domain &" > /dev/null

#create service

mkdir "$home/$user/web/$domain/script"
cd "$home/$user/web/$domain/script"

cat > systemctl_script.sh << EOL 
[Unit]
Description=$domain application

[Service]
# systemd will run this executable to start the service
# if /usr/bin/dotnet doesn't work, use `which dotnet` to find correct dotnet executable path
ExecStart=dotnet "$home/$user/web/$domain/netcoreapp/@ApplicationName.dll"
# to query logs using journalctl, set a logical name here
SyslogIdentifier= '$domain'

# Use your username to keep things simple.
# If you pick a different user, make sure dotnet and all permissions are set correctly to run the app
# To update permissions, use 'chown yourusername -R /srv/HelloWorld' to take ownership of the folder and files,
#       Use 'chmod +x /srv/HelloWorld/HelloWorld' to allow execution of the executable file
User="$user"

# ensure the service restarts after crashing
Restart=always
# amount of time to wait before restarting the service                        
RestartSec=5   

# This environment variable is necessary when dotnet isn't loaded for the specified user.
# To figure out this value, run 'env | grep DOTNET_ROOT' when dotnet has been loaded into your shell.
Environment=DOTNET_ROOT=/usr/lib64/dotnet

[Install]
WantedBy=multi-user.target
EOL



#Next phase, create a new script to update the the systemctl_script with prompt questions.

cat > update_shell_file.sh << EOL
#Get the dll filename to update the systemctl_script.sh
#Get the desired final name to update the systemctl_script.sh to service and add automatically on the system

#File that will be updated
file="$home/$user/web/$domain/script/systemctl_script.sh"


#fill variables with the necessary data to update the files.
read -p "What is the name of the DLL that should be initiated. Ex:. Project1.dll =" var_project_name
read -p "What is the name the systemd  service name file name should have? Ex:. ProjectOne =" var_systemd_name

#check if vars are empty
if [ $$var_project_name = "" ]; then
    echo var_project_name is empty
    exit 1;
fi

if [ $$var_systemd_name = "" ]; then
    echo var_systemd_name is empty
    exit 1;
fi

#update the systemctl_script.sh
sed -i 's/@ApplicationName=.*/@ApplicationName='$$var_project_name'/' $file

#copy the script file to the systemctl
mv "$home/$user/web/$domain/script/systemctl_script.sh" /etc/systemd/system/$$var_systemd_name.service

#Reload the service files to include the new service.
sudo systemctl daemon-reload

#enable your service on every reboot
sudo systemctl enable $$var_systemd_name.service

#Start your service
sudo systemctl start $$var_systemd_name.service

#check the status of your service
sudo systemctl status $$var_systemd_name.service

EOL

#remove double $$ 
sed -i 's/$$=.*/$$='$/' update_shell_file.sh
