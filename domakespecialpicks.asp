<%
server.execute "/cookiecheck.asp"
myname = session("username")
if myname <> "chadley" then
	session("page_message") = "You are not authorized to make special picks."
	response.redirect "default.asp"
	response.end
end if


week_id = request("week_id")

set cn = server.createobject("adodb.connection")
cn.open application("dbname"), application("dbuser"), application("dbpword")
''''cn.open "testdb"

sql = "select min(week_id) as week_id from (select week_id from football.sched where game_tsp > current timestamp + 2 hours) as t"
set rs = cn.execute(sql)
default_week_id = rs("week_id")
rs.close
if week_id < default_week_id then
	'response.redirect "makepicks.asp"
	'response.end
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

		sql = "select * from football.special_picks where username=? and game_id=?"
		

		set cmd=server.createobject("adodb.command") 'create a command object
		set cmd.activeconnection=cn // set active connection to the command object

		cmd.commandtext=sql
		cmd.prepared=true
		cmd.parameters.append cmd.createparameter("username",200,,50)
		cmd.parameters.append cmd.createparameter("game_id",3)


		cmd("game_id") = game_id
		cmd("username") = request("special_username")


		set rs2 = cmd.execute 'execute the query
		if rs2.eof then
			sql = "insert into football.special_picks (username,game_id,pick,pick_id) values (?,?,?,?)"		
			
			set cmd2=server.createobject("adodb.command") 'create a command object
			set cmd2.activeconnection=cn // set active connection to the command object

			cmd2.commandtext=sql
			cmd2.prepared=true
			cmd2.parameters.append cmd2.createparameter("username",200,,50)
			cmd2.parameters.append cmd2.createparameter("game_id",3)
			cmd2.parameters.append cmd2.createparameter("pick",200,,1)
			cmd2.parameters.append cmd2.createparameter("pick_id",3)


			cmd2("username") = request("special_username")
			cmd2("game_id") = game_id
			cmd2("pick") = pick
			cmd2("pick_id") = pick_id
			cmd2.execute


		else
			sql = "update football.special_picks set pick=?, pick_id=? where username=? and game_id=?"	
			
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
			cmd2("username") = request("special_username")
			cmd2("game_id") = game_id
			cmd2.execute
		end if
		rs2.close

	end if


	rs1.movenext
wend
rs1.close

%>
<script>window.document.location.replace("makespecialpicks.asp?week_id=<% = week_id %>");</script>
