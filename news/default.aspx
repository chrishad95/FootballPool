<%@ Page language="VB" src="news.vb" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Collections" %>
<%
	dim myname as string = ""
	server.execute ("/football/cookiecheck.aspx")
	dim fbn as new Rasputin.FootballNews()
	try
		myname = session("username")
	catch
	end try
	dim http_host as string = ""
	try
		http_host = request.servervariables("HTTP_HOST")
	catch
	end try
	
	if myname = "" then
        Dim returnurl As String = "/football/news"
        Response.Redirect("/football/login.aspx?returnurl=" & returnurl, True)
	end if
    Dim team_name As String = ""
    Dim url_team_name As String = ""

    Dim news_items As System.Collections.ArrayList
    
    Dim start As Integer = 0
    Dim count As Integer = 10
    If Request("start") <> "" Then
        start = Request("start")
    End If
    If Request("count") <> "" Then
        count = Request("count")
    End If
    
	team_name = request("team_name")
    If team_name <> "" Then
        url_team_name = System.Web.HttpUtility.UrlEncode(team_name)
        
        news_items = fbn.GetNewsItemsForTeam(team_name, start, count)
    Else
        news_items = fbn.GetNewsItems(start, count)
    End If
    Server.Execute("header.aspx")
%> 
   
   <%
		    For Each i As Hashtable In news_items
		        %><div class="news_item">
		        <h2><% =i("item_title")%></h2>
		        <p><% =i("item_excerpt")%></p>
		        </div><% 
		              Next
%>
<%
    If myname = "chadley" Then
		        %><p><a href="addnewsitem.aspx?team_name=<% = url_team_name %>">Add News Item for <% = team_name %></a></p><%

    End If
		       
    Server.Execute("footer.aspx")
    %>
		        
