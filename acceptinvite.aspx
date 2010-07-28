<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Data.SQLClient" %>
<%@ Import Namespace="System.Web.Mail" %>
<script runat="server" language="VB">
	private myname as string = ""

	private sub CallError(message as string)
		session("page_message") = message
		response.redirect("error.aspx", true)
	end sub
</script>
<%



	server.execute ("/cookiecheck.aspx")
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
	dim pool_id as integer
	dim invite_email as string
	dim invite_key as string

	try
		pool_id = request("pool_id")
		invite_email = request("email")
		invite_key = request("invite_key")
	catch ex as exception
		fb.makesystemlog( "Error in Accept Invitation", ex.tostring())
	end try
	if not fb.validatekey(pool_id:=pool_id, email:=invite_email, invite_key:=invite_key) then
		session("page_message") = "Invalid key/email combination."
		response.redirect("error.aspx", true)
	end if

	dim invitationaccepted as boolean = false
	dim invite_attempted as boolean = false
	dim really_logged_in as boolean = false

	if myname <> "" then
		really_logged_in = true
	end if

	dim submit as string = ""
	try
		submit = request("submit")
	catch
	end try
	dim username_for_email as string = ""
	try
		username_for_email = fb.GetUsernameForEmail(invite_email)
	catch
	end try

	if myname = "" and username_for_email <> "" then
		'not logged in but this email is associated with a player already so we'll use that one
		myname = username_for_email
	end if

	if request("submit") = "Accept Invitation" then
		if myname = ""  and username_for_email = "" then
			dim qs as string = "acceptinvite.aspx?" & request.servervariables("query_string")
			qs = system.web.httputility.urlencode(qs)
			session("page_message") = "You must login first to accept this invitation."
			response.redirect("login.aspx?ReturnUrl=" & qs, true)
		else
			invite_attempted = true
			dim res as string
			

			res = fb.AcceptInvitation(pool_id:=pool_id, email:=invite_email, invite_key:=invite_key, player_name:=myname)
			if res = invite_email then
				invitationaccepted = true
			else
				if res.IndexOf("SQLSTATE=23505") >= 0 then
					session("page_message") = "This userid is already a member of the specified pool."
					response.redirect("/error", true)
				else
					session("page_message") = res
					response.redirect("/error", true)
				end if
			end if
		end if
	end if
	if invite_attempted and invitationaccepted then
		if really_logged_in then
			response.redirect("/", true)
		else
			session("page_message") = "You successfully accepted the invitation.  However, you will have to login using your username: <b>" & myname & "</b> to participate in the pool.  If you have forgotten your password, you should request that it be reset.  If you submit a password reset, remember to use your username: <b>" & myname & "</b>"

			response.redirect("/football/login.aspx?username=" & myname)
		end if
	end if
%>
<html>
<head>
<title>Accept Invitation</title>
<style type="text/css" media="all">@import "/football/style2.css";</style>   
<script type="text/javascript" src="jquery.js"></script>
<script type="text/javascript" src="cmxform.js"></script>
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
		dim pool_ds as dataset
		pool_ds = fb.GetPoolDetails(pool_id)
		
		dim pool_drow as datarow

		if pool_ds.tables.count > 0 then
			if pool_ds.tables(0).rows.count > 0 then
				Pool_drow = pool_ds.tables(0).rows(0)
			else
				callerror("Pool not found.")
			end if
		else
			callerror("Pool not found.")
		end if
		dim desc as string = ""
		if pool_drow("pool_desc") is dbnull.value then
			desc = ""
		else
			desc = pool_drow("pool_desc")
		end if

		%>
		<form class="cmxform">
			<input type="hidden" name="pool_id" value="<% = pool_id %>" />
			<input type="hidden" name="invite_key" value="<% = invite_key %>" />
			<input type="hidden" name="email" value="<% = invite_email %>" />
			<fieldset>
				<legend>Pool Invitation</legend>
				<ol>
					<li><label>Pool Name: </label><% = pool_drow("pool_name") %></li>
					<li><label>Description: </label><% = fb.bbencode(desc) %></li>
					<li><label>Eligibility: </label><% = pool_drow("eligibility") %></li>
					<%
						if myname <> "" then
							%><li><label>Player Name: </label><% = myname %></li><%
							if not really_logged_in then
								%><li>You can accept this invitation without logging in, however to use the football pool you will need to login.</li><%
								if myname <> "" then
								%><li>Your username is <b><% = myname %></b></li><%
								end if
							end if
						else
							%>
							<li><label>Player Name: </label>Not logged in.</li>
							<li>You must log in to accept this invitation.  If you have an account you will be asked to login as part of the invitation process.  If you don't have an account you can get one if you <a href="register.aspx" target="_blank">register.</a>  This link will open in a new window.</li>
							<%
						end if
					%>
				</ol>
				<input type="submit" name="submit" value="Accept Invitation" />  <input type="submit" name="submit" value="Decline Invitation" />
			</fieldset>
		</form>
</div>

<div id="Menu">
<% 
server.execute("nav.aspx")
%>
</div>

<!-- BlueRobot was here. -->

</body>

</html>
