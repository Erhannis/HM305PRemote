# hm305p_remote

Control an HM305P/RS310P via zeroconnect (zeroconf) and HM305PControl

## Getting Started

Ok, so.
Have an HM305P benchtop power supply.
Turn it on and connect it to a computer/pi via usb.
On that computer, clone https://github.com/Erhannis/HM305PControl/tree/feature/remote_control and run PSUManControlServer.py.
Run this app, HM305PRemote.
Click autoconnect, and so forth.

Notes:
Warning: setting the overprotects does not turn them on.  I haven't found a way to read or write overprotect enable.
If the connection fails, the UI may not register it, and get into a weird state and you'll have to restart.  It looks like weird internal Dart problems, and I don't feel like trying to fix it, atm.
There are some improvements that could be made - more values to control, maybe add some slider bars, etc.  This seems sufficient to me, for the moment.  I'm likely to accept reasonable pull requests.
Sorry it looks kinda gross.  I don't yet know all the ways to beat Flutter's UI system.
Also, occasionally everything just stops working and I have no idea why.  Sorry; good luck. 