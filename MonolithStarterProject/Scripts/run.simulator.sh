#!/usr/bin/env node


var args = process.argv.slice(2);

monolithPath = args[0]
if (monolithPath == undefined) {
	monolithPath = "/Users/macbook/Dev/Projects/Flex 3/Monolith/Release/Monolith.framework/Monolith"
}


var ioslib = require('ioslib');

var execute = function(command, callback) {
	var exec = require('child_process').exec;
	console.log("running command: " + command);
	exec(command, function(error, stdout, stderr) {
		console.log(error);
		console.log(stderr);
		console.log(stdout);
		if (callback) {
			callback()
		}
	});
}

ioslib.simulator.launch(null, {
	focus: true,
	killIfRunning: false
})
.on('launched', function (msg) {
	console.log('Simulator has launched');
	
	setTimeout(function() {
		execute('xcrun simctl spawn booted launchctl debug system/com.apple.SpringBoard --environment DYLD_INSERT_LIBRARIES="'+monolithPath+'"', function() {
			execute('xcrun simctl spawn booted launchctl stop com.apple.SpringBoard', function() {
				process.exit(0);
			});
		});
	}, 1000);
	
})
.on('appStarted', function (msg) {
	console.log('App has started');
})
.on('log', function (msg) {
	console.log('[LOG] ' + msg);
})
.on('error', function (err) {
	console.error(err);
});