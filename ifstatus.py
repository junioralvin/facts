#!/usr/bin/env python
import os
import commands
interfaces=[]
for x in os.listdir("/sys/class/net"):
    if "Link detected: yes" in commands.getoutput("ethtool %s"%x):
        if x not in interfaces:
            interfaces.append(x)
print "ifup=%s"%(",".join(interfaces))

interfaces=[]
for x in os.listdir("/sys/class/net"):
    if "Link detected: no" in commands.getoutput("ethtool %s"%x):
        if x not in interfaces:
            interfaces.append(x)
print "ifdown=%s"%(",".join(interfaces))

