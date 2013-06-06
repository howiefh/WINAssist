@echo off
@title ÇÐ»»hostsÎÄ¼þ
if exist C:\Windows\System32\drivers\etc\hosts.ipv4 (
   move C:\Windows\System32\drivers\etc\hosts C:\Windows\System32\drivers\etc\hosts.ipv6
   move C:\Windows\System32\drivers\etc\hosts.ipv4 C:\Windows\System32\drivers\etc\hosts
) else (
   move C:\Windows\System32\drivers\etc\hosts C:\Windows\System32\drivers\etc\hosts.ipv4
   move C:\Windows\System32\drivers\etc\hosts.ipv6 C:\Windows\System32\drivers\etc\hosts
)