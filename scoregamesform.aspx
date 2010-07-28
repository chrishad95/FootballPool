<%@ Page language="VB" runat="server" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Data.ODBC" %>
<%@ Import Namespace="System.Web.Mail" %>
<%
server.execute("/cookiecheck.aspx")

dim myname as string
myname = ""
try
	if session("username") <> "" then
		myname = session("username")
	end if
catch
end try
if myname <> "chadley" then
	response.redirect("/football")
	response.end()
end if

dim default_week_id as integer

dim week_id as integer
dim sql as string

dim con as odbcconnection
dim cmd as odbccommand
dim dr as odbcdatareader
dim oda as odbcdataadapter
dim parm1 as odbcparameter

dim ds as dataset
dim drow as datarow
dim dt as datatable

con = new odbcconnection(System.Configuration.ConfigurationSettings.AppSettings("connString"))
con.open()

sql = "select max(week_id) as max_week_id from football.sched "
cmd = new odbccommand(sql,con)

dr = cmd.executereader()
if dr.read() then
	if not dr.item("max_week_id") is dbnull.value then
		default_week_id = dr.item("max_week_id")
	else
		response.redirect("/football")
		response.end()
	end if
else
	response.redirect("/football")
	response.end()
end if
dr.close()

if request("week_id") = "" then
	week_id = 1
else
	try
		week_id = request("week_id")
	catch
		week_id = 1
	end try

		
end if
if week_id > default_week_id then
	week_id = 1
end if
	
' get the games for the week
sql = "select a.game_id, d.away_score, d.home_score,  b.team_id as home_id, b.team_name as home_name, b.team_shortname as home_shortname, b.team_alias as home_alias, c.team_id as away_id, c.team_name as away_name, c.team_shortname as away_shortname, c.team_alias as away_alias , a.game_url, year(a.game_tsp) as game_year, month(a.game_tsp) as game_month, day(a.game_tsp) as game_day from football.sched a full outer join football.teams b on b.team_id=a.home_id full outer join football.teams c on c.team_id=a.away_id full outer join football.scores d on d.game_id=a.game_id where a.week_id=? order by a.game_tsp, a.game_id"

cmd = new odbccommand(sql,con)
parm1 = new odbcparameter("week_id", odbctype.int)
parm1.value = week_id
cmd.parameters.add(parm1)

dim games_ds as dataset = new dataset()
oda = new odbcdataadapter()
oda.SelectCommand = cmd
oda.Fill(games_ds)



dim temp_rows as DataRow()

dim i as integer
con.close()

%>

<html>
<head>
	<title>Score Games - rasputin.dnsalias.com - [<% = myname %>]</title>
	<style type="text/css" media="screen">@import "/style2.css";</style>
	<style type="text/css">
	.winner {
		background-color: #00FF00;
		text-align: center;
		
	}
	.home_pick_cell {
		background-color: Lavender;
	}
	.away_pick_cell {
		background-color: MistyRose;
	}
	.home_pick_cell {
		color:#333;
		font:11px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
		text-align: center;
	}
	.home_pick_cell a {
		color:#333;
		font:11px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
		text-align: center;
	}
	.away_pick_cell {
		color:#333;
		font:11px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
		text-align: center;
	}
	.away_pick_cell a {
		color:#333;
		font:11px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
		text-align: center;
	}
	.pick_cell {
		color:#333;
		font:11px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
		text-align: center;
	}
	.pick_cell a {
		color:#333;
		font:11px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
		text-align: center;
	}
	.loser {
	text-decoration: line-through;
		text-align: center;
	}
	.loser a {
		color:#333;
		font:11px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
		text-align: center;
	}
	.winner a{
		color:#333;
		font:11px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
		text-align: center;
	}
	.score_cell {
		text-align: right;
	}
	.table_header {
		background-color: #C0C0C0;
	}
	td {
	font:11px verdana, arial, helvetica, sans-serif;
	}
	</style>
</head>

<body>


	<div id="Header">
		<a href="/">rasputin.dnsalias.com</a>
	</div>

	<div id="Content">
		<%
		try
			response.write(session("page_message"))
			session("page_message") = ""
			response.write("<BR>")
		catch
		end try
		%>
		
		<form name="pickweekform" action="scoregamesform.aspx">
		<table>
		<tr><td colspan=3>Week # <select name="week_id" onChange="window.document.pickweekform.submit();" >
		<%
		for i = 1 to default_week_id
			if i = week_id then
				%>
				<option value="<% = i %>" selected><% = i %></option>
				<%
			else
				%>
				<option value="<% = i %>"><% = i %></option>
				<%
			end if
			
		next		
		%>
		</select></td></tr>
		</table>
		</form>
		<form name="scoreform" method="post" action="scoregames.aspx">
		<input type="hidden" name="week_id" value="<% = week_id %>">
		<%
		for each drow in games_ds.tables(0).rows
		%>
		
		<table border="1" cellspacing="0" cellpadding="3">
		<tr><td width="100" nowrap><% = drow("away_name") %></td><td><input type="text" name="away_score_<% = drow("game_id") %>" value="<% = drow("away_score") %>"></td></tr>
		<tr><td width="100" nowrap><% = drow("home_name") %></td><td><input type="text" name="home_score_<% = drow("game_id") %>" value="<% = drow("home_score") %>"></td></tr>
		
		</table>
		<br />
		<%
		next
		%>
		<input type="submit" value="Submit Scores">
		</form>
	</div>

<div id="Menu">
<% server.execute ("/nav.aspx") %>
<% server.execute ("nav.aspx") %>
</div>



<!-- BlueRobot was here. -->

</body>
</html>
