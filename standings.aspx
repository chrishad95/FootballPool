<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Data.SQLClient" %>
<%@ Import Namespace="System.Web.Mail" %>
<script runat="server" language="VB">
	private myname as string = ""

	private sub CallError(message as string)
		session("page_message") = message
		response.redirect("error.aspx", true)
	end sub
</script>
<%

server.execute("/football/cookiecheck.aspx")

dim fb as new Rasputin.FootballUtility()
fb.initialize()

dim myname as string = ""
try
	if session("username") <> "" then
		myname = session("username")
	end if
catch
end try
	
dim http_host as string = ""
try
	http_host = request.servervariables("HTTP_HOST")
catch
end try

dim pool_id as integer
try
	if request("pool_id") <> "" then
		pool_id = request("pool_id")
	end if
catch 
end try

dim isowner as boolean = false
if fb.isowner(pool_id:=pool_id, pool_owner:=myname) then
	isowner = true
end if

if fb.isplayer(pool_id:=pool_id, player_name:=myname) or isowner then
else	
	callerror("Invalid pool_id")
end if

dim week_id as integer
dim week_is_set as boolean = false
try
	if request("week_id") <> "" then
		week_id = request("week_id")
		week_is_set = true
	end if
catch 
end try

dim standings_ds as new dataset()

dim weeks_ds as new dataset()
weeks_ds = fb.listweeks(pool_id:=pool_id)
if week_is_set then
	try
		dim foundweek as boolean = false
		for each drow as datarow in weeks_ds.tables(0).rows
			if drow("week_id") = week_id then
				foundweek = true
			end if
		next
		if foundweek then
			standings_ds = fb.getstandingsforweek(pool_id:=pool_id, week_id:=week_id)
		else
			standings_ds = fb.getstandings(pool_id:=pool_id)
		end if
	catch
	end try
else
	standings_ds = fb.getstandings(pool_id:=pool_id)
end if


dim pool_details_ds as new dataset()
pool_details_ds = fb.getpooldetails(pool_id:= pool_id)


dim banner_image as string = fb.getbannerimage(pool_id)

dim pool_name as string = ""
pool_name = pool_details_ds.tables(0).rows(0)("pool_name")

dim sort_by as string = "TOTALSCORE"
dim sort_dir as string = "DESC"

try
	if request("sort_by") = "USERNAME" OR request("sort_by") = "HOME" OR request("sort_by") = "AWAY" OR request("sort_by") = "WINS" OR request("sort_by") = "LOSSES" OR request("sort_by") = "WEEKWINS"  OR request("sort_by") = "TOTALSCORE" OR request("sort_by") = "LWP" then
		sort_by = request("sort_by")
	end if
catch
end try
try
	if request("sort_dir") = "ASC" or request("sort_dir") = "DESC" then
		sort_dir = request("sort_dir")
	end if
catch
end try

dim options_ht as new system.collections.hashtable()
options_ht = fb.getPoolOptions(pool_id:=pool_id)

dim colspan as integer = 8

if options_ht("LONEWOLFEPICK") = "on" then
		colspan = colspan + 1
end if

if options_ht("WINWEEKPOINT") = "on" then
		colspan = colspan + 1
end if
%>

<html>
<head>
	<title>Pool Standings - <% = http_host %> - [<% = myname %>]</title>
	<style type="text/css" media="screen">@import "/football/style4.css";</style>
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
	.loser {
		text-decoration: line-through;
		text-align: center;
	}
	.score_cell {
		text-align: right;
	}

	.week_table {
		width: 200;
	}

	td {
		color:#333;
		font:11px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
		text-align: center;
	}
	tr:hover {
		background: #ffffd9;	
	}
	.nopick_cell {
		background-color: #FFFF99;
	}
	.hidden_pick_cell {
		background-color: #0099CC;
	}

	.table_subheader {
		font-size: 11px;
		font-weight: bold;
		background: Silver;
	}
	.table_header {
		font-size: 12px;
		font-weight: bold;
		background: Silver;
	}	
	.table_header td {
		font-size: 12px;
		font-weight: bold;
		background: Silver;
	}	
	.table_header a {
		text-decoration: none;   
		color: navy;
	}

	.RowLight {
		background: WhiteSmoke;
	}

	.RowDark {
		background: Gainsboro;
	}
	
	.content {
		border: none;
		padding: 1px;
		margin:0px 0px 20px 170px;
	}
	</style>
</head>

<body>

	<div class="content">
		<%
			if banner_image = "" then
				%><h1><% = pool_name %></h1><%
			else
				%><img src="<% = banner_image %>" border="0"><BR><BR><%
			end if
		%>
		<br>

		<form action="standings.aspx">
		<input type="hidden" name="pool_id" value="<% = pool_id %>">
		<table class="week_table">
		<tr><td colspan=3 align="left" id="weekselect" nowrap >Week # <select name="week_id" onChange="this.form.submit.click()">
		<option>Select Week</option>
		<%
		try
			if not week_is_set then
				week_id = fb.getdefaultweek(pool_id:=pool_id)
			end if
			for each drow as datarow in weeks_ds.tables(0).rows
				dim i as integer = drow("week_id")
				if i  = week_id then
					%>
					<option value="<% = i %>" selected><% = i %></option>
					<%
				else
					%>
					<option value="<% = i %>"><% = i %></option>
					<%
				end if
			next
		catch
		end try
		%>
		</select> <input type="submit" name="submit" value="Refresh"></td></tr>
		</table>
		</form>
		<%If standings_ds.Tables.Count > 0 Then%>
		<table border=1 cellspacing=0 cellpadding=3>
		<tr><td class="table_header" colspan="<% = colspan %>"><% = pool_name %> Standings</td></tr>
		<tr><%
			if sort_by = "USERNAME" then
				if sort_dir = "ASC" then
					%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=USERNAME&sort_dir=DESC">Player</a></td><%
				else
					%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=USERNAME&sort_dir=ASC">Player</a></td><%
				end if
			else
				%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=USERNAME&sort_dir=ASC">Player</a></td><%
			end if

			if sort_by = "WINS" then
				if sort_dir = "ASC" then
					%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=WINS&sort_dir=DESC">WINS</a></td><%
				else
					%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=WINS&sort_dir=ASC">WINS</a></td><%
				end if
			else
				%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=WINS&sort_dir=DESC">WINS</a></td><%
			end if

			

			if sort_by = "LOSSES" then
				if sort_dir = "ASC" then
					%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=LOSSES&sort_dir=DESC">LOSSES</a></td><%
				else
					%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=LOSSES&sort_dir=ASC">LOSSES</a></td><%
				end if
			else
				%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=LOSSES&sort_dir=DESC">LOSSES</a></td><%
			end if


			if sort_by = "WINS" then
				if sort_dir = "ASC" then
					%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=WINS&sort_dir=DESC">Win %</a></td><%
				else
					%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=WINS&sort_dir=ASC">Win %</a></td><%
				end if
			else
				%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=WINS&sort_dir=DESC">Win %</a></td><%
			end if


			if sort_by = "HOME" then
				if sort_dir = "ASC" then
					%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=HOME&sort_dir=DESC">HOME</a></td><%
				else
					%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=HOME&sort_dir=ASC">HOME</a></td><%
				end if
			else
				%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=HOME&sort_dir=DESC">HOME</a></td><%
			end if
			

			if sort_by = "AWAY" then
				if sort_dir = "ASC" then
					%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=AWAY&sort_dir=DESC">AWAY</a></td><%
				else
					%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=AWAY&sort_dir=ASC">AWAY</a></td><%
				end if
			else
				%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=AWAY&sort_dir=DESC">AWAY</a></td><%
			end if

			if options_ht("LONEWOLFEPICK") = "on" then

				if sort_by = "LWP" then
					if sort_dir = "ASC" then
						%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=LWP&sort_dir=DESC">LWP</a></td><%
					else
						%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=LWP&sort_dir=ASC">LWP</a></td><%
					end if
				else
					%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=LWP&sort_dir=DESC">LWP</a></td><%
				end if
			end if

			if options_ht("WINWEEKPOINT") = "on" then

				if sort_by = "WEEKWINS" then
					if sort_dir = "ASC" then
						%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=WEEKWINS&sort_dir=DESC">Week Wins</a></td><%
					else
						%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=WEEKWINS&sort_dir=ASC">Week Wins</a></td><%
					end if
				else
					%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=WEEKWINS&sort_dir=DESC">Week Wins</a></td><%
				end if
			end if

			if sort_by = "TOTALSCORE" then
				if sort_dir = "ASC" then
					%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=TOTALSCORE&sort_dir=DESC">Total Score</a></td><%
				else
					%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=TOTALSCORE&sort_dir=ASC">Total Score</a></td><%
				end if
			else
				%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=TOTALSCORE&sort_dir=DESC">Total Score</a></td><%
			end if

			if sort_by = "TOTALSCORE" then
				if sort_dir = "ASC" then
					%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=TOTALSCORE&sort_dir=DESC">Pts Behind</a></td><%
				else
					%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=TOTALSCORE&sort_dir=ASC">Pts Behind</a></td><%
				end if
			else
				%><td class="table_subheader"><a href="?pool_id=<% = pool_id %>&sort_by=TOTALSCORE&sort_dir=DESC">Pts Behind</a></td><%
			end if
		%>
		</tr>
		<% 
		dim player_rows as datarow()
		player_rows = standings_ds.tables(0).select(filterExpression:="1=1", sort:=sort_by & " " & sort_dir)

			
		dim rowtype as string = "RowDark"	
		for each pdrow as datarow in player_rows

			if rowtype = "RowLight" then
				rowtype = "RowDark"
			else
				rowtype = "RowLight"
			end if
			dim pname as string = ""
			if pdrow("nickname") is dbnull.value then
				pname = pdrow("username")
			else
				if pdrow("nickname") <> "" then
					pname = pdrow("nickname")
				else
					pname = pdrow("username")
				end if
			end if

			Dim pcent as integer = 0
			try
				pcent = system.convert.toInt32 ( (pdrow("wins") / (pdrow("wins") + pdrow("losses"))) * 10000) / 100
			catch
			End try

			%><tr class="<% = rowtype %>"><td nowrap><% = pname %></td>
			<td class="score_cell"><% = pdrow("wins") %></td>
			<td class="score_cell"><% = pdrow("losses") %></td>
			<td class="score_cell"><% = pcent  %>%</td>
			<td class="score_cell"><% = pdrow("home") %></td>
			<td class="score_cell"><% = pdrow("away") %></td><%

			if options_ht("LONEWOLFEPICK") = "on" then
				%><td class="score_cell"><% = pdrow("lwp") %></td><%
			end if
			if options_ht("WINWEEKPOINT") = "on" then
				%><td class="score_cell"><% = pdrow("weekwins") %></td><%
			end if
			%>
			<td class="score_cell"><% = pdrow("totalscore") %></td>
			<td class="score_cell"><% = pdrow("rank") %></td>
			</tr><%
		next
		%>
		
		</table>
		<% end if %>
		<br />
		<br />
		<% server.execute("/football/comment_ticker.aspx") %>

	</div>

<div id="NavAlpha">
<% server.execute ("nav.aspx") %>
</div>

<!-- BlueRobot was here. -->
</body>
</html>
