<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<script runat="server" language="VB">
	private myname as string = ""

	private sub CallError(message as string)
		session("page_message") = message
		response.redirect("error.aspx", true)
	end sub
</script>
<%
server.execute("/cookiecheck.aspx")
dim fb as new Rasputin.FootballUtility()

dim message_text as string = ""

try
	myname = session("username")
catch
end try

dim http_host as string = ""
try
	http_host = request.servervariables("HTTP_HOST")
catch
end try
dim thread_id as integer
try
	thread_id = request("t")
catch
end try

dim pool_id as integer
try
	if request("pool_id") <> "" then
		pool_id = request("pool_id")
	end if
catch ex as exception
	fb.makesystemlog("error in comment.aspx", ex.tostring())
end try

if myname = "" then
	callerror("You must login.")
end if


dim isowner as boolean = false
isowner = fb.isowner(pool_id:=pool_id, pool_owner:=myname)
dim isplayer as boolean = false
isplayer = fb.isplayer(pool_id:=pool_id, player_name:=myname)

if  isplayer or isowner then
else
	callerror("Invalid player/pool.")
end if

dim submit as string = ""
try
	submit = request("submit")
catch
end try

dim res as string = ""

dim comments_ds as new dataset()
comments_ds = fb.GetComments(pool_id:=pool_id, thread_id:=thread_id, count:=0)

dim pooldetails_ds as new dataset()
pooldetails_ds = fb.getpooldetails(pool_id:=pool_id)
dim pool_name as string = ""
try
	pool_name = pooldetails_ds.tables(0).rows(0)("pool_name")
catch
end try
dim alreadyviewed as boolean = false
try
	if session("post" & thread_id) = "true" then
		alreadyviewed = true
	end if
catch
end try
if not alreadyviewed then 
	fb.incrementviewcount(pool_id:=pool_id, comment_id:=thread_id)
	session("post" & thread_id) = "true"
end if
%>

<html>
<head>
	<title>Pool Comments - <% = http_host %> - [<% = myname %>]</title>
	<link rel="stylesheet" href='/football/hoverbox.css' type="text/css" media="screen, projection" />
	<!--[if IE]>
	<link rel="stylesheet" href='/football/ie_fixes.css' type="text/css" media="screen, projection" />
	<![endif]-->

	<style type="text/css" media="all">@import "/style4.css";</style> 
	<script type="text/javascript" src="/football/jquery.js"></script>
	<script type="text/javascript" src="/football/cmxform.js"></script>
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
		
		.thead
		{
			background: #5C7099 url(images/gradients/gradient_thead.gif) repeat-x top left;
			color: #FFFFFF;
			font: bold 14px tahoma, verdana, geneva, lucida, 'lucida grande', arial, helvetica, sans-serif;
		}
		.thead a:link
		{
			color: #FFFFFF;
		}
		.thead a:visited
		{
			color: #FFFFFF;
		}
		.thead a:hover, .thead a:active
		{
			color: #FFFF00;
		}
		.tfoot
		{
			background: #3E5C92;
			color: #E0E0F6;
		}
		.tfoot a:link
		{
			color: #E0E0F6;
		}
		.tfoot a:visited
		{
			color: #E0E0F6;
		}
		.tfoot a:hover, .tfoot a:active
		{
			color: #FFFF66;
		}
		.tborder
		{
			background: #D1D1E1;
			color: #000000;
			border: 1px solid #0B198C;
		}
		
		.content {
			border: none;
			padding: 1px;
		}
		
		.bigusername { 
		font: normal 12px tahoma, verdana, geneva, lucida, 'lucida grande', arial, helvetica, sans-serif;
		font-size: 14pt; 
		}

		.block1
		{
			font: normal 12px tahoma, verdana, geneva, lucida, 'lucida grande', arial, helvetica, sans-serif;
			background: #F5F5FF;
			color: #000000;
		}
		.block1 a {

			font: normal 12px tahoma, verdana, geneva, lucida, 'lucida grande', arial, helvetica, sans-serif;
			text-decoration: underline;
		}
		.block2
		{
			background: #E1E4F2;
			color: #000000;
		}
		#navBeta ul {
			border: 0;
			margin: 15;
			padding: 0;
		}
		
	</style>
</head>

<body>

<div class="content">

	<table class="tborder" cellpadding="6" cellspacing="1" border="0" width="100%" align="center">
	<tr>
		<td class="thead" >
		<% = http_host %> - <% = pool_name %>
		</td>
	</tr>
	<tr>
		<td class="block1" >
		<a href="/"><% = http_host %></a> > <a href="/football/showthreads.aspx?pool_id=<% = pool_id %>"><% = pool_name %></a>
		</td>
	</tr>
	</table>
	<br />

		<div align="left">
		<a href="/football/newcomment.aspx?pool_id=<% = pool_id %>&ref_id=<% = thread_id %>"><img src="/football/images/reply.gif" alt="Reply" border="0" /></a>
		</div>
		<br />
<%
	try
		for each commentrow as datarow in comments_ds.tables(0).rows

			dim comment_text as string = commentrow("comment_text")
			dim comment_title as string = commentrow("comment_title")
			dim comment_id as integer = commentrow("comment_id")
			dim comment_username as string = commentrow("username")
			dim comment_tsp as datetime = commentrow("comment_tsp")
			dim comment_nickname as string = ""
			if not commentrow("nickname") is dbnull.value then
				comment_nickname = commentrow("nickname")
			end if

			%>
			<table class="tborder" cellpadding="6" cellspacing="1" border="0" width="100%" align="center">
			<tr>
				<td class="thead" >
				<% = comment_tsp %><%
				if comment_username = myname or myname= "chadley" then
					%> <a href="/football/editcomment.aspx?pool_id=<% = pool_id %>&comment_id=<% = comment_id %>">Edit</a><%
				end if
				%>
				</td>
			</tr>
			
			<tr>
				<td class="block2" style="padding:0px">
					<!-- user info -->
					<table cellpadding="0" cellspacing="6" border="0" width="100%">
					<tr>
						
						<td nowrap="nowrap">
							<div class="bigusername">
							<%
								dim avatar as string = ""
								avatar = fb.GetAvatar(pool_id:=pool_id, username:=comment_username)
								if avatar <> "" then
								%>
									<ul class="hoverbox">
									<li>
									<a href="javascript:void(0)"><img src="/users/<% = comment_username & "/" & avatar %>" alt="description" ><img src="/users/<% = comment_username & "/" & avatar %>" alt="description" class="preview" ></a>
									</li>
									</ul>	
								<%
								end if

							%>
							<% = comment_username %><% 
								if comment_nickname <> "" then
									response.write(" A.K.A. " & comment_nickname)
								end if
							%>
							</div>							
						</td>
						<td width="100%">&nbsp;</td>
					</tr>
					</table>
					<!-- / user info -->
				</td>
			</tr>


			<tr>
				<td class="block1">
				
					
						<!-- icon and title -->

						<div class="smallfont">
							
							<strong><% = comment_title %></strong>
						</div>
						<hr size="1" style="color:#D1D1E1" />
					<div>
					<% = fb.bbencode(comment_text) %>
					</div>
					<!-- / message -->

					<div align="right">
						<!-- controls -->

							<a href="/football/newcomment.aspx?pool_id=<% = pool_id %>&ref_id=<% = comment_id %>&quote=true" rel="nofollow"><img src="/football/images/quote.gif" alt="Reply With Quote" border="0" /></a>
						
						<!-- / controls -->
					</div>
					
				<!-- message, attachments, sig -->
				
				</td>

			</tr>




			</table>
			<br />
			<%
		next
	catch ex as exception
		fb.makesystemlog("error in showthread.aspx", ex.tostring())
	end try
%>
	<div align="left">
	<a href="/football/newcomment.aspx?pool_id=<% = pool_id %>&ref_id=<% = thread_id %>"><img src="/football/images/reply.gif" alt="Reply" border="0" /></a>
	</div>
</div>

<div id="navAlpha">
<% server.execute ("nav.aspx") %>
</div>

<div id="navBeta"><%
	try
		dim feedtext as string = ""
		feedtext = fb.getfeed(pool_id:=pool_id, xslfile:=server.mappath("football.xsl"))
		if feedtext <> "" then
			response.write(feedtext)
		else
			server.execute ("/quotes/getrandomquote.aspx")
		end if
	catch ex as exception
		fb.makesystemlog("error in showthread.aspx", ex.tostring())
	end try
%></div>


<!-- BlueRobot was here. -->

</body>
<%
if message_text <> "" then
	%><script>window.alert("<% = message_text.replace("""", "\""") %>")</script><%
end if
%>
</html>
