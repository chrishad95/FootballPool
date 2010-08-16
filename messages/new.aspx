<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Collections" %>
<script runat="server" language="VB">
	private myname as string = ""
</script>
<%
	server.execute ("/football/cookiecheck.aspx")
	dim fb as new Rasputin.FootballUtility()
	try
		myname = session("username")
	catch
	end try
	dim http_host as string = ""
	try
		http_host = request.servervariables("HTTP_HOST")
	catch
	end try
	
	if myname = "" then
		dim returnurl as string = "/football/messages/new.aspx"
		response.redirect(System.Configuration.ConfigurationSettings.AppSettings("login") & "?returnurl=" & returnurl, true)
	end if
	dim subject as string = ""
	dim body as string = ""
	dim to_user as string = ""

	if Request.RequestType = "GET" then
		if request("id") <> "" then
			dim replymsg = fb.getmessage(request("id"))
			subject = "RE: " & replymsg("subject")
			body = replymsg("body")
			to_user = replymsg("from_user")
		end if
	end if

	if Request.RequestType = "POST" then
		if request("to_user") <> "" and request("body") <> "" then
			dim res as string = ""
			res = fb.SendMessage(request("to_user"), myname, request("subject"), request("body"))
			if res = "Message was sent." then
				session("page_message") = res
				response.redirect("default.aspx", true)
			else
				session("error_message") = res
			end if
		else
			session("error_message") = "Invalid form data."
		end if
	end if
%>
<html>
<head>
<title><% = http_host %> | Messages</title>
<style type="text/css" media="all">@import "/football/css/cssplay4.css";</style>
<style type="text/css">

form {  /* set width in form, not fieldset (still takes up more room w/ fieldset width */
  font:100% verdana,arial,sans-serif;
  margin: 0;
  padding: 0;
  min-width: 500px;
  max-width: 600px;
  width: 560px; 
}

form fieldset {
  / * clear: both; note that this clear causes inputs to break to left in ie5.x mac, commented out */
  border-color: #000;
  border-width: 1px;
  border-style: solid;
  padding: 10px;        /* padding in fieldset support spotty in IE */
  margin: 0;
}

form fieldset legend {
	font-size:1.1em; /* bump up legend font size, not too large or it'll overwrite border on left */
                       /* be careful with padding, it'll shift the nice offset on top of border  */
}

form label { 
	display: block;  /* block float the labels to left column, set a width */
	float: left; 
	width: 150px; 
	padding: 0; 
	margin: 5px 0 0; /* set top margin same as form input - textarea etc. elements */
	text-align: right; 
}

form fieldset label:first-letter { /* use first-letter pseudo-class to underline accesskey, note that */
	text-decoration:underline;    /* Firefox 1.07 WIN and Explorer 5.2 Mac don't support first-letter */
                                    /* pseudo-class on legend elements, but do support it on label elements */
                                    /* we instead underline first letter on each label element and accesskey */
                                    /* each input. doing only legends would  lessens cognitive load */
                                   /* opera breaks after first letter underlined legends but not labels */
}

form input, form textarea {
	/* display: inline; inline display must not be set or will hide submit buttons in IE 5x mac */
	width:auto;      /* set width of form elements to auto-size, otherwise watch for wrap on resize */
	margin:5px 0 0 10px; /* set margin on left of form elements rather than right of
                              label aligns textarea better in IE */
}

form input#reset {
	margin-left:0px; /* set margin-left back to zero on reset button (set above) */
}

textarea { overflow: auto; }

form small {
	display: block;
	margin: 0 0 5px 160px; /* instructions/comments left margin set to align w/ right column inputs */
	padding: 1px 3px;
	font-size: 88%;
}

form .required{font-weight:bold;} /* uses class instead of div, more efficient */

form br {
	clear:left; /* setting clear on inputs didn't work consistently, so brs added for degrade */
}
</style>

</head>
<body>
<div id="head">
</div>
<div id="foot">
</div>
<div id="content">
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
<form id="myform" class="niceform" method="post">
<fieldset>
<legend>New Message</legend>

<label for="to_user">To:</label>
<input type="text" id="to_user" name="to_user" value="<% = to_user %>" /><br>

<label for="subject">Subject:</label>
<input type="text" name="subject" id="subject" value="<% = subject %>" /><br>

<label for="body">Body:</label>
<textarea name="body" id="body" rows="5" cols="25"></textarea> <br>
<label for="kludge"></label>
	<input type="submit" value="Send" id="submit" tabindex="5">
</fieldset>
</form>
</div>

<div id="left">
<% 
server.execute("/football/nav.aspx")
%>
</div>
</body>

</html>
