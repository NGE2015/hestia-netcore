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
ExecStart=/usr/bin/dotnet "'$home'/'$user'/web/'$domain'/netcoreapp/'$domain'.dll"
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

#copy the script file to the systemctl
mv "$home/$user/web/$domain/script/systemctl_script.sh" /etc/systemd/system/$domain.sh
