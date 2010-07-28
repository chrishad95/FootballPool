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

if myname = "" then
	callerror("You must login.")
end if

dim http_host as string = ""
try
	http_host = request.servervariables("HTTP_HOST")
catch
end try

dim comment_id as integer
try
	if request("comment_id") <> "" then
		comment_id = request("comment_id")
	end if
catch ex as exception
end try

dim pool_id as integer
try
	if request("pool_id") <> "" then
		pool_id = request("pool_id")
	end if
catch ex as exception
end try

dim submit as string = ""
try
	submit = request("submit")
catch
end try

dim commentdetails_ds as new dataset()
dim thread_id as integer
dim comment_text as string
dim comment_title as string

commentdetails_ds = fb.getcommentdetails(pool_id:=pool_id, comment_id:=comment_id)
if commentdetails_ds.tables.count > 0 then
	if commentdetails_ds.tables(0).rows.count > 0 then
		if commentdetails_ds.tables(0).rows(0)("username") = myname or myname = "chadley" then
			comment_text = commentdetails_ds.tables(0).rows(0)("comment_text")
			comment_title = commentdetails_ds.tables(0).rows(0)("comment_title")
			if commentdetails_ds.tables(0).rows(0)("ref_id") is dbnull.value then
				thread_id = comment_id
			else
				thread_id = commentdetails_ds.tables(0).rows(0)("ref_id")
			end if
		else
			callerror("Invalid comment_id/username")
		end if
	else
		callerror("Comment not found.")
	end if
else
	callerror("Comment not found.")
end if


if submit = "Edit Comment" then
	dim res as string = ""
	res = fb.updatecomment(pool_id:=pool_id, comment_id:=comment_id, comment_title:=request("comment_title"), comment_text:=request("comment_text"))
	if res = comment_id then
		response.redirect("showthread.aspx?pool_id=" & pool_id & "&t=" & thread_id, true)
	end if

end if

%>

<html>
<head>
	<title>Edit Comment - <% = http_host %> - [<% = myname %>]</title>
	<style type="text/css" media="all">@import "/football/style2.css";</style> 
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

<div id="Header"><% = http_host %></div>

<div id="Content">
		<form class="cmxform">
			<input type="hidden" name="pool_id" value="<% = pool_id %>">
			<input type="hidden" name="comment_id" value="<% = comment_id %>">
			<fieldset>
				<legend>Edit Comment</legend>
				Comment Title: <input type="text" name="comment_title" id="comment_title" size="50" value="<% = comment_title %>" /><br />
				Comment Text:<br />
				<textarea rows="10" cols="60" name="comment_text" id="comment_text"><% = comment_text %></textarea>
				<br />
				<input type="submit" name="submit" value="Edit Comment" />
			</fieldset>
		</form>

	<BR />
	<br />
</div>

<div id="Menu">
<% server.execute ("nav.aspx") %>
</div>



<!-- BlueRobot was here. -->

</body>
<%
if message_text <> "" then
	%>
	<script>window.alert("<% = message_text.replace("""", "\""") %>")</script>
	<% 
end if
%>
</html>
