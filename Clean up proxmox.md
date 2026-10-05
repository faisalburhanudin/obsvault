```
ls -la /mnt/inspect
df -h /mnt/inspect          # how full it is
du -sh /mnt/inspect/* 2>/dev/null | sort -h   # what's taking space
total 24
drwxrwxr-x+ 3 root root  4096 Oct 19  2023 .
drwxr-xr-x  4 root root  4096 Oct  4 23:17 ..
drwx------  2 root root 16384 Oct 19  2023 lost+found
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1       3.5T   28K  3.3T   1% /mnt/inspect
16K     /mnt/inspect/lost+found
```

