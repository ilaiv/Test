
function ReadFile( fso, fileName){
	var textFile = fso.OpenTextFile(fileName, 1, false);
	var text = "";
	if (!textFile.AtEndOfStream){
		text = textFile.ReadAll();
	};
	textFile.Close();
	return text;
}

var fso = WScript.CreateObject("Scripting.FileSystemObject");

var dpr = ReadFile(fso, "SASPlanet.dpr");
dpr = dpr.replace('  u_MadExcept,\r\n', "");
var dprFile = fso.OpenTextFile("SASPlanet.dpr", 2, false);
dprFile.write(dpr);