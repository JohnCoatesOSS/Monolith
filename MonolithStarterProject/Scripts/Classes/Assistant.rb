#!/usr/bin/env ruby
require 'json'
STDOUT.sync = true
debuggingAssistant = false

class Assistant
  def initialize()
    @classesDirectory = File.expand_path(File.dirname(__FILE__))
    @scriptsDirectory = File.expand_path(@classesDirectory + "/../")
    @projectDirectory = File.expand_path(@scriptsDirectory + "/../")
    @externalDirectory = File.join(@projectDirectory, "External")
    @scriptsJSONpath = File.join(@scriptsDirectory, "scripts.json")
    @remoteProjectDirectory = "https://raw.githubusercontent.com/JohnCoates/Monolith/master/MonolithStarterProject"
  end

  def readConfig()
    # read config.json
    configFilename = "config.json"
    @configFilepath = File.join(@scriptsDirectory, configFilename)
    config = JSON.parse(File.read(@configFilepath))
    @config = config
  end

  # returns true if scripts were updated
  def runAutoUpdateAsNeeded()
    shouldAutoUpdateScript = @config['shouldAutoUpdateScript']
    if !shouldAutoUpdateScript
      return false
    end

    currentTimestamp = Time.now.to_i
    lastUpdateCheck = @config['lastUpdateCheck']
    checkUpdatesEveryXHours = @config['checkUpdatesEveryXHours']
    checkUpdatesEveryXSeconds = checkUpdatesEveryXHours * 3600
    secondsSinceLastUpdateCheck = currentTimestamp - lastUpdateCheck

    returnValue = false
    if secondsSinceLastUpdateCheck > checkUpdatesEveryXSeconds
      returnValue = ensureScriptsAreUpdated()
      @config['lastUpdateCheck'] = currentTimestamp
      saveConfig()
    end

    return returnValue
  end

  def saveConfig()
    File.open(@configFilepath, "w") do |fileHandle|
      prettyOutput = JSON.pretty_generate(@config)
      fileHandle.write(prettyOutput)
    end
  end

  # returns true if scripts were updated
  def ensureScriptsAreUpdated()
    scriptsJSON = JSON.parse(File.read(@scriptsJSONpath))
    currentVersion = scriptsJSON['currentScriptsVersion']

    puts "Checking for an update to Monolith Scripts. Configure this in Scripts/config.json"
    remoteScriptsJSON = remoteScriptsJSONContents()
    remoteVersion = remoteScriptsJSON['currentScriptsVersion']

    if Gem::Version.new(remoteVersion) > Gem::Version.new(currentVersion)
      puts "Version #{remoteVersion} of Monolith Scripts are available. You have #{currentVersion}"
      puts "Installing new version"
      if downloadNewScripts(scriptsJSON, remoteScriptsJSON)
        buildCRC32sForScripts(scriptsJSON)
        return true
      end
    end

    # signify no scripts were updated
    return false
  end

  # returns true if scripts were updated
  def downloadNewScripts(scriptsJSON, remoteScriptsJSON)
    remoteScripts = remoteScriptsJSON['scripts']
    remoteCRC32Hashes = remoteScriptsJSON['crc32']
    localCRC32Hashes = scriptsJSON['crc32']

    # buffer writes so that scripts are left
    # in a half updated state
    pendingWrites = {}

    remoteScripts.each do |scriptPath|
      localPath = File.join(@projectDirectory, scriptPath)
      remotePath = "#{@remoteProjectDirectory}/#{scriptPath}"

      if File.exists?(localPath) == false
        remoteContents = contentsOfURL(remotePath)
        pendingWrites[localPath] = remoteContents
        puts "New script: #{scriptPath}"
      else
        # puts "Checking CRC for #{scriptPath}"
        localCRC32 = localCRC32Hashes[scriptPath]
        remoteCRC32 = remoteCRC32Hashes[scriptPath]

        if localCRC32 != remoteCRC32
          # check local script to see if we should overwrite it
          # of if it's been modified by user
          currentCRC32 = crc32ForFilePath(localPath)
          if currentCRC32 != localCRC32
            puts "Presenting difference between your version of #{scriptPath} and the new version."
            remoteContents = contentsOfURL(remotePath)

            # write temporary update file to use in diff
            temporaryUpdateFile = "#{localPath}.update"

            overwriteFile(temporaryUpdateFile, remoteContents)
            system "diff \"#{localPath}\" \"#{temporaryUpdateFile}\""

            # delete temporary diff file
            File.delete(temporaryUpdateFile)

            puts "#{scriptPath} has an update available, but you've made changes to it (changes displayed above)"
            puts "Would you like to overwrite your changes with the update? [y/N]"
            response = getUserResponse()
            if response.length == 0 || response[0].downcase != 'y'
              puts "Update cancelled, continuing"
              return false
            else
              testUpdatedFile = "#{localPath}.updated"
              #pendingWrites[testUpdatedFile] = remoteContents
              pendingWrites[localPath] = remoteContents
            end
          else # if file is unchanged (crc32 matches)
            remoteContents = contentsOfURL(remotePath)
            pendingWrites[localPath] = remoteContents
          end # currentCRC32 != localCRC32
        end # localRC32 != remoteCRC32

      end # if File.exists?(localPath) == false
    end # remoteScripts.each do |scriptPath|

    pendingWrites.each do |filePath, contents|
      puts "Writing #{filePath} update."
    end
    puts "Finished updating, continuing"

    # return true to signify scripts were updated
    return true
  end # downloadNewScripts

  def overwriteFile(filePath, contents)
    File.open(filePath, "w") do |fileHandle|
      fileHandle.write contents
    end
  end

  def contentsOfURL(url, redirectLimit = 10)
    require 'net/http'
    uri = URI(url)
    contents = Net::HTTP.get(uri)
    return contents
  end

  def remoteScriptsJSONContents()
    require 'json'
    remoteScriptsJsonPath = "#{@remoteProjectDirectory}/Scripts/scripts.json"
    json = contentsOfURL(remoteScriptsJsonPath)
    parsed = JSON.parse(json)
    return parsed
  end

  def crc32ForFilePath(filePath)
    require 'zlib'
    contents = File.read(filePath)
    return Zlib::crc32(contents)
  end

  def buildCRC32sForScripts(scriptsJSON)
    scripts = scriptsJSON['scripts']
    crc32Hashes = {}

    scripts.each do |scriptPath|
      filePath = File.join(@projectDirectory, scriptPath)
      crc32 = crc32ForFilePath(filePath)
      crc32Hashes[scriptPath] = crc32;
    end

    scriptsJSON['crc32'] = crc32Hashes;

    File.open(@scriptsJSONpath, "w") do |fileHandle|
      fileHandle.write(JSON.pretty_generate(scriptsJSON))
    end

    return scriptsJSON
  end

  # returns latest config
  def ensureConfigIsSetupFromDefault()
    if @config['deviceIP'] == '127.0.0.1'
    	configureConfigJSONFromDefault()
    end

    return @config
  end

  # returns updated config
  def configureConfigJSONFromDefault()
    puts "config.json hasn't been set up yet, let's do that now."
  	puts "Your device MUST be connected to the same Wi-Fi network as this computer"
  	puts "Find your iOS device's IP address by following these steps:"
    puts "1. Open Settings app on your device"
    puts "2. Tap on Wi-Fi"
    puts "3. Tap on your connected network"
    puts "4. Your IP adress will look like 192.168.1.150"
  	puts "Enter your device's IP now:"

  	response = getUserResponse()

  	require "resolv"
  	enteredIP = response.to_s
  	doesResolve = enteredIP =~ Resolv::IPv4::Regex ? true : false
  	while !doesResolve
  		puts "You entered an invalid IP: \"#{enteredIP}\". I'm expecting an IP in a similar format as: 192.168.1.150"
  		response = getUserResponse()

  		enteredIP = response.to_s
  		doesResolve = enteredIP =~ Resolv::IPv4::Regex ? true : false
  	end

  	deviceIP = enteredIP

    File.open(@configFilepath, "w") do |fileHandle|
			@config['deviceIP'] = deviceIP
      fileHandle.write(JSON.pretty_generate(@config))
    end

    deviceName = @config['deviceName']
  	puts "Great, we're using #{deviceIP} for your device's IP"
  	puts "We'll call your device \"#{deviceName}\" for now"
    puts "Feel free to change your device name in Scripts/config.json"
  	puts "You can change your device's IP there too."
  	puts "Press enter to continue building your tweak"
  	response = getUserResponse()

    return @config
  end

  def ensureSSHKeysAreOnDevice(device)
  	if (ensureSSHKeysAreGenerated() == false)
  		installSSHKeysOnDevice(device)
  		return
  	end

  	if !canConnectWithSSHToDevice(device)
  		installSSHKeysOnDevice(device)
  	end
  end
  def getUserResponse()
    STDOUT.flush
  	response = gets || ''
  	response.chomp!
  	return response
  end

  def installSSHKeysOnDevice(device)
    # check for RSA keys
  	sshPublicKeyPath = File.expand_path("~/.ssh/id_rsa.pub")
  	if File.exists?(sshPublicKeyPath) == false
      # check DSA second
      sshPublicKeyPath  = File.expand_path("~/.ssh/id_dsa.pub")
      if File.exists?(sshPublicKeyPath) == false
    		puts "Couldn't find public key at: #{sshPublicKeysPath}, can't continue install!"
    		exit
      end
  	end

  	sshPublicKeyContents = File.read(sshPublicKeyPath)

  	deviceName = device[:name]
  	puts "Your computer's SSH keys need to be installed on your device \"#{deviceName}\" before we can procede."
  	puts "Make sure you have the package \"OpenSSH\" installed on your iOS device. Otherwise open up Cydia now and install it before proceeding."
  	puts "You may get asked for your device's password."
    puts "Hint: The default password is: alpine"
  	# system "ssh -p 22 root@#{device[:ip]} \"area #{appToLaunch}\""


  	require 'open3'
  	deviceIP = device[:ip]
  	command = "ssh -l root -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=yes -o ConnectTimeout=8 #{deviceIP} \"echo -e '\n#{sshPublicKeyContents}' >> ~/.ssh/authorized_keys2\""
  	stdout, stderr, status = Open3.capture3(command)

  	if status.exitstatus != 0
      handleSSHError(stdout, stderr, status, deviceIP)
  		puts "Couldn't connect to device! Try again? [y]/n"
      response = getUserResponse()
  		if response.length == 0 || response[0].downcase != 'n'
  			return installSSHKeysOnDevice(device)
  		else
  			puts "Couldn't install SSH keys, can't continue install!"
  			exit
  		end
  		return false
  	else
  		puts "SSH keys successfully transferred to device, continuing with install!"

      puts "This tweak requires Monolith, so if you don't have it you'll need to install before proceeding."
      puts "Would you like to install Monolith on your device? [y]/n"


      response = getUserResponse()

      if response.length == 0 || response[0].downcase != 'n'
        remoteCommand = 'uiopen "cydia://url/https://cydia.saurik.com/api/share#?source=http://getdelta.co/&package=com.johncoates.monolith"'
        puts "Launching Cydia on your device. Please follow the prompts and then install Monolith."
        puts "If launching fails, open Cydia and add the repo: http://getdelta.co/ then install Monolith from there."
        command = "ssh -l root -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no -o ConnectTimeout=8 #{deviceIP} '#{remoteCommand}'"
        STDOUT.flush
      	require 'open3'
        stdout, stderr, status = Open3.capture3(command)

      	if status.exitstatus != 0
          handleSSHError(stdout, stderr, status, deviceIP)
      	end
        puts "Once you've installed Monolith press enter to continue."

        response = getUserResponse()
      end
  		return true
  	end

  	exit
  end

  def canConnectWithSSHToDevice(device)
    STDOUT.flush
  	require 'open3'
  	deviceIP = device[:ip]
  	command = "ssh -l root -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no -o ConnectTimeout=8 #{deviceIP}"
    puts "Attempting to connect to device, with timeout of 8 seconds"
  	stdout, stderr, status = Open3.capture3(command)

  	if status.exitstatus != 0
      handleSSHError(stdout, stderr, status, deviceIP)
  		return false
  	else
  		puts "can connect!"
  		return true
  	end
  end

  def handleSSHError(stdout, stderr, status, deviceIP)
    puts "SSH response: #{stdout}, #{stderr}"
    puts "SSH exit status: #{status.exitstatus}"

    if stderr.include?('Host is down') || stderr.include?("Operation timed out")
      puts "Connecting to your device timed out."
      puts "There's a few different things that could be wrong"
      puts "-You might need to install OpenSSH. You can install it through Cydia"
      puts "-Your device might have changed IPs. Check if your device's IP is still #{deviceIP}"
      puts "-Your device might not be on the same Wi-Fi as your computer is. Please verify that it is."
      puts "Press enter to exit"
      getUserResponse()
      exit
    end
  end

  # returns whether they were generated before this method was called true/false
  def ensureSSHKeysAreGenerated()
  	sshKeysPath = File.expand_path("~/.ssh/id_rsa")
  	if File.exists?(sshKeysPath) && File.exists?(sshKeysPath + ".pub")
      return true
    else
      secondKeyPath = File.expand_path("~/.ssh/id_dsa")
      if File.exists?(secondKeyPath) && File.exists?(secondKeyPath + ".pub")
        return true
      end
  	end

  	puts "You have no SSH keys generated. These are required for auto-installing your tweak on your device! (Checked #{sshKeysPath})"
  	puts "Would you like to generate SSH keys now? [y]/n"

  	response = getUserResponse

  	if response.length == 0 || response[0].downcase != "n"
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

  # makes sure dpkg is installed, otherwise it exists
  def ensureDPKGInstalled()
  	if whichBinary("dpkg-deb") == nil
      puts "dpkg not detected, please re-download the starter project from https://github.com/JohnCoates/Monolith!"
      puts "You can place the External folder into this current project to fix this issue."
      exit 1
  	end # if dpkg-deb = nil
  end # ensureDPKGInstalled

  # taken from http://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
  def whichBinary(cmd)
  	exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    # add path to External directory
    # in case our enviroment variables aren't set correctly
    envPATH = ENV['PATH'] ? ENV['PATH'] : '/usr/bin/'
    if envPATH.include?(@externalDirectory) == false
      ENV['PATH'] = "#{@externalDirectory}:#{envPATH}"
    end

  	ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
  		exts.each { |ext|
  			exe = File.join(path, "#{cmd}#{ext}")
  			return exe if File.executable?(exe) && !File.directory?(exe)
  		}
  	end
  	return nil
  end
end

if debuggingAssistant == true
  # Debugging
  assistant = Assistant.new()
  assistant.ensureDPKGInstalled
end
