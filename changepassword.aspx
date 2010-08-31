<%@ Page language="VB" runat="server" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Data.ODBC" %>
<%@ Import Namespace="System.Web.Mail" %>
<%@ Import Namespace="System.Security.Cryptography" %>
<%@ Import Namespace="System.Text" %>
<script runat="server" language="VB">

	private sub MakeSystemLog (log_title as string, log_text as string)
	
		dim sql as string
		dim cmd as odbccommand
		dim con as odbcconnection
		dim parm1 as odbcparameter
		
		sql = "insert into journal.entries (username,journal_type,entry_tsp,entry_date,entry_title,entry_text) values (?,?,current timestamp,date(current timestamp),?,?)"
		
		dim connstring as string
		connstring = ConfigurationSettings.AppSettings("connString")
		
		con = new odbcconnection(connstring)
		con.open()
		cmd = new odbccommand(sql,con)
	
		parm1 = new odbcparameter("username", odbctype.varchar, 50)
		parm1.value = "chadley"
		cmd.parameters.add(parm1)
		parm1 = new odbcparameter("journal_type", odbctype.varchar, 20)
		parm1.value = "SYSTEM"
		cmd.parameters.add(parm1)
		parm1 = new odbcparameter("entry_title", odbctype.varchar, 200)
		parm1.value = log_title
		cmd.parameters.add(parm1)
		parm1 = new odbcparameter("entry_text", odbctype.text, 32700)
		parm1.value = log_text
		cmd.parameters.add(parm1)
		
		cmd.executenonquery()
	end sub
	
	private sub ChangePassword(sender as Object, e as EventArgs)
	
		dim username as string = ""
		dim password as string = ""
		dim newpassword as string = ""
		dim newpassword2 as string = ""
		try
			username = session("username")
			password = txtPassword.text
			newpassword = txtNewPassword.text
			newpassword2 = txtNewPassword2.text

		catch
			session("page_message") = "Incorrect username/password.  Please use your BACK button and try again."
			response.redirect("/error", true)
			
		end try
		
		if username = "" or password = ""  or newpassword = "" or newpassword2 = "" then
			session("page_message") = "Incorrect username/password.  Please use your BACK button and try again."
			
			response.redirect("/error",true)
		end if

		
		if newpassword <> newpassword2 then

			session("page_message") = "New Password and Confirm New Password don't match.  Please use your BACK button and try again."
			
			response.redirect("/error",true)
		end if

		if newpassword.length < 6 then
			
			session("page_message") = "New Password must be at least 6 characters.  Please use your BACK button and try again."
			
			response.redirect("/error",true)
		end if

		dim con as odbcconnection
		dim cmd as odbccommand
		dim dr as odbcdatareader
		dim parm1 as odbcparameter
		
		dim connstring as string
		
		connstring  = ConfigurationSettings.AppSettings("connString")
		
		
		dim sql as string
				
		con = new odbcconnection(connstring)
		con.open()
		
		'Encrypt the password
		Dim md5Hasher as New MD5CryptoServiceProvider()
		
		Dim hashedBytes as Byte()   
		dim hashedbytes2 as byte()

		Dim encoder as New UTF8Encoding()
		
		hashedBytes = md5Hasher.ComputeHash(encoder.GetBytes(password))
		hashedBytes2 = md5Hasher.ComputeHash(encoder.GetBytes(newpassword))
		
		sql = "update admin.users set password=? where ucase(username) = ? and password=? "
		
		cmd = new odbccommand(sql,con)
		
		parm1 = new odbcparameter("newpassword", odbctype.Binary, 16)
		parm1.value = hashedbytes2
		cmd.parameters.add(parm1)

		parm1 = new odbcparameter("username", odbctype.varchar, 30)
		parm1.value = username.toupper()
		cmd.parameters.add(parm1)
		

		parm1 = new odbcparameter("password", odbctype.Binary, 16)
		parm1.value = hashedbytes
		cmd.parameters.add(parm1)
		
		dim rows_affected as integer = 0

		rows_affected = cmd.executenonquery()
		if rows_affected > 0 then
			makesystemlog("Changed Password", username & " has changed their password successfully.")
			session("page_message") = "Congratulations, you have successfully changed your password."
			response.redirect("/success", true)
		else
			makesystemlog("Changed Password", username & " has failed to change their password. (Incorrect password)")
			session("page_message") = "Incorrect username/password.  Please use your BACK button and try again."
			response.redirect("/error", true)
		end if

	end sub
	
</script>
<% 

dim myname as string = ""
try
	myname = session("username")
catch
end try

if myname = "" then
	session("page_message") = "You must login first, to change your password."

	response.redirect("/error",true)
end if

	
dim http_host as string = ""
try
	http_host = request.servervariables("HTTP_HOST")
catch
end try

%>
<html>
<head>
<title>Change Password - <% = http_host %></title>
<style type="text/css" media="all">@import "/style2.css";</style>
</head>

<body>

<div id="Header"><% = http_host %></div>

<div id="Content">
<form runat="server">
  <h2>Change Password</h2>
  <table>
  <tr><td>Username:</td><td><% = session("username") %></td></tr>
  <tr><td>Password:</td><td><asp:TextBox runat="server" id="txtPassword" textmode="password" /></td></tr>
  <tr><td>New Password:</td><td><asp:TextBox runat="server" id="txtNewPassword" textmode="password" /></td></tr>
  <tr><td>Confirm New Password:</td><td><asp:TextBox runat="server" id="txtNewPassword2" textmode="password" /></td></tr>
  <tr><td colspan=2><asp:Button runat="server" Text="Change Password"
       OnClick="ChangePassword" /></td></tr>
  </table>
  <asp:Label id="_message" ForeColor="red" runat=server />
</form>
</div>

<div id="Menu">
<% 
Server.Execute("/nav.aspx")
%>
</div>

<!-- BlueRobot was here. -->

</body>

</html>

