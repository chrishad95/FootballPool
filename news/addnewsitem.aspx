<%@ Page Language="VB" AutoEventWireup="false" CodeFile="addnewsitem.aspx.vb" Inherits="addnewsitem" %>

<%  Server.Execute("header.aspx")%>
    <form id="form1" runat="server">
    <div>
        <p><asp:Label ID="Label1" runat="server" Text="Title"></asp:Label><asp:TextBox ID="txtTitle"
            runat="server"></asp:TextBox></p>
            <p>
        <asp:Label ID="Label2" runat="server" Text="Body"></asp:Label></p>
        <p><asp:TextBox ID="txtBody"
            runat="server" Height="72px" Rows="4"></asp:TextBox>
            </p>
            <p><asp:Label ID="Label3" runat="server" Text="Excerpt"></asp:Label></p><p><asp:TextBox ID="txtExcerpt"
            runat="server"></asp:TextBox></p>
        <p><asp:Label ID="Label4" runat="server" Text="Source URL"></asp:Label><asp:TextBox
            ID="txtSourceURL" runat="server"></asp:TextBox></p>
        <p><asp:Label ID="Label5" runat="server" Text="Team Name"></asp:Label><asp:TextBox ID="txtTeamName"
            runat="server"></asp:TextBox></p>
        <p><asp:Button ID="Button1" runat="server" Text="Add News Item" /></p>
        
        
        
    </div>
    </form>

<%  Server.Execute("footer.aspx")%>