<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<script runat="server" language="VB">


</script>
<%
	server.execute("/cookiecheck.aspx")
	dim fb as new Rasputin.FootballUtility()
	dim http_host as string = ""
	try
		http_host = request.servervariables("HTTP_HOST")
	catch
	end try
	dim submit as string
	try
		submit = request("submit")
	catch
	end try
	dim nickname as string = ""
	try
		nickname = request("nickname")
	catch
	end try
	dim myname as string = ""
	try
		myname = session("username")
	catch
	end try
	if myname = "" then
		session("page_message") = "You must login to set your nickname."
		response.redirect("error.aspx", true)
	end if
	dim pool_id as integer 
	try
		pool_id = request("pool_id")
	catch
	end try

	if fb.isplayer(pool_id:=pool_id, player_name:=myname) then
	else
		session("page_message") = "Invalid pool_id/player_name."
		response.redirect("error.aspx", true)
	end if

	dim message_text as string = ""

	if submit = "Change Nickname" then
		dim res as string
		res = fb.changenickname(pool_id:=pool_id, username:=myname, nickname:=nickname)
		if res=myname then
			message_text = "Nickname was changed."
		else
			message_text = res
		end if
	end if
	
	dim pool_details_ds as new dataset()
	pool_details_ds = fb.getpooldetails(pool_id:= pool_id)

	dim banner_image as string = ""
	if not pool_details_ds.tables(0).rows(0)("pool_banner") is dbnull.value then
		banner_image = "/users/" &  pool_details_ds.tables(0).rows(0)("pool_owner") & "/" & pool_details_ds.tables(0).rows(0)("pool_banner")
	end if

	dim pool_name as string = ""
	pool_name = pool_details_ds.tables(0).rows(0)("pool_name")

%>
<html>
<head>
	<title>Change Nickname - <% = http_host %></title>
	<style type="text/css" media="screen">@import "/football/style4.css";</style>
	<style>
		.content {
			border: none;
			padding: 1px;
			margin:0px 0px 20px 170px;
		}
	</style>
	
</head>

<body>

	<div class="content">
		<%
			if banner_image = "" then
				%><h1><% = pool_name %></h1><%
			else
				%><img src="<% = banner_image %>" border="0"><BR><BR><%
			end if
		%>
		<h2>Change Nickname</h2>
		<form>
		<input type="hidden" name="pool_id" value="<% = pool_id %>">
		<TABLE>
		<TR>
			<TD>Nickname:</TD>
			<TD><input type="text" name="nickname" id="nickname" /></TD>
		</TR>
		<TR>
			<TD colspan=2><input type="submit" name="submit" value="Change Nickname" /></TD>
		</TR>
		</TABLE>
		</form>
		<%
			if message_text <> "" then
				%><script>window.alert("<% = message_text %>")</script><%
			end if
		%>
	</div>

<div id="NavAlpha">
<% server.execute ("nav.aspx") %>
</div>


<!-- BlueRobot was here. -->

</body>
</html>
