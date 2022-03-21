import platform
import os

'''
print(platform.system())
print(platform.release())
print(platform.version())
print(platform.machine()) # x86_64
print(platform.uname())
print(platform.node()) # archlinux
print(os.name)
'''

result = os.popen('pwd').read()
print(result)
print("home" in result)
