#!/usr/bin/ruby
require 'fileutils'

# configure with your device's IP
# make sure you can SSH in without a password
# use this tutorial: http://www.priyaontech.com/2012/01/ssh-into-your-jailbroken-idevice-without-a-password/
device = {name: '📱 iPhone 5', ip:'192.168.1.153'}
configuration = "Release"

shouldInstallOnDevice = TRUE
# in case we want to turn off device install quickly
shouldInstallOnDevice = FALSE

shouldBuildPackage = TRUE
# in case we want to turn off package building quickly
#shouldBuildPackage = FALSE

appToRestart = "SpringBoard"

shouldReboot = FALSE
# in case we want to turn on rebooting quickly
#shouldReboot = TRUE

shouldLaunchSimulator = TRUE

# build tools
projectDirectory = File.expand_path(File.dirname(__FILE__  ) + "/../")
scriptsDirectory = projectDirectory + "/Scripts"
classesDirectory = scriptsDirectory + "/Classes"
allClassesPath = classesDirectory + "/All"
require allClassesPath

ensureDPKGInstalled

configuration = Configuration.new(
	defaultBuildFolder:"#{projectDirectory}/Release",
	defaultBuildConfiguration:"Release",
	defaultTarget:"Tweak" ,
	defaultProjectDirectory:projectDirectory,
	defaultShouldInstallOnDevice: shouldInstallOnDevice,
	defaultShouldBuildPackage: shouldBuildPackage,
	defaultAppToTerminate: "SpringBoard"
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

simulatorBuild = XcodeBuild.new(projectDirectory:projectDirectory,
														target:configuration.target,
														configuration:configuration.buildConfiguration,
														sdk:"iphonesimulator",
														buildFolder:"#{configuration.buildFolder}/Simulator")
# build simulator
if simulatorBuild.build == false
	exit
end

tweakVersion = deviceBuild.buildSetting 'CURRENT_PROJECT_VERSION'
tweakName = deviceBuild.buildSetting 'PRODUCT_NAME'

if !tweakVersion
	puts "error: Couldn't read CURRENT_PROJECT_VERSION variable"
	exit
end

if !tweakName
	puts "error: Couldn't read PRODUCT_NAME variable"
	exit
end


Dir.chdir(configuration.buildFolder) do
	stagingDirectory = File.expand_path("#{configuration.buildFolder}/_")
	packaging = Packaging.new(stagingDirectory:stagingDirectory, installationDevice:configuration.device)

	# clear staging folder
	packaging.clearStaging
	
	executablePath = deviceBuild.buildSetting 'EXECUTABLE_PATH'
	installationFolder = "/Library/Monolith/Plugins/"
	packaging.createStagingDirectoryIfDoesntExist installationFolder
	deviceBinary = "#{deviceBuild.buildFolder}/#{executablePath}"
	simulatorBinary = "#{simulatorBuild.buildFolder}/#{executablePath}"

	# sign with entitlements
	entilementsPath = "#{projectDirectory}/Resources/Entitlements.plist"
	if signBinary(deviceBinary, entilementsPath) == false
		puts "failed to sign binary @ #{deviceBinary}"
		exit 1;
	end

	# make tweak name filesystem safe
	tweakNameFilesystem = sanitizeFilename(tweakName)
	
	installationPath = "/Library/Monolith/Plugins/#{tweakNameFilesystem}.dylib"
	packaging.lipo(inputFiles:[deviceBinary, simulatorBinary], installationPath:installationPath)
	
	binaryStagingPath = packaging.stagingPathForInstallationPath installationPath
	
	if configuration.shouldBuildPackage
		# copy over layout contents
		packaging.copyLayoutFolderContents projectDirectory + "/layout"
		version = deviceBuild.buildSetting 'CURRENT_PROJECT_VERSION'
		
		# filename
		filename = "#{tweakNameFilesystem}_#{version}.deb"

		packaging.buildPackage filename
		
		if configuration.shouldInstallOnDevice
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
