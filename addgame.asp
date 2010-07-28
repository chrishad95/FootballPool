<%
server.execute "/cookiecheck.asp"
myname = session("username")

if myname <> "chadley" then
	session("page_message") = "You do not have authority to add games."
	response.redirect "default.asp"
	response.end
end if

%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">

<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
<title>Football - Add Game - rasputin.dnsalias.com</title>
<style type="text/css" media="all">@import "/football/style.css";</style>
</head>

<body>

<div id="Header"><a href="http://rasputin.dnsalias.com">rasputin.dnsalias.com</a></div>

<div id="Content">
		<%
		if session("page_message") <> "" then
			response.write session("page_message") & "<BR>"
			session("page_message") = ""
		end if
		set cn=server.createobject("adodb.connection")
		cn.open application("dbname"), application("dbuser"), application("dbpword")
''''cn.open "testdb"

		%>
		<FORM ACTION="doaddgame.asp">
		<TABLE>
		<TR>
			<TD>Week Id:</TD>
			<TD><INPUT TYPE="text" NAME="week_id" value="<% = request("week_id") %>"></TD>
		</TR>
		<TR>
			<TD>Home Team:</TD>
			<TD><SELECT NAME="home_id">
			<%
				sql = "select team_id, team_name from football.teams order by team_name"
				set rs = cn.execute(sql)
				while not rs.eof
					%><option value="<% = rs("team_id") %>"><% = rs("team_name") %></option><%
					rs.movenext
				wend
				rs.close

			
			%>
			</SELECT></TD>
		</TR>
		<TR>
			<TD>Away Team:</TD>
			<TD><SELECT NAME="away_id">
			<%
				sql = "select team_id, team_name from football.teams order by team_name"
				set rs = cn.execute(sql)
				while not rs.eof
					%><option value="<% = rs("team_id") %>"><% = rs("team_name") %></option><%
					rs.movenext
				wend
				rs.close

			
			%></SELECT></TD>
		</TR>
		<TR>
			<TD>Game Time</TD>
			<TD>
			<select name="game_year"><option value="">YEAR</option><%
			for i = 2004 to 2008
				%><option value="<% =  zeropad(i,4) %>"><% = zeropad(i,4) %></option><%
			next
			%>
			</select>
			<select name="game_month"><option value="">MONTH</option><%
			for i = 1 to 12
				%><option value="<% =  zeropad(i,2) %>"><% = zeropad(i,2) %></option><%
			next
			%>
			</select>
			<select name="game_day"><option value="">DAY</option><%
			for i = 1 to 31
				%><option value="<% =  zeropad(i,2) %>"><% = zeropad(i,2) %></option><%
			next
			%>
			</select>
			<select name="game_hour"><option value="">HOUR</option><%
			for i = 0 to 23
				%><option value="<% =  zeropad(i,2) %>"><% = zeropad(i,2) %></option><%
			next
			%>
			</select>
			<select name="game_minute"><option value="">MINUTE</option><%
			for i = 0 to 59
				%><option value="<% =  zeropad(i,2) %>"><% = zeropad(i,2) %></option><%
			next
			%>
			</select>
			
			</TD>
		</TR>
		<TR>
			<TD colspan=2><INPUT TYPE="submit" value="Add Game"></TD>
		</TR>
		</TABLE>
		</FORM>

</div>

<div id="Menu">
<% server.execute "/nav.asp" %>
<% server.execute "nav.asp" %>
</div>

<!-- BlueRobot was here. -->

</body>

</html><%

'functions
function zeropad(s,n)
	zeropad = "000000000000000000000" & s
	zeropad = right(zeropad,n)
end function
%>