# Filename: tide_harmonics_library_generator_multi.R
# Extract harmonics constituents for tide stations to be used 
# elsewhere. The harmonics Rdata file needs to have been generated by the 
# tide_harmonics_parse.R script already. 
# Files available at https://github.com/millerlp/Tide_calculator
# This version will take in a list of known-good station names and 
# produce a set of libraries. There must be no ambiguities in the 
# name found when searching the database.

# Author: Luke Miller  Sep 9, 2012
###############################################################################

# Load the previously-generated harmonics file that contains data for all 637
# reference sites in North America. These are only for tide reference stations 
# maintained by NOAA. NOAA generates predictions for a few thousand other 
# 'subordinate' stations that are not included in this data set. The subordinate
# station predictions are generally made by applying a height offset 
# correction and high/low tide time correction to the predictions from the local
# reference station. If you wish to make predictions for one of these 
# subordinate stations you'll still need to first generate predictions for the 
# local reference station (contained in this data set) and apply your 
# corrections afterwards.
load('./data/output.Rdata')


# This is the list of station ID names. Each needs to return only one match
# from the possible stations in the database. All stations need to be in the
# same time zone so that the correct GMToffset value is used. The GMToffset 
# value must always be given for standard time, not daylight savings time in
# the relevant time zone. For example, west coast sites should always have
# a GMToffset value of 8, since Pacific Standard Time is GMT - 8. 

		
GMToffset = 1 # Time zone correction for the site's local standard time zone
			  # relative to Greenwich Mean Time.

df <- read.csv("./data/list.txt",header = TRUE)
stationIDs = df$Station

#stationIDs = c("BAYONNE_BOUCAU",
#		"LE_CROUESTY",
#		"SAINT-MALO"
#		)		
		


# Begin main for loop to cycle through each stationID and generate the
# output library files.
for (stNumber in 1:length(stationIDs)) {
	# Escape any leading parentheses, since those throw off the pattern
	# matching. Replace any instance of ( with \\(, recalling that you need
	# to double-escape the parenthesis symbol in a regular expression with the
	# back slashes.
	stationIDs[stNumber] = gsub("\\(", "\\\\(", stationIDs[stNumber])
	
# Find row index of the desired station in the harms list
	stInd = grep(stationIDs[stNumber], harms$station)
	
	if (length(stInd) < 1) {
		cat('\a No matching site found\n')
		
	}
	
# If there are multiple matches to the stationID given, have the user
# choose the appropriate station.
	if (length(stInd) > 1) {
		cat('There are ', length(stInd), ' matching stations: \n')
		for (i in 1:length(stInd)) {
			cat(i, ': ',harms$station[stInd[i]],'\n', sep = '')
		}
		cat('Please choose the desired station number: \n')
		newstInd = scan(file = '', what = integer(), nmax = 1)
		cat('Using this site: \n')
		cat(harms$station[stInd[newstInd]],'\n')
	}
	
# Remove spaces and other weird characters from station ID so it can be used as 
# a library name
	libname = gsub('[ ]', '', stationIDs[stNumber])
	libname = gsub('[,()&.\\]', '', libname)
	
	
# If the user had to choose a station from the list, extract part of the
# chosen station's name to add to the libname
	if (exists("newstInd")) {
		statname = harms$station[stInd[newstInd]] # get station name
		comloc = regexpr(',', statname) # find location of first comma in name
		statname = substr(statname,1,comloc-1) # extract 1st part of name
		statname = gsub('[ ]','', statname) # remove spaces
		libname = paste(libname,statname,sep = '')
	}
	libname = paste('Tidelib_',libname,sep = '') # Finish building libname
	
	
	if (exists("newstInd")) {
		stInd = stInd[newstInd] # re-assign value to stInd
		rm(newstInd)
	}
# We only want to hold on to starting constants for this year (and future years)
# so we'll get the year index for the current year so that we can dump data from
# earlier years
	curr.date = as.POSIXlt(Sys.time())
	curr.year = curr.date$year + 1900
	year.ind = curr.year - harms$startyear + 1
	
# Specify number of years' worth of starting constants to keep
# The maximum number of years to hold is a function of the available program 
# memory space on the microcontroller (Arduino 328P = 30 kb). Ten years of data
# will consume roughly 10 kb in a minimal example sketch. 
	keep.years = 20
	
# Extract the useful bits from the harms list, keeping only data for the 
# desired tide station.
# NOAA generally reports 37 harmonic constituents for a tide station on their 
# site. These correspond to the first 37 constants listed in the XTide harmonics
# file, and all of the names match up except LDA2 (called LAM2 by NOAA). So we
# can just keep the first 37 constants instead of all 175 from the XTide file.
# These will give predictions that are well within the variance in tide height
# caused by local day-to-day weather conditions. Note that the order of the 
# named constituents differs between the XTide harmonics file and the NOAA 
# web pages.
	harms1 = list(name = harms$name[1:37], 
			speed = harms$speed[1:37],
			startyear = seq(curr.year, (curr.year+keep.years-1)),
			equilarg = harms$equilarg[1:37, year.ind:(year.ind+keep.years-1)],
			nodefactor = harms$nodefactor[1:37, year.ind:(year.ind+keep.years-1)],
			station = harms$station[stInd],
			stationIDnumber = harms$stationIDnumber[stInd],
			units = harms$units[stInd],
			longitude = harms$longitude[stInd],
			latitude = harms$latitude[stInd],
			timezone = harms$timezone[stInd],
			tzfile = harms$tzfile[stInd],
			datum = harms$datum[stInd],
			A = harms$A[stInd,1:37],
			kappa = harms$kappa[stInd,1:37])
	
	attr(harms1$equilarg, 'dimnames')[[1]] = harms1$name
	attr(harms1$equilarg, 'dimnames')[[2]] = harms1$startyear
	attr(harms1$nodefactor, 'dimnames')[[1]] = harms1$name
	attr(harms1$nodefactor, 'dimnames')[[2]] = harms1$startyear
	#########################################################
# Calculate starting values for subsequent years relative to unix epoch
	yr.start = seq(curr.year, (curr.year + keep.years -1))
	yr.unix = as.numeric(as.POSIXct(paste(yr.start,"1","1",sep = '-'))) - 
			as.numeric(as.POSIXct('1970-1-1'))
	
# generate some file names etc. 
	libnamecpp = paste(libname,'.cpp',sep = '')
	libnameh = paste(libname, '.h', sep = '')
	libdirname = paste('./data/arduino_libraries/',libname, sep = '')
	libexample = 'Tide_calculator.ino' # generic name for example Arduino sketch
	libexample2 = 'Tide_calculator_check.ino' # name for another Arduino example sketch
# Create a directory to hold the library output files
	dir.create(libdirname)
# Create a directory to hold the example Arduino file
	dir.create(paste(libdirname,'/examples/Tide_calculator',sep = ''), recursive = TRUE)
	dir.create(paste(libdirname,'/examples/Tide_calculator_check',sep = ''), recursive = TRUE)
	
	####################################################
# Begin sending output to a .cpp source file
	sink(file = paste(libdirname,libnamecpp, sep = '/'), type = 'output', 
			split = TRUE, append = FALSE)
	
	cat('/* ', libnamecpp, '\n')
	cat(' This source file contains a tide calculation function for the site listed\n')
	cat(' below. This file and the associated header file should be placed in the\n')
	cat(' Ardiuno/libraries/ directory inside a single folder.\n')
	cat(' Luke Miller, ')
	cat(strftime(curr.date, format = '%Y-%m-%d'),'\n')
	cat(' http://github.com/millerlp/Tide_calculator\n')
	cat(' Released under the GPL version 3 license.\n')
	cat(' Compiled for Arduino v1.8.8 circa 2019\n\n')
	cat(' The harmonic constituents used here were originally derived from \n')
	cat(' the Center for Operational Oceanic Products and Services (CO-OPS),\n')
	cat(' National Ocean Service (NOS), National Oceanic and Atmospheric \n')
	cat(' Administration, U.S.A.\n')
	cat(' The data were originally processed by David Flater for use with XTide,\n')
	cat(' available at http://www.flaterco.com/xtide/files.html\n')
	cat(' The predictions from this program should not be used for navigation\n')
	cat(' and no accuracy or warranty is given or implied for these tide predictions.\n')
	cat(' */\n')
	cat('#include <Arduino.h>\n')
	cat('#include <Wire.h>\n')
	cat('#include <avr/pgmspace.h>\n')
	cat('#include "RTClib.h" // https://github.com/millerlp/RTClib\n')
	cat('#include "', libnameh,'"\n\n', sep = '')
	cat('unsigned int YearIndx = 0; // Used to index rows in the Equilarg/Nodefactor arrays\n')
	cat('float currHours = 0;          // Elapsed hours since start of year\n')
	cat('const int adjustGMT = ')
	cat(GMToffset)
	cat(';     // Time zone adjustment to get time in GMT.\n')
	cat('//Make sure this is correct for the local standard time of the tide station.\n')
	cat('// 8 = Pacific Standard Time (America/Los_Angeles)\n')
	cat('/* Initialize harmonic constituent arrays. These each hold 37 values for\n')
	cat('the tide site that was extracted using the R scripts:\n')
	cat('tide_harmonics_parse.R and tide_harmonics_library_generator.R\n\n')
	cat("The values are available from NOAA's http://tidesandcurrent.noaa.gov site.\n")
	cat("Kappa here is referred to as 'Phase' on NOAA's site. The order of the\n")
	cat('constituents is shown below in the names. Unfortunately this does not match\n')
	cat("NOAA's order, so you will have to rearrange NOAA's values if you want to\n")
	cat('put new site values in here by hand.\n')
	cat('The Speed, Equilarg and Nodefactor arrays can all stay the same for any site.\n')
	cat('*/\n\n')
	
	cat('// Selected station: ', harms1$station, '\n', sep = '')
	cat('char stationID[] = "', harms1$station, '";\n', sep = '')
	cat('// Selection station ID number: ', harms1$stationIDnumber,'\n',sep='')
	cat('const long stationIDnumber = ', harms1$stationIDnumber, ';\n', sep = '')
	cat("// The 'datum' printed here is the difference between mean sea level and \n") 
	cat("// mean lower low water for the NOAA station. These two values can be \n") 
	cat("// found for NOAA tide reference stations on the tidesandcurrents.noaa.gov\n")
	cat("//  site under the datum page for each station.\n") 
	cat('const float Datum =', harms1$datum, '; // units in feet\n')
	cat('// Harmonic constant names: ')
	cat(harms1$name, sep = ', ')
	cat('\n')
	cat("// These names match the NOAA names, except LDA2 here is LAM2 on NOAA's site\n")
	cat("typedef float PROGMEM prog_float_t; // Need to define this type before use\n")
	cat("// Amp is the amplitude of each of the harmonic constituents for this site\n")
	cat('const prog_float_t Amp[] PROGMEM = {')
	cat(harms1$A, sep = ',')
	cat('};\n')
	cat("// Kappa is the 'modified' or 'adapted' phase lag (Epoch) of each of the \n")
	cat("// harmonic constituents for this site.\n")
	cat('const prog_float_t Kappa[] PROGMEM = {')
	cat(harms1$kappa, sep = ',')
	cat('};\n')
	cat("// Speed is the frequency of the constituent, denoted as little 'a' by Hicks 2006\n")
	cat('const prog_float_t Speed[] PROGMEM = {')
	cat(harms1$speed, sep = ',')
	cat('};\n')
	
	## Create code for a 4 year x 37 constituent array
	cat('const prog_float_t Equilarg[')
	cat(keep.years)
	cat('][37] PROGMEM = { \n')
	for (i in 1:(ncol(harms1$equilarg)-1)) {
		cat('{')
		cat(harms1$equilarg[, i], sep = ',')
		cat('},\n')
	}
	cat('{')
	cat(harms1$equilarg[ ,ncol(harms1$equilarg)], sep = ',')
	cat('} \n };\n')
	cat('\n')
	
	cat('const prog_float_t Nodefactor[')
	cat(keep.years)
	cat('][37] PROGMEM = { \n')
	for (i in 1:(ncol(harms1$nodefactor)-1)) {
		cat('{')
		cat(harms1$nodefactor[, i], sep = ',')
		cat('},\n')
	}
	cat('{')
	cat(harms1$nodefactor[ ,ncol(harms1$nodefactor)], sep = ',')
	cat('} \n };\n')
	cat('\n')
	
	cat('// Define unix time values for the start of each year.\n')
	cat('//                                      ')
	cat(yr.start, sep = '       ')
	cat('\n')
	cat('const unsigned long startSecs[] PROGMEM = {')
	cat(yr.unix, sep = ',')
	cat('};\n\n')
	
	cat('// 1st year of data in the Equilarg/Nodefactor/startSecs arrays.\n')
	cat('const unsigned int startYear = ')
	cat(yr.start[1], ';\n', sep = '')
	cat('//------------------------------------------------------------------\n')
	cat('// Define some variables that will hold extract values from the arrays above\n')
	cat('float currAmp, currSpeed, currNodefactor, currEquilarg, currKappa, tideHeight;\n\n')
	cat("// Constructor function, doesn't do anything special\n")
	cat('TideCalc::TideCalc(void){}\n\n')
	cat('// Return tide station name\n')
	cat('char* TideCalc::returnStationID(void){\n')
	cat('    return stationID;\n')
	cat('}\n\n')
	cat('// Return NOAA tide station ID number\n')
	cat('long TideCalc::returnStationIDnumber(void){\n')
	cat('    return stationIDnumber;\n')
	cat('}\n\n')
	cat('// currentTide calculation function, takes a DateTime object from real time clock\n')
	cat('float TideCalc::currentTide(DateTime now) {\n')
	cat('	// Calculate difference between current year and starting year.\n')	
	cat('	YearIndx = now.year() - startYear;\n ')
	cat('	// Calculate hours since start of current year. Hours = seconds / 3600\n')
	cat('	currHours = (now.unixtime() - pgm_read_dword_near(&startSecs[YearIndx])) / float(3600);\n')
	cat('   // Shift currHours to Greenwich Mean Time\n')
	cat('   currHours = currHours + adjustGMT;\n')
	cat('   // *****************Calculate current tide height*************\n')
	cat('   tideHeight = Datum; // initialize results variable, units of feet.\n')
	cat('   for (int harms = 0; harms < 37; harms++) {\n')
	cat('       // Step through each harmonic constituent, extract the relevant\n')
	cat('       // values of Nodefactor, Amplitude, Equilibrium argument, Kappa\n')
	cat('       // and Speed.\n')
	cat('       currNodefactor = pgm_read_float_near(&Nodefactor[YearIndx][harms]);\n')
	cat(' 		currAmp = pgm_read_float_near(&Amp[harms]);\n')
	cat('       currEquilarg = pgm_read_float_near(&Equilarg[YearIndx][harms]);\n')
	cat('       currKappa = pgm_read_float_near(&Kappa[harms]);\n')
	cat('       currSpeed = pgm_read_float_near(&Speed[harms]);\n')
	cat('    // Calculate each component of the overall tide equation\n')
	cat('    // The currHours value is assumed to be in hours from the start of the\n')
	cat('    // year, in the Greenwich Mean Time zone, not the local time zone.\n')
	cat('       tideHeight = tideHeight + (currNodefactor * currAmp *\n')
	cat('           cos( (currSpeed * currHours + currEquilarg - currKappa) * DEG_TO_RAD));\n')
	cat('    }\n')
	cat('    //******************End of Tide Height calculation*************\n')
	cat('    return tideHeight;  // Output of tideCalc is the tide height, units of feet\n')
	cat('}\n')
# Close the source file
	sink()
	###################################################################
# Open a header file for writing
	sink(file = paste(libdirname,libnameh,sep = '/'), type = 'output', 
			split = TRUE, append = FALSE)
	cat('/* ', libnameh,'\n')
	cat('  A library for calculating the current tide height at \n')
	cat('  ', harms1$station, ', NOAA station ID number ', harms1$stationIDnumber,'\n')
	cat('  Luke Miller, ')
	cat(strftime(curr.date, format = '%Y-%m-%d'),'\n')
	cat('  Compiled under Arduino 1.8.8\n')
	cat('  https://github.com/millerlp/Tide_calculator\n')
	cat(' Released under the GPL version 3 license.\n')
	cat(' The harmonic constituents used here were originally derived from \n')
	cat(' the Center for Operational Oceanic Products and Services (CO-OPS),\n')
	cat(' National Ocean Service (NOS), National Oceanic and Atmospheric \n')
	cat(' Administration, U.S.A.\n')
	cat(' The data were originally processed by David Flater for use with XTide,\n')
	cat(' available at http://www.flaterco.com/xtide/files.html\n')
	cat(' The predictions from this program should not be used for navigation\n')
	cat(' and no accuracy or warranty is given or implied for these tide predictions.\n')
	cat(' It is highly recommended that you verify the output of these predictions\n')
	cat(' against the relevant NOAA tide predictions online.\n')
	cat('*/ \n \n')
	libnameh2 = paste(libname, '_h', sep = '')
	cat('#ifndef ', libnameh2, '\n')
	cat('#define ', libnameh2, '\n')
	cat('#include <Arduino.h>\n')
	cat('#include <avr/pgmspace.h>\n')
	cat('#include <Wire.h>\n')
	cat('#include "RTClib.h" // https://github.com/millerlp/RTClib\n\n')
	cat('class TideCalc {\n')
	cat(' public:\n')
	cat('	 TideCalc();\n')
	cat('    float currentTide(DateTime now); // returns predicted tide for\n')
	cat('    // the supplied date and time. The time should always be given in\n')
	cat('    // the local standard time for the site, not daylight savings time\n')
	cat('    // output units = feet\n')
	cat('    char* returnStationID(void); // NOAA station name\n')
	cat('    long returnStationIDnumber(void); // NOAA station ID number\n')
	cat('};\n')
	cat('#endif')
	sink()
	###################################################################
# Create the keywords.txt file
	sink(file = paste(libdirname,'keywords.txt', sep = '/'), type = 'output',
			split = TRUE, append = FALSE)
	cat('TideCalc    KEYWORD1\n')
	cat('currentTide    KEYWORD2\n')
	cat('returnStationID KEYWORD2\n')
	sink() # Close keywords.txt file
	###################################################################
# Create Tide_calculator.ino example sketch
	sink(file = paste(libdirname,'/examples/Tide_calculator/',libexample,sep = ''), 
			type = 'output', split = TRUE, append = FALSE)
	cat('/* ', libexample, '\n')
	cat(' Copyright (c) ')
	cat(strftime(curr.date, format = '%Y'))
	cat(' Luke Miller\n')
	cat('This code calculates the current tide height for the \n')
	cat('pre-programmed site. It requires a real time clock\n')
	cat('(DS1307 or DS3231 chips) to generate a time for the calculation.\n')
	cat('The site is set by the name of the included library (see line 44 below)\n\n')
	cat('Written under version 1.6.4 of the Arduino IDE.\n\n')
	cat('This program is free software: you can redistribute it and/or modify\n')
	cat('it under the terms of the GNU General Public License as published by\n')
	cat('the Free Software Foundation, either version 3 of the License, or \n')
	cat('(at your option) any later version.\n\n')
	cat('This program is distributed in the hope that it will be useful, \n')
	cat('but WITHOUT ANY WARRANTY; without even the implied warranty of\n')
	cat('MERCHANTIBILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n')
	cat('GNU General Public License for more details.\n\n')
	cat('You should have received a copy of the GNU General Public License\n')
	cat('along with this program. If not, see http://www.gnu.org/licenses/\n\n')
	cat(' The harmonic constituents used here were originally derived from \n')
	cat(' the Center for Operational Oceanic Products and Services (CO-OPS),\n')
	cat(' National Ocean Service (NOS), National Oceanic and Atmospheric \n')
	cat(' Administration, U.S.A.\n')
	cat(' The data were originally processed by David Flater for use with XTide,\n')
	cat(' available at http://www.flaterco.com/xtide/files.html\n')
	cat('As with XTide, the predictions generated by this program should \n')
	cat('NOT be used for navigation, and no accuracy or warranty is given\n')
	cat('or implied for these tide predictions. The chances are pretty good\n')
	cat('that the tide predictions generated here are completely wrong.\n')
	cat('It is highly recommended that you verify the output of these predictions\n')
	cat('against the relevant NOAA tide predictions online.\n')
	cat('*/ \n')
	cat('//--------------------------------------------------------------\n')
	cat('//Initial setup\n')
	cat('//Header files for talking to real time clock\n')
	cat('#include <Wire.h> // Required for RTClib\n')
	cat('#include <SPI.h> // Required for RTClib to compile properly\n')
	cat('#include <RTClib.h> // From https://github.com/millerlp/RTClib\n')
	cat('// Real Time Clock setup\n')
	cat('RTC_DS1307 RTC;  // Uncomment when using this chip\n')
	cat('// RTC_DS3231 RTC; // Uncomment when using this chip\n\n')
	cat('// Tide calculation library setup.\n')
	cat('// Change the library name here to predict for a different site.\n')
	cat('#include "', libnameh, '"\n', sep = '')
	cat('// Other sites available at http://github.com/millerlp/Tide_calculator\n')
	cat('TideCalc myTideCalc; // Create TideCalc object called myTideCalc\n\n')
	cat('int currMinute; // Keep track of current minute value in main loop\n')
	cat('float results; // results holds the output from the tide calc. Units = ft.\n')
	cat('//*******************************************************************\n')
	cat('// Welcome to the setup loop\n')
	cat('void setup(void)\n')
	cat('{\n')
	cat('  Wire.begin();\n')
	cat('  RTC.begin();\n\n')
	cat('  // For debugging output to serial monitor\n')
	cat('  Serial.begin(57600); // Set baud rate to 57600 in serial monitor\n')
	cat('  //*************************************\n')
	cat('  DateTime now = RTC.now(); // Get current time from clock\n')
	cat('  currMinute = now.minute(); // Store current minute value\n')
	cat('  printTime(now);  // Call printTime function to print date/time to serial\n')
	cat('  Serial.println("Calculating tides for: ");\n')
	cat('  Serial.print(myTideCalc.returnStationID());\n')
	cat('  Serial.print(" ");\n')
	cat('  Serial.println(myTideCalc.returnStationIDnumber());\n\n')
	cat('  // Calculate new tide height based on current time\n')
	cat('  results = myTideCalc.currentTide(now);\n\n')
	cat('  //*****************************************\n')
	cat('  // For debugging\n')
	cat('  Serial.print("Tide height: ");\n')
	cat('  Serial.print(results, 3);\n')
	cat('  Serial.println(" ft.");\n')
	cat('  Serial.println(); // blank line\n\n')
	cat('  delay(2000);\n')
	cat('}  // End of setup loop\n\n')
	cat('//********************************************\n')
	cat('// Welcome to the main loop\n')
	cat('void loop(void)\n')
	cat('{\n')
	cat('  // Get current time, store in object "now"\n ')
	cat('  DateTime now = RTC.now();\n')
	cat('  // If it is the start of a new minute, calculate new tide height\n')
	cat('  if (now.minute() != currMinute) { \n')
	cat("  // If now.minute doesn't equal currMinute, a new minute has turned\n")
	cat("  // over, so it's time to update the tide height. We only want to do\n")
	cat('  // this once per minute.\n')
	cat('  currMinute = now.minute(); // update currMinute\n')
	cat('  Serial.println();\n')
	cat('  printTime(now);\n\n')
	cat('  // Calculate new tide height based on current time\n')
	cat('  results = myTideCalc.currentTide(now);\n\n')
	cat('  //*****************************************\n')
	cat('  // For debugging\n')
	cat('  Serial.print("Tide height: ");\n')
	cat('  Serial.print(results, 3);\n')
	cat('  Serial.println(" ft.");\n')
	cat('  Serial.println(); // blank line\n\n')
	cat('  }  // End of if (now.minute() != currMinute) statement \n')
	cat('} // End of main loop \n\n\n')
	cat('//*******************************************\n')
	cat('// Function for printing the current date/time to the\n')
	cat('// serial port in a nicely formatted layout.\n')
	cat('void printTime(DateTime now) {\n')
	cat('  Serial.print(now.year(), DEC);\n')
	cat('  Serial.print("/");\n')
	cat('  Serial.print(now.month(), DEC); \n')
	cat('  Serial.print("/");\n')
	cat('  Serial.print(now.day(), DEC); \n')
	cat('  Serial.print("  ");\n ')
	cat('  Serial.print(now.hour(), DEC); \n')
	cat('  Serial.print(":");\n')
	cat('  if (now.minute() < 10) {\n')
	cat('    Serial.print("0");\n')
	cat('    Serial.print(now.minute());\n')
	cat('   }\n')
	cat('  else if (now.minute() >= 10) {\n')
	cat('    Serial.print(now.minute());\n')
	cat('  }\n')
	cat('  Serial.print(":");\n')
	cat('  if (now.second() < 10) {\n')
	cat('    Serial.print("0");\n')
	cat('    Serial.println(now.second());\n')
	cat('  }\n')
	cat('  else if (now.second() >= 10) {\n')
	cat('    Serial.println(now.second());\n')
	cat('  }\n')
	cat('} // End of printTime function\n')
	cat('//*************************************\n')
	sink() # close Tide_calculator.ino example sketch
	
	###################################################################
# Create Tide_calculator_check.ino example sketch
	sink(file = paste(libdirname,'/examples/Tide_calculator_check/',libexample2,sep = ''), 
			type = 'output', split = TRUE, append = FALSE)
	cat('/* ', libexample2, '\n')
	cat(' Copyright (c) ')
	cat(strftime(curr.date, format = '%Y'))
	cat(' Luke Miller\n')
	cat('This code calculates the tide height for the \n')
	cat('pre-programmed site based on user input date and time. You should not\n')
	cat('need a functional clock chip to run this example, just use the Serial Monitor.\n')
	cat('\n Just open the Serial Monitor and input a date and time using the \n')
	cat('format: YYYY MM DD HH MM SS and send a newline at the end.\n')
	cat('The site is set by the name of the included library (see line 44 below)\n\n')
	cat('Written under version 1.8.8 of the Arduino IDE.\n\n')
	cat('This program is free software: you can redistribute it and/or modify\n')
	cat('it under the terms of the GNU General Public License as published by\n')
	cat('the Free Software Foundation, either version 3 of the License, or \n')
	cat('(at your option) any later version.\n\n')
	cat('This program is distributed in the hope that it will be useful, \n')
	cat('but WITHOUT ANY WARRANTY; without even the implied warranty of\n')
	cat('MERCHANTIBILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n')
	cat('GNU General Public License for more details.\n\n')
	cat('You should have received a copy of the GNU General Public License\n')
	cat('along with this program. If not, see http://www.gnu.org/licenses/\n\n')
	cat(' The harmonic constituents used here were originally derived from \n')
	cat(' the Center for Operational Oceanic Products and Services (CO-OPS),\n')
	cat(' National Ocean Service (NOS), National Oceanic and Atmospheric \n')
	cat(' Administration, U.S.A.\n')
	cat(' The data were originally processed by David Flater for use with XTide,\n')
	cat(' available at http://www.flaterco.com/xtide/files.html\n')
	cat('As with XTide, the predictions generated by this program should \n')
	cat('NOT be used for navigation, and no accuracy or warranty is given\n')
	cat('or implied for these tide predictions. The chances are pretty good\n')
	cat('that the tide predictions generated here are completely wrong.\n')
	cat('It is highly recommended that you verify the output of these predictions\n')
	cat('against the relevant NOAA tide predictions online.\n')
	cat('*/ \n')
	cat('//--------------------------------------------------------------\n')
	cat('//Initial setup\n')
	cat('//Header files for talking to real time clock\n')
	cat('#include <Wire.h> // Required for RTClib\n')
	cat('#include <SPI.h> // Required for RTClib to compile properly\n')
	cat('#include <RTClib.h> // From https://github.com/millerlp/RTClib\n')
	cat('// Declare variables to hold user input\n')
	cat('long myyear;\n')
	cat('long mymonth;\n')
	cat('long myday;\n') 
	cat('long myhour;\n') 
	cat('long myminute;\n') 
	cat('long mysec;\n')
	cat('DateTime myTime;\n')
	cat('// Tide calculation library setup.\n')
	cat('// Change the library name here to predict for a different site.\n')
	cat('#include "', libnameh, '"\n', sep = '')
	cat('// Other sites available at http://github.com/millerlp/Tide_calculator\n')
	cat('TideCalc myTideCalc; // Create TideCalc object called myTideCalc\n\n')
	cat('int currMinute; // Keep track of current minute value in main loop\n')
	cat('float results; // results holds the output from the tide calc. Units = ft.\n')
	cat('//*******************************************************************\n')
	cat('//*******************************************************************\n')
	cat('// Welcome to the setup loop\n')
	cat('void setup(void)\n')
	cat('{\n')
	cat('  // For debugging output to serial monitor\n')
	cat('  Serial.begin(57600); // Set baud rate to 57600 in serial monitor for slow 8MHz micros\n')
	cat('  //*************************************\n')
	cat('  Serial.println("Calculating tides for: ");\n')
	cat('  Serial.print(myTideCalc.returnStationID());\n')
	cat('  Serial.print(" ");\n')
	cat('  Serial.println(myTideCalc.returnStationIDnumber());\n\n')
	cat('  Serial.println("Enter date and time in the format:");\n')
	cat('  Serial.println("   YYYY MM DD HH MM");\n')
	cat('  Serial.println("For example, noon on Jan 1 2019: 2019 1 1 12 00");\n')
	cat('  myTime = DateTime(2019,1,1,12,0,0);\n')
	cat('  results = myTideCalc.currentTide(myTime);\n')
	cat('  Serial.print("Tide height: ");\n')
	cat('  Serial.print(results,3);\n')
	cat('  Serial.println(" ft.");\n')
	cat('  delay(2000);\n')
	cat('}  // End of setup loop\n\n')
	cat('//********************************************\n')
	cat('// Welcome to the main loop\n')
	cat('void loop(void)\n')
	cat('{\n')
	
	cat('// When the user has entered a date and time value in the serial\n')
	cat('// monitor and hit enter, the following section will execute.\n')
	cat('while (Serial.available() > 0) {\n')
	cat('  // Expect the year first\n')
	cat('  myyear = Serial.parseInt();\n')
	cat('  // Expect month next \n')
	cat('  mymonth = Serial.parseInt();\n')
	cat('  // Expect day next\n')
	cat('  myday = Serial.parseInt();\n')
	cat('  // Expect hour next\n')
	cat('  myhour = Serial.parseInt();\n')
	cat('  // Expect minute next\n')
	cat('  myminute = Serial.parseInt();\n')
	cat('\n')  
	cat('  // When the enter symbol newline comes along, convert the \n')
	cat('  // values to a DateTime object and set the clock\n')
	cat("  if (Serial.read() == '\\n'){\n")
	cat('    myTime = DateTime(myyear,mymonth,myday,myhour,myminute,0);\n')
	cat('    printTime(myTime);\n')
	cat('    // Calculate new tide height based on current time\n')
	cat('    results = myTideCalc.currentTide(myTime);\n')
	cat('    Serial.print("Tide height: ");\n')
	cat('    Serial.print(results,3);\n')
	cat('    Serial.println(" ft.");\n\n')
	cat('    }\n')
	cat('  }  // end of while loop\n')
	cat('}  // end of main loop\n')
	cat('//*******************************************\n')
	cat('// Function for printing the current date/time to the\n')
	cat('// serial port in a nicely formatted layout.\n')
	cat('void printTime(DateTime now) {\n')
	cat('  Serial.print(now.year(), DEC);\n')
	cat('  Serial.print("-");\n')
	cat('  Serial.print(now.month(), DEC); \n')
	cat('  Serial.print("-");\n')
	cat('  Serial.print(now.day(), DEC); \n')
	cat('  Serial.print("  ");\n ')
	cat('  Serial.print(now.hour(), DEC); \n')
	cat('  Serial.print(":");\n')
	cat('  if (now.minute() < 10) {\n')
	cat('    Serial.print("0");\n')
	cat('    Serial.print(now.minute());\n')
	cat('   }\n')
	cat('  else if (now.minute() >= 10) {\n')
	cat('    Serial.print(now.minute());\n')
	cat('  }\n')
	cat('  Serial.print(":");\n')
	cat('  if (now.second() < 10) {\n')
	cat('    Serial.print("0");\n')
	cat('    Serial.println(now.second());\n')
	cat('  }\n')
	cat('  else if (now.second() >= 10) {\n')
	cat('    Serial.println(now.second());\n')
	cat('  }\n')
	cat('} // End of printTime function\n')
	cat('//*************************************\n')
	sink() # close Tide_calculator_check.ino example sketch
	
} # end of main for loop that cycles through each stationID
