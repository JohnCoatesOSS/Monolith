## Monolith
Monlith is a framework to build iOS tweaks. This repository holds the Monolith framework as well as source code for example tweaks.

## Beta Status
### Please note that Monolith is currently in beta. There's debug logging that you'll see when you hook things, and the API may change.

## Features
* **XCode Integration:** Projects are built straight from XCode. No modification of XCode's internal files are required, everything is native.
* **Simple:** Monolith takes the complication out of building tweaks.

## Documentation

Documentation is being worked on, please check back soon. Watch this project on Github for update notifications.

## Community

- **Find a bug?** [Open an issue](https://github.com/johncoates/Monolith/issues/new). Try to be as specific as possible.
- **Have a feature request** [Open an issue](https://github.com/johncoates/Monolith/issues/new). Tell me why this feature would be useful, and why you and others would want it.


## Building Tweaks

Prerequisites: 

* Building Monolith tweaks requires XCode 6.
* Architectures supported are ARM-64, ARM, and x86-64
* Please note that building for the iOS Simulator requires that you build for the 5s simulator or later, as 32-bit x86 builds aren't supported

I recommend building **Templates/ObjectiveC Tweak** first. Here are the steps:

* Edit **build.rb** with your device's IP at the top
* Open **Objective C Tweak.xcodeproj**
* Build the **Tweak** target to make sure you're not getting any errors
* Open an instance of Terminal, drag **build.rb** in and hit enter to make sure it's working.
* From now on, you can use the **Install Tweak** target to build and install your tweak on your device.

## License

Monolith's license is found at [Monolith.framework/LICENSE.txt](https://github.com/johncoates/Monolith/blob/master/Monolith.framework/LICENSE.txt). Basically you can use Monolith for free as long as your product is free. If you're selling a tweak, then 15% of your sales go to John Coates to fund the development of Monolith.