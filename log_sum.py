#!/usr/bin/python

import sys, getopt, operator, datetime
from dateutil.parser import *

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

def resCode(inputFile):
	resDict = dict()
	for line in inputFile:
		columns = line.split(" ")
		statusCode = int(columns[8])
		try:
			resDict[statusCode][0] = resDict[statusCode][0] + 1
			resDict[statusCode][1].add(columns[0])
		except KeyError:
			resDict[statusCode] = [1, {columns[0]}]
			
	resArr = []
	for err, count in sorted(resDict.iteritems(), reverse = True, key=operator.itemgetter(1, 0)):
		for ip in count[1]:
			resArr.append([str(err), ip])
		
	return resArr

def filterStatusCode(inputLines, minInc, maxExc):
	res = []
	for line in inputLines:
		columns = line.split(" ")
		statusCode = int(columns[8])
		if statusCode >= minInc and statusCode < maxExc:
			res.append(line)
	return res

def failResCode(inputFile):
	return resCode(filterStatusCode(inputFile, 400, 600))

def extractDate(row):
	columns = row.split(" ")
	return columns[3] + " " + columns[4]
	
def transformDate(dateString):
	dateString = dateString.replace('/', ' ')
	dateString = dateString[1:-1]
	dateString = dateString[:11] + ' ' + dateString[12:]
	
	return parse(dateString)
	
def calculateLimit(inputFile, days=0, hours=0):
	lastDate = extractDate(inputFile[0])
	
	date = transformDate(lastDate)
	if hours:
		return date - datetime.timedelta(hours=hours)
	else:
		midnight = date.replace(hour=0, minute=0, second=0)
		return midnight - datetime.timedelta(days - 1)
		
	
def filterOnTime(inputLines, timeLimit):
	count = 0
	while True:
		dateStr = extractDate(inputLines[count])
		date = transformDate(dateStr)
		if date < timeLimit:
			break
		count = count + 1
			
	return inputLines[:count]
		
def main(argv):
	timeLimit = "None"
	
	try:
		opts, args = getopt.getopt(argv, "cd:Fh:n:rt2")
	except getopt.GetoptError:
		print usage
		sys.exit(1)
	for opt, arg in opts:
		if opt == "-c":
			func=conn
		elif opt == "-d":
			timeLimit = "Days"
			days = int(arg)
		elif opt == "-F":
			func = failResCode
		elif opt == "-h":
			timeLimit = "Hours"
			hour = int(arg)
		elif opt == "-n":
			print arg
		elif opt == "-r":
			func = resCode
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
	if timeLimit != "None":
		_input = _file.readlines()
		_input.reverse()
		if timeLimit == "Days":
			timeStamp = calculateLimit(_input, days=days)
		else:
			timeStamp = calculateLimit(_input, hours=hour)
		_input = filterOnTime(_input, timeStamp)
		result = func(_input)
	else:
		result = func(_file)
		
	if len(result) == 0:
		exit(0)
		
	ipColWidth = max(len(row[0]) for row in result)
	countColWidth = max(len(str(row[1])) for row in result)
	for item in result:
		print item[0].ljust(ipColWidth) + "  " + str(item[1]).rjust(countColWidth)
	
if __name__ == "__main__":
	main(sys.argv[1:])
