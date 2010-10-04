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

dim parms as new System.Collections.HashTable()

try
	parms.add("myname", session("username"))
catch
end try

try
	parms.add("http_host", request.servervariables("HTTP_HOST"))
catch
end try

try
	parms.add("url", request.servervariables("URL"))
	parms.add("query_string", request.servervariables("QUERY_STRING"))
catch
end try

if parms("myname") = "" then
	session("error_message") = "You must login to make comments."
	response.redirect("login.aspx?returnurl=" & parms("url") & "?" &  parms("query_string"), true)
end if

dim submit as string = ""
try
	submit = request("submit")
catch
end try

dim res as string = ""

dim ref_id as integer
dim ref_id_set as boolean = false
try
	if request("ref_id") <> "" then
		ref_id = request("ref_id")
		ref_id_set = true
	end if
catch
end try
dim quote as string = ""
try
	quote = request("quote")
catch
end try

dim commentdetails_ds as new dataset()
dim quote_text as string = ""
dim quote_author as string = ""
dim quote_title as string = ""

if ref_id_set then
	commentdetails_ds = fb.getcommentdetails(pool_id:=0, comment_id:=ref_id)
	if commentdetails_ds.tables.count > 0 then
		if commentdetails_ds.tables(0).rows.count > 0 then
			if quote = "true" then
				quote_text = "[quote]" & commentdetails_ds.tables(0).rows(0)("comment_text") & "[/quote]"
				quote_author = commentdetails_ds.tables(0).rows(0)("username") & " said" & system.environment.newline
			end if
			if not commentdetails_ds.tables(0).rows(0)("comment_title") is dbnull.value then
				quote_title = "RE: " & commentdetails_ds.tables(0).rows(0)("comment_title")
			end if
		else
			callerror("Invalid ref_id/pool_id")
		end if
	else
		callerror("Invalid ref_id/pool_id")
	end if
end if
dim thread_id as integer

if submit = "Make Comment" then
	if ref_id_set then
		dim temp_id as integer = ref_id
		if commentdetails_ds.tables(0).rows(0)("ref_id") is dbnull.value then
		else
			temp_id = commentdetails_ds.tables(0).rows(0)("ref_id")
		end if
		thread_id = temp_id

		res = fb.MakeComment(pool_id:=0, username:=parms("myname"), comment_text:=request("comment_text"), comment_title:=request("comment_title"), ref_id:=temp_id)
	else
		res = fb.MakeComment(pool_id:=0, username:=parms("myname"), comment_text:=request("comment_text"), comment_title:=request("comment_title"))
	end if
	if res = parms("myname") then
		session("page_message") = "Comment was added."
		response.redirect ("showthreads.aspx", true)
	else
		session("error_message")  = "Comment was not added."
	end if
end if
%>

<html>
<head>
	<title>Make Comment - www.SmackPools.com</title>
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

		.content {
			border: none;
			padding: 1px;
			margin:0px 0px 20px 170px;
		}
	</style>
</head>

<body>

<div id="Header"><% = parms("http_host") %></div>
	<div class="content">
	<%
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
		<form class="cmxform" method="post">
			<% 
				if ref_id_set then
					%><input type="hidden" name="ref_id" value="<% = ref_id %>"><%
				end if
			%>
			<fieldset>
				<legend>Make Comment</legend>
				Comment Title: <input type="text" name="comment_title" id="comment_title" size="50" value="<% = quote_title %>" /><br />
				Comment Text:<br />
				<textarea rows="10" cols="60" name="comment_text" id="comment_text"><% = quote_author %><% = quote_text %></textarea>
				<br />
				<input type="submit" name="submit" value="Make Comment" />
			</fieldset>
		</form>
	<BR />
	<br />
</div>
<div id="NavAlpha">
<% server.execute ("nav.aspx") %>
</div>
<!-- BlueRobot was here. -->
</body>
</html>
