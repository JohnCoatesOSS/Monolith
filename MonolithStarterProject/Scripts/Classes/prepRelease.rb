# build CRC32s for release
require_relative 'Assistant'

# Update CRC32s before every distribution
assistant = Assistant.new()
scriptsJSON = JSON.parse(File.read(assistant.instance_variable_get(:@scriptsJSONpath)))
assistant.buildCRC32sForScripts(scriptsJSON)
