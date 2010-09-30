<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<%
dim myname as string = ""
try
	if session("username") <> "" then
		myname = session("username")
	end if
catch
end try
dim isowner as boolean = false
dim isplayer as boolean = false

dim pool_id as integer 
try
	pool_id = request("pool_id")
catch
end try

dim fb as new Rasputin.FootballUtility()
fb.initialize()

isowner = fb.isowner(pool_id:=pool_id, pool_owner:=myname)
isplayer = fb.isplayer(pool_id:=pool_id, player_name:=myname)

dim isscorer as boolean = false
isscorer = fb.isscorer(pool_id:=pool_id, username:=myname)

dim http_host as string = ""
try
	http_host = request.servervariables("HTTP_HOST")
catch
end try

%>
<a href="/football">Home</a><BR>
<%
if myname <> "" then
	%>
	<A HREF="logout.aspx">Logout</A><BR>
	<A HREF="/football/changepassword.aspx">Change&nbsp;Password</A><BR>
	<a href="/football/showthreads.aspx">Trash&nbsp;Talk</a><BR>
	<%
else
	%>
	<A HREF="/football/login.aspx">Login</A><BR>
	<A HREF="/football/register.aspx">Register</A><BR>
	<A HREF="/football/resetpassword.aspx">Reset Password</A><BR>
	<%
end if
%>
<a href="/football/ayudame.aspx">Help!</a><BR><br />
<a href="/football/donate.aspx">Donate</a><BR><br />
<%
if http_host <> "superpools.gotdns.com" then
	%>
	<a href="/football">My Pools</a><BR>	
	<%
end if

try
	if isplayer or isowner then
		%>
		<a href="/football/showsched.aspx?pool_id=<% = pool_id %>">Schedule</a><BR>
		<a href="/football/makepicks.aspx?pool_id=<% = pool_id %>">Make&nbsp;Picks</a><BR>
		<a href="/football/showpicks.aspx?pool_id=<% = pool_id %>">Show&nbsp;Picks</a><BR>
		<a href="/football/standings.aspx?pool_id=<% = pool_id %>">Standings</a><BR>
		<a href="/football/sendinvite.aspx?pool_id=<% = pool_id %>">Send&nbsp;Invite</a><BR>
		<a href="/football/nickname.aspx?pool_id=<% = pool_id %>">Change&nbsp;Nickname</a><BR>
		<a href="/football/pickavatar.aspx?pool_id=<% = pool_id %>">Avatar</a><BR>
		<a href="/football/stats.aspx?pool_id=<% = pool_id %>">Statistics</a><BR>
		<%
	end if
catch
end try
if myname <> "" then
	%>
	<a href="/football/newpool.aspx">New&nbsp;Pool</a><BR>
	<a href="/football/upload.aspx">Upload&nbsp;File</a><BR>
	<%
end if
if isowner then
	%>
	<br />
	Owner Tasks:
	<br />
	<a href="/football/adminpool.aspx?pool_id=<% = pool_id %>">Admin</a><BR>
	<a href="/football/scoregames.aspx?pool_id=<% = pool_id %>">Game Scores</a><BR>
	<a href="/football/sendnotice.aspx?pool_id=<% = pool_id %>">Send Notices</a><BR>	
	<%
end if
if isscorer then
	%>
	<a href="/football/scoregames.aspx?pool_id=<% = pool_id %>">Game Scores</a><BR>
	<%
end if
try
	if session("username") = "chadley" then
		%>
			
		<%
	end if
catch
end try
%>
