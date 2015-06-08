#!/usr/bin/ruby

# configure with your device's IP
# make sure you can SSH in without a password
# use this tutorial: http://www.priyaontech.com/2012/01/ssh-into-your-jailbroken-idevice-without-a-password/
deviceIP = "192.168.1.153"
configuration = "Release"

require 'fileutils'

# check for dpkg-deb
# add path to homebrew directory
# in case our enviroment variables aren't set correctly
ENV['PATH'] = ENV['PATH'] ? ENV['PATH'] + ':/usr/local/bin/' : "/usr/local/bin/"

# taken from http://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
def which(cmd)
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
    exts.each { |ext|
      exe = File.join(path, "#{cmd}#{ext}")
      return exe if File.executable?(exe) && !File.directory?(exe)
    }
  end
  return nil
end

# taken from http://stackoverflow.com/questions/1939333/how-to-make-a-ruby-string-safe-for-a-filesystem
def sanitizeFilename(filename)
  # Split the name when finding a period which is preceded by some
  # character, and is followed by some character other than a period,
  # if there is no following period that is followed by something
  # other than a period (yeah, confusing, I know)
  fn = filename.split /(?<=.)\.(?=[^.])(?!.*\.[^.])/m

  # We now have one or two parts (depending on whether we could find
  # a suitable period). For each of these parts, replace any unwanted
  # sequence of characters with an underscore
  fn.map! { |s| s.gsub /[^a-z0-9\-]+/i, '_' }

  # Finally, join the parts with a period and return the result
  return fn.join '.'
end

# install dpkg as necessary

if which("dpkg-deb") == nil
  puts "dpkg not detected, install? y/n"
  
  # work-around fix for gets = nil error
  response = gets
  response ||= ''
  response.chomp!
  
  if response[0] == "y"
    if which("brew") == nil
      puts "installing prerequisite: homebrew package manager"
      system "ruby -e \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)\""
    end
    
    puts "installing dpkg with homebrew"
    system "brew install dpkg"

  elsif response[0] == "n"
    puts "install refused: cannot continue with build"
    exit;
  else
    puts "Expected y or n, received: "+response
    puts "cannot continue with build"
  end
end

require 'open3'

def syscall(*cmd)
  begin
    stdout, stderr, status = Open3.capture3(*cmd)
    status.success? && stdout.slice!(0..-(1 + $/.size)) # strip trailing eol
  rescue
  end
end

Dir.chdir(File.dirname(__FILE__)) do

  target = "Tweak"
 xcodeRawBuildSettings = syscall "xcodebuild", "-target", target, "-configuration", configuration, "build", "CONFIGURATION_BUILD_DIR=release/product", "OBJROOT=release/build", "-showBuildSettings"

  # get xcode variables
  # taken from https://gist.github.com/Cocoanetics/6765089
  xcodeBuildSettings = Hash.new
  # pattern for each line
  LINE_PATTERN = Regexp.new(/^\s*(.*?)\s=\s(.*)$/)
  # extract the variables 
  xcodeRawBuildSettings.each_line do |line|
    match = LINE_PATTERN.match(line)        
    #store found variable in hash      
    if (match)
      xcodeBuildSettings[match[1]] = match[2]
    end
  end

  
  executablePath = xcodeBuildSettings['EXECUTABLE_PATH']
  tweakVersion = xcodeBuildSettings['CURRENT_PROJECT_VERSION']
  tweakName = xcodeBuildSettings['PRODUCT_NAME']
    
  if !executablePath
    puts "error: Couldn't read EXECUTABLE_PATH variable"
    exit
  end
  
  if !tweakVersion
    puts "error: Couldn't read CURRENT_PROJECT_VERSION variable"
    exit
  end
  
  if !tweakName
    puts "error: Couldn't read PRODUCT_NAME variable"
    exit
  end
  
  
  # build project
  system "xcodebuild", "-target", target, "-configuration", configuration, "build", "CONFIGURATION_BUILD_DIR=release/product", "OBJROOT=release/build"
  
  Dir.chdir("./release") do  
    # clear folder
    if File.exists?('./_') == true
      FileUtils.rm_r("./_")
    end
  
    FileUtils.mkdir_p("./_/Library/Monolith/Plugins/")
    
    # make tweak name filesystem safe
    tweakNameFilesystem = sanitizeFilename(tweakName)
    
    FileUtils.copy_file(src="./product/#{executablePath}", dst="./_/Library/Monolith/Plugins/#{tweakNameFilesystem}.dylib")
    
    # copy over control file, anything else in DEBIAN folder
    FileUtils.mkdir_p("./_/DEBIAN/")
    FileUtils.cp_r(src="../DEBIAN", dst="./_/")
    
    # remove .DS_Store files
    system "find ./_/ -name '*.DS_Store' -type f -delete"
    
    filename = "#{tweakNameFilesystem}_#{tweakVersion}.deb"
    system "dpkg-deb", "-b", "-Zgzip", "_", filename
    
    # transfer deb
    system "scp -P 22 #{filename} root@#{deviceIP}:#{filename}"
    
    # install deb
    system "ssh -p 22 root@#{deviceIP} \"dpkg -i #{filename}\""
    
    # kill the app we're testing
#    system "ssh -p 22 root@#{deviceIP} \"killall MobileStore\""
    
    end
end