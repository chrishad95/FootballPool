<%
server.execute "/cookiecheck.asp"
myname = session("username")

set cn = server.createobject("adodb.connection")
cn.open application("dbname"), application("dbuser"), application("dbpword")
''''cn.open "testdb"

if myname = "" then

	' check for fastkey and username info
	
	if request("username") = "" or request("fastkey") = "" or request("week_id") = "" or not isnumeric(request("week_id")) then
		session("page_message") = "<div id=""ErrorMessage"">You must login to make picks in the football pool. 1</div>" 
		response.redirect "default.asp"
		response.end
	else
		sql = "select count(*) from football.fastkeys where username=? and week_id=? and fastkey=?"
		

		set cmd=server.createobject("adodb.command") 'create a command object
		set cmd.activeconnection=cn // set active connection to the command object

		cmd.commandtext=sql
		cmd.prepared=true
		cmd.parameters.append cmd.createparameter("username",200,,30)
		cmd.parameters.append cmd.createparameter("week_id",3)
		cmd.parameters.append cmd.createparameter("fastkey",200,,30)


		cmd("username") = request("username")
		cmd("week_id") = cint(request("week_id"))
		cmd("fastkey") = request("fastkey")

		set rs = cmd.execute 'execute the query
		if rs(0) <= 0 then
		session("page_message") = "<div id=""ErrorMessage"">You must login to make picks in the football pool. 2</div>"
		response.redirect "default.asp"
		response.end
		
		else
			myname = request("username")
		end if
		
	end if
	
end if


week_id = request("week_id")
tie_breaker = request("tie_breaker")
sql = "select min(week_id) as min_week_id from (select min(game_tsp) as fuck_game_tsp, week_id from football.sched a group by week_id) as t where fuck_game_tsp > current timestamp + 30 minutes"
set rs = cn.execute(sql)
default_week_id = rs("min_week_id")

rs.close
if cint(week_id) < cint(default_week_id) then
	session("page_message") = "You can no longer make picks for week #" & week_id
	response.redirect "makepicks.asp"
	response.end
end if

if isnumeric(week_id) and isnumeric(tie_breaker) then
		sql = "select * from football.sched where char(week_id)=?"
		

		set cmd=server.createobject("adodb.command") 'create a command object
		set cmd.activeconnection=cn // set active connection to the command object

		cmd.commandtext=sql
		cmd.prepared=true
		cmd.parameters.append cmd.createparameter("week_id",200,,50)


		cmd("week_id") = cstr(week_id)

		set rs = cmd.execute 'execute the query
		if not rs.eof then

			sql = "select username,week_id,score from football.tiebreaker where week_id=? and username=?"
			

			set cmd2=server.createobject("adodb.command") 'create a command object
			set cmd2.activeconnection=cn // set active connection to the command object

			cmd2.commandtext=sql
			cmd2.prepared=true
			cmd2.parameters.append cmd2.createparameter("week_id",3)
			cmd2.parameters.append cmd2.createparameter("username",200,,50)


			cmd2("week_id") = cint(week_id)
			cmd2("username") = myname

			set rs2 = cmd2.execute 'execute the query
			if rs2.eof then
				sql = "insert into football.tiebreaker (username,week_id,score) values (?,?,?)"
				set cmd3=server.createobject("adodb.command") 'create a command object
				set cmd3.activeconnection=cn // set active connection to the command object

				cmd3.commandtext=sql
				cmd3.prepared=true
				cmd3.parameters.append cmd3.createparameter("username",200,,50)
				cmd3.parameters.append cmd3.createparameter("week_id",3)
				cmd3.parameters.append cmd3.createparameter("score",3)


				cmd3("username") = myname
				cmd3("week_id") = cint(week_id)
				cmd3("score") = cint(tie_breaker)
				cmd3.execute

			else
				sql = "update football.tiebreaker set score=? where week_id=? and username=?"
				set cmd3=server.createobject("adodb.command") 'create a command object
				set cmd3.activeconnection=cn // set active connection to the command object

				cmd3.commandtext=sql
				cmd3.prepared=true
				cmd3.parameters.append cmd3.createparameter("score",3)
				cmd3.parameters.append cmd3.createparameter("week_id",3)
				cmd3.parameters.append cmd3.createparameter("username",200,,50)


				cmd3("score") = cint(tie_breaker)
				cmd3("week_id") = cint(week_id)
				cmd3("username") = myname
				cmd3.execute
			end if
			rs2.close

		end if
		rs.close


end if

sql = "select * from football.sched order by game_id"
set rs1 = cn.execute(sql)
while not rs1.eof
	game_id = rs1("game_id")
	pick = ""
	pick_id = ""
	
	if request("game_" & game_id) = "AWAY" then
		pick = "A"
		pick_id = rs1("away_id")
		
	end if
	if request("game_" & game_id) = "HOME" then
		pick = "H"
		pick_id = rs1("home_id")
	end if
	if pick <> "" then

		sql = "select * from football.picks2 where username=? and game_id=?"
		

		set cmd=server.createobject("adodb.command") 'create a command object
		set cmd.activeconnection=cn // set active connection to the command object

		cmd.commandtext=sql
		cmd.prepared=true
		cmd.parameters.append cmd.createparameter("username",200,,50)
		cmd.parameters.append cmd.createparameter("game_id",3)


		cmd("game_id") = game_id
		cmd("username") = myname


		set rs2 = cmd.execute 'execute the query
		if rs2.eof then
			sql = "insert into football.picks2 (username,game_id,pick,pick_id) values (?,?,?,?)"		
			
			set cmd2=server.createobject("adodb.command") 'create a command object
			set cmd2.activeconnection=cn // set active connection to the command object

			cmd2.commandtext=sql
			cmd2.prepared=true
			cmd2.parameters.append cmd2.createparameter("username",200,,50)
			cmd2.parameters.append cmd2.createparameter("game_id",3)
			cmd2.parameters.append cmd2.createparameter("pick",200,,1)
			cmd2.parameters.append cmd2.createparameter("pick_id",3)


			cmd2("username") = myname
			cmd2("game_id") = game_id
			cmd2("pick") = pick
			cmd2("pick_id") = pick_id
			cmd2.execute


		else
			sql = "update football.picks2 set pick=?, pick_id=? where username=? and game_id=?"	
			
			set cmd2=server.createobject("adodb.command") 'create a command object
			set cmd2.activeconnection=cn // set active connection to the command object

			cmd2.commandtext=sql
			cmd2.prepared=true
			cmd2.parameters.append cmd2.createparameter("pick",200,,1)
			cmd2.parameters.append cmd2.createparameter("pick_id",3)
			cmd2.parameters.append cmd2.createparameter("username",200,,50)
			cmd2.parameters.append cmd2.createparameter("game_id",3)


			cmd2("pick") = pick
			cmd2("pick_id") = pick_id
			cmd2("username") = myname
			cmd2("game_id") = game_id
			cmd2.execute
		end if
		rs2.close

	end if


	rs1.movenext
wend
rs1.close
if session("username") <> "" then
session("page_message") = "Your picks were entered successfully."

%><script>window.document.location.replace("makepicks.asp?week_id=<% = week_id %>");</script><%
else

%><script>window.document.location.replace("makepicks.asp?week_id=<% = week_id %>&username=<% = request("username") %>&fastkey=<% = request("fastkey") %>");</script><%
end if


%>
