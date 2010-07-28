<%@ Page language="VB" runat="server" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SQLClient" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Web.Mail" %>
<script runat="server" language="VB">
	private myname as string = ""
	private myconnstring as string = ConfigurationSettings.AppSettings("connString")
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

	private function ListPools(pool_owner as string) as dataset

		dim res as new system.data.dataset()
		try
			dim sql as string
			dim cmd as SQLCommand
			dim con as SQLConnection
			dim parm1 as SQLParameter
			
			dim connstring as string
			connstring = ConfigurationSettings.AppSettings("connString")
			
			con = new SQLConnection(connstring)
			con.open()

			sql = "select * from pool.pools where pool_owner=?"

			cmd = new SQLCommand(sql,con)

			parm1 = new SQLParameter("@pool_owner", SQLDbType.varchar, 50)
			parm1.value = pool_owner
			cmd.parameters.add(parm1)

			dim oda as new SQLDataAdapter()
			oda.selectcommand = cmd
			oda.fill(res)
		
			con.close()
		catch ex as exception
			makesystemlog("Error getting pool list", ex.tostring())
		end try

		return res
	end function

	private function GetPoolDetails(pool_owner as string, pool_id as integer) as dataset

		dim res as new system.data.dataset()
		try
			dim sql as string
			dim cmd as SQLCommand
			dim con as SQLConnection
			dim parm1 as SQLParameter
			
			dim connstring as string
			connstring = ConfigurationSettings.AppSettings("connString")
			
			con = new SQLConnection(connstring)
			con.open()

			sql = "select * from pool.pools where pool_owner=? and pool_id=?"

			cmd = new SQLCommand(sql,con)

			parm1 = new SQLParameter("@pool_owner", SQLDbType.varchar, 50)
			parm1.value = pool_owner
			cmd.parameters.add(parm1)

			parm1 = new SQLParameter("@pool_id", SQLDbType.int)
			parm1.value = pool_id
			cmd.parameters.add(parm1)

			dim oda as new SQLDataAdapter()
			oda.selectcommand = cmd
			oda.fill(res)
		
			con.close()
		catch ex as exception
			makesystemlog("Error getting pool details", ex.tostring())
		end try

		return res
	end function


	private function GetPoolGames(pool_owner as string, pool_id as integer) as dataset

		dim res as new system.data.dataset()
		try
			dim sql as string
			dim cmd as SQLCommand
			dim con as SQLConnection
			dim parm1 as SQLParameter
			
			dim connstring as string
			connstring = ConfigurationSettings.AppSettings("connString")
			
			con = new SQLConnection(connstring)
			con.open()

			sql = "select sched.game_id, sched.week_id, sched.home_id, sched.away_id, sched.game_tsp, sched.game_url, sched.pool_id, away.team_name as away_team_name, away.team_shortname as away_team_shortname, home.team_name as home_team_name, home.team_shortname as home_team_shortname from football.sched sched full outer join football.teams home on sched.pool_id=home.pool_id and sched.home_id=home.team_id full outer join football.teams away on sched.pool_id=away.pool_id and sched.away_id=away.team_id where sched.pool_id in (select pool_id from pool.pools where pool_owner=? and pool_id=?) order by sched.game_tsp"

			cmd = new SQLCommand(sql,con)

			parm1 = new SQLParameter("@pool_owner", SQLDbType.varchar, 50)
			parm1.value = pool_owner
			cmd.parameters.add(parm1)

			parm1 = new SQLParameter("@pool_id", SQLDbType.int)
			parm1.value = pool_id
			cmd.parameters.add(parm1)

			dim oda as new SQLDataAdapter()
			oda.selectcommand = cmd
			oda.fill(res)
		
			con.close()
		catch ex as exception
			makesystemlog("Error getting pool games", ex.tostring())
		end try

		return res
	end function


	private function GetPoolTeams(pool_owner as string, pool_id as integer) as dataset

		dim res as new system.data.dataset()
		try
			dim sql as string
			dim cmd as SQLCommand
			dim con as SQLConnection
			dim parm1 as SQLParameter
			
			dim connstring as string
			connstring = ConfigurationSettings.AppSettings("connString")
			
			con = new SQLConnection(connstring)
			con.open()

			sql = "select * from football.teams where pool_id in (select pool_id from pool.pools where pool_owner=? and pool_id=?) order by team_name"

			cmd = new SQLCommand(sql,con)

			parm1 = new SQLParameter("@pool_owner", SQLDbType.varchar, 50)
			parm1.value = pool_owner
			cmd.parameters.add(parm1)

			parm1 = new SQLParameter("@pool_id", SQLDbType.int)
			parm1.value = pool_id
			cmd.parameters.add(parm1)

			dim oda as new SQLDataAdapter()
			oda.selectcommand = cmd
			oda.fill(res)
		
			con.close()
		catch ex as exception
			makesystemlog("Error getting pool details", ex.tostring())
		end try

		return res
	end function

	private function GetPoolInvitations(pool_owner as string, pool_id as string) as dataset

		dim res as new system.data.dataset()
		try
			dim sql as string
			dim cmd as SQLCommand
			dim con as SQLConnection
			dim parm1 as SQLParameter
			
			dim connstring as string
			connstring = ConfigurationSettings.AppSettings("connString")
			
			con = new SQLConnection(connstring)
			con.open()

			sql = "select * from pool.invites where pool_id in (select pool_id from pool.pools where pool_owner=? and pool_id=?) order by email"

			cmd = new SQLCommand(sql,con)

			parm1 = new SQLParameter("@pool_owner", SQLDbType.varchar, 50)
			parm1.value = pool_owner
			cmd.parameters.add(parm1)

			parm1 = new SQLParameter("@pool_id", SQLDbType.int)
			parm1.value = pool_id
			cmd.parameters.add(parm1)

			dim oda as new SQLDataAdapter()
			oda.selectcommand = cmd
			oda.fill(res)
		
			con.close()
		catch ex as exception
			makesystemlog("Error getting pool invites", ex.tostring())
		end try

		return res

	end function

	private function GetPoolPlayers(pool_owner as string, pool_id as integer) as dataset

		dim res as new system.data.dataset()
		try
			dim sql as string
			dim cmd as SQLCommand
			dim con as SQLConnection
			dim parm1 as SQLParameter
			
			dim connstring as string
			connstring = ConfigurationSettings.AppSettings("connString")
			
			con = new SQLConnection(connstring)
			con.open()

			sql = "select * from pool.players where pool_id in (select pool_id from pool.pools where pool_owner=? and pool_id=?) order by username"

			cmd = new SQLCommand(sql,con)

			parm1 = new SQLParameter("@pool_owner", SQLDbType.varchar, 50)
			parm1.value = pool_owner
			cmd.parameters.add(parm1)

			parm1 = new SQLParameter("@pool_id", SQLDbType.int)
			parm1.value = pool_id
			cmd.parameters.add(parm1)

			dim oda as new SQLDataAdapter()
			oda.selectcommand = cmd
			oda.fill(res)
		
			con.close()
		catch ex as exception
			makesystemlog("Error getting pool players", ex.tostring())
		end try

		return res
	end function


	private function UpdatePool(POOL_ID as INTEGER, POOL_OWNER as String, POOL_NAME as String, POOL_DESC as String, ELIGIBILITY as String, POOL_LOGO as String, POOL_BANNER as String) as string
		dim res as string = ""
		try
			dim cn as new SQLConnection()
			cn.connectionstring = myconnstring
			cn.open()
			dim sql as string = "update POOL.POOLS set POOL_NAME=?, POOL_DESC=?, POOL_TSP=?, ELIGIBILITY=?, POOL_LOGO=?, POOL_BANNER=? where POOL_ID=? and pool_owner=?"
			dim cmd as SQLCommand = new SQLCommand(sql, cn)

			cmd.parameters.add(new SQLParameter("@POOL_NAME", SQLDbType.VARCHAR, 100))
			cmd.parameters.add(new SQLParameter("@POOL_DESC", SQLDbType.VARCHAR, 500))
			cmd.parameters.add(new SQLParameter("@POOL_TSP", SQLDbType.datetime))
			cmd.parameters.add(new SQLParameter("@ELIGIBILITY", SQLDbType.VARCHAR, 10))
			cmd.parameters.add(new SQLParameter("@POOL_LOGO", SQLDbType.VARCHAR, 255))
			cmd.parameters.add(new SQLParameter("@POOL_BANNER", SQLDbType.VARCHAR, 255))
			cmd.parameters.add(new SQLParameter("@POOL_ID", SQLDbType.int))
			cmd.parameters.add(new SQLParameter("@POOL_OWNER", SQLDbType.VARCHAR, 50))
			cmd.parameters("@POOL_ID").value = POOL_ID
			cmd.parameters("@POOL_OWNER").value = POOL_OWNER
			cmd.parameters("@POOL_NAME").value = POOL_NAME
			cmd.parameters("@POOL_DESC").value = POOL_DESC
			cmd.parameters("@POOL_TSP").value = system.datetime.now
			cmd.parameters("@ELIGIBILITY").value = ELIGIBILITY
			cmd.parameters("@POOL_LOGO").value = POOL_LOGO
			cmd.parameters("@POOL_BANNER").value = POOL_BANNER
			cmd.executenonquery()
			cn.close()
			res = pool_name
		catch ex as exception
			res = ex.toString()
		end try
		return res
	end function

	private function CreateTeam(TEAM_NAME as String, TEAM_SHORTNAME as String, URL as String, POOL_ID as INTEGER, pool_owner as string) as string
		dim res as string = ""

		try
			dim cn as new SQLConnection()
			cn.connectionstring = myconnstring
			cn.open()

			dim sql as string = ""

			dim pools_ds as dataset = listpools(pool_owner)

			if pools_ds.tables.count > 0 then
				dim temp_rows as datarow()
				temp_rows = pools_ds.tables(0).select("pool_id=" & pool_id)
				if temp_rows.length > 0 then

					sql = "insert into FOOTBALL.TEAMS(TEAM_NAME, TEAM_SHORTNAME, URL, POOL_ID) values ( ?, ?, ?, ?)"
					dim cmd as SQLCommand = new SQLCommand(sql, cn)

					cmd.parameters.add(new SQLParameter("@TEAM_NAME", SQLDbType.VARCHAR, 20))
					cmd.parameters.add(new SQLParameter("@TEAM_SHORTNAME", SQLDbType.CHAR, 3))
					cmd.parameters.add(new SQLParameter("@URL", SQLDbType.VARCHAR, 200))
					cmd.parameters.add(new SQLParameter("@POOL_ID", SQLDbType.int))
					cmd.parameters("@TEAM_NAME").value = TEAM_NAME
					cmd.parameters("@TEAM_SHORTNAME").value = TEAM_SHORTNAME
					cmd.parameters("@URL").value = URL
					cmd.parameters("@POOL_ID").value = POOL_ID
					cmd.executenonquery()
					cn.close()
					res = team_name
				else
					res = "invalid pool_id for " & pool_owner
				end if
			else
				res = "No Pools found for " & pool_owner
			end if


		catch ex as exception
			if ex.message.tostring().indexof("duplicate rows") >= 0 then
				res = "Team already exists for this pool."
			else
				res = ex.message
				makesystemlog("Error in Create Team", ex.tostring())
			end if

		end try
		return res
	end function
	
	private function InvitePlayer(POOL_ID as INTEGER, pool_owner as string, email as string)

		dim res as string = ""
		try
			dim pools_ds as dataset = listpools(pool_owner)

			if pools_ds.tables.count > 0 then
				dim temp_rows as datarow()
				temp_rows = pools_ds.tables(0).select("pool_id=" & pool_id)
				if temp_rows.length > 0 then
					dim invite_key as string = createinvitekey()
					'CreateInvite(POOL_ID as INTEGER, EMAIL as String, INVITE_KEY as String, INVITE_TSP as datetime)
					res = createinvite(pool_id:=pool_id, email:=email, invite_key:=invite_key, invite_tsp:=system.datetime.now)
					if res = email then
						sendinvite(email:=email, invite_key:=invite_key, pool_id:=pool_id, pool_owner:=temp_rows(0)("pool_owner"), pool_name:=temp_rows(0)("pool_name"))
					end if
				else
					res = "invalid pool_id for " & pool_owner
				end if
			else
				res = "No Pools found for " & pool_owner
			end if


		catch ex as exception
			if ex.message.tostring().indexof("duplicate rows") >= 0 then
				res = "Team already exists for this pool."
			else
				res = ex.message
				makesystemlog("Error in InvitePlayer", ex.tostring())
			end if

		end try
		return res
	end function
	
	private sub SendInvite(email as string, invite_key as string, pool_id as string, pool_owner as string, pool_name as string)

		dim sb as new stringbuilder()
		
		sb.append("You have been invited to participate in a pool created by " & pool_owner & ".  <br><br>" & system.environment.newline)
		
		
		
		sb.append("To accept the invitation please visit the following link.<br><br>" & system.environment.newline)
		sb.append("Go to:<br /> <a href=""http://superpools.gotdns.com/football/acceptinvite.aspx?pool_id=" & pool_id & "&email=" & email & "&invite_key=" & invite_key & """>http://superpools.gotdns.com/football/acceptinvite.aspx?pool_id=" & pool_id & "&email=" & email & "&invite_key=" & invite_key & "</a> <br /><br /><br />" & system.environment.newline & system.environment.newline  )
		

		
		sb.append ("Thanks,<br />" & system.environment.newline & "Chris<br><br>" & system.environment.newline)
		
		'response.write(sb.tostring())
		
		dim myMessage as New MailMessage()
		
		myMessage.BodyFormat = MailFormat.Html
		myMessage.From = "chrishad95@yahoo.com"
		myMessage.To = email
		myMessage.Subject = "Invitation to " & pool_name 
		myMessage.Body = sb.toString()
		
		myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/smtsperver", "smtp.mail.yahoo.com")
		myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/smtpserverport", 25)
		myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/sendusing", 2)
		myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate", 1)
		myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/sendusername", "chrishad95")
		myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/sendpassword", "househorse89")

		' Doesn't have to be local... just enter your
		' SMTP server's name or ip address!
		
		
		SmtpMail.SmtpServer = "smtp.mail.yahoo.com"
		try
			SmtpMail.Send(myMessage)
		catch 		
			try
				SmtpMail.Send(myMessage)
			catch 		
				try
					SmtpMail.Send(myMessage)
				catch ex as exception
					response.write(ex.tostring())
				end try
			end try
		end try
	end sub

	private function CreateInviteKey()

		'Need to create random password.
		Dim validcharacters as String
		
		validcharacters = "ABCDEFGHIJKLMNPQRSTUVWXYZabcdefghijklmnpqrstuvwxyz23456789"
		
		dim c as char
		Thread.Sleep( 30 )
		
		Dim fixRand As New Random()
		dim randomstring as stringbuilder = new stringbuilder(20)
		
		
		dim i as integer
		for i = 0 to 29    
		
			randomstring.append(validcharacters.substring(fixRand.Next( 0, len(validcharacters) ),1))
			
			
		next

		return randomstring.tostring()
	end function


	private function CreateInvite(POOL_ID as INTEGER, EMAIL as String, INVITE_KEY as String, INVITE_TSP as datetime) as string
		dim res as string = ""
		try
			dim cn as new SQLConnection()
			cn.connectionstring = myconnstring
			cn.open()
			dim sql as string = "insert into POOL.INVITES(POOL_ID, EMAIL, INVITE_KEY, INVITE_TSP) values (?, ?, ?, ?)"
			dim cmd as SQLCommand = new SQLCommand(sql, cn)

			cmd.parameters.add(new SQLParameter("@POOL_ID", SQLDbType.int))
			cmd.parameters.add(new SQLParameter("@EMAIL", SQLDbType.VARCHAR, 255))
			cmd.parameters.add(new SQLParameter("@INVITE_KEY", SQLDbType.VARCHAR, 40))
			cmd.parameters.add(new SQLParameter("@INVITE_TSP", SQLDbType.datetime))
			cmd.parameters("@POOL_ID").value = POOL_ID
			cmd.parameters("@EMAIL").value = EMAIL
			cmd.parameters("@INVITE_KEY").value = INVITE_KEY
			cmd.parameters("@INVITE_TSP").value = INVITE_TSP
			cmd.executenonquery()
			cn.close()
			res = email
		catch ex as exception
			res =  ex.toString()
		end try
		return res
	end function

	private function UpdateTeam(TEAM_ID as INTEGER, TEAM_NAME as String, TEAM_SHORTNAME as String, URL as String, POOL_ID as INTEGER, pool_owner as string) as string
		dim res as string = ""
		try
			dim cn as new SQLConnection()
			cn.connectionstring = myconnstring
			cn.open()
			dim sql as string = ""

			dim pools_ds as dataset = listpools(pool_owner)

			if pools_ds.tables.count > 0 then
				dim temp_rows as datarow()
				temp_rows = pools_ds.tables(0).select("pool_id=" & pool_id)
				if temp_rows.length > 0 then

					sql = "update FOOTBALL.TEAMS set TEAM_NAME=?, TEAM_SHORTNAME=?, URL=? where POOL_ID=? and TEAM_ID=?"
					dim cmd as SQLCommand = new SQLCommand(sql, cn)
					dim rowsupdated as integer

					cmd.parameters.add(new SQLParameter("@TEAM_NAME", SQLDbType.VARCHAR, 20))
					cmd.parameters.add(new SQLParameter("@TEAM_SHORTNAME", SQLDbType.char, 3))
					cmd.parameters.add(new SQLParameter("@URL", SQLDbType.VARCHAR, 200))
					cmd.parameters.add(new SQLParameter("@POOL_ID", SQLDbType.int))
					cmd.parameters.add(new SQLParameter("@TEAM_ID", SQLDbType.int))
					cmd.parameters("@TEAM_ID").value = TEAM_ID
					cmd.parameters("@TEAM_NAME").value = TEAM_NAME
					cmd.parameters("@TEAM_SHORTNAME").value = TEAM_SHORTNAME
					cmd.parameters("@URL").value = URL
					cmd.parameters("@POOL_ID").value = POOL_ID
					rowsupdated = cmd.executenonquery()
					cn.close()
					if rowsupdated > 0 then
						res = team_name
					else
						res = "Team was not updated."
						response.write ("TEAM_ID=" & TEAM_ID & "<br />")
						response.write ("team_name=" & team_name & "<br />")
						response.write ("TEAM_SHORTNAME=" & TEAM_SHORTNAME & "<br />")
						response.write ("URL=" & URL & "<br />")
						response.write ("POOL_ID=" & POOL_ID & "<br />")

					end if
				else
					res = "invalid pool_id for " & pool_owner
				end if
			else
				res = "No Pools found for " & pool_owner
			end if


		catch ex as exception
			if ex.message.tostring().indexof("duplicate rows") >= 0 then
				res = "Team already exists for this pool."
			else
				res = ex.message
				makesystemlog("Error in Update Team", ex.tostring())
			end if

		end try
		return res
	end function

	private function CreateGame(WEEK_ID as INTEGER, HOME_ID as INTEGER, AWAY_ID as INTEGER, GAME_TSP as datetime, GAME_URL as String, POOL_ID as INTEGER, pool_owner as string) as string
		dim res as string = ""
		try
			dim cn as new SQLConnection()
			cn.connectionstring = myconnstring
			cn.open()



			dim pools_ds as dataset = listpools(pool_owner)

			if pools_ds.tables.count > 0 then
				dim temp_rows as datarow()
				temp_rows = pools_ds.tables(0).select("pool_id=" & pool_id)
				if temp_rows.length > 0 then

					dim sql as string = "insert into FOOTBALL.SCHED(WEEK_ID, HOME_ID, AWAY_ID, GAME_TSP, GAME_URL, POOL_ID) values (?, ?, ?, ?, ?, ?)"


					dim cmd as SQLCommand = new SQLCommand(sql, cn)

					cmd.parameters.add(new SQLParameter("@WEEK_ID", SQLDbType.int))
					cmd.parameters.add(new SQLParameter("@HOME_ID", SQLDbType.int))
					cmd.parameters.add(new SQLParameter("@AWAY_ID", SQLDbType.int))
					cmd.parameters.add(new SQLParameter("@GAME_TSP", SQLDbType.datetime))
					cmd.parameters.add(new SQLParameter("@GAME_URL", SQLDbType.VARCHAR, 300))
					cmd.parameters.add(new SQLParameter("@POOL_ID", SQLDbType.int))
					cmd.parameters("@WEEK_ID").value = WEEK_ID
					cmd.parameters("@HOME_ID").value = HOME_ID
					cmd.parameters("@AWAY_ID").value = AWAY_ID
					cmd.parameters("@GAME_TSP").value = GAME_TSP
					cmd.parameters("@GAME_URL").value = GAME_URL
					cmd.parameters("@POOL_ID").value = POOL_ID
					cmd.executenonquery()
					cn.close()
					res = pool_owner
				else
					res = "invalid pool_id for " & pool_owner
				end if
			else
				res = "No Pools found for " & pool_owner
			end if

		catch ex as exception
			res = ex.message
			makesystemlog("Error adding game", ex.tostring())
		end try
		return res
	end function



	private sub CallError(message as string)
		session("page_message") = message
		response.redirect("/error", true)
	end sub

</script>
<%
	dim http_host as string = ""
	try
		http_host = request.servervariables("HTTP_HOST")
	catch
	end try

	server.execute ("/cookiecheck.aspx")
	dim message_text as string = ""
	try
		myname = session("username")
	catch
	end try
	if myname = "" then
		session("page_message") = "You must login to create pools."
		response.redirect("/error", true)
	end if

	dim pool_id as integer
	try
		if request("pool_id") <> "" then
			pool_id = request("pool_id")
		end if
	catch
	end try



	try
		if request("submit") = "Update Pool Details" then
			updatepool(pool_id:=pool_id, pool_owner:=myname, pool_name:=request("poolname"), pool_desc:=request("desc"), pool_banner:=request("bannerurl"), pool_logo:=request("logourl"), eligibility:=request("eligibility"))
		end if
	catch
	end try
	'CreateTeam(TEAM_NAME as String, TEAM_SHORTNAME as String, URL as String, POOL_ID as INTEGER)
	try
		if request("submit") = "Add Team" then
			dim res as string = ""
			res = createteam(pool_id:=pool_id, pool_owner:=myname, team_name:=request("team_name"), team_shortname:=request("team_shortname"), url:=request("url"))
			if res <> request("team_name") then
				message_text = res
			else
				message_text = "Team was added successfully."
			end if
		end if
	catch
	end try

	'CreateGame(WEEK_ID as INTEGER, HOME_ID as INTEGER, AWAY_ID as INTEGER, GAME_TSP as datetime, GAME_URL as String, POOL_ID as INTEGER)
	try
		if request("submit") = "Add Game" then
			dim game_time as string

			dim res as string = ""
			res = creategame(pool_id:=pool_id, pool_owner:=myname, week_id:=request("week_id"), home_id:=request("home_id_select"), away_id:=request("away_id_select"), game_tsp:=request("game_time"), game_url:=request("game_url"))
			if res <> myname then
				message_text = res
			else
				message_text = "Game was added successfully."
			end if
		end if
	catch ex as exception
		message_text = ex.message
		makesystemlog("error adding game", ex.tostring())
	end try

	try
		if request("submit") = "Edit Team" then
			dim res as string = ""
			res = updateteam(team_id:=request("team_select"), pool_id:=pool_id, pool_owner:=myname, team_name:=request("team_name"), team_shortname:=request("team_shortname"), url:=request("url"))
			if res <> request("team_name") then
				message_text = res
			else
				message_text = "Team was updated successfully."
			end if
		end if
	catch
	end try

	try
		if request("submit") = "Invite Player" then
			dim res as string = ""
			res = InvitePlayer(pool_id:=pool_id, pool_owner:=myname, email:=request("invite_player_email"))
			if res <> request("invite_player_email") then
				message_text = res
			end if
		end if
	catch
	end try

	dim pool_ds as dataset
	pool_ds = GetPoolDetails(myname, pool_id)
	
	dim pool_drow as datarow

	if pool_ds.tables.count > 0 then
		if pool_ds.tables(0).rows.count > 0 then
			Pool_drow = pool_ds.tables(0).rows(0)
		else
			callerror("Pool not found.")
		end if
	else
		callerror("Pool not found.")
	end if
	dim teams_ds as dataset
	teams_ds = getpoolteams(myname, pool_id)

	dim players_ds as dataset
	players_ds = getPoolPlayers(pool_owner:=myname, pool_id:=pool_id)


%>
<html>
<head>
<title>Pool Admin Page</title>    
	<script type="text/javascript" src="jquery.js"></script>
    <script type="text/javascript" src="cmxform.js"></script>
	 <script>
		var teams = {};
		<%
		try
			for each team_drow as datarow in teams_ds.tables(0).rows
				response.write(system.environment.newline)
				%>teams[<% = team_drow("team_id") %>]= new Array("<% = team_drow("team_name") %>","<% = team_drow("team_shortname") %>","<% = team_drow("url") %>");<%
			next
		catch
		end try
		
		%>
		function handleteamselect() {
			var x=document.getElementsByName("team_select");
			var idx = x[0].value;

			x = document.getElementsByName("team_name");
			x[0].value = teams[idx][0];

			x = document.getElementsByName("team_shortname");
			x[0].value = teams[idx][1];

			x = document.getElementsByName("url");
			x[0].value = teams[idx][2];

		}
	 </script>
	<style type="text/css" media="all">@import "/football/style2.css";</football/style>
	<style type="text/css" media="all">@import "like-adw.css";</football/style>
<style>
	form.cmxform fieldset {
	  margin-bottom: 10px;
	}
	form.cmxform legend {
	  padding: 0 2px;
	  font-weight: bold;
	}
	form.cmxform label {
	  display: inline-block;
	  line-height: 1.8;
	  vertical-align: top;
	}
	form.cmxform fieldset ol {
	  margin: 0;
	  padding: 0;
	}
	form.cmxform fieldset li {
	  list-style: none;
	  padding: 5px;
	  margin: 0;
	}
	form.cmxform fieldset fieldset {
	  border: none;
	  margin: 3px 0 0;
	}
	form.cmxform fieldset fieldset legend {
	  padding: 0 0 5px;
	  font-weight: normal;
	}
	form.cmxform fieldset fieldset label {
	  display: block;
	  width: auto;
	}
	form.cmxform em {
	  font-weight: bold;
	  font-style: normal;
	  color: #f00;
	}
	form.cmxform label {
	  width: 120px; /* Width of labels */
	}
	form.cmxform fieldset fieldset label {
	  margin-left: 123px; /* Width plus 3 (html space) */
	}
</football/style>
</head>

<body onLoad="handleteamselect()">

<div id="Header"><% = http_host %></div>

<div id="Content">
	<h2><% = pool_drow("pool_name") %></h2>

	<%
	if message_text <> "" then
		%><script>window.alert("<% = message_text.replace("""", "\""") %>")</script><%
	end if
	%>
	<form class="cmxform">
		<input type="hidden" name="pool_id" value="<% = pool_drow("pool_id") %>" />
		<fieldset>
			<legend>Pool Details</legend>
			<ol>
				<li><label for="poolname">Name <em>*</em></label> <input type="text" name="poolname" id="poolname" value = "<% = pool_drow("pool_name") %>" /></li>
				<li><label for="desc">Description </label> <textarea id="desc" name="desc" /><% = pool_drow("pool_desc") %></textarea></li>
				<li><label for="bannerurl">Banner Url </label> <input id="bannerurl" name="bannerurl" value="<% = pool_drow("pool_banner") %>" /></li>
				<li><label for="logourl">Logo Url </label> <input id="logourl" name="logourl" value="<% = pool_drow("pool_logo") %>" /></li>
				<li><label for="eligibility">Eligibility <em>*</em></label> <select name="eligibility" id="eligibility"><%
					try
						dim temparray() as string = {"OPEN","BEFORE","AFTER"}
						for each s as string in temparray
							if s = pool_drow("eligibility") then
								%><option value="<% = s %>" SELECTED><% = s %></option><%
							else
								%><option value="<% = s %>" ><% = s %></option><%
							end if
						next
					catch ex as exception
						makesystemlog("Error in adminpool.aspx", ex.tostring())
					end try
				
				%></select></li>
			</ol>
			<input type="submit" name="submit" value="Update Pool Details" />
		</fieldset>
	</form>

	<form class="cmxform">
		<input type="hidden" name="pool_id" value="<% = pool_drow("pool_id") %>" />
		<fieldset>
			<legend>Teams</legend>
			<%
				if teams_ds.tables.count > 0 then
					if teams_ds.tables(0).rows.count > 0 then
						%><li><label for="team_select">Teams </label> <select onChange="handleteamselect()" name="team_select" id="team_select"><%
						for each team_drow as datarow in teams_ds.tables(0).rows
							%><option value="<% = team_drow("team_id") %>"><% = team_drow("team_name") %></option><%
						next
						%></select> <input type="submit" name="submit" value="Delete Team"></li><%
					else
						%><ol><li><label >No teams found.</li></ol><%
					end if
				else
					%><ol><li><label >No teams found.</li></ol><%
				end if
			%>
			
			<ol>
				<li><label ><b>Team Details</b></li>
				<li><label for="team_name">Team Name <em>*</em></label> <input type="text" name="team_name" id="team_name" value = "" /></li>
				<li><label for="team_shortname">Team Shortname </label> <input type="text" id="team_shortname" name="team_shortname" /></li>
				<li><label for="url">Team Url </label> <input id="url" name="url" value="" /></li>
			</ol>
			<input type="submit" name="submit" value="Add Team" /> <input type="submit" name="submit" value="Edit Team">
		</fieldset>
	</form>

	<form class="cmxform">
		<input type="hidden" name="pool_id" value="<% = pool_drow("pool_id") %>" />
		<fieldset>
			<legend>Players</legend>
			<%
				if players_ds.tables.count > 0 then
					if players_ds.tables(0).rows.count > 0 then
						%><ol><li><label for="player_select">Players </label> <select name="player_select" id="player_select"><%
						for each player_drow as datarow in players_ds.tables(0).rows
							%><option value="<% = player_drow("player_id") %>"><% = player_drow("player_name") %></option><%
						next
						%></select> <input type="submit" name="submit" value="Delete Player"></li></ol><%
					else
						%><ol><li><label >No players found.</li></ol><%
					end if
				else
					%><ol><li><label >No players found.</li></ol><%
				end if
			%>
			<ol>
				<li><label for="invite_player_email">Email </label> <input type="text" name="invite_player_email" id="invite_player_email" value = "" /> <input type="submit" name="submit" value="Invite Player"></li>
			</ol>
			<%
				try
					dim invites_ds as dataset
					invites_ds = GetPoolInvitations(pool_id:=pool_id, pool_owner:=myname)

					if invites_ds.tables.count > 0 then
						if invites_ds.tables(0).rows.count > 0 then
							%>
							<table>			
							<caption>Open Invitations</caption>
							<thead>
								<tr>
									<th scope="col">Email Address</th>
									<th scope="col">Invitation Time</th>
									<th scope="col">Actions</th>
								</tr>
							</thead>	
							<tfoot>
								<tr>
									<th scope="row">Total</th>
									<td colspan="2"><% = invites_ds.tables(0).rows.count %> invitations</td>
								</tr>
							</tfoot>	
							<tbody>
							<%
							for each invite_drow as datarow in invites_ds.tables(0).rows
								%><tr>
								<td><% = invite_drow("email") %></td>
								<td><% = invite_drow("invite_tsp") %></td>
								<td><a href="deleteinvite.aspx?pool_id=<% = pool_id %>&<% = invite_drow("email") %>">Delete</a></td>
								</tr><%
							next
							%></tbody></table><%
						else
							%><ol><li><label >No invitations found.</li></ol><%
						end if
					else
						%><ol><li><label >No invitations found.</li></ol><%
					end if
				catch ex as exception
					makesystemlog("error in adminpool.aspx", ex.tostring())
				end try
			%>
		</fieldset>
	</form>
	
	<form class="cmxform">
		<input type="hidden" name="pool_id" value="<% = pool_drow("pool_id") %>" />
		<fieldset>
			<legend>Games</legend>
			<%
			
				dim games_ds as new dataset()
				try
					games_ds = GetPoolGames(pool_id:=pool_id, pool_owner:=myname)
				catch
				end try
				dim teams_rows as datarow()

				if teams_ds.tables.count > 0 then
					if teams_ds.tables(0).rows.count > 0 then
						teams_rows = teams_ds.tables(0).select("1=1", "team_name asc")
					end if
				end if

				if games_ds.tables.count > 0 then
					if games_ds.tables(0).rows.count > 0 then
						%><li><label for="game_select">Games </label> <select  name="game_select" id="game_select"><%
						for each drow as datarow in games_ds.tables(0).rows
							%><option value="<% = drow("game_id") %>"><% = drow("away_team_name") %> at <% = drow("home_team_name") %> on <% = drow("game_tsp") %></option><%
						next
						%></select> <input type="submit" name="submit" value="Delete Game"></li><%
					else
						%><ol><li><label >No games found.</li></ol><%
					end if
				else
					%><ol><li><label >No games found.</li></ol><%
				end if
			%>
			
			<ol>
				<li><label ><b>Game Details</b></li>
				<li><label for="away_id_select">Away Team <em>*</em></label> <select name="away_id_select" id="away_id_select"><%
						for each drow as datarow in teams_rows
							%><option value="<% = drow("team_id") %>"><% = drow("team_name") %></option><%
						next
						%></select></li>
				<li><label for="home_id_select">Home Team <em>*</em></label> <select name="home_id_select" id="home_id_select"><%
						for each drow as datarow in teams_rows
							%><option value="<% = drow("team_id") %>"><% = drow("team_name") %></option><%
						next
						%></select></li>
				<li><label for="game_time">Game Time <em>*</em></label> <input type="text" name="game_time" id="game_time" value = "" /> MM/DD/YYYY HH:MM</li>
				<li><label for="week_id">Week <em>*</em></label> <input type="text" name="week_id" id="week_id" value = "" /></li>
				<li><label for="game_url">Game Link </label> <input type="text" name="game_url" id="game_url" value = "" /></li>
			</ol>
			<input type="submit" name="submit" value="Add Game" /> <input type="submit" name="submit" value="Edit Game">
		</fieldset>
	</form>
</div>

<div id="Menu">
<% 
Server.Execute("nav.aspx")
%>
</div>

<!-- BlueRobot was here. -->

</body>

</html>