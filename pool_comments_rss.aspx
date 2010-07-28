<%@ Page language="VB" src="/football/football.vb" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.XML" %>
<%@ Import Namespace="System.IO" %>
<%
server.execute("/football/cookiecheck.aspx")

dim fb as new Rasputin.FootballUtility()

dim myname as string
myname = ""
try
	if session("username") <> "" then
		myname = session("username")
	end if
catch
end try
dim pool_id as integer
dim pool_id_set as boolean = false
try
	if request("pool_id") <> "" then
		pool_id = request("pool_id")
		pool_id_set = true
	end if
catch
end try


dim http_host as string = ""
try
	http_host = request.servervariables("HTTP_HOST")
catch
end try


dim articles_ds as dataset = new dataset()
if pool_id_set then
	articles_ds = fb.GetCommentsFeed(pool_id:=pool_id, username:=myname)
else
	articles_ds = fb.GetCommentsFeed(username:=myname)
end if

Dim dtUpdatedDate As DateTime  = system.datetime.now

try
	dtUpdatedDate = articles_ds.tables(0).rows(0)("comment_tsp")
catch
end try

Response.ContentType = "text/xml"

Dim sw As System.IO.StringWriter = New System.IO.StringWriter
Dim ms As New MemoryStream
Dim atomWriter As New XmlTextWriter(sw)

atomWriter.Formatting = Formatting.Indented
atomWriter.WriteStartDocument(True)

atomWriter.WriteStartElement("feed")
atomWriter.WriteAttributeString("xmlns", "http://www.w3.org/2005/Atom")

' write title, link and date
if pool_id_set then
	dim pool_details_ds as dataset = fb.getpooldetails(pool_id:=pool_id)
	dim pool_name as string = pool_details_ds.tables(0).rows(0)("pool_name") 
	atomWriter.WriteElementString("title", "Comments for " & pool_name)
else
	atomWriter.WriteElementString("title", "Comments for " & myname)
end if

atomWriter.WriteStartElement("link")
atomWriter.WriteAttributeString("href", "http://" & http_host)
atomWriter.WriteEndElement()

atomWriter.WriteElementString("updated", dtUpdatedDate.ToString("s"))

' write author info
atomWriter.WriteStartElement("author")
atomWriter.WriteElementString("name", "chadley")
atomWriter.WriteElementString("email", "webmaster@" & http_host)
atomWriter.WriteEndElement()
atomWriter.WriteElementString("id", "urn:uuid:" & http_host) ' RSS feeds doesnt really have any id element

Dim gNode As XmlNode = Nothing
dim article_ctr as integer = 0
dim maxarticles as integer = 20

for each drow as datarow in articles_ds.tables(0).rows
	article_ctr = article_ctr + 1
	if article_ctr <= maxarticles then
		dim comment_date as datetime = drow("comment_tsp")

		atomWriter.WriteStartElement("entry")
			atomWriter.WriteElementString("title", drow("comment_title")) 

			atomWriter.WriteStartElement("link")
				atomWriter.WriteAttributeString("href", "http://" & http_host & "/football/articles/" & drow("pool_id") & "/" & drow("comment_id") & "/default.aspx")  

			atomWriter.WriteEndElement()

    		atomWriter.WriteElementString("id", "urn:uuid:" & drow("comment_id"))
			atomWriter.WriteElementString("updated", comment_date.ToString("s"))

			atomWriter.WriteStartElement("content")
				atomWriter.WriteAttributeString("type", "html")
				atomWriter.WriteString(fb.bbencode(drow("comment_text")))
			atomWriter.WriteEndElement()
		atomWriter.WriteEndElement()
	end if
next

atomWriter.WriteEndElement()
atomWriter.WriteEndDocument()
response.write(sw.toString())
response.end

%>
