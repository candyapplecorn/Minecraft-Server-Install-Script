#!/bin/bash

function launchMinecraft(){
	tmux kill-server
	tmux new-session -s user -d "\
	/home/user/java/jre1.8.0_131/bin/java \
	-Xmn2G -Xss4M -Xms4G -Xmx4G \
	-XX:+UseLargePages -XX:+AggressiveOpts \
	-XX:+UseFastAccessorMethods -XX:+OptimizeStringConcat \
	-XX:+UseBiasedLocking -Xincgc -XX:MaxGCPauseMillis=10 \
	-XX:SoftRefLRUPolicyMSPerMB=10000 -XX:+CMSParallelRemarkEnabled \
	-XX:ParallelGCThreads=10 -Djava.net.preferIPv4Stack=true \
	-jar /home/user/minecraft_server.1.12.jar nogui; \ 
	"
}

if (( `ps -C java | wc -l` < 2 )); then 
	launchMinecraft
fi
