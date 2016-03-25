#!bin/bash

#	DO WHAT THE Frak YOU WANT TO PUBLIC LICENSE 
#                    Version 2, December 2004 
#
# Copyright (C) 2016 Joseph Burger <candyapplecorn@gmail.com> 
#
# Everyone is permitted to copy and distribute verbatim or modified 
# copies of this license document, and changing it is allowed as long 
# as the name is changed. 
#
#            DO WHAT THE Frak YOU WANT TO PUBLIC LICENSE 
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
#
#  0. You just DO WHAT THE Frak YOU WANT TO.

# ============================================================================

# The intended user of this script is someone who wants to host a minecraft
# server. Many people who do this just want it done and don't care how, so
# I assume many of the people who will want to use this script might not have
# used Linux/Unix before. Thus I commented almost everything and tried to
# explain how most of it works because I think the majority of people who will 
# use this script are 'nix beginers.

# This is a shell script meant to be executed with
# the bourne-again shell environment (bash), which
# is why it begins with #!bin/bash. That line tells
# the operating system what to execute this script
# with.

# EVERYTHING AFTER A '#', INCLUDING THE '#', IS A COMMENT, AND ISN'T
# RUN BY THE SHELL INTERPRETER. That means most of this file is just
# comments and not actual code. My comments try to explain things.

# ============================================================================

# This script does two things.
# First, it checks to see if the minecraft server is running.
# Then, if the server isn't running, this script starts it.
# The way to use this script is to add it to crontab so
# that cron runs it once every minute or so (running
# a simple `ps | grep` once a minute is no performance penalty!).

# ============================================================================

# To add this script to crontab, assuming you have crontab installed,
# type:
# crontab -e
# this will bring up a selection of text editors. Personally I use
# vim but you can use nano or emacs or whatever you like.
# Then, append this line at the end of the crontab file: (remove the #)

#   All these asterisks tell cron whether to run
#   this script monthly, daily, hourly, etc. I
#   think all *'s makes it minute-ly
#  /
# |         	       Make a dir to hold your server's contents.
# |		       You can do this with this command:
# |		       mkdir ~/minecraftserverdir
# |		      /
# v                  v
# * * * * * cd ~/minecraftserverdir/; bash start.sh
#		^			 ^
#		|			 |
#	        |			  \
#               |			    Run this script.
#               |
#               \ Your home dir. You can get here 
# 	          by entering '$cd' or '$cd ~'

# Edit: The script does this now, if run with the "install" option

# ============================================================================




# ============================================================================
# 	Functions
# ============================================================================
# This is a function. It only runs when called,
# and this is just its definition. In bash, a
# function must be defined before it can be called.
# Some languages, like Javascript, have a feature
# called "hoisting", which lets the programmer place
# a function call in the code PRECEDING the function definition
runifnotrunning () {
	# List all processes and filter all but the one running minecraft
	ps x | egrep "minecraft[^ ]*jar"
	# An alternative command that doesn't use egrep would be
	# ps -C java
	# However this isn't dependable since any java process would show up;
	# We want just minecraft

	# $? returns the return value of the last run command.
	# If the previous command, $ps, returned any processes,
	# $? == 0. However if $ps didn't return a single process,
	# (as in, minecraft isn't running) it will return 1.
	if [ $? != 0 ]
	then
		# Using tmux is great because then the server administrator
		# may attach to the tmux session and run various server
		# commands. To work with tmux, go look up a guide or read
		# its man page.

		# To attach to the session:
		# tmux attach-session -t minecraftserver
		# To detach from the session (without killing the server)
		# ctrl-b : detach
		# To kill the session:
		# tmux kill-session -t minecraftserver

		# Check to see if the tmux session exists
		tmux list-sessions | grep minecraftserver
		if [ $? != 0 ] # If session doesn't exist,
		then
			# Create a detached session.
			tmux new -s minecraftserver -d
		fi
		# Send the command to run the server to the detached session
		tmux send-keys -t minecraftserver "java -Xms1G -Xmx2048M \
		-Djava.net.preferIPv4Stack=true -XX:MaxPermSize=128M \
		-XX:UseSSE=3 -XX:-DisableExplicitGC -XX:+UseParallelOldGC \
		-XX:ParallelGCThreads=4 -XX:+AggressiveOpts \
		-jar ${HOME}/minecraftserver/minecraft_server.*.jar nogui" \
		C-m

	fi
}
#Check if run as root
checksudo () {
	ROOT_UID="0"
	if [ "$UID" -ne "$ROOT_UID" ] ; then
		echo "You must be root to do that!"
		exit 1
	fi
}
# clean out the user's crontab. Needs sudo privilege
clean_crontab() {
	sed -ri '/minecraftserverdir/ d' /var/spool/cron/crontabs/${SUDO_USER}
}

# END functions
# ============================================================================


# ============================================================================
# The Main Program

if [[ $# -eq 0 ]]
then
	runifnotrunning	
elif [[ $# -eq 1 && $1 == "uninstall" ]]
then
	checksudo
	# Check to see if the minecraft server folder exists
	ls ~/minecraftserverdir 2>/dev/null 1>/dev/null
	if [ $? != 0 ]
	then
		echo "${HOME}/minecraftserverdir doesn't exist. Exiting."
	else
		echo "Removing the minecraft server."
		clean_crontab
		find ${HOME} -type d -name minecraftserverdir \
		     2>/dev/null -exec rm -r {} \;
		
	fi;
elif [[ $# -eq 1 && $1 == "install" ]]
then
	checksudo
	# Check to see if the minecraft server folder exists
	ls ~/minecraftserverdir 2>/dev/null 1>/dev/null
	if [ $? == 0 ]
	then
		echo "${HOME}/minecraftserverdir exists. Exiting script."
	# If it doesn't exist:
	else
		# Make the folder to hold the server files
		mkdir ~/minecraftserverdir
		# Find, then copy this script into the new folder
		script=$(find . -type f -name *start.sh 2>/dev/null)
		cp $script ~/minecraftserverdir/
		# Enter the folder.
		cd ~/minecraftserverdir

		# Grab the page source from minecraft.net/download with curl
		# Then use perl as a sed replacement to get the download link
		# and then print that and send it to xargs wget which
		# executes the download.
		curl -s https://minecraft.net/download | \
		perl -lne '/a href="([^\s]+minecraft_server[^\s]+jar)"/ && print $1' | \
		xargs wget

		# First, clean out the user's crontab. Needs sudo privilege
		clean_crontab
		# This will append the cronjob to your crontab.
		# Editing the crontab requires sudo, thus the
		# script will have to be run with sudo if you
		# intend to use this install feature
		echo "* * * * * cd ${HOME}/minecraftserverdir; \
		bash ${HOME}/minecraftserverdir/start.sh" | \
		sudo tee --append /var/spool/cron/crontabs/${SUDO_USER} 1>/dev/null
	fi;
elif [[ $# -eq 1 && $1 == "humor" ]]
then
	fortune | cowsay
elif [[ $# -eq 1 && $1 == "linecount" ]]
then
	echo -n "There are this many lines of code in start.sh: "
	egrep -v "^.*#.*" minecraftserver/start.sh  | sed -r /^s*$/d | wc -l
else
	# This is a heredoc. 
	cat <<'EOF'
Usage: 
	To run the minecraft server:
	bash start.sh
	To install or uninstall:
	sudo bash start.sh [install | uninstall | humor | linecount]
EOF
fi;
