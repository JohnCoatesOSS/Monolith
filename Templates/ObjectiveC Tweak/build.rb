#!/usr/bin/ruby

# configure with your device's IP
# make sure you can SSH in without a password
# use this tutorial: http://www.priyaontech.com/2012/01/ssh-into-your-jailbroken-idevice-without-a-password/
deviceIP = "192.168.1.161"
tweakName = "Monolith Example"

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
  response = gets.chomp
  
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

Dir.chdir(File.dirname(__FILE__)) do
  # build project
  target = "Tweak"
  system "xcodebuild", "-target", target, "-configuration", "Release", "build", "CONFIGURATION_BUILD_DIR=release/product", "OBJROOT=release/build"
  
  Dir.chdir("./release") do  
  # clear folder
    if File.exists?('./_') == true
      FileUtils.rm_r("./_")
    end
  
    FileUtils.mkdir_p("./_/Library/Monolith/Plugins/")
    
    # make tweak name filesystem safe
    tweakNameFilesystem = sanitizeFilename(tweakName)
    
    FileUtils.copy_file(src="./product/Tweak.framework/Tweak", dst="./_/Library/Monolith/Plugins/#{tweakNameFilesystem}.dylib")
    
    # copy over control file
    FileUtils.mkdir_p("./_/DEBIAN/")
    FileUtils.copy_file(src="../DEBIAN/control", dst="./_/DEBIAN/control")
    
    # remove .DS_Store files
    system "find ./_/ -name '*.DS_Store' -type f -delete"
    
    filename = "#{tweakNameFilesystem}.deb"
    system "dpkg-deb", "-b", "-Zgzip", "_", filename
    
    # transfer deb
    system "scp -P 22 #{filename} root@#{deviceIP}:#{filename}"
    
    # install deb
    system "ssh -p 22 root@#{deviceIP} \"dpkg -i #{filename}\""
    
    # kill the app we're testing
#    system "ssh -p 22 root@#{deviceIP} \"killall MobileStore\""
    
    end
end