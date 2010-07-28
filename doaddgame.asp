<%
server.execute "/cookiecheck.asp"
myname = session("username")
if myname <> "chadley" then
	session("page_message") = "You do not have authority to add games."
	response.redirect "default.asp"
	response.end
end if

week_id = request("week_id")

game_year = request("game_year")
game_month = request("game_month")
game_day = request("game_day")
game_hour = request("game_hour")
game_minute = request("game_minute")

away_id = request("away_id")
home_id = request("home_id")
if not isnumeric(week_id) then
	response.redirect "addgame.asp"
	response.end
end if
if not isnumeric(away_id) then
	response.redirect "addgame.asp"
	response.end
end if
if not isnumeric(home_id) then
	response.redirect "addgame.asp"
	response.end
end if
if not isnumeric(game_year) then
	response.redirect "addgame.asp"
	response.end
end if
if not isnumeric(game_month) then
	response.redirect "addgame.asp"
	response.end
end if
if not isnumeric(game_day) then
	response.redirect "addgame.asp"
	response.end
end if
if not isnumeric(game_hour) then
	response.redirect "addgame.asp"
	response.end
end if
if not isnumeric(game_minute) then
	response.redirect "addgame.asp"
	response.end
end if

set cn = server.createobject("adodb.connection")
cn.open application("dbname"), application("dbuser"), application("dbpword")
''''cn.open "testdb"

sql = "select count(*) from football.teams where char(team_id)=?"

set cmd=server.createobject("adodb.command") 'create a command object
set cmd.activeconnection=cn // set active connection to the command object

cmd.commandtext=sql
cmd.prepared=true
cmd.parameters.append cmd.createparameter("team_id",200,,50)


cmd("team_id") = cstr(away_id)
set rs = cmd.execute 'execute the query
if rs(0) <> 1 then
	response.redirect "addgame.asp"
	response.end
end if
rs.close

sql = "select count(*) from football.teams where char(team_id)=?"

set cmd=server.createobject("adodb.command") 'create a command object
set cmd.activeconnection=cn // set active connection to the command object

cmd.commandtext=sql
cmd.prepared=true
cmd.parameters.append cmd.createparameter("team_id",200,,50)


cmd("team_id") = cstr(home_id)
set rs = cmd.execute 'execute the query
if rs(0) <> 1 then
	response.redirect "addgame.asp"
	response.end
end if
rs.close



sql = "select max(game_id) as max_game_id from football.sched"

set cmd=server.createobject("adodb.command") 'create a command object
set cmd.activeconnection=cn // set active connection to the command object

cmd.commandtext=sql
cmd.prepared=true
set rs = cmd.execute 'execute the query
if isnull(rs(0)) then
	next_game_id = 1 
else
	next_game_id = rs(0) + 1
end if
rs.close
game_time = zeropad(game_year,4)
game_time = game_time & "-"
game_time = game_time & zeropad(game_month,2)
game_time = game_time & "-"
game_time = game_time & zeropad(game_day,2)
game_time = game_time & "-"
game_time = game_time & zeropad(game_hour,2)
game_time = game_time & "."
game_time = game_time & zeropad(game_minute,2)
game_time = game_time & ".00.000000"

sql = "insert into football.sched (game_id,week_id,home_id,away_id,game_tsp) values (?,?,?,?,'" & game_time & "')"



set cmd=server.createobject("adodb.command") 'create a command object
set cmd.activeconnection=cn // set active connection to the command object

cmd.commandtext=sql
cmd.prepared=true

cmd.parameters.append cmd.createparameter("game_id",3)
cmd.parameters.append cmd.createparameter("week_id",3)
cmd.parameters.append cmd.createparameter("home_id",3)
cmd.parameters.append cmd.createparameter("away_id",3)


cmd("game_id") = cint(next_game_id)
cmd("week_id") = cint(week_id)
cmd("home_id") = cint(home_id)
cmd("away_id") = cint(away_id)

cmd.execute


'functions
function zeropad(s,n)
	zeropad = "000000000000000000000" & s
	zeropad = right(zeropad,n)
end function
%>