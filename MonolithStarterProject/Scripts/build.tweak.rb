#!/usr/bin/env ruby
# README:
# CONFIGURE THIS SCRIPT IN config.json FIRST

STDOUT.sync = true
require 'fileutils'
require 'json'

# read config.json
configFilename = "config.json"
configFilepath = File.join(File.dirname(__FILE__), configFilename)
config = JSON.parse(File.read(configFilepath))

deviceIP = config['deviceIP']
deviceName = config['deviceName']

if config['deviceIP'] == '127.0.0.1'
	puts "config.json hasn't been set up yet, let's do that now."
	puts "Your device MUST be connected to the same Wi-Fi network as this computer"
	puts "IPs look like 127.0.0.1, let's find your device's IP."
	puts "Find your iOS device's IP address here: Settings App -> Wi-Fi -> tap current network -> IP Address field"
	puts "Enter your device's IP now:"

	# work-around fix for gets = nil error
	response = gets
	response ||= ''
	response.chomp!

	require "resolv"
	enteredIP = response.to_s
	doesResolve = enteredIP =~ Resolv::IPv4::Regex ? true : false
	while !doesResolve
		puts "You entered an invalid IP: \"#{enteredIP}\". I'm expecting an IP in a similar format as: 127.0.0.1"
		response = gets
		response ||= ''
		response.chomp!

		enteredIP = response.to_s
		doesResolve = enteredIP =~ Resolv::IPv4::Regex ? true : false
	end

	deviceIP = enteredIP

    File.open(configFilepath, "w") do |fileHandle|
			config['deviceIP'] = deviceIP
      fileHandle.write(JSON.pretty_generate(config))
    end

	puts "Great, we're using #{deviceIP} for your device's IP"
	puts "We'll call your device \"#{deviceName}\" for now, but you can change this in config.json"
	puts "Press enter to continue building your tweak"
	response = gets
	response ||= ''
	response.chomp!
end



# returns whether they were generated before this method was called true/false
def ensureSSHKeysAreGenerated()
	sshKeysPath = File.expand_path("~/.ssh/id_rsa")
	if File.exists?(sshKeysPath)
		return true
	end

	puts "You have no SSH keys generated. These are required for auto-installing your tweak on your device! (Checked #{sshKeysPath})"
	puts "Would you like to generate SSH keys now? y/n"

	# work-around fix for gets = nil error
	response = gets
	response ||= ''
	response.chomp!

	if response[0].downcase == "y"
		puts "Generating SSH keys"
		system "ssh-keygen -t rsa -f ~/.ssh/id_rsa -N \"\" -q"
		if File.exists?(sshKeysPath) == false
			puts "SSH keys generation failed. Cannot continue with device install."
			exit
		else
			puts "SSH keys have been generated!"
			return false
		end
	else
		puts "SSH keys generation refused, cannot continue with device install"
		exit
	end
end

# configure with your device's IP
# device = {name: '📱 iPhone 5', ip:'192.168.1.153'}
device = {name: deviceName, ip:deviceIP}
configuration = "Release"

shouldInstallOnDevice = TRUE
# in case we want to turn off device install quickly, uncomment the following line
# shouldInstallOnDevice = FALSE

shouldBuildPackage = TRUE
# in case we want to turn off package building quickly, uncomment the following line
#shouldBuildPackage = FALSE

appToRestart = "SpringBoard"

shouldReboot = FALSE
# in case we want to turn on rebooting quickly, uncomment the following line
#shouldReboot = TRUE

# if we're testing in the simulator leave this true
# NOTE: LEAVE THIS OFF FOR NOW, THIS FEATURE WILL BE IN A FUTURE RELEASE
shouldTargetSimulator = FALSE
shouldLaunchSimulator = FALSE

# build tools
projectDirectory = File.expand_path(File.dirname(__FILE__  ) + "/../")
scriptsDirectory = projectDirectory + "/Scripts"
classesDirectory = scriptsDirectory + "/Classes"
allClassesPath = classesDirectory + "/All"
require allClassesPath

# make sure dpkg is installed before doing anything else
# we need this to be able to build a .deb file
ensureDPKGInstalled

configuration = Configuration.new(
	defaultBuildFolder:"#{projectDirectory}/Release",
	defaultBuildConfiguration:"Release",
	defaultTarget:"Tweak" ,
	defaultProjectDirectory:projectDirectory,
	defaultShouldInstallOnDevice: shouldInstallOnDevice,
	defaultShouldBuildPackage: shouldBuildPackage,
	defaultAppToTerminate: appToRestart,
	defaultDevice: device
)

deviceBuild = XcodeBuild.new(projectDirectory:projectDirectory,
														target:configuration.target,
														configuration:configuration.buildConfiguration,
														sdk:"iphoneos",
														buildFolder:"#{configuration.buildFolder}/Device")
# build device
if deviceBuild.build == false
	exit
end
if shouldTargetSimulator
	simulatorBuild = XcodeBuild.new(projectDirectory:projectDirectory,
															target:configuration.target,
															configuration:configuration.buildConfiguration,
															sdk:"iphonesimulator",
															buildFolder:"#{configuration.buildFolder}/Simulator")
	# build simulator
	if simulatorBuild.build == false
		exit
	end
end

tweakName = deviceBuild.buildSetting 'PRODUCT_NAME'

plistFilePath = deviceBuild.buildSetting 'INFOPLIST_FILE'
plistFilePath = projectDirectory + "/#{plistFilePath}"

plist = XcodePlist.new plistFilePath
shortVersion = plist.property "CFBundleShortVersionString"
buildVersion = plist.property "CFBundleVersion"
tweakVersion = "#{shortVersion}-#{buildVersion}"

if !shortVersion
	puts "error: Couldn't read CFBundleShortVersionString from #{plistFilePath}"
	exit
end

if !buildVersion
	puts "error: Couldn't read CFBundleVersion from #{plistFilePath}"
	exit
end

if !tweakName
	puts "error: Couldn't read PRODUCT_NAME variable"
	exit
end

# update control file
controlFilepath = projectDirectory + "/layout/DEBIAN/control"
controlContents = File.read(controlFilepath)
controlContents.gsub!(/(Version:).*/i, "\\1 #{tweakVersion}")
open(controlFilepath, 'w') { |fileHandle|
	fileHandle.puts controlContents
}

Dir.chdir(configuration.buildFolder) do
	stagingDirectory = File.expand_path("#{configuration.buildFolder}/_")
	packaging = Packaging.new(stagingDirectory:stagingDirectory, installationDevice:configuration.device)

	# clear staging folder
	packaging.clearStaging

	executablePath = deviceBuild.buildSetting 'EXECUTABLE_PATH'
	installationFolder = "/Library/Monolith/Plugins/"
	packaging.createStagingDirectoryIfDoesntExist installationFolder
	deviceBinary = "#{deviceBuild.buildFolder}/#{executablePath}"

	# sign with entitlements
	entilementsPath = "#{projectDirectory}/Resources/Entitlements.plist"
	if signBinary(deviceBinary, entilementsPath) == false
		puts "failed to sign binary @ #{deviceBinary}"
		exit 1;
	end

	# make tweak name filesystem safe
	tweakNameFilesystem = sanitizeFilename(tweakName)

	installationPath = "/Library/Monolith/Plugins/#{tweakNameFilesystem}.dylib"

	# copy tweak to staging
	if shouldTargetSimulator
		simulatorBinary = "#{simulatorBuild.buildFolder}/#{executablePath}"
		packaging.lipo(inputFiles:[deviceBinary, simulatorBinary], installationPath:installationPath)
	else
		packaging.copyFileToInstallationDirectory(filePath:deviceBinary,
                                            installationPath: installationPath)
	end

	binaryStagingPath = packaging.stagingPathForInstallationPath installationPath

	if configuration.shouldBuildPackage
		# copy over layout contents
		packaging.copyLayoutFolderContents projectDirectory + "/layout"
		version = tweakVersion

		# filename
		filename = "#{tweakNameFilesystem}_#{version}.deb"

		packaging.buildPackage filename

		if configuration.shouldInstallOnDevice
			# make sure we can actually install on device
			ensureSSHKeysAreOnDevice(device)

			packaging.installOnDevice

			if shouldReboot
				packaging.rebootDevice
			# kill the app we're testing
			else
				if configuration.appToTerminate
					packaging.terminateApp configuration.appToTerminate
				end # app to terminate

				if configuration.appToLaunch
					packaging.launchApp configuration.appToLaunch
				end # app to launch
			end # should reboot
		end # device install

		# show package in finder
		packagePath = File.expand_path(filename)
  	system "open -R \"#{packagePath}\""

		if shouldLaunchSimulator
			require 'pathname'
			monolithFrameworkPath = nil

			# find Monolith.framework in framework search paths
			frameworkPaths = deviceBuild.buildSetting 'FRAMEWORK_SEARCH_PATHS'
			splitFrameworkPaths = frameworkPaths.split(/\s(?=(?:[^"]|"[^"]*")*$)/)
			splitFrameworkPaths.each do |frameworkFolder|
				# remove quotes
				frameworkFolder.gsub!(/\A"|"\Z/, '')

				# check for tilde
				if frameworkFolder[0,1] == '~'
					frameworkFolder = File.expand_path(frameworkFolder)
				end

				path = Pathname.new(frameworkFolder)

				# resolve relative path
				if path.relative?
					projectPath = Pathname.new(projectDirectory)
					path = projectPath + path
				end
				frameworkName = Pathname.new("Monolith.framework")
				possiblePath = path + frameworkName

				if File.exists? String(possiblePath)
					monolithFrameworkPath = String(possiblePath)
				end
			end

			monolithFrameworkPath += "/Monolith"
			response = syscall("\"#{scriptsDirectory}/run.simulator.sh\" \"#{monolithFrameworkPath}\"")
			puts response

		end # launch simulator

	 end # build package
end # build folder
