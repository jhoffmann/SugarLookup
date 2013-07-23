# SugarLookup
## Applescript Utility for QuickSilver and Launchbar

### Usage:

#### LaunchBar

* copy the script and the xml file into *~/Library/Application Support/LaunchBar/Actions*
* edit the **SugarLookupPrefs.xml** file and add your username and password
* compile the AppleScript: `osacompile -o SugarLookup.scpt SugarLookup.applescript`
* Hit your Launchbar hotkey (apple-space by default), find SugarLookup in the list, and type `<bug|itr|case> <number>` to find a single result, or `<bugs|cases|itrs> <query string>` to get a list of matches
* You can customize the queries and their keywords in the XML file

#### QuickSilver

* copy the script and the xml file into *~/Library/Application Support/Quicksilver/Actions*
* edit the **SugarLookupPrefs.xml** file and add your username and password
* compile the AppleScript: `osacompile -o SugarLookup.scpt SugarLookup.applescript`
* ** Restart QuickSilver **, not sure why this step is required, seems QS only scanned the folder on startup.
* Hit your Quicksilver hotkey (apple-space by default), put the first pane into text mode (.), type `<bug|itr|case> <number>`, and choose the SugarLookup action in the second pane
* You can customize the queries and their keywords in the XML file, though I couldn't find a way to have QuickSilver handle a list of results, so it's only returning the first match


#### Alfred

* install the `SugarLookup SOAP.alfredworkflow` file into Alfred (required the Powerpack)
* open Alfred's preferences, click the `Workflows` tab, right click the new workflow and `Show in Finder`
* Open the prefs.php and customize your username/password
* Enjoy!