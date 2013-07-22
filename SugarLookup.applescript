# Usage:
#    /usr/bin/osascript SugarLookup.applescript
#
# Compiling:
#    /usr/bin/osacompile -o SugarLookup.scpt SugarLookup.applescript
#
# Uncomment and run in the Applescript Editor for quick testing
# my handle_string("bug 12345")

#
#
# The main function, logs into Sugar and calls get_entry_list
on sugar_lookup(queryString)
	global app_url
	
	# Load our preferences from the XML file
	try
		set {app_url, SOAP_username, SOAP_password, maxResults} to load_prefs()
	on error error_message
		my_error("Unable to load preferences from XML file: " & error_message)
	end try
	
	# These should be static no matter the instance
	set SOAP_app to app_url & "/service/v4_1/soap.php"
	set method_namespace_URI to "http://www.sugarcrm.com/sugarcrm"
	set SOAP_action to ""
	
	# Login procedure, first we need to md5 our password
	set hashPasswordCmd to "/sbin/md5 -q -s" & SOAP_password
	set hashPassword to do shell script hashPasswordCmd
	
	set the method_parameters to {user_auth:{user_name:SOAP_username, |password|:hashPassword}}
	set method_name to "login"
	
	copy my SOAP_call(SOAP_app, method_name, method_namespace_URI, method_parameters, SOAP_action) to {call_indicator, call_result}
	if the call_indicator is false then
		my_error(call_result)
	else
		# Now that we have a session, we can send our query
		set session_id to |id| of call_result
		set keyword to first word of queryString
		
		try
			set {module, whereClause, queryFields, orderBy} to load_query(keyword)
		on error error_message
			my_error("Unable to find the keyword you specified in the query list: " & error_message)
			return false
		end try
		
		set whereClause to replaceString(whereClause, "{term}", words 2 thru -1 of queryString as string)
		
		set the method_parameters to {session:session_id, module_name:module, query:whereClause, order_by:orderBy, |offset|:0, select_fields:queryFields, link_name_to_fields_array:"", max_results:maxResults, deleted:0, favorites:0}
		
		set method_name to "get_entry_list"
		
		copy my SOAP_call(SOAP_app, method_name, method_namespace_URI, method_parameters, SOAP_action) to {call_indicator, call_result}
		
		if the call_indicator is false then
			my_error("There was a problem making the SOAP call: " & call_result)
			return false
		else
			set recordList to {}
			repeat with entry in entry_list of call_result
				set recordID to ""
				set recordModule to module
				set recordNumber to ""
				set recordName to ""
				set recordStatus to ""
				repeat with field in name_value_list of entry
					if the |name| of field is "id" then
						set recordID to value of field
					else if the |name| of field is "bug_number" or the |name| of field is "case_number" or the |name| of field is "itrequest_number" then
						set recordNumber to value of field
					else if the |name| of field is "name" then
						set recordName to value of field
					else if the |name| of field is "status" then
						set recordStatus to value of field
					end if
				end repeat
				set end of recordList to {recordID, recordModule, recordNumber, recordName, recordStatus}
			end repeat
		end if
	end if
	
	return recordList
end sugar_lookup

#
# LaunchBar support:
#
on handle_string(lbText)
	set recordList to sugar_lookup(lbText)
	
	if the recordList is false then return false
	
	set displayList to "["
	repeat with result in recordList
		set displayList to displayList & create_url(result)
	end repeat
	set displayList to displayList & "]"
	
	tell application "LaunchBar"
		set selection as list to displayList
		activate
	end tell
end handle_string

#
# Launchbar can take a JSON formatted list of urls and titles to display
#
on create_url(result)
	global app_url
	set {recordID, recordModule, recordNumber, recordName, recordStatus} to result
	set recordURL to app_url & "/index.php?action=DetailView&module=" & recordModule & "&record=" & recordID
	set recordTitle to "[" & recordNumber & ":" & recordStatus & "] " & recordName
	
	return "{\"url\": \"" & recordURL & "\", \"title\": \"" & recordTitle & "\"}"
end create_url

#
# QuickSilver Support (Limited)
#
using terms from application "Quicksilver"
	global app_url
	
	on get direct types
		return {"NSStringPboardType"}
	end get direct types
	
	on get argument count
		return 1
	end get argument count
	
	on process text theText
		set recordList to sugar_lookup(theText)
		
		if the recordList is false then return "No matches found."
		
		# Can't display a list in QS, just make a URL for the first result
		set {recordID, recordModule, recordNumber, recordName, recordStatus} to first item of recordList
		set theUrl to app_url & "/index.php?action=DetailView&module=" & recordModule & "&record=" & recordID
		
		set the clipboard to theUrl
		return theUrl
	end process text
end using terms from

#
# Alfred Support (Limited)
#
on run argv
	global app_url
	
	set theText to argv as text
	set recordList to sugar_lookup(theText)
	
	# Can't display a list in Alfred, just make a URL for the first result
	set {recordID, recordModule, recordNumber, recordName, recordStatus} to first item of recordList
	set theUrl to app_url & "/index.php?action=DetailView&module=" & recordModule & "&record=" & recordID
	
	return theUrl
end run

#
# Load various query formats from an xml file in the same directory as the AppleScript
#
on load_prefs()
	tell application "Finder"
		set myPath to container of (path to me) as text
	end tell
	
	set prefsFile to (myPath & "SugarLookupPrefs.xml")
	
	tell application "System Events"
		# Load the defined queries and their keywords
		tell XML element "prefs" of XML element "main" of contents of XML file prefsFile
			set app_url to (value of (XML elements whose name is "app_url")) as string
			set SOAP_username to (value of (XML elements whose name is "user")) as string
			set SOAP_password to (value of (XML elements whose name is "password")) as string
			set maxResults to (value of (XML elements whose name is "max_results")) as string
		end tell
	end tell
	
	return {app_url, SOAP_username, SOAP_password, maxResults}
end load_prefs

#
# Load various query formats from an xml file in the same directory as the AppleScript
#
on load_query(keyword)
	tell application "Finder"
		set myPath to container of (path to me) as text
	end tell
	
	set prefsFile to (myPath & "SugarLookupPrefs.xml")
	
	tell application "System Events"
		# Load the defined queries and their keywords
		tell XML element "queries" of XML element "main" of contents of XML file prefsFile
			repeat with thisElement from 1 to (count of XML elements)
				set xml_keyword to (value of (XML elements whose name is "keyword") of XML element thisElement) as string
				if xml_keyword is keyword then
					# Turn the comma seperated list of fields in the XML value into an AppleScript list
					set xml_module to (value of (XML elements whose name is "module") of XML element thisElement) as string
					set xml_where to (value of (XML elements whose name is "where") of XML element thisElement) as string
					set xml_fields to (value of (XML elements whose name is "fields") of XML element thisElement) as string
					set xml_order to (value of (XML elements whose name is "orderBy") of XML element thisElement) as string
					
					set tid to AppleScript's text item delimiters
					set AppleScript's text item delimiters to ","
					set field_list to text items of xml_fields
					set AppleScript's text item delimiters to tid
					return {xml_module, xml_where, field_list, xml_order}
				end if
			end repeat
		end tell
	end tell
	
	return false
end load_query

#
# ljr (http://applescript.bratis-lover.net/library/string/)
#
on replaceString(theText, oldString, newString)
	local ASTID, theText, oldString, newString, lst
	set ASTID to AppleScript's text item delimiters
	try
		considering case
			set AppleScript's text item delimiters to oldString
			set lst to every text item of theText
			set AppleScript's text item delimiters to newString
			set theText to lst as string
		end considering
		set AppleScript's text item delimiters to ASTID
		return theText
	on error eMsg number eNum
		set AppleScript's text item delimiters to ASTID
		error "Can't replaceString: " & eMsg number eNum
	end try
end replaceString

#
# Simple SOAP wrapper from Apple's developer script examples
#
on my_error(error_message)
	beep
	display dialog "An Error Occured" & return & return & error_message buttons {"Die"} default button 1
end my_error

#
# Simple SOAP wrapper from Apple's developer script examples
#
on SOAP_call(SOAP_app, method_name, method_namespace_URI, method_parameters, SOAP_action)
	try
		using terms from application "http://www.apple.com/placebo"
			tell application SOAP_app
				set this_result to call soap {method name:method_name, method namespace uri:method_namespace_URI, parameters:method_parameters, SOAPAction:SOAP_action}
			end tell
		end using terms from
		return {true, this_result}
	on error error_message
		return {false, error_message}
	end try
end SOAP_call
