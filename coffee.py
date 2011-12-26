#!/usr/bin/env python

import subprocess

jsoutput = subprocess.Popen(['coffee', '-cp', 'filesystem.coffee'], stdout=subprocess.PIPE).communicate()[0]
jsfile = open('filesystem.js', 'w')

jsfile.write('"use strict";\n')

for line in jsoutput.split('\n'):
	line = line.replace('getter_', 'get ').replace('setter_', 'set ')
	print line
	jsfile.write(line + '\n')

jsfile.close()

