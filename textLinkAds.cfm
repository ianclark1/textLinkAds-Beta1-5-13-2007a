<!---
textLinkAds()
COPYRIGHT & LICENSING INFO
-------------------------------------------------------------------

FileCanWrite() and FileLastModified() contributed by Jesse Houwing from the cflib.org UDF libraries.
Copyright 2007 TJ Downes - tdownes@sanative.net - http://www.sanative.net

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

to install this script, cfinclude this file in your pages you desire to display Text Link Ads

use this line of code in your site to output the ads in your preferred location

<cfoutput>#textLinkAds()#</cfoutput>

5/9/2007
removed fileSize() function. Unneeded. Added check for length of XML array. This eliminated an error when an emtpy XML doc was returned.
5/13/20007
removed result attribute from cfhttp tag, also changed output attribute on cffile write action to use cfhttp.filecontent rather than the named result. 
This allows backwards compatbility with CF 6.
--->
<cffunction name="textLinkAds" access="private" returntype="any">
	<cfscript>
		// sets the key generated by TLA
		var inventoryKey = "yout Text Link Ads XML Key";
		// Number of seconds before connection to XML times out (This can be left the way it is).
		var connectionTimeout = 10;
		// the path to the site root. I call this from the root of my site, but you may need to change this
		var thisPath = ExpandPath('.\');
		// Local file to store XML. This file MUST be writable by ColdFusion
		// You should create a blank file and CHMOD it to 666 (or change your Windows file permissions)
		var localXMLFilename = "local_109516.xml";
		// creates the full path to the file
		var fullXMLFilePath = thisPath & "\" & localXMLFilename;
		// sets the referring URL for TLA. You can set this statically or dynamically
		var siteReferrer = "http://" & cgi.SERVER_NAME & cgi.SCRIPT_NAME;
		// the URL to the XML feed on TLA
		var xmlURL = "http://www.text-link-ads.com/xml.php?inventory_key=" & inventoryKey & "&referer=" & urlEncodedFormat(siteReferrer) &  "&user_agent=" & urlEncodedFormat(cgi.HTTP_USER_AGENT);
		// set the status of the XML Request to TLA
		var xmlRequestStatus = "failed";
		// set the xml variable to blank in the event that generating the XML fails
		var xml = "";
		// set the ad content to blank
		var adContent = "";
		// tells script to abort if there are failures
		var abortMission = 0;
		
		// check if the file exists and throw textual error if not
		if(NOT FileExists(fullXMLFilePath)) {
			adContent = "Text Link Ads script error: " & localXMLFilename & " does not exist. Please create a blank file named " & localXMLFilename & ".<br />";
			abortMission = 1;
		}
		// check to ensure xml file is writable
		if(NOT FileCanWrite(fullXMLFilePath)) {
			adContent = adContent & "Text Link Ads script error: " & localXMLFilename & " is not writable. Please set write permissions on " & localXMLFilename;
			abortMission = 1;
		}
	</cfscript>
	
	<cfif abortMission>
		<cfreturn adContent />
		<cfexit />
	</cfif>
	
	<!--- check last modfied date of file and file size. get new XML if needed --->
	<cfif (FileLastModified(fullXMLFilePath) lt DateAdd("s", -3600, now()))>
		<cftry>
			<cfhttp method="get" url="#xmlURL#" timeout="#connectionTimeout#" />
			<cfset xmlRequestStatus = "success" />
			<cfcatch type="any">
				<cfset xmlRequestStatus = "failed" />
			</cfcatch>
		</cftry>
		<!--- write new XML to XML file --->
		<cfif NOT Compare(xmlRequestStatus, "success")>
			<cffile action="write" file="#fullXMLFilePath#" output="#CFHTTP.FileContent#" />
		</cfif>
	</cfif>
	
	<cftry>
		<!--- read XML into memory --->
		<cffile action="read" file="#fullXMLFilePath#" variable="xml" />
		
		<cfcatch type="any">
			<cfset adContent = "cannot read " & localXMLFilename/>
		</cfcatch>
	</cftry>
	
	<!--- create our Text Link Ads HTML --->
	<cfif Len(Trim(xml)) AND IsXML(xml)>
		<cfsavecontent variable="adContent">
			<cfset xml = XMLParse(xml) />
			<cfset items = XMLSearch(xml,"Links/Link") />
			<cfif ArrayLen(items) AND Compare(items[1].xmlchildren[1].xmltext, "http://www.phusor.com")>
			<ul style="list-style: none; padding: 0; width: 100%; border: 0px; border-spacing: 0px; margin: 0; overflow: hidden;">
				<cfloop from="1" to="#ArrayLen(items)#" index="i">
				<li style="display: inline; padding: 0; width: 100%; float: left; clear: none; margin: 0;">
				<span style="margin: 0; font-size: 10px; color: #000000; padding: 3px; width: 100%; display: block;"><cfoutput>#items[i].xmlchildren[3].xmltext#<a style="color: ##FB4A07; font-size: 10px;" href="#items[i].xmlchildren[1].xmltext#">#items[i].xmlchildren[2].xmltext#</a> #items[i].xmlchildren[4].xmltext#</cfoutput></span>
				</li>
				</cfloop>
			</ul>
			</cfif>
		</cfsavecontent>
	<cfelse>
		<cfset adContent = "" />
	</cfif>
	<cfreturn adContent />
</cffunction>
<!--- refer to cflib.org for assitance with any of the functions below --->
<cfscript>
/**
 * FileCanWrite();
 * Checks to see if a file can be written to.
 * 
 * @param filename 	 The name of the file. (Required)
 * @return Returns a boolean. 
 * @author Jesse Houwing (j.houwing@student.utwente.nl) 
 * @version 1, November 14, 2002 
 */
function FileCanWrite(filename){
	var daFile = createObject("java", "java.io.File");
	daFile.init(JavaCast("string", filename));
	return daFile.canWrite();
}

/**
 * Returns the date the file was last modified.
 * 
 * @param filename 	 Name of the file. (Required)
 * @return Returns a date. 
 * @author Jesse Houwing (j.houwing@student.utwente.nl) 
 * @version 1, November 15, 2002 
 */
function FileLastModified(filename){
	var _File =  createObject("java","java.io.File");
	// Calculate adjustments fot timezone and daylightsavindtime
	var _Offset = ((GetTimeZoneInfo().utcHourOffset)+1)*-3600;
	_File.init(JavaCast("string", filename));
	// Date is returned as number of seconds since 1-1-1970
	return DateAdd('s', (Round(_File.lastModified()/1000))+_Offset, CreateDateTime(1970, 1, 1, 0, 0, 0));
}
</cfscript>