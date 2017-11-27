#!/bin/bash

while true; do
	read -s -p "Would you like to do something? " answer
	answer="${answer:-y}"
	case "$answer" in
		[yY] | [yY][Ee][Ss] )
			echo "You chose Yes!"
			echo "I would do something here"
			break;;
		[nN] | [n|N][O|o] )
			echo "You chose No!"; 
			exit;;
		*)
			echo "Invalid input! Enter Yes or No";;
	esac
done
echo "Glad this works"
