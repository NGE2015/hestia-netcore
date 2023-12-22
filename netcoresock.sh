#!/bin/bash
user=$1
domain=$2
ip=$3
home=$4
docroot=$5
prvdot=$(ps -fu $user | grep "$domain" | cut -c 12-17)
echo $prvdot
mkdir "$home/$user/web/$domain/netcoreapp"
chown -R $user:$user "$home/$user/web/$domain/netcoreapp"
rm $home/$user/web/$domain/netcoreapp/app.sock
kill -9 $prvdot
runuser -l $user -c "cd $home/$user/web/$domain/netcoreapp && nohup /usr/bin/dotnet $home/$user/web/$domain/netcoreapp/app.dll &" > /dev/null
sleep 5
chmod 777 $home/$user/web/$domain/netcoreapp/app.sock


cat > update_shell_file.sh << EOL
##!/bin/bash
# Define your base directories and files
#home="/path/to/home"
#user="your_user"
#domain="your_domain"

file="$home/$user/web/$domain/script/systemctl_script.sh"

# Ask for user input
read -p "Enter the name of the DLL to be initiated (e.g., Project1.dll): " var_project_name
read -p "Enter the desired systemd service name (e.g., ProjectOne): " var_systemd_name

# Check if vars are empty
if [ -z "$var_project_name" ]; then
    echo "var_project_name is empty"
    exit 1
fi

if [ -z "$var_systemd_name" ]; then
    echo "var_systemd_name is empty"
    exit 1
fi

# Update the systemctl_script.sh with the application name
sed -i 's/@ApplicationName=.*/@ApplicationName='"$var_project_name"'/' "$file"

# Move the script file to the systemctl directory
sudo mv "$file" "/etc/systemd/system/$var_systemd_name.service"

# Reload the service files to include the new service
sudo systemctl daemon-reload

# Enable your service on every reboot
sudo systemctl enable "$var_systemd_name.service"

# Start your service
sudo systemctl start "$var_systemd_name.service"

# Check the status of your service
sudo systemctl status "$var_systemd_name.service"
EOL
