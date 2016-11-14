# raspberry Pi 3 wifi
A Script to make your raspberry pi 3 into a AP(Acess Point). You dont need nothing more,
 just execute this script and you will create a AP from your Raspberry PI 3.
 ![Example](/img/Screenshot from 2016-11-14 01:52:24.png)

#How to use ?
You just need type 
```
sudo bash pifi.sh
```
If you want Disable your AP, just type
```
sudo service hostapd stop
```
And 
```
sudo service hostapd start
```
if you want your AP back.

#Credits
This scrip is a junction of [this](https://github.com/seanmragan/OnionPi/blob/master/pifi.sh) and [this](https://gist.github.com/Lewiscowles1986/fecd4de0b45b2029c390) scripts. 
This script basically put together the best of theses two scripts above.
