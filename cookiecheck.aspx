<%@ Page language="VB" debug="true" src="/football/football.vb" %>
<%@ import namespace="system.io" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SQLClient" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Security.Cryptography" %>
<%@ Import Namespace="System.Text" %>
<script runat="server" language="VB">
	private function getrandomstring() as string

		Dim validcharacters as String
		validcharacters = "ABCDEFGHIJKLMNPQRSTUVWXYZabcdefghijklmnpqrstuvwxyz23456789"
		
		dim c as char
		Thread.Sleep( 30 )
		
		Dim fixRand As New Random()
		dim randomstring as stringbuilder = new stringbuilder(40)	
		
		dim i as integer
		for i = 0 to 39    
			randomstring.append(validcharacters.substring(fixRand.Next( 0, len(validcharacters) ),1))		
		next
		return randomstring.ToString()

	end function
</script>
<%

dim myname as string
myname = ""
try
	if session("username") <> "" then
		myname = session("username")
	end if
catch
end try
if myname = "" then
	session("username") = ""
end if

if myname = "" then
	dim fb as new Rasputin.FootballUtility()
	try
	
		dim mycookies as HttpCookieCollection
		mycookies = request.cookies
		dim username as string
		dim password as string
		username = ""
		password = ""

		try
			username = mycookies("username").value
			password = mycookies("password").value
		catch 
		end try
		if username <> "" and password <> "" then
			dim res as string
			res = fb.login(username, password)
			if res <> "" then
				session("username") = res
				myname = res
			end if
		end if
	catch ex as exception
		fb.makesystemlog("Error Detected - " & datetime.now, ex.tostring())
	end try
	
end if
%>
