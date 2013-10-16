ContextS-Communication-Stack
============================

The current communication stack for Context S

The networking solution occurs in two parts for the communication between a client iOs device and the OSX program running Context. 

If a user is on the same wireless network as the Context system (the Mac tower), the device will communicate directly through a TCP socket connection. The Mac will broadcast its IP address over Bonjour and once the device receives the IP address they will create a socket connection between each other. This solution is in a rough state in the folder Bonjour prototype. 

In the case that a user is not on the same wireless network as the Mac tower, a middle iOs device will be employed to serve as a middle man for the client's device to send data through into Context. This solution can be seen in the folder Context S File Transfer. 
