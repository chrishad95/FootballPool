<%
server.execute "/cookiecheck.asp"
server.execute "updateplayerscores.asp"

myname = session("username")

%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">

<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
<title>Football - Standings - rasputin.dnsalias.com [<% = session("username") %>]</title>
<style type="text/css" media="all">@import "/football/style.css";</style>
<style type="text/css">
.winner {
	background-color: #FFFF33;
	
}

.loser a {
	color:#333;
	font:11px verdana, arial, helvetica, sans-serif;
	text-decoration: none;
}
.winner a{
	color:#333;
	font:11px verdana, arial, helvetica, sans-serif;
	text-decoration: none;
}
.table_header {
	background-color: #C0C0C0;
}
.term {
	font:12px verdana, arial, helvetica, sans-serif;
	font-weight: bold;
	

}
.definition {
	font:11px verdana, arial, helvetica, sans-serif;

}

</style>
</head>

<body>

<div id="Header"><a href="http://rasputin.dnsalias.com">rasputin.dnsalias.com</a></div>

<div id="Content">
		<h2>Current Standings</h2>
		<%

		
		set cn=server.createobject("adodb.connection")
		cn.open application("dbname"), application("dbuser"), application("dbpword")
''''cn.open "testdb"

		sql = "select a.username, a.game_id, b.week_id, a.pick_id, b.away_id,  c.away_score, b.home_id, c.home_score from football.picks2 a full outer join football.sched b on a.game_id=b.game_id full outer join football.scores c on a.game_id=c.game_id where not a.username is null and not c.away_score is null order by a.username, b.week_id, a.game_id"
		
		
				
		set cmd=server.createobject("adodb.command") 'create a command object
		set cmd.activeconnection=cn // set active connection to the command object

		cmd.commandtext=sql
		cmd.prepared=true

		set rs = server.createobject("adodb.recordset")
		rs.cursortype = 3
		rs.cursorlocation = 2
		rs.open cmd		
		scores = rs.getrows()
		rs.close
		
		rowcount = ubound(scores,2)
		colcount = ubound(scores,1)
		
		'USERNAME,GAME_ID,WEEK_ID,PICK_ID,AWAY_ID,AWAY_SCORE,HOME_ID,HOME_SCORE 
		' USERNAME = scores(0,r)
		' GAME_ID = scores(1,r)
		' WEEK_ID = scores(2,r)
		' PICK_ID = scores(3,r)
		' AWAY_ID = scores(4,r)
		' AWAY_SCORE = scores(5,r)
		' HOME_ID = scores(6,r)
		' HOME_SCORE = scores(7,r)
		
		numplayers = 0
		current_player = ""
		set player_wins = CreateObject("Scripting.Dictionary")
		set player_nopicks = CreateObject("Scripting.Dictionary")
		set player_losses = CreateObject("Scripting.Dictionary")
		set player_wins_lw = CreateObject("Scripting.Dictionary")
		set player_losses_lw = CreateObject("Scripting.Dictionary")
		set player_wins_pts = CreateObject("Scripting.Dictionary")
		set player_losses_pts = CreateObject("Scripting.Dictionary")
		
		latest_week = 0
		for i = 0 to rowcount
			if scores(2,i) > latest_week then
				latest_week = scores(2,i)
			end if
		next
		
		for i = 0 to rowcount
			if not player_wins.exists(scores(0,i)  ) then
				player_wins.add scores(0,i) ,"0"
			end if
			if not player_nopicks.exists(scores(0,i)  ) then
				player_nopicks.add scores(0,i) ,"0"
			end if
			if not player_losses.exists(scores(0,i)  ) then
				player_losses.add scores(0,i) ,"0"
			end if
			if not player_losses_lw.exists(scores(0,i)  ) then
				player_losses_lw.add scores(0,i) ,"0"
			end if
			if not player_wins_lw.exists(scores(0,i)  ) then
				player_wins_lw.add scores(0,i) ,"0"
			end if
			if not player_losses_pts.exists(scores(0,i)  ) then
				player_losses_pts.add scores(0,i) ,"0"
			end if
			if not player_wins_pts.exists(scores(0,i)  ) then
				player_wins_pts.add scores(0,i) ,"0"
			end if
			if scores(3,i) = scores(4,i) then
				' picked away team
				if scores(5,i) > scores(7,i) then
					player_wins.item(scores(0,i) ) = cint(player_wins.item( scores(0,i) )) + 1
					player_wins_pts.item(scores(0,i) ) = cint(player_wins_pts.item( scores(0,i) )) + scores(5,i) - scores(7,i)
					
				else
					player_losses.item(scores(0,i) ) = cint(player_losses.item( scores(0,i) )) + 1	
					
					player_losses_pts.item(scores(0,i) ) = cint(player_losses_pts.item( scores(0,i) )) + scores(7,i) - scores(5,i)
				end if
				if scores(2,i) = latest_week then
					if scores(5,i) > scores(7,i) then
						player_wins_lw.item(scores(0,i) ) = cint(player_wins_lw.item( scores(0,i) )) + 1
					else
						player_losses_lw.item(scores(0,i) ) = cint(player_losses_lw.item( scores(0,i) )) + 1				
					end if
				end if
			end if
			if scores(3,i) = scores(6,i) then
				' picked home team
				if scores(5,i) < scores(7,i) then
					player_wins.item(scores(0,i) ) = cint(player_wins.item( scores(0,i) )) + 1
					
					player_wins_pts.item(scores(0,i) ) = cint(player_wins_pts.item( scores(0,i) )) + scores(7,i) - scores(5,i)
				else
					player_losses.item(scores(0,i) ) = cint(player_losses.item( scores(0,i) )) + 1
					
					player_losses_pts.item(scores(0,i) ) = cint(player_losses_pts.item( scores(0,i) )) + scores(5,i) - scores(7,i)
				
				end if
				if scores(2,i) = latest_week then
					if scores(5,i) < scores(7,i) then
						player_wins_lw.item(scores(0,i) ) = cint(player_wins_lw.item( scores(0,i) )) + 1
					else
						player_losses_lw.item(scores(0,i) ) = cint(player_losses_lw.item( scores(0,i) )) + 1				
					end if
				end if
			end if
			if isnull(scores(3,i)) then
			
						player_nopicks.item(scores(0,i) ) = cint(player_nopicks.item( scores(0,i) )) + 1			
			end if
		next
		
		rank = 1
		overall_best_score = 0
		overall_best_score_lw = 0
		%>
		<table border=1 cellspacing=0 cellpadding=4 id="standingstable">
		<tr>
		<td align=center class="table_header">Rank</td>
		<td align=center class="table_header">Player</td>
		<td align=center class="table_header">Total Score</td>
		<td align=center class="table_header">Points <br />behind</td>
		<td align=center class="table_header">Week #<% = latest_week %> <br />score</td>
		<td align=center class="table_header">Gain or (loss) <br />in Week #<% = latest_week %></td>
		<td align=center class="table_header">W</td>
		<td align=center class="table_header">L</td>
		<td align=center class="table_header">Win %</td>
		<td align=center class="table_header">Non Picks</td>
		<td align=center class="table_header">Bragging<br />Points</td>
		<td align=center class="table_header">Heartbreaker<br />Points</td>
		</tr>
		
		
		<%
		while player_wins.count > 0 
			temp = player_wins.keys
			best_player = ""
			best_score = 0
			
			for each p in temp
				if cint(player_wins.item(p)) > best_score then
					best_player = p
					best_score = cint(player_wins.item(p))
					if cint(best_score) > cint(overall_best_score) then
						overall_best_score = cint(best_score)
						overall_best_score_lw = player_wins_lw.item(p)
					end if
				end if
			next
			%>
			<tr>
			<td align=center><% = rank %></td>
			<td align=center><% = best_player %></td>
			<td align=center><% = best_score %></td>
			<%
			if overall_best_score = best_score then
				%><td align=center> - </td><%
			else
				%><td align=center><% = overall_best_score - best_score %></td><%
			end if
			%>			
			<td align=center><% = player_wins_lw(best_player) %></td>
			<td align=center><%
				if cint(overall_best_score_lw) = cint(player_wins_lw(best_player)) then
					%> - <%
				elseif cint(overall_best_score_lw) > cint(player_wins_lw(best_player)) then
					%>(<% = overall_best_score_lw - player_wins_lw(best_player) %>)<%
				else
					%><% = player_wins_lw(best_player) - overall_best_score_lw %><%
				end if
			
			
			%></td>
			<td align=center><% = player_wins(best_player) %></td>
			<td align=center><% = player_losses(best_player) %></td>
			<td align=center><% = formatpercent(player_wins(best_player) / (player_losses(best_player) + player_wins(best_player))) %></td>
			<td align=center><% =  player_nopicks(best_player) %></td>
			<td align=center><% =  formatnumber(player_wins_pts(best_player) / player_wins(best_player),2) %></td>
			<td align=center><% =  formatnumber(player_losses_pts(best_player) / player_losses(best_player),2) %></td>
			</tr><%
			player_wins.remove(best_player)
			player_losses.remove(best_player)
			player_wins_lw.remove(best_player)
			player_losses_lw.remove(best_player)
			rank = rank + 1
		
		wend
		
			
		
		%>
		</table>
		<h3>Explanation</h3>
		
		<span class="term">Total Score</span> - <span class="definition">This is the sum of all your good picks.  That is all the picks you made and the team you picked won the game.  This number is what the rank is based upon.</span>
		<br /><br />
		
		<span class="term">Points Behind</span> - <span class="definition">This is the number of points you are behind the leader (Rank #1).</span>  
		<br /><br />
		
		<span class="term">Week #x Score</span> - <span class="definition">This is your score for the latest week.</span>
		<br /><br />
		
		<span class="term">Gain or (Loss) in Week #x</span> - <span class="definition">This is how many points you gained or (lost) in relation to the leader's score.  Basically this is the difference between your score and the leader's score for the week.  You want a positive number here.</span>
		<br /><br />
		
		<span class="term">W</span> - <span class="definition">Your total number of wins, same as Total Score.</span>
		<br /><br />
		
		<span class="term">L</span> - <span class="definition">Your total number of losses,  games where didn't pick the winner.  A tie will count as a loss, for everybody.</span>
		<br /><br />
		
		<span class="term">Win % </span> - <span class="definition">Wins divided by (Wins + Losses).  This number shows how accurate your picks are when you make them.  A good stat for people who may not have made picks for all games.</span>
		<br /><br />
		
		<span class="term">Jeopardy Score</span> - <span class="definition">Wins minus Losses.  I'm not sure how useful this stat is.</span>
		<br /><br />
		
		<span class="term">Bragging Points</span> - <span class="definition">Take the games where you picked the winner.  Add all the points your winning teams won by.  Divide that number by the number of games where you picked the winner.  Meaning, on average when you picked the winner, this is how many points they won by. You want a high number here.</span>
		<br /><br />
		<span class="term">Heartbreaker Points</span> - <span class="definition">Similar to bragging points, take the games where you picked the loser.  Add all the points your losing teams lost by.  Divide that number by the number of games where you picked the loser.  Meaning, on average wen you picked the loser, this is how many points they lost by.  You want a low number here.</span>
		<br /><br />
</div>

<div id="Menu">
<% server.execute "/nav.asp" %>
<% server.execute "nav.asp" %>
</div>

<!-- BlueRobot was here. -->

</body>

</html>
