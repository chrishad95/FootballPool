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

dim message_text as string = ""

try
	myname = session("username")
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
catch ex as exception
	fb.makesystemlog("error in makepicks.aspx", ex.tostring())
end try

dim week_id as integer = 0
try
	week_id = request("week_id")
catch ex as exception
end try
dim fastkey as string = ""
try
	fastkey = request("fastkey")
catch
end try
dim player_name as string = ""
try
	player_name = request("player_name")
catch
end try

dim fastkeyisvalid as boolean = false

try
	if fastkey <> "" and player_name <> "" then
		fastkeyisvalid = fb.isvalidfastkey(fastkey:=fastkey, player_name:=player_name, pool_id:=pool_id, week_id:=week_id)
	end if
catch ex as exception
	fb.makesystemlog("error in makepicks.aspx", ex.tostring())
end try

if fb.isplayer(pool_id:=pool_id, player_name:=myname) or fb.isowner(pool_id:=pool_id, pool_owner:=myname) or fastkeyisvalid then
else	
	callerror("Invalid pool_id")
end if

if not fastkeyisvalid then 
	player_name = myname
end if

dim games_ds as new dataset()
games_ds = fb.GetGamesForWeek(pool_id:=pool_id, week_id:=week_id)

if games_ds.tables.count > 0 then
	if games_ds.tables(0).rows.count > 0 then
	else
		week_id = fb.getdefaultweek(pool_id:=pool_id)
		games_ds = fb.getgamesforweek(pool_id:=pool_id, week_id:=week_id)
	end if
else
	week_id = fb.getdefaultweek(pool_id:=pool_id)
	games_ds = fb.getgamesforweek(pool_id:=pool_id, week_id:=week_id)
end if
dim tiebreaker_game as string = ""
try
	tiebreaker_game = fb.GetTieBreakerText(pool_id:=pool_id, week_id:=week_id)
catch ex as exception
	fb.makesystemlog("Error getting tiebreakertext", ex.tostring())
end try

try
	if games_ds.tables.count > 0 then
		dim temprows as datarow()
		temprows = games_ds.tables(0).select("1=1", "game_tsp asc")
		if temprows.length > 0 then
			dim check_date as datetime
			check_date = temprows(0)("game_tsp")
			check_date = check_date.addminutes(-30)

		''	If DateTime.Compare(t1, t2) > 0 Then
		''		Console.WriteLine("t1 > t2")
		''	End If
		''	If DateTime.Compare(t1, t2) = 0 Then
		''		Console.WriteLine("t1 == t2")
		''	End If
		''	If DateTime.Compare(t1, t2) < 0 Then
		''		Console.WriteLine("t1 < t2")
		''	End If

			if request("submit") = "Submit Picks" then
				if system.datetime.compare(check_date , system.datetime.now) > 0 then
						dim res as string = ""
						res = fb.SubmitPicks(r:=request, pool_id:=pool_id, player_name:=player_name )
				else
					message_text = "It is too late to make picks for this week."
				end if
			end if
		end if
	end if
catch ex as exception
	fb.makesystemlog("Error in submit picks", ex.tostring())
end try

dim pool_details_ds as new dataset()
pool_details_ds = fb.getpooldetails(pool_id:= pool_id)

dim banner_image as string = ""
if not pool_details_ds.tables(0).rows(0)("pool_banner") is dbnull.value then
	banner_image = "/users/" & pool_details_ds.tables(0).rows(0)("pool_owner") & "/" &  pool_details_ds.tables(0).rows(0)("pool_banner")
end if

dim pool_name as string = ""
pool_name = pool_details_ds.tables(0).rows(0)("pool_name")


dim options_ht as new system.collections.hashtable()
options_ht = fb.getPoolOptions(pool_id:=pool_id)

%>

<html>
<head>
	<title>Make Picks - <% = pool_name %> - [<% = player_name %>]</title>
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
	
	.content {
		border: none;
		padding: 1px;
		margin:0px 0px 20px 170px;
	}
	</style>
	<script>

		function doallgamerows() {
			var elements = document.forms["picksform"].elements;

			for (var i=0; i<elements.length; i++) {
				if (elements[i].type == "radio") {
					if (elements[i].name.indexOf("game_") == 0) {
						var game_id = elements[i].name;
						game_id = game_id.replace("game_","");
						dogamerow(game_id);
					}
				}
			}
		}

		function dogamerow(game_id) {
			var radiobuttonname = "game_" + game_id;

			var x=document.getElementsByName(radiobuttonname);
			var ischecked = false;
			for (var y in x) {
				if (x[y].checked) {
					ischecked = true;
				}
			}
			if (ischecked) {
				var t=document.getElementById("gamerow" + game_id)
				if (t) {
					t.bgColor = "#CCCCFF";
				}
			}
		}
	</script>
</head>

<body onLoad="doallgamerows()">

	<div class="content">
		<%
			if banner_image = "" then
				%><h1><% = pool_name %></h1><%
			else
				%><img src="<% = banner_image %>" border="0"><BR><BR><%
			end if
		%>

		<h2>Make Picks: Week #<% = week_id %></h2>
		<form name="picksform" action="makepicks.aspx">
		<% 
		if fastkeyisvalid then
		%><input type="hidden" name="fastkey" value="<% = fastkey %>"><%
		end if
		%>
		<% 
		if player_name <> "" then
		%><input type="hidden" name="player_name" value="<% = player_name %>"><%
		end if
		%>
		<input type="hidden" name="pool_id" value="<% = pool_id %>">
		Week #<SELECT NAME="week_id">
		<%
			try
				dim weeks_ds as dataset
				weeks_ds = fb.listweeks(pool_id:=pool_id)
				if weeks_ds.tables.count > 0 then
					if weeks_ds.tables(0).rows.count > 0 then
						for each drow as datarow in weeks_ds.tables(0).rows
							dim selected as string = ""
							if week_id = drow("week_id") then
								selected = " SELECTED "
							else
								selected = ""
							end if
							%><option value="<% = drow("week_id") %>" <% = selected %>><% = drow("week_id") %></option><%
						next
					end if
				end if
			catch ex as exception
				fb.makesystemlog("error listing weeks", ex.tostring())
			end try
		%>
		</SELECT> <input type="submit" value="Refresh"><BR><BR>
		<TABLE border=1 cellspacing=0 cellpadding=3 >
		<TR><TD>Game Date/Time</TD><TD align=right>Away Team</TD><TD align=left>Home Team</TD></TR>
		<%
		dim missed_picks as integer = 0
		dim picks_ds as new dataset()
		picks_ds = fb.getpicksforweek(pool_id:=pool_id, week_id:=week_id, player_name:=player_name)

		if games_ds.tables.count > 0 then
			if games_ds.tables(0).rows.count > 0 then
				for each drow as datarow in games_ds.tables(0).rows
					dim temprows as datarow()
					dim away_selected as string = ""
					dim home_selected as string = ""
					try
						if picks_ds.tables.count > 0 then
							temprows = picks_ds.tables(0).select("game_id=" & drow("game_id"))
							if temprows.length > 0 then
								if temprows(0)("team_id") = drow("away_id") then
									away_selected = " CHECKED "
								End if
								if temprows(0)("team_id") = drow("home_id") then
									home_selected = " CHECKED "
								End if
							end if
						end if
					catch ex as exception
						fb.makesystemlog("error getting pick temprows", ex.tostring())
					end try
					dim away_url as string = "javascript:void()"
					if not drow("away_url") is dbnull.value then
						if drow("away_url") <> "" then
							away_url = drow("away_url")
						end if
					end if
					dim home_url as string = "javascript:void()"
					if not drow("home_url") is dbnull.value then
						if drow("home_url") <> "" then
							home_url = drow("home_url")
						end if
					end If
					
					Dim away_record as String = ""
					Dim home_record as String = ""
					if options_ht("TEAMRECORDS") = "on" Then
						away_record = fb.getTeamRecord(pool_id:=pool_id, team_id:=drow("away_id"))
						home_record = fb.getTeamRecord(pool_id:=pool_id, team_id:=drow("home_id"))
						away_record = "(" & away_record & ")"
						home_record = "(" & home_record & ")"

					End If
					
					%><TR id="gamerow<% = drow("game_id") %>"><TD><% = drow("game_tsp") %></TD><TD align=right ><a target=_blank href="<% = away_url %>"><% = drow("away_team") %> <% = away_record %></a> <INPUT TYPE="radio" NAME="game_<% = drow("game_id") %>" value="<% = drow("away_id") %>" <% = away_selected %> onChange="dogamerow(<% = drow("game_id") %>)" ></TD><TD align=left ><INPUT TYPE="radio" NAME="game_<% = drow("game_id") %>" value="<% = drow("home_id") %>" <% = home_selected %> onChange="dogamerow(<% = drow("game_id") %>)"><a target=_blank href="<% = home_url %>"><% = drow("home_team") %> <% = home_record %></a> </TD></TR><%
				next
			end if
		end if
		%>		
		<tr><td colspan="3">Tie Breaker: <% = tiebreaker_game %> <input type="text" size="4" name="tiebreaker" value="<% = fb.gettiebreakervalue(pool_id:=pool_id, player_name:=player_name, week_id:=week_id) %>"></td></tr>
		</TABLE>
		<INPUT TYPE="submit" name="submit" value="Submit Picks">
		</form>
		To see what the <u>current</u> Vegas Favorites are, go to <a href="http://www.vegas.com/gaming" target="_blank">vegas.com</a><br />

		<BR><BR>

		<script type="text/javascript"><!--
		google_ad_client = "pub-8829998647639174";
		google_ad_width = 728;
		google_ad_height = 90;
		google_ad_format = "728x90_as";
		google_ad_type = "text_image";
		google_ad_channel = "";
		google_color_border = "6699CC";
		google_color_bg = "003366";
		google_color_link = "FFFFFF";
		google_color_text = "AECCEB";
		google_color_url = "AECCEB";
		//--></script>
		<script type="text/javascript"
		  src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
		</script>

	</div>

<div id="NavAlpha">
<% server.execute ("nav.aspx") %>
</div>



<!-- BlueRobot was here. -->

</body>
<%
if message_text <> "" then
	%><script>window.alert("<% = message_text.replace("""", "\""") %>")</script><%
end if
%>
</html>
