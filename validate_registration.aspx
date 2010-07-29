<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Web.Mail" %>
<script runat="server" language="VB">
function validusername(u as string)
	validusername = true
	
	if u.ToUpper() = "SYSTEM" then
		validusername = false
	end if
		
	dim i as integer
	dim validcharacters as string
	validcharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_"
	
	dim c as string
	
	for i = 0 to u.length -1
		c = u.substring(i,1)
		if validcharacters.indexof(c) < 0 then
			validusername = false
		end if
	next
end function

function getrandomstring()


		'Need to create random password.
		Dim validcharacters as String
		
		validcharacters = "ABCDEFGHIJKLMNPQRSTUVWXYZabcdefghijklmnpqrstuvwxyz23456789"
		
		dim c as char
		Thread.Sleep( 30 )
		
		Dim fixRand As New Random()
		dim randomstring as stringbuilder = new stringbuilder(20)
		
		
		dim i as integer
		for i = 0 to 29    
		
			randomstring.append(validcharacters.substring(fixRand.Next( 0, len(validcharacters) ),1))
			
			
		next

		getrandomstring = randomstring.tostring()

end function

</script>
<%

dim fb as new Rasputin.FootballUtility()
fb.initialize()


dim username as string
dim validate_key as string
username = ""
validate_key = ""

try
	username = request("username")
catch ex as exception
end try

try
	validate_key = request("validate_key")
catch ex as exception
end try

if username = "" or validate_key = "" then
	session("page_message") = "Invalid input information."
	response.redirect("error.aspx",true)
end if

dim res as boolean
res = false
try 
	res = fb.validateEmail(validate_key, username)
catch ex as exception
end try

if not res then
	session("error_message") = "Invalid validation information. Account was not validated."
	response.redirect("default.aspx", true)
end if
%>
<html>
<head>
	<title>www.smackpools.com | Registration Validated</title>
	<style type="text/css" media="all">@import "/football/style4.css";</style> 
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
		<h1>www.smackpools.com</h1>
		<h2>Registration Validated</h2>

		
	Your account/email has been validated.<br>
	Thanks for registering!<br>
	<br>
	Please visit the <a href="/football/login.aspx">login</a> page to use your account.<br>

	</div>

<div id="navAlpha">
<% server.execute ("nav.aspx") %>
</div>

<!-- BlueRobot was here. -->

</body>
</html>



