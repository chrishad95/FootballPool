<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<%
if session("username") <> "" then
dim fb as new Rasputin.FootballUtility()
%>
<DIV ID="TICKER" STYLE="overflow:hidden; width:520px"  onmouseover="TICKER_PAUSED=true" onmouseout="TICKER_PAUSED=false">
		Latest Comments: &nbsp; &nbsp;
		<% 
			dim threads_dt as new datatable()
			threads_dt = fb.ShowThreads(count:=5)
			dim spacer as string = ""
			for each drow as datarow in threads_dt.rows
				%><% = spacer %><a href="/football/showthread.aspx?t=<% = drow("thread_id") %>"><% = System.Web.HttpUtility.HtmlEncode(drow ("thread_title")) %></a> <%
				spacer = " :: "
			next
		%>
		</DIV>
		<script type="text/javascript" src="js/webticker_lib.js" language="javascript"></script>
<% 
end if
%>
