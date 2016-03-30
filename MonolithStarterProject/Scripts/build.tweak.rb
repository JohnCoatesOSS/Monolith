#!/usr/bin/env ruby
# README:
# CONFIGURE THIS SCRIPT IN config.json FIRST

STDOUT.sync = true
require 'fileutils'
require 'json'

# build tools
projectDirectory = File.expand_path(File.dirname(__FILE__) + "/../")
scriptsDirectory = projectDirectory + "/Scripts"
classesDirectory = scriptsDirectory + "/Classes"
allClassesPath = classesDirectory + "/All"
require allClassesPath

# Assistant
assistant = Assistant.new()

# read config
config = assistant.readConfig()

# get updates
if assistant.runAutoUpdateAsNeeded() == true
	# load self so we execute with a fresh script
	load __FILE__
	exit;
end

# run config setup if needed
config = assistant.ensureConfigIsSetupFromDefault()

deviceIP = config['deviceIP']
deviceName = config['deviceName']

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

appToTerminate = "SpringBoard"

shouldReboot = FALSE
# in case we want to turn on rebooting quickly, uncomment the following line
#shouldReboot = TRUE

# if we're testing in the simulator leave this true
# NOTE: LEAVE THIS OFF FOR NOW, THIS FEATURE WILL BE IN A FUTURE RELEASE
shouldTargetSimulator = FALSE
shouldLaunchSimulator = FALSE

# make sure dpkg is installed before doing anything else
# we need this to be able to build a .deb file
assistant.ensureDPKGInstalled

configuration = Configuration.new(
	defaultBuildFolder:"#{projectDirectory}/Release",
	defaultBuildConfiguration:"Release",
	defaultTarget:"Tweak" ,
	defaultProjectDirectory:projectDirectory,
	defaultShouldInstallOnDevice: shouldInstallOnDevice,
	defaultShouldBuildPackage: shouldBuildPackage,
	defaultAppToTerminate: appToTerminate,
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
	packaging = Packaging.new(stagingDirectory:stagingDirectory, installationDevice:configuration.device, assistant:assistant)

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
			assistant.ensureSSHKeysAreOnDevice(device)

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
		if defined?($showBuiltFileInFinder) != nil
			if $showBuiltFileInFinder
				packagePath = File.expand_path(filename)
				system "open -R \"#{packagePath}\""
			end
		end


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

if defined?($preventTerminalFromExiting) != nil
	if $preventTerminalFromExiting
		puts "Finished building. Press enter to exit."
		response = assistant.getUserResponse()
		puts response
	end
end
