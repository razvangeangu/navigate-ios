
# Navigate

This is an application that proves indoor navigation capabilities on an iOS device. The research has been conducted by Răzvan Geangu supervised by [Dr. Andrew Coles](https://nms.kcl.ac.uk/andrew.coles/) | Department of Informatics, King’s College London.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

The project is built using Xcode 9 and requires Swift 4 and iOS 11 or later. The Raspberry Pi (RPI) 3 was configured separately and built using Node.Js on a Kali distribution of Linux.

Xcode *for the iOS application*:
```
https://developer.apple.com/xcode/
```

Kali Linux ARM image or other linux distribution *for the Raspberry Pi*:
```
https://www.offensive-security.com/kali-linux-arm-images/
```

Node.JS *for the Raspberry Pi*
```
https://nodejs.org/
```

### Installing
#### Raspberry Pi
1. Clone [this repository](https://github.com/razvangeangu/navigate-server) on the RPI
2. Install Node.JS and [forever](https://github.com/foreverjs/forever)
3. Start RPI server
	```bash
	./bluetooth.sh && forever start index.js
	```

#### iCloud configuration
1. Register for a developer account with Apple
2. Start Xcode and configure the developer account
3. Navigate to [iCloud Dashboard](https://icloud.developer.apple.com/dashboard/)
4. Set the cloud container for the application
5. Run Navigate application using Xcode *(wait for cloud sync to be finished)*
6. Make **recordName** index QUERYABLE for all Record Types *(AccessPoint, Floor, Room, Tile)*
7. Restart Navigate application

## How to use
1. Start Raspberry Pi Server
2. Open Navigate Application on the iOS device
3. Wait for connection to be made
4. Start moving in the building with the Raspberry Pi
5. Set destination
	```
	Double tap anywhere on the map within bounds or select a room from the table view
	```
6. Navigate
	```
	Use the displayed path from the 2D map or tap camera button to enable the Augmented Reality experience
	```

## More information
### Features
* **Positioning**
	* The system estimates the user's **position** by scanning the current Access Points (APs) using the Raspberry Pi and matching them with the offline database. It displays a blue circle on the 2D map where the user is situated
* **Navigation**
	* The 2D map allows the user to **navigate** to any accessible point *(within the bounds of the building)*. By double tapping any spot on the map, the application finds the shortest path using [A* search algorithm](https://en.wikipedia.org/wiki/A*_search_algorithm) computes the distance and time and displays it by smaller blue circles from the *current location* to the selected *destination*
	* The Augmented Reality (AR) button allows the user to navigate using the camera view. The AR experience displays blue circles in the air to be followed to the *selected destination*
* **Gestures**
	* Pan - Allows the user to interact with the 2D map by changing its' position
	* Pinch - Allows the user to interact with the 2D map by changing its' scale/zoom
	* Tap - Allows the user to interact with the 2D map to select the destination for navigation
* **Admin Panel** - can be activated using the search text field. To switch between the application modes use the [SecretCommands](/Navigate/Model/Util/Util.swift) accordingly
	* Enables *Tile, Room, Floor, AccessPoint* editing
	* **Tap Gesture** modified to allow editing the tiles *(Room and tile type must be selected)*
* **Util**
	* Change floors using the picker view
	* Search for rooms in table view
	* Select room as destination by tapping in table view
	* Centre *cameraNode* to *currentLocation*
	* Rotate *cameraNode* accordingly to the *heading* of the device

### Built With

* Xcode, Swift, CloudKit, CoreData, ARKit, CoreLocation, UserNotifications, CoreBluetooth, SpriteKit, UIKit, Photos
* Node.JS

## Versioning

This is version **1.0.0**.

## Authors

* Developer **Răzvan-Gabriel Geangu** - [GitHub](https://github.com/RazvanGeangu), [Personal Website](https://razvangeangu.com/)
* Supervisor **Dr Andrew Coles** - [Personal Website](https://nms.kcl.ac.uk/andrew.coles/)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.