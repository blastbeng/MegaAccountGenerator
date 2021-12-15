#!/bin/sh
CONFIGDIR="/var/lib/mailservermega"
MOUNTDIR="$CONFIGDIR/mnt"
MAILFILE="$CONFIGDIR/generated-emails.txt"
DMSPATH="/opt/docker-mailserver"
DMSDATA="$DMSPATH/docker-data/dms/mail-data"
DMSDOMAIN="exampledomain.com"
MAILSEARCHPATH="$DMSDATA/$DMSDOMAIN"

#prechecks

if [ ! -d $CONFIGDIR ] || [ ! -d $MOUNTDIR ]; then
	sudo mkdir -p $MOUNTDIR
	sudo chown -R user:user $CONFIGDIR
fi

echo "Available options: "
echo "  add : add new account(s)"
echo "  del : delete single account"
echo "  delall : delete all accounts"

read OPERATION

case $OPERATION in 

	add)
		echo "Enter the number of the accounts you wish to create:"
		read COUNT 
		re='^[0-9]+$'
		if ! [[ $COUNT =~ $re ]] ; then
   			echo "Error: Not a number" >&2; exit 1
		fi
		for i in $(seq $COUNT); do
		
	        	name=$(tr -dc a-z0-9 </dev/urandom | head -c $(shuf -i 16-24 -n 1) ; echo '')
			pass=$(tr -dc A-Za-z0-9 </dev/urandom | head -c $(shuf -i 16-24 -n 1) ; echo '')
	
	
			user="$name@exampledomain.com"
	
			cd $DMSPATH
	
			$DMSPATH/setup.sh email add $user $pass

			$DMSPATH/setup.sh quota set $user 50M
	
			echo -e "$user $pass $name" >> $MAILFILE
	
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
				/usr/bin/tmux new-session -d -s "mutt" /usr/bin/mutt -f "imaps://$user:$pass@exampledomain.com/INBOX"
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

        		link="$(cat $path/*.mail* | grep -m1 https://mega.nz/#confirm | xargs)"

			/usr/bin/$megaverifycmd $link

			

		done
		;;
	del)
		cd $DMSPATH
		$DMSPATH/setup.sh email list
		echo "Choose which email you'd like to delete:"
		read mail
		$DMSPATH/setup.sh email del -y $mail
		;;
	delall)
		cd $DMSPATH
		input="$MAILFILE"
		declare -i lineno=0
		IFS=''
		while read data; do
		  user=$(echo $data | awk '{split($0,a," "); print a[1]}')
		  $DMSPATH/setup.sh email del -y $user
		  let ++lineno
		  sed -i "1 d" "$input"
		  rm -rf "$MOUNTDIR/$user"
		done < "$input"
		;;
	*)
		echo "Wrong options selected"
		;;
esac
