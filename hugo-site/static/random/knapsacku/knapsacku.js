function knapsackunbounded(event)
{
event.preventDefault();

var w = document.getElementById("textboxw").value;
var c = document.getElementById("textboxc").value;
var W = document.getElementById("textboxk").value;

w = w.split(",");
c = c.split(",");
n = W;

p = w.length; 

var z = new Array(n+1);
var i, j;
for(i = 0; i < n+1; i++) z[i] = 0;
var mat = new Array(n+1);
for(i = 0; i < n+1; i++) mat[i] = new Array(p);
var s = new Array(n+1);
for(i = 0; i < n+1; i++){
	s[i] = "";
	for(j = 0; j < p; j++) mat[i][j] = 0;
}

RESULT = "";
RESULT = RESULT + "<tr> <th class='tg-amwm'> v </th>";
for(i = 0; i < p; i++) RESULT = RESULT + "<th  class='tg-amwm'> " + c[i] + " - z(v - " + w[i] + ") </th>";
RESULT = RESULT + "<th class='tg-amwm'> z(v) </th> <th class='tg-amwm'> i </th> </tr>";


var row = "";
for(i = 0; i < parseInt(parseInt(n)+1); i++)
{
	
	row = "";
	row = row + "<tr>";
	row = row + "<th class='tg-baqh'> " + i.toString() + " </th>";
	z[i] = 0;
	for(j = 0; j < p; ++j)
	{
		if(i < w[j]) mat[i][j] = -1;
		else
		{
			mat[i][j] = parseInt((parseInt(c[j])+parseInt(z[i-w[j]])));
			if(mat[i][j] > z[i]) z[i] = mat[i][j];
		}
	if(mat[i][j] == -1) row = row + "<th class='tg-baqh'>" + "-" + " </th>";
	else
		row = row + "<th class='tg-baqh'>" + mat[i][j].toString() + " </th>";
	}
	for(j = 0; j < p; j++)
		if(z[i] == mat[i][j] && z[i] != 0 && s[i].length == 0) s[i] = s[i] + (j+1).toString();
		else if(z[i] == mat[i][j] && z[i] != 0) s[i] = s[i] + " or " + (j+1).toString();

	row = row + "<th class='tg-baqh'> " + z[i].toString() + "</th>";
	if(s[i] == "") s[i] = "-";
	row = row + "<th class='tg-baqh'> " + s[i] + "</th>";
	row = row + "</tr>";
	RESULT = RESULT + row;
}



document.getElementById("tab").innerHTML = RESULT;



}
