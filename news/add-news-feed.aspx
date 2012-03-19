<%@ Page Language="VB" AutoEventWireup="false" CodeFile="add-news-feed.aspx.vb" Inherits="news_add_news_feed" %>

<%  Server.Execute("header.aspx")%>
    <form id="form1" runat="server">
    <div>
        <p><asp:Label ID="Label1" runat="server" Text="Title"></asp:Label><asp:TextBox ID="txtTitle"
            runat="server"></asp:TextBox></p>
        <p><asp:Label ID="Label4" runat="server" Text="URL"></asp:Label><asp:TextBox
            ID="txtURL" runat="server"></asp:TextBox></p>
        <p><asp:Button ID="Button1" runat="server" Text="Add News Feed" /></p>
        
        
        
    </div>
    </form>

<%  Server.Execute("footer.aspx")%>
