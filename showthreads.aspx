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
server.execute("/football/cookiecheck.aspx")
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

dim pool_id as integer
dim pool_id_found as boolean = false

try
	if request("pool_id") <> "" then
		pool_id = request("pool_id")
		pool_id_found = true
	end if
catch ex as exception
end try

dim pool_details_ds as new dataset()
pool_details_ds = fb.getpooldetails(pool_id:= pool_id)

dim options_ht as new system.collections.hashtable()
options_ht = fb.getPoolOptions(pool_id:=pool_id)


dim isowner as boolean = false
isowner = fb.isowner(pool_id:=pool_id, pool_owner:=myname)
dim isplayer as boolean = false
isplayer = fb.isplayer(pool_id:=pool_id, player_name:=myname)

if options_ht("HIDECOMMENTS") = "on" then
	if  isplayer or isowner then
	else
		callerror("Invalid player/pool.")
	end if
end if

dim submit as string = ""
try
	submit = request("submit")
catch
end try

dim res as string = ""

if submit = "Make Comment" and myname <> "" then
	res = fb.MakeComment(pool_id:=pool_id, username:=myname, comment_text:=request("comment_text"), comment_title:=request("comment_title"))
	if res = myname then
		message_text = "Comment was added."
	else
		message_text = "Comment was not added."
	end if
end if

dim threads_ds as new dataset()
dim banner_image as string = ""
dim pool_name as string = ""
if pool_id_found then
	threads_ds = fb.ShowThreads(pool_id:=pool_id, count:=0)
	
	if not pool_details_ds.tables(0).rows(0)("pool_banner") is dbnull.value then
		banner_image = "/users/" & pool_details_ds.tables(0).rows(0)("pool_owner") & "/" &  pool_details_ds.tables(0).rows(0)("pool_banner")
	end if
	
	pool_name = pool_details_ds.tables(0).rows(0)("pool_name")
else
	threads_ds = fb.ShowThreads()
end if

%>

<html>
<head>
	<title>Trash Talk - <% = http_host %> - [<% = myname %>]</title>
	<style type="text/css" media="all">@import "/football/style4.css";</style> 
	<style>
	.thread_title {	
		background: #F5F5FF;
		color: #000000;
		width: 500px;
	}
	.last_post {
		background: #E1E4F2;
		color:#333;
		font:10px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
	}
	.title_text {
		color:#333;
		font:14px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
	}
	.author_text {
		color:#333;
		font:12px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
	}
	.time_text {
		color:#333;
		font:10px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
	}
	.poster_text {
		color:#333;
		font:12px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
	}
	.replies {
		color:#333;
		font:12px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
		background: #F5F5FF;
		text-align: right;
	}
	.views {
		color:#333;
		font:12px verdana, arial, helvetica, sans-serif;
		text-decoration: none;
		background: #E1E4F2;
		text-align: right;
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
	.content {
		border: none;
		padding: 1px;
		margin:0px 0px 20px 170px;
	}
	
	.tborder
	{
		background: #D1D1E1;
		color: #000000;
		border: 1px solid #0B198C;
	}
	</style>
</head>

<body>

<div class="content">

<%
	if banner_image = "" then
		%><h1><% = pool_name %></h1><%
	else
		%><img src=" <% = banner_image %>" border="0"><BR><BR><%
	end if
	try
		if session("page_message") <> "" then
			%>
			<div class="message">
			<% = session("page_message") %><br />
			</div>
			<%
			session("page_message") = ""
		end if
	catch
	end try
	try
		if session("error_message") <> "" then
			%>
			<div class="error_message">
			<% = session("error_message") %><br />
			</div>
			<%
			session("error_message") = ""
		end if
	catch
	end try
%>

<div align="left">
<% 
if pool_id_found then
%>
<a href="newcomment.aspx?pool_id=<% = pool_id %>" rel="nofollow"><img src="images/newthread.gif" alt="New Thread" border="0" /></a>
<%
end if
%>
</div>

<br />

<table class="tborder" border=0 cellspacing=1 cellpadding=2 width="100%">		
<tr><td colspan="4" class="thead"><% = http_host %> - Discussions for <% = pool_name %></td><tr>
<%
	dim threadsfound as integer = 0
	try
		threadsfound = threads_ds.tables(0).rows.count
		if threads_ds.tables(0).rows.count > 0 then
			%>	
			<tr><td class="thead">Thread</td><td class="thead">Last Post</td><td class="thead">Replies</td><td class="thead">Views</td></tr>
			<%
			dim threadrows as datarow()
			threadrows = threads_ds.tables(0).select(filterExpression:="1=1", sort:="thread_tsp desc")

			for each threadrow as datarow in threadrows

				dim thread_title as string = threadrow("thread_title")
				if thread_title.trim() = "" then
					thread_title = "No Subject"
				end if
				dim thread_author as string = threadrow("thread_author")
				dim thread_tsp as datetime = threadrow("thread_tsp")
				dim last_poster as string = threadrow("last_poster")
				dim replies as integer = threadrow("replies")
				dim views as integer = threadrow("views")
				dim thread_id as integer = threadrow("thread_id")

				%>
				<tr><td class="thread_title"><span class="title_text"><a href="/football/showthread.aspx?pool_id=<% = pool_id %>&t=<% = thread_id %>"><% = thread_title %></a></span><br /><span class="author_text"><% = thread_author %></span></td><td class="last_post"><span class="time_text"><% = thread_tsp.tostring().replace(" ", "&nbsp;") %></span><br />
				by&nbsp;<span class="poster_text"><% = last_poster %></span></td><td class="replies"><% = replies %></td><td class="views"><% = views %></td></tr>
				<%
			next
		end if
	catch ex as exception
		fb.makesystemlog("error in showthreads.aspx", ex.tostring())
	end try			
	%>				
	<tr><td colspan="4" class="tfoot" >Found <% = threadsfound %> active threads.</td></tr>
	</table><%
%>
<link rel="alternate" type="application/rss+xml" title="<% = pool_name %>" href="pool_comments_rss.aspx?pool_id=<% = pool_id %>" />

		Would you like to make a <a href="/donate.aspx">donation?</a><br /><br />
		<BR><BR>

		<script type="text/javascript"><!--
		google_ad_client = "pub-8829998647639174";
		google_ad_width = 728;
		google_ad_height = 90;
		google_ad_format = "728x90_as";
		google_ad_type = "text_image";
		google_ad_channel = "";
		google_color_border = "6699CC";
		google_color_bg = "003366";
		google_color_link = "FFFFFF";
		google_color_text = "AECCEB";
		google_color_url = "AECCEB";
		//--></script>
		<script type="text/javascript"
		  src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
		</script>
</div>

<div id="navAlpha">
<% server.execute ("nav.aspx") %>
</div>


<!-- BlueRobot was here. -->

</body>
<%
if message_text <> "" then
	%><script>window.alert("<% = message_text.replace("""", "\""") %>")</script><%
end if
%>
</html>
