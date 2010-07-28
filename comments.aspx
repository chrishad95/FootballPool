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
fb.initialize()

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

if fb.isplayer(pool_id:=pool_id, player_name:=myname) then
else
	callerror("Invalid player/pool.")
end if

dim submit as string = ""
try
	submit = request("submit")
catch
end try

dim res as string = ""

if submit = "Make Comment" then
	res = fb.MakeComment(pool_id:=pool_id, username:=myname, comment_text:=request("comment_text"), comment_title:=request("comment_title"))
	if res = myname then
		message_text = "Comment was added."
	else
		message_text = "Comment was not added."
	end if
end if

dim comments_ds as new dataset()
comments_ds = fb.GetComments(pool_id:=pool_id, comment_count:=0)

%>

<html>
<head>
	<title>Pool Comments - <% = http_host %> - [<% = myname %>]</title>
	<style type="text/css" media="all">@import "/football/style4.css";</style> 
	<script type="text/javascript" src="jquery.js"></script>
	<script type="text/javascript" src="cmxform.js"></script>
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
	</style>
</head>

<body>

<div class="content">

		<h1><% = http_host %></h1>

</div>

<%
	try
		for each commentrow as datarow in comments_ds.tables(0).rows
			dim comment_text as string = commentrow("comment_text")
			dim comment_title as string = commentrow("comment_title")
			
			%>
			<div class="content">
			<h2><% = comment_title %></h2>
			<% = comment_text %>
			</div>
			<%
		next
	catch
	end try
%>

<div class="content">

		<form class="cmxform">
			<input type="hidden" name="pool_id" value="<% = pool_id %>">
				<h2>Make Comment</h2>
				Comment Title: <input type="text" name="comment_title" id="comment_title" /><br />
				Comment Text:<br />
				<textarea rows="10" cols="60" name="comment_text" id="comment_text"></textarea><br />
				<input type="submit" name="submit" value="Make Comment" />
		</form>

</div>

<div id="navAlpha">
<% server.execute ("nav.aspx") %>
</div>

<div id="navBeta"><%
	server.execute ("/quotes/getrandomquote.aspx")
%></div>


<!-- BlueRobot was here. -->

</body>
<%
if message_text <> "" then
	%><script>window.alert("<% = message_text.replace("""", "\""") %>")</script><%
end if
%>
</html>
