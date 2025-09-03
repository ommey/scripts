These scripts will enable a ubuntu lite server to act as a wifi-ethernet router
with automatic dns and dhcp handling. connecting a device to the scripted pis ethernet port will provide it with a internet connection.

pi_wifi_router_01:
SSID and Password are manually typed into the file in order for router to connect to existing wifi and function.

pi_wifi_router_02:
Will prompt user for an SSID and password + some optimization by reducing amount of host addresses pi holds for potential connectors (because pi only has 1 eth port)
