COPYRIGHT
(C) 2010, Stephen J. Withington, Jr. | http://www.stephenwithington.com

PROJECT
MuraGoogleMaps TM

VERSION
0.1-Alpha

PURPOSE
A plugin for Mura CMS (www.getmura.com).
I will display one or more locations on a custom Google Map.
Directions to any of the locations will be available and have the option to disable.
Can accept either a properly formatted CSV file or XML file.
Future plans to accept a query object. However, currently does not allow
end-user control via the admin UI to add/edit/delete locations.

FILE FORMAT REQUIREMENTS

.CSV file
	- Header Row is REQUIRED and must contain 'LocationName,Lat,Lng,Address,Phone,InfoWindow,Zindex,Icon'
	- Excel files (.xls, .xlsx, etc.) are NOT CSV files. You need to 'Save As' .CSV
	- View the included 'sample.csv' file for reference.

.XML files
	- All nodes must be present even if the value is empty.
	- View the included 'sample.xml' file for reference.

FIELD DESCRIPTIONS
Fields marked 'Optional' below may be left blank.
- LocationName: Required (String), Name or title of the location.
- Lat: Optional* (String), Latitude of the location. 
- Lng: Optional* (String), Longitude of the location.
- Address: Optional* (String), Address of the location (can be anywhere in the world and can simply be a city, state, country, etc.)
- Phone: Optional (string), Phone number of the location
- InfoWindow: Optional** (String), Content to display in the InfoWindow when an end-user clicks on the location icon/marker.
- Zindex: Optional (Integer), The stacking order of the Icons/Markers
- Icon: Optional (String), The full URL to an icon to be used in lieu of the standard Google location marker. Preferably a .png file. If you copy and paste the URL into a browser, the file should display, if it doesn't, then the map won't be able to display it either.

*If you do not supply a Lat and Lng, then an Address is needed! If you choose to supply the Lat and Lng, then the Address will be reverse-geo-coded and may not match exactly to what you might expect. You can supply all three fields if you wish.
** InfoWindow will be auto-generated if left blank and consist of the LocationName, Address and Phone. Otherwise, you can supply properly formatted HTML to be displayed in the InfoWindow.