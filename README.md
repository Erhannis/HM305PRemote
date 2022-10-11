# hm305p_remote

Control an HM305P/RS310P via zeroconnect (zeroconf) and HM305PControl

![Interface screenshot](screenshot.png?raw=true "Interface")

## Getting Started

Ok, so.<br/>
Have an HM305P benchtop power supply.<br/>
Turn it on and connect it to a computer/pi via usb.<br/>
On that computer, clone https://github.com/Erhannis/HM305PControl/tree/feature/remote_control and run PSUManControlServer.py.<br/>
Run this app, HM305PRemote.<br/>
Click autoconnect, and so forth.<br/>

Notes:
Warning: setting the overprotects does not turn them on.  I haven't found a way to read or write overprotect enable.<br/>
If the connection fails, the UI may not register it, and get into a weird state and you'll have to restart.  It looks like weird internal Dart problems, and I don't feel like trying to fix it, atm.<br/>
There are some improvements that could be made - more values to control, maybe add some slider bars, etc.  This seems sufficient to me, for the moment.  I'm likely to accept reasonable pull requests.<br/>
Sorry it looks kinda gross.  I don't yet know all the ways to beat Flutter's UI system.<br/>
Also, occasionally everything just stops working and I have no idea why.  Sorry; good luck.<br/>
* Try restarting the app, then the phone, then the server, then the computer, then the PSU, then everything.<br/>
* ...Ok, so, read this: https://learn.microsoft.com/en-us/answers/questions/101168/mdns-not-sending-queries-to-the-network.html<br/>
  * TL;DR: on Windows, try disabling and reenabling your wifi *interface*.<br/>
* There may be other problems.  My time on this has run out.<br/>
