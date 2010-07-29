<%@ Page language="VB" runat="server" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Data.ODBC" %>
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
server.execute("connstring.aspx")


if request("username") = "" or request("validate_key") = "" then
	session("page_message") = "Invalid input information."
	response.redirect("/error",true)
end if

dim username as string
dim validate_key as string

username = request("username")
validate_key = request("validate_key")


dim con as odbcconnection
dim cmd as odbccommand
dim dr as odbcdatareader
dim parm1 as odbcparameter

dim connstring as string = System.Configuration.ConfigurationSettings.AppSettings("connString")

dim sql as string

con = new odbcconnection(connstring)
con.open()


sql = "update admin.users set validated='Y' where ucase(username)=? and validate_key=?"

cmd = new odbccommand(sql,con)

parm1 = new odbcparameter("username", odbctype.varchar, 30)
parm1.value = username.toupper()
cmd.parameters.add(parm1)

parm1 = new odbcparameter("validate_key", odbctype.varchar, 40)
parm1.value = validate_key
cmd.parameters.add(parm1)

cmd.executenonquery()

%>

<html>
<head>
	<title>Registration Validated - rasputin.dnsalias.com</title>
	<style type="text/css" media="screen">@import "/style4.css";</style>
	
</head>

<body>


	<div class="content">
		<h1>rasputin.dnsalias.com</h1>
		<h2>Registration Validated</h2>

		
	Your account/email has been validated.<br>
	Thanks for registering!<br>
	<br>
	Please visit the <a href="/login.aspx">login</a> page to use your account.<br>

	</div>

<div id="navAlpha">
<% server.execute ("/nav.aspx") %>
</div>


<div id="navBeta"><%
	server.execute ("/quotes/getrandomquote.aspx")
%></div>

<!-- BlueRobot was here. -->

</body>
</html>



