<%

set cn = server.createobject("adodb.connection")


cn.open application("dbname"), application("dbuser"), application("dbpword")
''''cn.open "testdb"

sql = "delete from football.player_scores"
cn.execute sql


sql = "select a.username, a.game_id, b.week_id, a.pick_id, b.away_id,  c.away_score, b.home_id, c.home_score from football.picks2 a full outer join football.sched b on a.game_id=b.game_id full outer join football.scores c on a.game_id=c.game_id where not a.username is null and not c.away_score is null order by a.username, b.week_id, a.game_id"


	
set cmd=server.createobject("adodb.command") 'create a command object
set cmd.activeconnection=cn // set active connection to the command object

cmd.commandtext=sql
cmd.prepared=true

set rs = server.createobject("adodb.recordset")
rs.cursortype = 3
rs.cursorlocation = 2
rs.open cmd	
while not rs.eof

	if rs(3) = rs(4) then
		' picked away
		if rs(5) > rs(7) then
			' pick was a winner
			sql = "insert into football.player_scores (username,game_id,score) values ('" & rs(0) & "'," & rs(1) & ",1)"
			cn.execute sql
			
		else
			' pick was a loser
			sql = "insert into football.player_scores (username,game_id,score) values ('" & rs(0) & "'," & rs(1) & ",0)"
			cn.execute sql
		end if
	end if
	if rs(3) = rs(6) then
		' picked home
		if rs(5) < rs(7) then
			' pick was a winner
			sql = "insert into football.player_scores (username,game_id,score) values ('" & rs(0) & "'," & rs(1) & ",1)"
			cn.execute sql
			
		else
			' pick was a loser
			sql = "insert into football.player_scores (username,game_id,score) values ('" & rs(0) & "'," & rs(1) & ",0)"
			cn.execute sql
		end if
	end if
	rs.movenext
	
wend
rs.close


%>
