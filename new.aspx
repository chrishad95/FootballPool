<%@ Page language="VB" runat="server" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SQLClient" %>
<%@ Import Namespace="System.Collections" %>
<script runat="server" language="VB">

	private sub MakeSystemLog (log_title as string, log_text as string)
	
		dim sql as string
		dim cmd as SQLCommand
		dim con as SQLConnection
		dim parm1 as SQLParameter
		
		sql = "insert into journal.entries (username,journal_type,entry_tsp,entry_date,entry_title,entry_text) values (?,?,current timestamp,date(current timestamp),?,?)"
		
		dim connstring as string
		connstring = ConfigurationSettings.AppSettings("connString")
		
		con = new SQLConnection(connstring)
		con.open()
		cmd = new SQLCommand(sql,con)
	
		parm1 = new SQLParameter("username", SQLDbType.varchar, 50)
		parm1.value = "chadley"
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("journal_type", SQLDbType.varchar, 20)
		parm1.value = "SYSTEM"
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("entry_title", SQLDbType.varchar, 200)
		parm1.value = log_title
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("entry_text", SQLDbType.text, 32700)
		parm1.value = log_text
		cmd.parameters.add(parm1)
		
		cmd.executenonquery()
	end sub 
	private function CreatePool(pool_owner as string, pool_name as string, pool_desc as string) as string
		
		dim res as string

		dim sql as string
		dim cmd as SQLCommand
		dim con as SQLConnection
		dim parm1 as SQLParameter
		
		dim connstring as string
		connstring = ConfigurationSettings.AppSettings("connString")
		
		con = new SQLConnection(connstring)
		con.open()

		sql = "create table pool.pools (pool_id int NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 100, INCREMENT BY 5),  pool_owner varchar(50), pool_name varchar(100), pool_desc varchar(500), pool_tsp timestamp)"

		sql = "select * from final table (insert into pool.pools (pool_owner, pool_name, pool_desc, pool_tsp) values (?,?,?,?))"

		cmd = new SQLCommand(sql,con)

		parm1 = new SQLParameter("@pool_owner", SQLDbType.varchar, 50)
		parm1.value = pool_owner
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("@pool_name", SQLDbType.varchar, 100)
		parm1.value = pool_name
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("@pool_desc", SQLDbType.varchar, 500)
		parm1.value = pool_desc
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("@pool_tsp", SQLDbType.datetime)
		parm1.value = datetime.now
		cmd.parameters.add(parm1)

		dim ds as new dataset()
		dim da as new SQLDataAdapter()
		da.selectcommand = cmd
		try
			da.fill(ds)

			if ds.tables(0).rows.count > 0 then
				res = ds.tables(0).rows(0)("pool_id")
			else
				res = "Create failed."
			end if
		catch ex as exception
			res = ex.message
		end try
		
		con.close()

		return res			

	end function
	private function UpdatePool(pool_id as integer, pool_owner as string, pool_name as string, pool_desc as string) as string
		
		dim res as string

		dim sql as string
		dim cmd as SQLCommand
		dim con as SQLConnection
		dim parm1 as SQLParameter
		
		dim connstring as string
		connstring = ConfigurationSettings.AppSettings("connString")
		
		con = new SQLConnection(connstring)
		con.open()

		
		sql = "select * from final table (insert into pool.pools (pool_owner, pool_name, pool_desc, pool_tsp) values (?,?,?,?))"
		sql = "update pool.pools set pool_owner=?, pool_name=?, pool_desc=?, pool_tsp=? where pool_id=?"

		cmd = new SQLCommand(sql,con)

		parm1 = new SQLParameter("@pool_owner", SQLDbType.varchar, 50)
		parm1.value = pool_owner
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("@pool_name", SQLDbType.varchar, 100)
		parm1.value = pool_name
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("@pool_desc", SQLDbType.varchar, 500)
		parm1.value = pool_desc
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("@pool_tsp", SQLDbType.datetime)
		parm1.value = datetime.now
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("@pool_id", SQLDbType.int)
		parm1.value = pool_id
		cmd.parameters.add(parm1)


		dim rowsupdated as integer

		try
			rowsupdated = cmd.executenonquery()
			res = rowsupdated
		catch ex as exception
			res = ex.message
		end try
		
		con.close()

		return res			

	end function

	private function AddTeam(pool_id as integer, team_name as string, team_shortname as string, team_url as string) as string
		
		dim res as string

		dim sql as string
		dim cmd as SQLCommand
		dim con as SQLConnection
		dim parm1 as SQLParameter
		
		dim connstring as string
		connstring = ConfigurationSettings.AppSettings("connString")
		
		con = new SQLConnection(connstring)
		con.open()


		sql = "select * from final table ( insert into pool.teams (pool_id, team_name, team_shortname, team_url, team_tsp) values (?,?,?,?,?) )"

		cmd = new SQLCommand(sql,con)

		parm1 = new SQLParameter("@pool_id", SQLDbType.int)
		parm1.value = pool_id
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("@team_name", SQLDbType.varchar, 100)
		parm1.value = team_name
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("@team_shortname", SQLDbType.varchar, 5)
		parm1.value = team_shortname
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("@team_url", SQLDbType.varchar, 255)
		parm1.value = team_url
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("@team_tsp", SQLDbType.datetime)
		parm1.value = datetime.now
		cmd.parameters.add(parm1)

		dim ds as new dataset()
		dim da as new SQLDataAdapter()
		da.selectcommand = cmd
		try
			da.fill(ds)

			if ds.tables(0).rows.count > 0 then
				res = ds.tables(0).rows(0)("team_id")
			else
				res = "Create failed."
			end if
		catch ex as exception
			res = ex.message
		end try
		
		con.close()

		return res	

	end function

	private function AddGameGroup(pool_id as integer, game_group_name as string) as string
			
		dim res as string

		dim sql as string
		dim cmd as SQLCommand
		dim con as SQLConnection
		dim parm1 as SQLParameter
		
		dim connstring as string
		connstring = ConfigurationSettings.AppSettings("connString")
		
		con = new SQLConnection(connstring)
		con.open()


		sql = "select * from final table ( insert into pool.gamegroups (pool_id, game_group_name, game_group_tsp) values (?,?,?) )"

		cmd = new SQLCommand(sql,con)

		parm1 = new SQLParameter("@pool_id", SQLDbType.int)
		parm1.value = pool_id
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("@game_group_name", SQLDbType.varchar, 100)
		parm1.value = game_group_name
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("@game_group_tsp", SQLDbType.datetime)
		parm1.value = datetime.now
		cmd.parameters.add(parm1)

		dim ds as new dataset()
		dim da as new SQLDataAdapter()
		da.selectcommand = cmd
		try
			da.fill(ds)

			if ds.tables(0).rows.count > 0 then
				res = ds.tables(0).rows(0)("game_group_id")
			else
				res = "Create failed."
			end if
		catch ex as exception
			res = ex.message
		end try
		
		con.close()

		return res	
	end function

	private function AddPlayer(pool_id as integer, username as string) as string
		dim res as string

		dim sql as string
		dim cmd as SQLCommand
		dim con as SQLConnection
		dim parm1 as SQLParameter
		
		dim connstring as string
		connstring = ConfigurationSettings.AppSettings("connString")
		
		con = new SQLConnection(connstring)
		con.open()


		sql = "select * from final table ( insert into pool.players (pool_id, username, player_tsp) values (?,?,?) )"

		cmd = new SQLCommand(sql,con)

		parm1 = new SQLParameter("@pool_id", SQLDbType.int)
		parm1.value = pool_id
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("@username", SQLDbType.varchar, 30)
		parm1.value = username
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("@player_tsp", SQLDbType.datetime)
		parm1.value = datetime.now
		cmd.parameters.add(parm1)

		dim ds as new dataset()
		dim da as new SQLDataAdapter()
		da.selectcommand = cmd
		try
			da.fill(ds)

			if ds.tables(0).rows.count > 0 then
				res = ds.tables(0).rows(0)("player_id")
			else
				res = "Create failed."
			end if
		catch ex as exception
			res = ex.message
		end try
		
		con.close()

		return res	
	end function

	private function AddGame(pool_id as integer, game_group_id as integer, game_time as datetime, home_id as integer, away_id as integer) as string
		
		dim res as string

		dim sql as string
		dim cmd as SQLCommand
		dim con as SQLConnection
		dim parm1 as SQLParameter
		
		dim connstring as string
		connstring = ConfigurationSettings.AppSettings("connString")
		
		con = new SQLConnection(connstring)
		con.open()


		sql = "select * from final table ( insert into pool.games (pool_id, game_group_id, game_time, home_id, away_id, game_tsp) values (?,?,?,?,?,?) )"

		cmd = new SQLCommand(sql,con)

		parm1 = new SQLParameter("@pool_id", SQLDbType.int)
		parm1.value = pool_id
		cmd.parameters.add(parm1)

		parm1 = new SQLParameter("@game_group_id", SQLDbType.int)
		parm1.value = game_group_id
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("@game_time", SQLDbType.datetime)
		parm1.value = game_time
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("@home_id", SQLDbType.int)
		parm1.value = home_id
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("@away_id", SQLDbType.int)
		parm1.value = away_id
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("@game_tsp", SQLDbType.datetime)
		parm1.value = datetime.now
		cmd.parameters.add(parm1)

		dim ds as new dataset()
		dim da as new SQLDataAdapter()
		da.selectcommand = cmd
		try
			da.fill(ds)

			if ds.tables(0).rows.count > 0 then
				res = ds.tables(0).rows(0)("game_id")
			else
				res = "Create failed."
			end if
		catch ex as exception
			res = ex.message
		end try
		
		con.close()

		return res	

	end function

	private function AddScore(game_id as integer, home_score as integer, away_score as integer) as string
		dim res as string

		dim sql as string
		dim cmd as SQLCommand
		dim con as SQLConnection
		dim parm1 as SQLParameter
		
		dim connstring as string
		connstring = ConfigurationSettings.AppSettings("connString")
		
		con = new SQLConnection(connstring)
		con.open()


		sql = "select * from final table ( insert into pool.scores (game_id, home_score, away_score, score_tsp) values (?,?,?,?) )"

		cmd = new SQLCommand(sql,con)

		parm1 = new SQLParameter("@game_id", SQLDbType.int)
		parm1.value = game_id
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("@home_score", SQLDbType.int)
		parm1.value = home_score
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("@away_score", SQLDbType.int)
		parm1.value = away_score
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("@score_tsp", SQLDbType.datetime)
		parm1.value = datetime.now
		cmd.parameters.add(parm1)

		dim ds as new dataset()
		dim da as new SQLDataAdapter()
		da.selectcommand = cmd
		try
			da.fill(ds)

			if ds.tables(0).rows.count > 0 then
				res = ds.tables(0).rows(0)("score_id")
			else
				res = "Create failed."
			end if
		catch ex as exception
			res = ex.message
		end try
		
		con.close()

		return res	
	end function
	
	private function UpdateScore(game_id as integer, home_score as integer, away_score as integer) as string
		dim res as string

		dim sql as string
		dim cmd as SQLCommand
		dim con as SQLConnection
		dim parm1 as SQLParameter
		
		dim connstring as string
		connstring = ConfigurationSettings.AppSettings("connString")
		
		con = new SQLConnection(connstring)
		con.open()


		sql = "update pool.scores set home_score=?, away_score=?, score_tsp=? where game_id=?"

		cmd = new SQLCommand(sql,con)

		parm1 = new SQLParameter("@home_score", SQLDbType.int)
		parm1.value = home_score
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("@away_score", SQLDbType.int)
		parm1.value = away_score
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("@score_tsp", SQLDbType.datetime)
		parm1.value = datetime.now
		cmd.parameters.add(parm1)
		parm1 = new SQLParameter("@game_id", SQLDbType.int)
		parm1.value = game_id
		cmd.parameters.add(parm1)

		dim rowsupdated as integer

		try
			rowsupdated = cmd.executenonquery()
			res = rowsupdated
		catch ex as exception
			res = ex.message
		end try
		
		con.close()

		return res	
	end function

</script>
<%
response.write ("hello world")
response.write ("<br />")

response.write (createpool(datetime.now.tostring(), "pool of chris", "my dang pool description"))
response.write ("<br />")

response.write (addteam(100, "Washington Redskins", "WAS", "http://www.washingtonredskins.com"))
response.write ("<br />")

response.write (addgame(100, 100, datetime.now, 100, 150))
response.write ("<br />")

response.write (addgamegroup(100, "week1"))
response.write ("<br />")

response.write (addplayer(100, "chadley"))
response.write ("<br />")

response.write (addscore(100, 17, 21))
response.write ("<br />")

response.write (updatescore(100, 31, 3))
response.write ("<br />")

response.write (updatepool(100, "chadley", "Awesome Pool", "Another description"))
response.write ("<br />")



%>