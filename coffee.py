#!/usr/bin/env python

import subprocess

jsoutput = subprocess.Popen(['coffee', '-cp', 'filesystem.coffee'], stdout=subprocess.PIPE).communicate()[0]
jsfile = open('filesystem.js', 'w')

for line in jsoutput.split('\n'):
	line.replace('getter', 'get ')
	print line
	jsfile.write(line + '\n')

jsfile.close()

