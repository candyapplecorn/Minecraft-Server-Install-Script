# Minecraft Server Install Script

For information about this script, please see: http://wp.me/p7ntqM-E

# Newer, better script: tmux launcher

This script is tiny compared to the older, previous one. When run it:

1. Checks to see if Java is running (Minecraft should be the only Java command on the server)
2. If Java isn't running:
  - kill the tmux server to prevent redundancy and errors
  - start a new, detached tmux session with the command to run the Minecraft server
  
The server operator must add this script to crontab. My crontab job is:

```* * * * * /bin/bash /home/user/tmux-launcher.sh```

Crontab will then run the script every minute. This way, as long as the server itself continues running, Minecraft will restart within one minute of crashing. 
