<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<%
	server.execute("/football/cookiecheck.aspx")
	dim fb as new Rasputin.FootballUtility()
	dim http_host as string = ""
	try
		http_host = request.servervariables("HTTP_HOST")
	catch
	end try
	
	dim myname as string = ""
	try
		myname = session("username")
	catch
	end try
	if myname = "" then
		session("page_message") = "You must be logged in to pick your avatar."
		response.redirect("error.aspx", true)
	end if
	dim pool_id as integer 
	try
		pool_id = request("pool_id")
	catch
	end try
	dim avatar as string = fb.getavatar(myname)

	if fb.isplayer(pool_id:=pool_id, player_name:=myname) then
	else
		session("page_message") = "Invalid pool_id/player_name."
		response.redirect("error.aspx", true)
	end if

	dim message_text as string = ""

	dim pool_details_ds as new dataset()
	pool_details_ds = fb.getpooldetails(pool_id:= pool_id)

	dim banner_image as string = fb.getbannerimage(pool_id)

	dim pool_name as string = ""
	pool_name = pool_details_ds.tables(0).rows(0)("pool_name")

%>
<html>
<head>
	<title><% = http_host %> | Avatar</title>
	<style type="text/css" media="screen">@import "/football/style4.css";</style>
	<style>
		.content {
			border: none;
			padding: 1px;
			margin:0px 0px 20px 170px;
		}
	</style>
	<link rel="stylesheet" href='hoverbox.css' type="text/css" media="screen, projection" />
	<!--[if IE]>
	<link rel="stylesheet" href='ie_fixes.css' type="text/css" media="screen, projection" />
	<![endif]-->
	
</head>

<body>

	<div class="content">
		<%
			if banner_image = "" then
				%><h1><% = pool_name %></h1><%
			else
				%><img src="<% = banner_image %>" border="0" alt="<% = pool_name %>"><BR><BR><%
			end if
		%>
		<p>
		Avatars are no longer hosted on this site.  You can create an avatar using <a href="http://www.gravatar.com">www.gravatar.com</a>.  Remember to register the email address that you used when you created your account on this site.<p>
		Current Avatar: 
		<ul class="hoverbox">
		<li>
		<a href="http://www.gravatar.com/<% = avatar %>"><img src="http://www.gravatar.com/avatar.php/<% = avatar %>?s=512" alt="description" ><img src="http://www.gravatar.com/avatar/<% = avatar %>?s=400" alt="description" class="preview" ></a><br>
		</li>
		</ul>
	</div>

<div id="NavAlpha">
<% server.execute ("nav.aspx") %>
</div>


<!-- BlueRobot was here. -->

</body>
</html>
