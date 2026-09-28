## Experiment on running process (no restart)

Before ![[Pasted image 20260928122628.png]]

After
TODO

## Longterm fix
Fix (I did not apply it):
1. In /etc/docker/daemon.json, change the line to:
"dns": ["100.100.100.100"],
2. Restart Docker: sudo systemctl restart docker. live-restore: true is set, so running containers stay up during the restart.
3. Restart the app so it gets the new resolv.conf: dokku ps:restart connector.
4. Check it: docker exec connector.web.1 cat /etc/resolv.conf should show only 100.100.100.100.