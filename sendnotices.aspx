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


Dim cn As SQLConnection
Dim cn2 As SQLConnection
dim cmd2 as odbccommand

Dim sConnString As String = System.Configuration.ConfigurationSettings.AppSettings("connString")
dim dr as odbcdatareader
dim cmd as odbccommand
dim oda as odbcdataadapter
dim ds as dataset

dim latest_week as integer
dim game_count as integer
dim user_list as string


Dim myMessage As New MailMessage

dim sql as string

cn = New System.Data.SQLClient.SQLConnection(sConnString)
cn.Open()

cmd = new odbccommand()
cmd.connection = cn


sql = "select min(week_id) as week_id from (select week_id from football.sched where game_tsp > current timestamp + 2 hours) as t"

cmd.commandtext = sql



dr = cmd.ExecuteReader()

While dr.Read
latest_week = dr.Item("week_id")
End While
dr.close()

sql = "select count(*) as game_count from football.sched where week_id=" & latest_week

cmd.commandtext = sql



dr = cmd.ExecuteReader()

While dr.Read
game_count = dr.Item("game_count")
End While
dr.close()


response.write("Latest Week: " & latest_week)
Response.Write("<BR/>")
response.write("Game Count: " & game_count)
Response.Write("<BR/>")


dim i as integer

sql = "select a.game_id, a.week_id, a.away_id, c.team_name, c.url as away_url, a.home_id, b.team_name, b.url as home_url, a.game_tsp from football.sched a full outer join football.teams b on a.home_id=b.team_id full outer join football.teams c on a.away_id=c.team_id where week_id=" & latest_week & " order by game_tsp"

'GAME_ID		0
'WEEK_ID		1
'AWAY_ID		2
'TEAM_NAME	3
'AWAY_URL	4
'HOME_ID		5
'TEAM_NAME	6
'HOME_URL	7
'GAME_TSP	8                   

cmd.commandtext = sql


oda = new odbcdataadapter()

ds = new DataSet()
oda.selectcommand = cmd
oda.fill(ds)










sql = "select count(*) as pick_count, username from football.picks2 where game_id in (select distinct game_id from football.sched where week_id=" & latest_week & ") group by username "

cmd.commandtext = sql



dr = cmd.ExecuteReader()

While dr.Read
	if dr.item("pick_count") = game_count then
	
		response.write("Username: " & dr.item("username"))
		response.write(" Pick Count: " & dr.item("pick_count"))
		Response.Write("<BR/>")
		if user_list = "" then
			user_list = "'" & dr.item("username") & "'"
		else
			user_list = user_list & ",'" & dr.item("username") & "'"
		end if
		
	end if
End While
dr.close()

' temp line

response.write("Userlist: " & user_list)
Response.Write("<BR/>")
if user_list <> "" then
	sql = "select distinct a.username,email from football.picks2 a full outer join chadley.users b on a.username=b.username where not a.username is null and not a.username in (" & user_list & ")"
else
	sql = "select distinct a.username,email from football.picks2 a full outer join chadley.users b on a.username=b.username where not a.username is null"
end if
cmd.commandtext = sql



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
	
	dim sb as new stringbuilder()
	
	sb.append("Hello, you are getting this email because you have participated in the football pool in the past and you have not made all your picks for the upcoming week: " & latest_week & vbcrlf & "<br />Please visit the link below to make your picks and submit them.  The link below should allow you to make your picks for this specific week without forcing you to login.  However, this is a new feature and it is untested.  I recommend that you login to verify that your picks were entered correctly.  <br /><br /> Go to:<br /> <a href=""http://rasputin.dnsalias.com/football/makepicks.asp?week_id=" & latest_week & "&username=" & dr.item("username") & "&fastkey=" & fastkey & """>http://rasputin.dnsalias.com/football/makepicks.asp?week_id=" & latest_week & "&username=" & dr.item("username") & "&fastkey=" & fastkey & "</a> <br />to make your picks.<br /><br />" & vbcrlf & vbcrlf & "Thanks,<br />" & vbcrlf & "Chris")
	
	
	response.write(sb.tostring())
	
	myMessage = New MailMessage
	
	myMessage.BodyFormat = MailFormat.Html
	myMessage.From = "chrishad95@yahoo.com"
	myMessage.To = dr.item("email")
	myMessage.Subject = "Football Pool Week #" & latest_week
	myMessage.Body = sb.toString()

	' Doesn't have to be local... just enter your
	' SMTP server's name or ip address!
	SmtpMail.SmtpServer = "127.0.0.1"
	SmtpMail.Send(myMessage)
	
	
	
	
End While
dr.close()

response.end





%>
