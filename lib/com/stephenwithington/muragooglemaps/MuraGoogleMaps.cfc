<!---

This file is part of MuraGoogleMaps TM
(c) Stephen J. Withington, Jr. | www.stephenwithington.com

CAREFULLY READ THE ENCLOSED LICENSE AGREEMENT (plugin/license.htm). BY USING THIS SOFTWARE, YOU ARE CONSENTING TO BE BOUND BY AND ARE BECOMING A PARTY TO THIS AGREEMENT. IF YOU DO NOT AGREE TO ALL OF THE TERMS OF THIS AGREEMENT, THEN DO NOT USE THIS SOFTWARE, AND, IF APPLICABLE, RETURN THIS PRODUCT TO THE PLACE OF PURCHASE FOR A FULL REFUND.

--->
<cfcomponent>

	<cfscript>
		variables.instance = structNew();
		variables.instance.pluginConfig = '';
		variables.instance.CSVFile = '';
		variables.instance.XMLFile = '';
		variables.instance.data = '';
		variables.instance.jsLocations = '';
		variables.instance.map = '';
	</cfscript>

	<cffunction name="init" hint="constructor" access="public" returntype="MuraGoogleMaps" output="false">
		<cfargument name="pluginConfig" required="true" />
		<cfargument name="CSVFile" required="false" />
		<cfargument name="XMLFile" required="false" />
		<cfscript>
			if ( StructKeyExists(arguments, 'pluginConfig') ) {
				setPluginConfig(arguments.pluginConfig);
			};
			
			if ( StructKeyExists(arguments, 'CSVFile') ) {
				setCSVFile(arguments.CSVFile);
				setData(readCSVFile(getCSVFile()));
				setMap(getData());
			};
			
			if ( StructKeyExists(arguments, 'XMLFile') ) {
				setXMLFile(arguments.XMLFile);
				setData(readXMLFile(getXMLFile()));
				setMap(getData());
			};
			
			return this;
		</cfscript>
	</cffunction>

	<cffunction name="getMap" access="public" returntype="any">
		<cfreturn variables.instance.map />
	</cffunction>

	<cffunction name="setMap" access="private" returntype="any" output="true">
		<cfargument name="mapData" type="array" required="true" />
		<cfargument name="displayDirections" default="true" type="boolean" required="false" />
		<cfargument name="displayTravelMode" default="true" type="boolean" required="false" />
		<cfargument name="mapHeight" default="400" type="numeric" required="false" />
		<cfargument name="mapInfoWindowMaxWidth" default="300" type="numeric" required="false" />
		<cfargument name="mapType" default="TERRAIN" type="string" required="false" />
		<cfargument name="mapWidth" default="600" type="numeric" required="false" />
		<cfargument name="start" default="Lebanon, KS" type="string" required="false" />
		
		<cfscript>
			var local = StructNew();
			//local.str = "<p><em>Sorry, we don't have any locations to display yet.</em></p>";
			local.str = '';
	
			// default start 'From' for directions
			if ( not structKeyExists(arguments, 'start') ) {
				arguments.start = start;
			};
			
			// validate mapType
			local.validMapTypes = 'ROADMAP,SATELLITE,HYBRID,TERRAIN';
			if ( not listFindNoCase(local.validMapTypes, arguments.mapType) ) {
				arguments.mapType = 'TERRAIN';
			} else {
				uCase(arguments.mapType);
			};
			
			// minimum map width and height attributes
			if ( val(arguments.mapWidth) lt 150 ) {
				arguments.mapWidth = 150;
			};
			if ( val(arguments.mapHeight) lt 100 ) {
				arguments.mapHeight = 100;
			};
		</cfscript>
		<cfsavecontent variable="local.gmapHtmlHeadContent">
			<cfoutput>
				<cfheader name="expires" value="#DateFormat(now(), 'ddd, dd mmm yyyy')# #TimeFormat(now(), 'HH:mm:ss tt')#" />
				<cfheader name="pragma" value="no-cache" />
				<cfheader name="cache-control" value="no-cache, no-store" />
				<style type="text/css">
					##gmapWrapper {font-family:Arial, Helvetica, sans-serif;font-size:10px;margin:0;padding:0;}
					##gmapWrapper form, ##gmapWrapper input, ##gmapWrapper select, ##gmapWrapper textarea {font-family:Arial, Helvetica, sans-serif;font-size:1em;}
					##gmapWrapper label {font-weight:bold;}
					##gmapWrapper ##map_canvas {width:#val(arguments.mapWidth)#px;height:#val(arguments.mapHeight)#px;padding:0;margin:0;}
					##gmapWrapper ##directions_form {width:#val(arguments.mapWidth)#px;padding:1.5em 0.5em 0 0.5em;}
					##gmapWrapper ##directions_panel {width:#val(arguments.mapWidth)#px;}
					##gmapWrapper table.adp-directions {width:100%;}
					##gmapStart {}
					##gmapEnd {}
					##gmapTravelMode {}
					##gmapSubmit {}
				</style>
				<meta name="viewport" content="initial-scale=1.0, user-scalable=no" />
				<meta name="map-generator" content="MuraGoogleMaps, v.0.1" />
				<meta name="map-author" content="Steve Withington; http://www.stephenwithington.com" />
				<script type="text/javascript" src="http://maps.google.com/maps/api/js?sensor=false"></script>
				<script type="text/javascript">
				/* <![CDATA[ */
					window.onload = function() {
						initialize();
					};
					// the locations array formatted from qryLocations
					// each location should be formatted as: ['LocationName',Lat,Lng,ZIndex,'Icon','InfoWindow']
					var locations = [#getJSLocations()#];
					var directionDisplay;
					var directionsService;
					var map;
					var marker;
					var markersArray = ArrayNew(1);
					var infoWindow;
		
					// INIT
					function initialize(){
						directionsDisplay = new google.maps.DirectionsRenderer();
						directionsService = new google.maps.DirectionsService();
		
						// let the map auto-zoom to fit all locations in the viewport
						var bounds = new google.maps.LatLngBounds();
						for (var i=0; i<locations.length; i++) {
							var location = locations[i];
							var point = new google.maps.LatLng(location[1],location[2]);
							bounds.extend(point);
						};
		
						// gather up map options for the constructor					
						var mapOptions = {
							center: bounds.getCenter()
							// mapTypeId opts: ROADMAP, SATELLITE, HYBRID, TERRAIN
							, mapTypeId: google.maps.MapTypeId.#arguments.mapType#
						};
		
						// GMap v3 Constructor
						map = new google.maps.Map(document.getElementById('map_canvas'), mapOptions);
						map.fitBounds(bounds);
		
						// Directions
						directionsDisplay.setMap(map);
						directionsDisplay.setPanel(document.getElementById('directions_panel'));
		
						// Markers/Icons and Info Windows
						setMarkers(map, locations);
					};
		
					// Markers/Icons
					function setMarkers(map, locations) {
						for (var i=0;i<locations.length;i++) {
							var location = locations[i];
							// get the 2nd and 3rd positions of the location array (latitude, longitude)
							var iLatLng = new google.maps.LatLng(location[1], location[2]);
							var marker = new google.maps.Marker({
								position: iLatLng
								, map: map
								, title: location[0]
								, zIndex: location[3]
								, icon: location[4]
							});
							// add an InfoWindow to the marker
							addInfoWindow(marker, location[5]);
						};
					};
		
					// Info Window
					function addInfoWindow(marker, content) {
						var infowindow = new google.maps.InfoWindow({
							content: '<div class="infoWindowWrapper">' + content + '</div>'
							// constrain the width of the infoWindow, otherwise it can expand to the full width of the page
							, maxWidth: #val(arguments.mapInfoWindowMaxWidth)#
						});
						google.maps.event.addListener(marker, 'click', function() {
							infowindow.open(map,marker);
						});
					};
		
					// Directions
					function calcRoute(start, end, mode) {
						if ( mode === undefined ) {
							// DirectionsTravelMode opts: DRIVING, WALKING, BICYCLING
							mode = 'DRIVING';
						};
						var request = {
							origin:start
							, destination:end
							, travelMode:google.maps.DirectionsTravelMode[mode]
						};
						directionsService.route(
							request
							, function(response, status) {
								if (status == google.maps.DirectionsStatus.OK) {
									directionsDisplay.setDirections(response);
								};
							}
						);
					};
				/* ]]> */
				</script>
			</cfoutput>
		</cfsavecontent>
		<cfsavecontent variable="local.str">
			<cfhtmlhead text="#local.gmapHtmlHeadContent#" />
			<cfoutput>
				<div id="gmapWrapper">
					<div id="map_canvas"></div>
					<cfif arguments.displayDirections>
						<div id="directions_form">
							<form name="frmDirections" id="frmDirections" action="##" method="post" onSubmit="calcRoute(this.start.value,this.end.value,this.mode.value); return false;">
								<div id="gmapStart">
									<label for="start">From:</label>
									<input type="text" size="40" id="start" name="start" value="#arguments.start#" />
								</div>
								<div id="gmapEnd">
									<label for="end">To:</label>
									<cfif ArrayLen(arguments.mapData)>
										<select name="end" id="end">
											<cfloop from="1" to="#ArrayLen(arguments.mapData)#" index="i">
												<option value="#arguments.mapData[i][2]#,#arguments.mapData[i][3]#">#arguments.mapData[i][1]#</option></cfloop>
										</select>&nbsp;&nbsp;
										<cfelse>
										<cfloop from="1" to="#ArrayLen(arguments.mapData)#" index="i">
											#arguments.mapData[i][1]# <input type="hidden" name="end" value="#arguments.mapData[i][2]#,#arguments.mapData[i][3]#" />&nbsp;&nbsp;</cfloop>
									</cfif>
								</div>
								<div id="gmapTravelMode">
									<cfif arguments.displayTravelMode>
										<label for="mode">Travel Mode:</label>
										<select name="mode" id="mode">
											<option value="DRIVING">Driving</option>
											<option value="BICYCLING">Bicycling</option>
											<option value="WALKING">Walking</option>
										</select>
										<cfelse>
										<input type="hidden" name="mode" id="mode" value="DRIVING" />
									</cfif>
								</div>
								<div id="gmapSubmit">

									<input type="submit" name="btnSubmit" id="btnSubmit" value="Get Directions!" />
								</div>
							</form>
						</div>
						<div id="directions_panel"></div>
					</cfif>
				</div>
			</cfoutput>
		</cfsavecontent>
		<cfset variables.instance.map = local.str />
	</cffunction>

	<cffunction name="readCSVFile" access="private" output="true" returntype="any">
		<cfargument name="filename" required="true" />
		<cfscript>
			var local = StructNew();
			local.csvData = ArrayNew(1);

			// read in the CSV file
			if ( StructKeyExists(arguments, 'filename') and len(trim(arguments.filename)) ) {
				local.fileReader = Createobject("java","java.io.FileReader");
				local.fileReader.init(arguments.filename);
	
				// thank you Mark Mandel for JavaLoader!
				local.paths = [ExpandPath("/plugins/#getPluginConfig().getDirectory()#/lib/opencsv-2.2.jar")];
				local.loader = CreateObject("component", "plugins.#getPluginConfig().getDirectory()#.lib.org.riaforge.javaloader.JavaLoader").init(local.paths);
				local.csvReader = local.loader.create("au.com.bytecode.opencsv.CSVReader");
	
				local.csvReader.init(local.fileReader);
				local.csvData = local.csvReader.readAll(); // available methods: close(), readAll(), readNext()
				local.csvReader.close(); // close the file since we're done reading it
			};
			return local.csvData;
		</cfscript>
	</cffunction>

	<cffunction name="readXMLFile" access="private" output="true" returntype="any">
		<cfargument name="filename" required="true" />
		<cfscript>
			var local = StructNew();
			local.xml = XmlParse(arguments.filename);			
			local.locationsArray = ArrayNew(2);			
			local.headerRow = ArrayNew(1);
			
			// locations
			for ( local.i=1; local.i lte ArrayLen(local.xml.locations.XmlChildren); local.i++ ) {
				// location
				local.location = local.xml.locations.location[i];
				for ( local.iLocation=1; local.iLocation lte ArrayLen(local.xml.locations.location[i].XmlChildren); local.iLocation++ ) {
					local.locationsArray[i][iLocation] = local.xml.locations.XmlChildren[i].XmlChildren[iLocation].XmlText;
				};
			};

			// Header Row
			for ( local.iHeaderRow=1; local.iHeaderRow lte arrayLen(local.xml["locations"]["location"].XmlChildren); local.iHeaderRow++ ) {
				ArrayAppend(local.headerRow, local.xml["locations"]["location"].XmlChildren[local.iHeaderRow].XmlName);
			};
			ArrayInsertAt(local.locationsArray, 1, local.headerRow);

			return local.locationsArray;
		</cfscript>
	</cffunction>

	<cffunction name="setData" access="private" output="false" returntype="void">
		<cfargument name="data" required="true" />
		<cfscript>
			var local = StructNew();
			local.locations = '';
			local.hasValidHeaderRow = true;

			if ( StructKeyExists(arguments, 'data') ) {
				local.data = arguments.data;
			} else {
				local.data = ArrayNew(1);
			};
	
			// validate CSV formatting by checking for the required HeaderRow
			if ( ArrayLen(local.data) ) {
				local.badElements = ArrayNew(1);
				local.objGeo = CreateObject('component', 'plugins.#getPluginConfig().getDirectory()#.lib.org.riaforge.googlegeocoder3.GoogleGeoCoder3').init();
				// 1st element in the array should be the headerRow and formatted as follows:
				local.validHeaderRow = "LocationName,Lat,Lng,Address,Phone,InfoWindow,ZIndex,Icon";
				for ( local.i=1; local.i lte ListLen(local.validHeaderRow); local.i++ ) {
					if ( local.data[1][local.i] neq ListGetAt(local.validHeaderRow, local.i) ) {
						local.hasValidHeaderRow = false;
						break;
					};
				};
			} else {
				local.hasValidHeaderRow = false;
			};
			// continue processing the array of data if the HeaderRow is formatted properly
			if ( local.hasValidHeaderRow ) {

				// remove the headerRow now that we don't need it
				local.temp = ArrayDeleteAt(local.data, 1);

				// parse the Data and find any problems
				for ( local.i=1; local.i lte ArrayLen(local.data); local.i++ ) {
					local.isGood = true;

					// fix any formatting issues that may occur with the LocationName
					local.data[local.i][1] = htmlEditFormat(local.data[local.i][1]);

					// Lat Lng
					if ( ( not len(trim(local.data[local.i][2])) or not len(trim(local.data[local.i][3])) ) and len(trim(local.data[local.i][4])) ) {

						// if we can't obtain the Latitude and Longitude for a location, then we can't plot it properly
						try {
							local.missingLatLng = trim(local.objGeo.getLatLng(local.data[local.i][4]));
						} catch (Any e) {
							ArrayAppend(local.badElements, local.i);
							local.isGood = false;
						};

						// if we have a good Lat Lng, update the missing array elements, otherwise remove it from the array
						if ( local.isGood ) {
							if ( len(trim(ListFirst(local.missingLatLng))) ) {
								local.data[local.i][2] = ListFirst(local.missingLatLng);
								local.data[local.i][3] = ListLast(local.missingLatLng);
							} else {
								ArrayAppend(local.badElements, local.i);
								local.isGood = false;
							};
						};
					};

					// Address
					if ( local.isGood ) {
						if ( not len(trim(local.data[local.i][4])) and ( len(trim(local.data[local.i][2])) and len(trim(local.data[local.i][3])) ) ) {
							try {
								local.data[local.i][4] = local.objGeo.getAddress(local.data[local.i][2] & ',' & local.data[local.i][3]);
							} catch (Any e) {
								ArrayAppend(local.badElements, local.i);
								local.isGood = false;
							};
						};
					};

					// InfoWindow
					if ( local.isGood ) {
						if ( not len(trim(local.data[local.i][6])) ) {
							local.data[local.i][6] = '<h3>' & local.data[local.i][1] & '</h3><p>' & ReReplace(htmlEditFormat(local.data[local.i][4]), ', ', '<br />', 'ALL') & '</p><p><strong>' & htmlEditFormat(local.data[local.i][5]) & '</strong></p>';
						} else {
							local.data[local.i][6] = ReReplace(local.data[local.i][6], '"', '&quot;', 'ALL');
						};
					};
				};
				
				// clean up bad elements
				if ( ArrayLen(local.badElements) ) {
					local.itemsDeleted = 0;
					for ( local.i=1;local.i lte ArrayLen(local.badElements); local.i++ ) {
						local.pos = local.badElements[local.i]-local.itemsDeleted;
						local.temp = ArrayDeleteAt(local.data, local.pos);
						local.itemsDeleted ++;
					};
				};			
	
				// prepare an array of locations to hand off to JavaScript
				setJSLocations(local.data);
			};

			variables.instance.data = local.data;
		</cfscript>
	</cffunction>

	<cffunction name="getData" access="private" output="false" returntype="any">
		<cfreturn variables.instance.data />
	</cffunction>

	<cffunction name="setJSLocations" access="private" output="false" returntype="void">
		<cfargument name="jsLocations" required="true" />
		<cfscript>
			var local = StructNew();
			local.jsLocations = '';
			local.data = ArrayNew(1);
			
			if ( StructKeyExists(arguments, 'jsLocations') ) {
				local.data = arguments.jsLocations;
			};

			if ( ArrayLen(local.data) ) {
				// prepare an array of locations to hand off to JavaScript
				for (local.i=1; local.i lte ArrayLen(local.data); local.i++) {
					local.jsLocations = local.jsLocations & '["' & local.data[local.i][1] & '",' & local.data[local.i][2] & ',' & local.data[local.i][3] & ',' & val(local.data[local.i][7]) & ',"' & local.data[local.i][8] & '","' & local.data[local.i][6] & '"]';
					// if there are more elements, then we need a comma
					if ( local.i neq ArrayLen(local.data) ) {
						local.jsLocations = local.jsLocations & ',';
					};
				};
			};

			variables.instance.jsLocations = local.jsLocations;
		</cfscript>
	</cffunction>

	<cffunction name="getJSLocations" access="private" output="false" returntype="any">
		<cfreturn variables.instance.jsLocations />
	</cffunction>

	<cffunction name="setCSVFile" access="private" output="false" returntype="void">
		<cfargument name="CSVFile" required="true" />
		<cfset variables.instance.CSVFile = arguments.CSVFile />
	</cffunction>

	<cffunction name="getCSVFile" access="private" output="false" returntype="any">
		<cfreturn variables.instance.CSVFile />
	</cffunction>

	<cffunction name="setXMLFile" access="private" output="false" returntype="void">
		<cfargument name="XMLFile" required="true" />
		<cfset variables.instance.XMLFile = arguments.XMLFile />
	</cffunction>

	<cffunction name="getXMLFile" access="private" output="false" returntype="any">
		<cfreturn variables.instance.XMLFile />
	</cffunction>

	<cffunction name="setPluginConfig" access="private" output="false" returntype="void">
		<cfargument name="pluginConfig" required="true" />
		<cfset variables.instance.pluginConfig = arguments.pluginConfig />
	</cffunction>

	<cffunction name="getPluginConfig" access="private" output="false" returntype="any">
		<cfreturn variables.instance.pluginConfig />
	</cffunction>

</cfcomponent>