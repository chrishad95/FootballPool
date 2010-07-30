<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Collections" %>
<%
dim fb as new Rasputin.FootballUtility()
dim http_host as string = ""
try
	http_host = request.servervariables("HTTP_HOST")
catch
end try

dim myname as string = ""
dim res as string = ""

try
	if session("username") <> "" then
		myname = session("username")
	end if
catch
end try

if myname = "" then
	session("error_message") = "You must login to create a new pool."
	response.redirect("/football/login.aspx?returnurl=/football/newpool.aspx", true)
end if

dim parms as new System.Collections.HashTable()
dim parmkeys as new system.collections.arraylist()

parmkeys.add("submit")
parmkeys.add("poolname")
parmkeys.add("desc")
parmkeys.add("bannerurl")
parmkeys.add("logourl")
parmkeys.add("eligibility")
parmkeys.add("participate")

for each k as object in parmkeys
	try
		if request(k.toString()) <> "" then
			parms.add(k.toString(), request(k.toString()))
		else
			parms.add(k.tostring(), "")
		end if
	catch ex as exception
	end try
next

if parms("submit") = "Create Pool" then
	res = fb.createpool(myname, parms("poolname"), parms("desc"), parms("eligibility"), parms("logourl"), parms("bannerurl"), parms("participate"))
	if res <> parms("poolname") then
		session("error_message") = "Pool was not created:" & res 
	else
		session("page_message") = "Your pool was created."
		dim pool_id as integer = 0
		pool_id = fb.getPoolID(parms("poolname"), myname)
		
		response.redirect("adminpool.aspx?pool_id=" & pool_id, true)
	end if
end if

%>
<html>
<head>
<title>New Pool</title>
	<script type="text/javascript" src="jquery.js"></script>
    <script type="text/javascript" src="cmxform.js"></script>
	<style type="text/css" media="all">@import "/football/style2.css";</style>
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

	<form class="cmxform">
		<p>Please complete the form below. Mandatory fields marked <em>*</em></p>
		<fieldset>
			<legend>Pool Details</legend>
			<ol>
				<li><label for="poolname">Name <em>*</em></label> <input type="text" name="poolname" id="poolname" /></li>
				<li><label for="desc">Description </label> <input id="desc" name="desc" /></li>
				<li><label for="bannerurl">Banner Url </label> <input id="bannerurl" name="bannerurl" /></li>
				<li><label for="logourl">Logo Url </label> <input id="logourl" name="logourl" /></li>
				<li><label for="eligibility">Eligibility <em>*</em></label> <select name="eligibility" id="eligibility"><option value="OPEN" SELECTED>OPEN</option><option value="BEFORE">BEFORE</option><option value="AFTER">AFTER</option></select></li>
				<li><label for="Participate">I am participating.</label> <input id="participate" name="participate" type=checkbox /></li>
			</ol>
		</fieldset>
		<p><input type="submit" name="submit" value="Create Pool" /></p>
	</form>

</div>

<div id="Menu">
<% 
Server.Execute("nav.aspx")
%>
</div>

<!-- BlueRobot was here. -->

</body>

</html>
