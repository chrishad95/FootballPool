<%@ Page language="VB" runat="server" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Data.SQLClient" %>
<%@ Import Namespace="System.Web.Mail" %>
<script runat="server" language="VB">
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
server.execute("/cookiecheck.aspx")
dim myname as string
myname = ""

try
myname = session("username")
catch
end try

if myname <> "chadley" then
	response.redirect("/football")
	response.end()
end if
	

Dim cn As SQLConnection
Dim cn2 As SQLConnection
dim cmd2 as odbccommand

Dim sConnString As String = System.Configuration.ConfigurationSettings.AppSettings("connString")
dim dr as odbcdatareader
dim cmd as odbccommand
dim oda as odbcdataadapter
dim ds as dataset
dim parm1 as odbcparameter


if request("week_id") = "" then
	response.redirect("/sendnotice.aspx")
	response.end()
end if

dim latest_week as integer
try
	latest_week = request("week_id")
catch
	response.redirect("/sendnotice.aspx")
	response.end()
end try

dim game_count as integer
dim user_list as string

Dim schemaInfo As New ListDictionary()

if request("username") = "" then
	response.redirect("/sendnotice.aspx")
	response.end()
end if

dim username as string
username = request("username")

Dim myMessage As New MailMessage

dim sql as string

cn = New System.Data.SQLClient.SQLConnection(sConnString)
cn.Open()


if username = "ALL" then

	sql = "select distinct a.username,b.email from football.picks2 a full outer join chadley.users b on a.username=b.username where not a.username is null"
	cmd = new odbccommand(sql,cn)
else if username = "TEST" then

	sql = "select distinct username,email from chadley.users where username='chadley'"
	cmd = new odbccommand(sql,cn)
else
	sql = "select distinct username,email from chadley.users where username=?"
	
	cmd = new odbccommand(sql,cn)
	
	parm1 = new odbcparameter("username", odbctype.varchar, 30)
	parm1.value = username
	cmd.parameters.add(parm1)
	
end if

dr = cmd.ExecuteReader()
dim fastkey as string

cn2 = New System.Data.SQLClient.SQLConnection(sConnString)
cn2.Open()

cmd2 = new odbccommand()
cmd2.connection = cn2

While dr.Read
	'generate a random string of 20 characters
	
	fastkey = getrandomstring()
	
	sql = "insert into football.fastkeys (username,week_id,fastkey) values ('" & dr.item("username") & "'," & latest_week & ",'" & fastkey & "')"
	
		
	cmd2.commandtext = sql
	cmd2.executenonquery()
	

	
	response.write("Send an email to " & dr.item("username") & " at " & dr.item("email") )
	Response.Write("<BR/>")
	Response.Write("<BR/>")
	
	dim sb as new stringbuilder()
	
	sb.append("This is just a friendly reminder from <a href=""http://rasputin.dnsalias.com"">http://rasputin.dnsalias.com</a> to make your football picks for Week #" & latest_week & ".  <br><br>" & system.environment.newline)
	
	
	
	sb.append("Here is your fastpick link.<br><br>" & system.environment.newline)
	sb.append("Go to:<br /> <a href=""http://rasputin.dnsalias.com/football/makepicks.asp?week_id=" & latest_week & "&username=" & dr.item("username") & "&fastkey=" & fastkey & """>http://rasputin.dnsalias.com/football/makepicks.asp?week_id=" & latest_week & "&username=" & dr.item("username") & "&fastkey=" & fastkey & "</a> <br />to make your picks.<br /><br />" & system.environment.newline & system.environment.newline  )
	
	sb.append ("Remember!  Don't be discouraged if you forgot to make your picks last week or if you did poorly.  Your worst week score will be dropped from your overall score!  If you know someone else who may be interested in the football pool, please let them know.<br/><br/><b>DO NOT FORWARD THIS EMAIL</b></BR> If you forward this email (without removing the fastpick link) to someone else they will be able to use the fastpick link to change your picks for this week.  <br><br>" & system.environment.newline)
	
	sb.append ("For more information about the pool go to the site and enter the keyword football in the keyword box in the menu on the left-hand-side of the site.<br><br>" & system.environment.newline)
	
	sb.append ("Thanks,<br />" & system.environment.newline & "Chris<br><br>" & system.environment.newline)
	
	response.write(sb.tostring())
	
	myMessage = New MailMessage
	
	myMessage.BodyFormat = MailFormat.Html
	myMessage.From = "chrishad95@yahoo.com"
	myMessage.To = dr.item("email")
	myMessage.Subject = "Football Pool Week #" & latest_week 
	myMessage.Body = sb.toString()
	
	myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/smtsperver", "smtp.mail.yahoo.com")
	myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/smtpserverport", 25)
	myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/sendusing", 2)
	myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate", 1)
	myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/sendusername", "chrishad95")
	myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/sendpassword", "househorse89")

	' Doesn't have to be local... just enter your
	' SMTP server's name or ip address!
	
	
	SmtpMail.SmtpServer = "smtp.mail.yahoo.com"
	try
		SmtpMail.Send(myMessage)
	catch 		
		try
			SmtpMail.Send(myMessage)
		catch 		
			try
				SmtpMail.Send(myMessage)
			catch ex as exception
				response.write(ex.tostring())
			end try
		end try
	end try
		
End While
dr.close()

%>
