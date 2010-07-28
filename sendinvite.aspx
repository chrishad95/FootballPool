<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<script runat="server" language="VB">


</script>
<%
	server.execute("/cookiecheck.aspx")
	dim fb as new Rasputin.FootballUtility()

	dim http_host as string = ""
	try
		http_host = request.servervariables("HTTP_HOST")
	catch
	end try

	dim submit as string
	try
		submit = request("submit")
	catch
	end try

	dim email as string
	try
		email = request("email")
	catch
	end try
	
	dim myname as string = ""
	try
		myname = session("username")
	catch
	end try

	if myname = "" then
		session("page_message") = "You must login before sending an invitation."
		response.redirect("error.aspx", true)
	end If
	
	dim pool_id as integer 
	try
		pool_id = request("pool_id")
	catch
	end try

	dim pool_details_ds as new dataset()
	pool_details_ds = fb.getpooldetails(pool_id:= pool_id)

	Dim eligibility as String = ""
	try
		eligibility = pool_details_ds.tables(0).rows(0)("ELIGIBILITY")
	catch 
	End try

	If fb.isowner(pool_id:=pool_id, pool_owner:=myname)  Then
		
	Else
		if fb.isplayer(pool_id:=pool_id, player_name:=myname) And eligibility = "OPEN" Then
		Else
			session("page_message") = "You are not authorized to send invitations for this pool."
			response.redirect("error.aspx", true)
		End if
	End If


	dim message_text as string = ""


	if submit = "Send Invitation" Then
		If email <> "" Then		
			dim res as string = ""
			res = fb.InvitePlayer(pool_id:=pool_id, username:=myname, email:=email)
			if res <> "SUCCESS" then
				message_text = res
			end If
		Else
			message_text = "Invalid email address."
		End If
	end if
	

	dim banner_image as string = ""
	if not pool_details_ds.tables(0).rows(0)("pool_banner") is dbnull.value then
		banner_image = "/users/" & pool_details_ds.tables(0).rows(0)("pool_owner") & "/" & pool_details_ds.tables(0).rows(0)("pool_banner")
	end if

	dim pool_name as string = ""
	pool_name = pool_details_ds.tables(0).rows(0)("pool_name")

	dim invites_ds as dataset
	try
		invites_ds = fb.GetPoolInvitations(pool_id:=pool_id, pool_owner:=myname)
	catch ex as exception
		fb.makesystemlog("error in sendinvite.aspx", ex.tostring())
	end try

%>
<html>
<head>
	<title>Send Invitation - <% = http_host %></title>
	<style type="text/css" media="screen">@import "/style4.css";</style>
	<style type="text/css" media="all">@import "cmxform.css";</style>
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
		<%
			if banner_image = "" then
				%><h1><% = pool_name %></h1><%
			else
				%><img src="<% = banner_image %>" border="0"><BR><BR><%
			end if
		%>
		<form class="cmxform" action="sendinvite.aspx">
			<input type="hidden" name="pool_id" value="<% = pool_id %>" />
			<fieldset>
				<legend>Send Invitation</legend>
				<ol>
					<li><label for="email">Email</label> <input type="text" name="email" id="email" /></li>
				</ol>
				<input type="submit" name="submit" value="Send Invitation" />
			</fieldset>
		</form>
		<%
			if message_text <> "" then
				%><script>window.alert("<% = message_text %>")</script><%
			end if
			%><fieldset><legend>Open Invitations</legend><%
			if invites_ds.tables.count > 0 then
				if invites_ds.tables(0).rows.count > 0 then
					%>
					<table>			
					<thead>
						<tr>
							<th scope="col">Email Address</th>
							<th scope="col">Invitation Time</th>
							<th scope="col">Actions</th>
						</tr>
					</thead>	
					<tfoot>
						<tr>
							<th scope="row">Total</th>
							<td colspan="2"><% = invites_ds.tables(0).rows.count %> invitations</td>
						</tr>
					</tfoot>	
					<tbody>
					<%
					for each invite_drow as datarow in invites_ds.tables(0).rows
						%><tr>
						<td><% = invite_drow("email") %></td>
						<td><% = invite_drow("invite_tsp") %></td>
						<td><a href="deleteinvite.aspx?pool_id=<% = pool_id %>&email=<% = system.web.httputility.urlencode(invite_drow("email"))  %>">Delete</a><br />
						<a href="resendinvite.aspx?pool_id=<% = pool_id %>&email=<% = system.web.httputility.urlencode(invite_drow("email")) %>">Resend</a></td>
						</tr><%
					next
					%></tbody></table><%
				else
					%><ol><li><label >No invitations found.</label></li></ol><%
				end if
			else
				%><ol><li><label >No invitations found.</label></li></ol><%
			end if
			%></fieldset><%
		%>
	</div>

<div id="NavAlpha">
<% server.execute ("nav.aspx") %>
</div>


<!-- BlueRobot was here. -->

</body>
</html>
