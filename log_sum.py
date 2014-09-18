#!/usr/bin/python

import sys, getopt, operator

usage = sys.argv[0] + " [-n N] [-h H | -d D] (-c | -2 | -r | -F | -t | -f) <filename>"

def conn(inputFile):
	ipDict = dict()
	for line in inputFile:
		columns = line.split(" ")
		try:
			ipDict[columns[0]] = ipDict[columns[0]] + 1
		except KeyError:
			ipDict[columns[0]] = 1
	return sorted(ipDict.iteritems(), reverse = True, key=operator.itemgetter(1))
	

def main(argv):
	try:
		opts, args = getopt.getopt(argv, "cd:Fh:n:rt2")
	except getopt.GetoptError:
		print usage
		sys.exit(1)
	for opt, arg in opts:
		if opt == "-c":
			func=conn
		elif opt == "-d":
			print arg
		elif opt == "-F":
			print "-F"
		elif opt == "-h":
			print arg
		elif opt == "-n":
			print arg
		elif opt == "-r":
			print "-r"
		elif opt == "-t":
			print "-t"
		elif opt == "-2":
			print "-2"
	
	if len(args) == 0:
		inputFile="/dev/stdin"
	elif len(args) == 1:
		if args[0] == '-':
			inputFile="/dev/stdin"
		else:
			inputFile=args[0]
	else:
		print "Invalid arguments"
		print usage
		exit(1)
	_file = open(inputFile, "r")
	result = func(_file)
	ipColWidth = max(len(row[0]) for row in result)
	countColWidth = max(len(str(row[1])) for row in result)
	for item in result:
		print item[0].ljust(ipColWidth) + "  " + str(item[1]).rjust(countColWidth)
	
if __name__ == "__main__":
	main(sys.argv[1:])
