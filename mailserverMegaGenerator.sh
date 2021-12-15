#!/bin/sh
CONFIGDIR="/var/lib/mailservermega"
MOUNTDIR="$CONFIGDIR/mnt"
RCLONECONFDIR="$CONFIGDIR/rclone"
MAILFILE="$CONFIGDIR/generated-emails.txt"
DMSPATH="/opt/docker-mailserver"
DMSDATA="$DMSPATH/docker-data/dms/mail-data"
DMSDOMAIN="example.com"
MAILSEARCHPATH="$DMSDATA/$DMSDOMAIN"

#prechecks

mkdir -p $MOUNTDIR/merged
mkdir -p $RCLONECONFDIR

is_mounted() {
    mount | awk -v DIR="$1" '{if ($3 == DIR) { exit 0}} ENDFILE{exit -1}'
}

usage() {
		echo "Available options: "
                echo "  -a : add new account(s)"
                echo "  -r : remove and delete single account"
                echo "  -p : purge and delete all accounts"
                echo "  -f : fix and then delete non working mega accounts"
                echo "  -e : enable all working mega mounts"
                echo "  -d : disable all mega mounts"
                echo "  -m : mount all working mega accounts"
                echo "  -u : umount all mega accounts"
                echo "  -h : show this help"
}

if [ $# -eq 0 ]
  then
    echo "No argument provided: "
    usage
fi

for arg in "$@"; do
shift
case "$arg" in 

	-a)
		echo "Enter the number of the accounts you wish to create:"
		read COUNT 
		re='^[0-9]+$'
		if ! [[ $COUNT =~ $re ]] ; then
   			echo "Error: Not a number" >&2; exit 1
		fi
		for i in $(seq $COUNT); do
			#name=$(/usr/local/bin/genRndUser)
			#pass=$(/usr/local/bin/genRndPass)
		
	        	name=$(tr -dc a-z0-9 </dev/urandom | head -c $(shuf -i 16-24 -n 1) ; echo '')
			pass=$(tr -dc A-Za-z0-9 </dev/urandom | head -c $(shuf -i 16-24 -n 1) ; echo '')

	        	#printf -v small "%s" {a..z}
			#printf -v large "%s" {A..Z}
			#printf -v digit "%s" {0..9}
			#special='@#$%^&*+=<>?' # Edit: Single quotes, not double quotes
	
			#get4() {
			#   for s in small large digit special; do
			#      echo "${!s}" | sed 's/./&\n/g' | grep . | shuf | head -1
			#   done| tr -d '\n'
			#}
	
			#pass=$(echo "$(get4)$(cat /dev/urandom | tr -dc 'a-zA-Z0-9$%&%' | fold -w $(shuf -i 8-14 -n 1) | head -n 1)" |
			#   sed 's/./&\n/g' | grep . | shuf | tr -d '\n')
	
	
			user="$name@example.com"
	
			#echo $user
			#echo $pass
	
			cd $DMSPATH
	
			$DMSPATH/setup.sh email add $user $pass

			$DMSPATH/setup.sh quota set $user 50M
	
			echo -e "$user $pass $name 1" >> $MAILFILE

			RCLONEFILE="$RCLONECONFDIR/$name.conf"

			rclonepass=$(/usr/bin/rclone obscure $pass)

			echo -e "[$name]" >> $RCLONEFILE
			echo -e "type = mega" >> $RCLONEFILE	
			echo -e "user = $user" >> $RCLONEFILE
			echo -e "pass = $rclonepass" >> $RCLONEFILE
		 
		        mkdir "$MOUNTDIR/$name"
	
		        path="$MAILSEARCHPATH/$name/cur"
	
			megaregout=$(/usr/bin/megareg --register --scripted --email $user --name $name --password $pass)

			megaverifycmd=${megaregout::-6}

			echo "Now waiting for the confirmation email"

			date1=`date +%s`			

			until [ -f $path/*.mail* ]
			do
				echo -ne "$(date -u --date @$((`date +%s` - $date1)) +%H:%M:%S)\r"
				sleep 1
				echo -ne "$(date -u --date @$((`date +%s` - $date1)) +%H:%M:%S)\r"
				sleep 1
				echo -ne "$(date -u --date @$((`date +%s` - $date1)) +%H:%M:%S)\r"
				sleep 1
				echo -ne "$(date -u --date @$((`date +%s` - $date1)) +%H:%M:%S)\r"
				sleep 1
				echo -ne "$(date -u --date @$((`date +%s` - $date1)) +%H:%M:%S)\r"
                                sleep 1
				echo -ne "$(date -u --date @$((`date +%s` - $date1)) +%H:%M:%S)\r"
                                sleep 1
				/usr/bin/tmux new-session -d -s "mutt" /usr/bin/mutt -f "imaps://$user:$pass@example.com/INBOX"
				echo -ne "$(date -u --date @$((`date +%s` - $date1)) +%H:%M:%S)\r"
                                sleep 1
                                echo -ne "$(date -u --date @$((`date +%s` - $date1)) +%H:%M:%S)\r"
                                sleep 1
                                echo -ne "$(date -u --date @$((`date +%s` - $date1)) +%H:%M:%S)\r"
                                sleep 1
                                echo -ne "$(date -u --date @$((`date +%s` - $date1)) +%H:%M:%S)\r"
                                sleep 1
                                echo -ne "$(date -u --date @$((`date +%s` - $date1)) +%H:%M:%S)\r"
                                sleep 1
				echo -ne "$(date -u --date @$((`date +%s` - $date1)) +%H:%M:%S)\r"
                                sleep 1
				/usr/bin/tmux kill-session -t "mutt"
			done

        		#link="$(cat "$path/*.mail*" | grep '<a id="bottom-button" href="https://mega.nz/#confirm' | sed -e 's/<a /\n<a /g' | sed -e 's/<a .*href=['"'"'"]//' -e 's/["'"'"'].*$//' -e '/^$/ d')"

			link="$(cat $path/*.mail* | grep -m1 https://mega.nz/#confirm | xargs)"
			
			#echo "$megaregout"

			#echo "$megaverifycmd"

			/usr/bin/$megaverifycmd $link

			sudo /bin/systemctl enable rclone-mega@$name.service

			sudo /bin/systemctl start rclone-mega@$name.service

		done
		/usr/local/bin/umountMegaMerged
		/usr/local/bin/mountMegaMerged
		;;
	-r)
		cd $DMSPATH
		#$DMSPATH/setup.sh email list
		cat $MAILFILE
		echo "Choose which email you'd like to delete:"
		read mail
		$DMSPATH/setup.sh email del -y $mail
		name=$(echo $mail | awk '{split($0,a,"@"); print a[1]}')
		rm -rf "$MOUNTDIR/$name"
		rm -rf "$RCLONECONFDIR/$name.conf"
		sudo /bin/systemctl stop rclone-mega@$name.service
                sudo /bin/systemctl disable rclone-mega@$name.service
		/usr/local/bin/umountMegaMerged
                /usr/local/bin/mountMegaMerged
		;;
	-p)
		cd $DMSPATH
		input="$MAILFILE"
		#cat $input
		declare -i lineno=0
		IFS=''
		while read data; do
		  user=$(echo $data | awk '{split($0,a," "); print a[1]}')
		  $DMSPATH/setup.sh email del -y $user
		  let ++lineno
		  sed -i "1 d" "$input"
		  rm -rf "$MOUNTDIR/$user"
		  rm -rf "$RCLONECONFDIR/$user.conf"
	          sudo /bin/systemctl stop rclone-mega@$name.service
	          sudo /bin/systemctl disable rclone-mega@$name.service
		done < "$input"
                /usr/local/bin/umountMegaMerged
		;;
	-f)
		input="$MAILFILE"
                IFS=''
		declare -i lineno=0
                while read data; do
                        name=$(echo $data | awk '{split($0,a," "); print a[3]}')
                        isworking=$(echo $data | awk '{split($0,a," "); print a[4]}')
			path="/var/lib/mailservermega/mnt/$name"
			sudo /usr/local/bin/restartSystemdIfNotRunning rclone-mega@$name.service running
			sleep 10
			let ++lineno
                        if [ $isworking == "0" ] || ! is_mounted $path; then
				sudo /bin/systemctl stop rclone-mega@$name.service
                               	sudo /bin/systemctl disable rclone-mega@$name.service
				rm -rf "$MOUNTDIR/$name"
                  		rm -rf "$RCLONECONFDIR/$name.conf"
				sed -i "1 d" "$input"
			fi
                done < "$input"
		/usr/local/bin/umountMegaMerged
                /usr/local/bin/mountMegaMerged
		;;
	-e)
		input="$MAILFILE"
		IFS=''
		while read data; do
        		name=$(echo $data | awk '{split($0,a," "); print a[3]}')
			isworking=$(echo $data | awk '{split($0,a," "); print a[4]}')
			if [ $isworking == "1" ]; then
				sudo /bin/systemctl enable rclone-mega@$name.service
			fi
		done < "$input"
		;;
	-d)
		input="$MAILFILE"
                IFS=''
                while read data; do
                        name=$(echo $data | awk '{split($0,a," "); print a[3]}')
                        sudo /bin/systemctl disable rclone-mega@$name.service
                done < "$input"
		;;
	-m)
		input="$MAILFILE"
                IFS=''
                while read data; do
                        name=$(echo $data | awk '{split($0,a," "); print a[3]}')
                        isworking=$(echo $data | awk '{split($0,a," "); print a[4]}')
			if [ $isworking == "1" ]; then
				sudo /bin/systemctl restart rclone-mega@$name.service
      			fi
	        done < "$input"
		/usr/local/bin/umountMegaMerged
		/usr/local/bin/mountMegaMerged
		;;
	-u)
		/usr/local/bin/umountMegaMerged
		input="$MAILFILE"
                IFS=''
                while read data; do
                        name=$(echo $data | awk '{split($0,a," "); print a[3]}')
                        sudo /bin/systemctl stop rclone-mega@$name.service
                done < "$input"
		;;
	-h)
		usage
                ;;
	*)
		echo "Wrong argument provided"
		usage
		;;
esac
done
