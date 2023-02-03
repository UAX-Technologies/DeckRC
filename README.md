# DeckRC
R/C controller made from a Steam Deck
![20221021_172536 - 1RUj71GE-2bwa4CfWqHKKlqXCpW9vNdCr](https://user-images.githubusercontent.com/117246427/199407927-d93827d3-4ad2-4146-a2b1-fe3d4d61b4d2.jpg)

[Video Overview of Early Prototype](https://youtu.be/YzaZdQglow4)

[Flight Demo with Early Prototype](https://youtu.be/_oFQyhxMKOQ)

***Repo Under Construction***


***Project Overview***

The project has a few goals:
1. Open source software to enable anyone to control a vehicle with the Steam Deck (using a wire, WiFi, or other self-developed means).
2. Build instructinos for DIY radio options to allow anyone to build their own fully functional long-range digital drone (Ubiquiti gear, ESP chips, Combine with [Drone Bridge](https://github.com/DroneBridge/DroneBridge)).
3. Support for existing High-power commercial radios (Doodle Labs, Silvus, Persistent Systems, Microhard).
4. Support for commercially developed versions of the product for industrial drone customers (and maybe a low cost version for consumers if the right radio can be found).


***Version History***

v1

-Simple script to install dependancies required to run QGC with full video

-Instrucitons to run QGC

-Instructions to setup joystick using Steam or using sc-controller


***Compatibility***

Currently compatible with any aircraft that uses the Mavlink protocol and can be connected to wirelessly. Some aircraft like the SkyviperV2450 can be connected to directly using built-in wifi for video and controls. Other aircraft may need a radio module or adapter to communicate wirelessly. 


***Radio Modules***

The Steam Deck can supply 7.5W from the USB port. With that power budget in mind, a prototype module using a Doodle Labs NanoOEM radio has been made and tested to over 1km (ran out of room at the field). More details and radio module development is planned.

If you have a radio module you would like to see integrated, please submit an issue/feature request or send an email to the address below.


***Commercial Options***

For commercial support or customized versions (hardware and software) please contact [UAX Technologies](https://uaxtech.com/)
