<%@ Page language="VB" runat="server" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Data.ODBC" %>
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


Dim cn As OdbcConnection
Dim cn2 As OdbcConnection
dim cmd2 as odbccommand

Dim sConnString As String = System.Configuration.ConfigurationSettings.AppSettings("connString")
dim dr as odbcdatareader
dim cmd as odbccommand
dim oda as odbcdataadapter
dim ds as dataset

dim latest_week as integer
latest_week = 1

dim game_count as integer
dim user_list as string

Dim schemaInfo As New ListDictionary()



Dim myMessage As New MailMessage

dim sql as string

cn = New Odbc.OdbcConnection(sConnString)
cn.Open()


cmd = new odbccommand
cmd.connection = cn

sql = "select distinct username,email from chadley.users where not username is null and username='chadley'"

sql = "select distinct username,email from chadley.users where not username is null"
cmd.commandtext = sql

dr = cmd.ExecuteReader()
dim fastkey as string

cn2 = New Odbc.OdbcConnection(sConnString)
cn2.Open()

cmd2 = new odbccommand()
cmd2.connection = cn2

While dr.Read
	'generate a random string of 20 characters
	
	fastkey = getrandomstring()
	
	sql = "insert into football.fastkeys (username,week_id,fastkey) values ('" & dr.item("username") & "',1,'" & fastkey & "')"
	
		
	cmd2.commandtext = sql
	cmd2.executenonquery()
	

	
	response.write("Send an email to " & dr.item("username") & " at " & dr.item("email") )
	Response.Write("<BR/>")
	
	dim sb as new stringbuilder()
	
	sb.append("Hello, you are getting this email because you have registered at <a href=""http://rasputin.dnsalias.com"">http://rasputin.dnsalias.com</a> in the past.  This email is to inform you that a new NFL season is starting this Thursday and you are invited to take part in the 2005 Football pool.  The football pool is for entertainment purposes only.  If we get a lot of people involved it should be a lot of fun.  <br><br>" & system.environment.newline)
	
	sb.append ("New this year is the Lone Wolfe Pick of the Week, which is where a player picks a team that nobody else picks that week, and that team wins.  That player will get an extra point for being the Lone Wolfe for that game.  :)  <br><br>" & system.environment.newline)
	
	sb.append ("This year the player who picks the most winning games for the week, will get 2 Weekly Winner points.  In the event of a tie, the tie breaker will decide the winner.  The tie breaker game is the last game scheduled for the week.  The player that picks the total score closest to, but without going over the combined scores from both teams in the tie breaker game wins for the week.  In the event that there is a double tie, each player will get 1 extra point instead of 2.  In the event that everybody goes over, the closest score wins.<br><br>" & system.environment.newline)
	
	sb.append ("The last change for this year is for those of us who may from time to time, stop thinking about football and forget to make our picks.  As the season progresses, your worst week will be dropped from your score when considering the overall winner for the season.  Meaning, if you forget to make your picks for the week, last year you would have lost points for the entire week, but this year that can count as your worst week.  If you make all your picks every week, then the week you picked the worst will be your worst week.<br><br>" & system.environment.newline)
	
	sb.append ("For more information about the pool go to the site and enter the keyword football in the keyword box in the menu on the left-hand-side of the site.<br><br>" & system.environment.newline)
	
	sb.append("Here is your fastpick link.<br><br>" & system.environment.newline)
	sb.append("Go to:<br /> <a href=""http://rasputin.dnsalias.com/football/makepicks.asp?week_id=" & latest_week & "&username=" & dr.item("username") & "&fastkey=" & fastkey & """>http://rasputin.dnsalias.com/football/makepicks.asp?week_id=" & latest_week & "&username=" & dr.item("username") & "&fastkey=" & fastkey & "</a> <br />to make your picks.<br /><br />" & vbcrlf & vbcrlf & "Thanks,<br />" & vbcrlf & "Chris")
	
	
	response.write(sb.tostring())
	
	myMessage = New MailMessage
	
	myMessage.BodyFormat = MailFormat.Html
	myMessage.From = "chrishad95@yahoo.com"
	myMessage.To = dr.item("email")
	myMessage.Subject = "Football Pool Week #1" 
	myMessage.Body = sb.toString()
	
	myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/smtsperver", "smtp.mail.yahoo.com")
	myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/smtpserverport", 25)
	myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/sendusing", 2)
	myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate", 1)
	myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/sendusername", "chrishad95")
	myMessage.Fields.Add("http://schemas.microsoft.com/cdo/configuration/sendpassword", "househorse89")

	' Doesn't have to be local... just enter your
	' SMTP server's name or ip address!
	SmtpMail.SmtpServer = "127.0.0.1"
	
	SmtpMail.SmtpServer = "smtp.mail.yahoo.com"
	try
		SmtpMail.Send(myMessage)
	catch ex as exception
		response.write(ex.tostring())
	end try
		
End While
dr.close()

%>
