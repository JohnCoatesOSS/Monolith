require 'fileutils'

deviceIP = "192.168.1.161"

Dir.chdir(File.dirname(__FILE__)) do
  # build project
  target = "Tweak"
  system "xcodebuild", "-target", target, "-configuration", "Release", "build", "CONFIGURATION_BUILD_DIR=release/product", "OBJROOT=release/build"
  
  Dir.chdir("./release") do  
    FileUtils.mkdir_p("./_/Library/Monolith/Plugins/")
    FileUtils.copy_file(src="./product/Tweak.framework/Tweak", dst="./_/Library/Monolith/Plugins/Tweak.dylib")
    
    # copy over control file
    FileUtils.mkdir_p("./_/DEBIAN/")
    FileUtils.copy_file(src="./DEBIAN/control", dst="./_/DEBIAN/control")
    
    filename = "tweak.deb"
    system "dpkg-deb", "-b", "-Zgzip", "_", filename
    
    # transfer deb
    system "scp -P 22 #{filename} root@#{deviceIP}:#{filename}"
    
    # install deb
    system "ssh -p 22 root@#{deviceIP} \"dpkg -i #{filename}\""
    
    # kill the app we're testing
#    system "ssh -p 22 root@#{deviceIP} \"killall MobileStore\""
    
    end
end