#!/usr/bin/ruby

require 'fileutils'
require 'open3'

$classesDirectory = File.expand_path(File.dirname(__FILE__))
$scriptsDirectory = File.expand_path($classesDirectory + "/../")
projectDirectory = File.expand_path($scriptsDirectory + "/../")

require "#{$classesDirectory}/Xcode"
require "#{$classesDirectory}/Packaging"
require "#{$classesDirectory}/Configuration"
require "#{$classesDirectory}/Assistant"

def syscall(*cmd)
	begin
		# puts "Syscall: #{cmd}"
		stdout, stderr, status = Open3.capture3(*cmd)
		status.success? && stdout.slice!(0..-(1 + $/.size)) # strip trailing eol
	rescue
		puts "Error with command: #{cmd}"
	end
end

def signBinary(binaryPath, entitlementsPath = nil)
	puts "Signing binary @ #{binaryPath} with #{entitlementsPath}"

	system "codesign -s - --entitlements \"#{entitlementsPath}\" -f \"#{binaryPath}\""
	exitstatus = $?.exitstatus
	if exitstatus != 0
		puts "ERROR: Codesign failed! Stopping build";
		exit 1;
	end
	return true
end

class XcodePlist
	def initialize (plistPath)
		@plistPath = plistPath
	end

	def property(propertyName)
		command = "/usr/libexec/PlistBuddy -c \"Print #{propertyName}\" \"#{@plistPath}\""
		return syscall command
	end

	def setProperty(propertyName, propertyValue)
		command = "/usr/libexec/PlistBuddy -c \"Set :#{propertyName} #{propertyValue}\" \"#{@plistPath}\""
		return syscall command
	end

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

def getUserResponse()
	response = gets
	response ||= ''
	response.chomp!
	return response
end
