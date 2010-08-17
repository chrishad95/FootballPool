<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<script runat="server" language="VB">

	private function link_to (url as string, text as string) as string
		return "<a class=""nav"" href=""" & url & """>" & text & "</a>"
	end function
</script>
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
<dl>
<dt><% = link_to("/football", "Home") %></dt>
<% if myname <> "" then %>
<dt><% = link_to("/football/logout.aspx", "Signout") %></dt>
<dt><% = link_to("/football/profile.aspx", "Profile") %></dt>
<dt><% = link_to("/football/messages", "Messages") %></dt>
<% else %>
<dt><% = link_to("/football/login.aspx", "Signin") %></dt>
<dt><% = link_to("/football/register.aspx", "Register") %></dt>
<% end if %>
<dt><% = link_to("/football/ayudame.aspx", "Help") %></dt>
<dt><% = link_to("/football/donate.aspx", "Donate") %></dt>
</dl>
<dl>
<%
try
	if isplayer or isowner then
		%>
		<dt><a class="nav" href="/football/showsched.aspx?pool_id=<% = pool_id %>">Schedule</a></dt>
		<dt><a class="nav" href="/football/makepicks.aspx?pool_id=<% = pool_id %>">Make&nbsp;Picks</a></dt>
		<dt><a class="nav" href="/football/showpicks.aspx?pool_id=<% = pool_id %>">Show&nbsp;Picks</a></dt>
		<dt><a class="nav" href="/football/standings.aspx?pool_id=<% = pool_id %>">Standings</a></dt>
		<dt><a class="nav" href="/football/sendinvite.aspx?pool_id=<% = pool_id %>">Send&nbsp;Invite</a></dt>
		<dt><a class="nav" href="/football/nickname.aspx?pool_id=<% = pool_id %>">Change&nbsp;Nickname</a></dt>
		<dt><a class="nav" href="/football/showthreads.aspx?pool_id=<% = pool_id %>">Trash&nbsp;Talk</a></dt>
		<dt><a class="nav" href="/football/stats.aspx?pool_id=<% = pool_id %>">Statistics</a></dt>
		<%
	end if
catch
end try
if myname <> "" then
	%>
	<dt><a class="nav" href="/football/newpool.aspx">New&nbsp;Pool</a></dt>
	<dt><a class="nav" href="/football/upload.aspx">Upload&nbsp;File</a></dt>
	<%
end if
if isowner then
	%>
	<dt><a href="/football/adminpool.aspx?pool_id=<% = pool_id %>">Admin</a></dt>
	<dt><a href="/football/scoregames.aspx?pool_id=<% = pool_id %>">Game Scores</a></dt>
	<dt><a href="/football/sendnotice.aspx?pool_id=<% = pool_id %>">Send Notices</a></dt>	
	<%
end if
if isscorer then
	%>
	<dt><a class="nav" href="/football/scoregames.aspx?pool_id=<% = pool_id %>">Game Scores</a></dt>
	<%
end if
%>
</dl>
