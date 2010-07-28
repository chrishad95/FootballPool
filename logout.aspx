<%@ Page Language="vb" Debug="true" %>
<%
session("username") = ""
session.abandon

dim objCookie as HttpCookie = new HttpCookie("username")
objCookie.Expires = DateTime.Today.AddYears(-1)
Response.AppendCookie(objCookie)

objCookie = new HttpCookie("password")
objCookie.Expires = DateTime.Today.AddYears(-1)
Response.AppendCookie(objCookie)

response.redirect ("/")

%>
