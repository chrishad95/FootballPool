<%@ Page Language="C#" Debug="true"%>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Xml" %>
<%@ Import Namespace="System.Xml.Schema" %>
<%@ Import Namespace="System.Web.Mail" %>
<script language="c#" runat="server">

private void mailLogReport(String logtext){

	DateTime rightnow = new DateTime();
	rightnow = DateTime.Now;
	logtext = "(processinventory)" + System.Environment.NewLine + logtext;
	
	MailMessage myMessage = new MailMessage();
	try {
		myMessage.BodyFormat = MailFormat.Text;
		myMessage.From = "chrishad95@rexfordroad.com";
		myMessage.To = "chrishad95@yahoo.com";
		myMessage.Subject = "Log Report - " + rightnow.ToString();
		myMessage.Body = logtext;
		
		SmtpMail.SmtpServer = "smtp.1and1.com";
		SmtpMail.Send(myMessage);
		
	}
	catch (Exception ex) { 
		insertLogReport(ex.ToString());
	}
	insertLogReport(logtext);
}
private void insertLogReport(String logtext){
	try{
		
		SqlConnection cn;
		SqlCommand cmd;
		SqlParameter parm1;
		String sql = "";
		DateTime rightnow = new DateTime();
		rightnow = DateTime.Now;
		
		String connstring = "server=mssql01.1and1.com; initial catalog=db108114264;uid=dbo108114264;pwd=j7aQMZbs";
		
		cn = new SqlConnection(connstring);
		cn.Open();
		sql = "insert into fb_journal_entries (username, journal_type, entry_title, entry_text) values (@username, @journal_type, @entry_title, @entry_text)";
		cmd = new SqlCommand(sql,cn);

		cmd.Parameters.Add(new SqlParameter("@username", SqlDbType.VarChar, 50)).Value = "";
		cmd.Parameters.Add(new SqlParameter("@journal_type", SqlDbType.VarChar, 20)).Value = "FOOTBALL";
		cmd.Parameters.Add(new SqlParameter("@entry_title", SqlDbType.VarChar, 200)).Value = "Import Log - " + DateTime.Now;
		cmd.Parameters.Add(new SqlParameter("@entry_text", SqlDbType.Text)).Value = logtext;
		
		
		cmd.ExecuteNonQuery ();
		cn.Close ();
		
		
	}
	catch (Exception ex) {
		throw (ex);	
	}
}

private void processxmlinventorystream(System.IO.Stream xmlstream) {
	try {
	
		// Create the validating reader and specify DTD validation.
		XmlTextReader txtReader = new XmlTextReader(xmlstream);
		XmlValidatingReader reader = new XmlValidatingReader(txtReader);
		reader.ValidationType = ValidationType.DTD;
		
		// Pass the validating reader to the XML document.
		// Validation fails due to an undefined attribute, but the 
		// data is still loaded into the document.
		XmlDocument doc = new XmlDocument();
		doc.Load(reader);
		XmlNode root = doc.FirstChild;
		System.Xml.XmlNodeList elemlist;
		
		SqlConnection con;
		SqlCommand cmd;
		SqlDataReader dr;
		SqlConnection con2;
		SqlCommand cmd2;
		SqlParameter parm1;
		String sql;
		String connstring = "server=mssql01.1and1.com; initial catalog=db108114264;uid=dbo108114264;pwd=j7aQMZbs";
		
		String isbn;
		Double units;
		String unit_cost;
		String item_qty;
		
		con = new SqlConnection(connstring);
		con.Open();
		cmd = new SqlCommand();
		cmd.Connection = con;
		cmd.CommandText = "create table master_inventory (item_number varchar(255), description varchar(255), units float , uncost float , price1 float , isbn varchar(255), avail_flag char(1), uncost_flag char(1), insert_flag char(1), expect_date datetime, mod_date datetime)";
		
		try {
			cmd.ExecuteNonQuery();
		} catch (Exception ex) {
				//Response.Write(ex.ToString());
		}
		con.Close();
		
		con = new SqlConnection(connstring);
		con.Open();
		cmd = new SqlCommand();
		cmd.Connection = con;
		cmd.CommandText = "update master_inventory set avail_flag='N', uncost_flag='N', insert_flag='N'";
		
		try {
			cmd.ExecuteNonQuery();
		} catch (Exception ex) {
				//Response.Write(ex.ToString());
		}
		con.Close();
		
		if (root["inventoryControlDetail"]["inventoryControlType"].InnerText == "FULL") {
			
			con = new SqlConnection(connstring);
			con.Open();
			cmd = new SqlCommand();
			cmd.Connection = con;
			cmd.CommandText = "delete from master_inventory";
			
			try {
				cmd.ExecuteNonQuery();
			} catch (Exception ex) {
				//Response.Write(ex.ToString());
				
			}
			con.Close();
			
		}		
		
		int rowsaffected = 0;
		
		elemlist = doc.GetElementsByTagName("inventoryItemData");
		
		if (root["inventoryControlDetail"]["inventoryControlType"].InnerText == "FULL") {
			mailLogReport("Received full inventory feed, ItemCount: " + elemlist.Count);
		}
		for (int i=0; i< elemlist.Count; i++) {
							
			con = new SqlConnection(connstring);
			con.Open();
			
			cmd = new SqlCommand();
			cmd.Connection = con;
			
			//Updating the units field with the new inventory quantity.
			cmd.CommandText = "update master_inventory set avail_flag='Y', units=@units, expect_date=@expect_date, mod_date=@mod_date where item_number=@item_number";
			
			parm1 = new SqlParameter("@units",System.Data.SqlDbType.Float);
			parm1.Value = System.Convert.ToDouble(elemlist[i]["availabilityDetail"]["itemQuantity"]["quantity"].InnerText);
			cmd.Parameters.Add(parm1);	
			
			parm1 = new SqlParameter("@expect_date",System.Data.SqlDbType.DateTime);
			parm1.Value = System.Convert.ToDateTime(elemlist[i]["availabilityDetail"]["expectedDate"].InnerText);
			cmd.Parameters.Add(parm1);	
				
			parm1 = new SqlParameter("@mod_date",System.Data.SqlDbType.DateTime);
			parm1.Value = DateTime.Now;
			cmd.Parameters.Add(parm1);		
			
			parm1 = new SqlParameter("@item_number",System.Data.SqlDbType.VarChar, 50);
			parm1.Value = elemlist[i]["itemID"].InnerText;
			cmd.Parameters.Add(parm1);
			rowsaffected = 0;
			try {
				rowsaffected = cmd.ExecuteNonQuery();
			} catch (Exception e) {
				//Response.Write(e.ToString());
				mailLogReport(e.ToString());
				
			}
			if (rowsaffected == 0) {
				
				cmd = new SqlCommand();
				cmd.Connection = con;
				
				//Inserting this record

				cmd.CommandText = "insert into master_inventory (item_number, units, uncost, avail_flag, uncost_flag, insert_flag,expect_date,mod_date) values (@item_number, @units, @uncost,'Y','Y','Y',@expect_date,@mod_date)";

				
				parm1 = new SqlParameter("@item_number",System.Data.SqlDbType.VarChar, 50);
				parm1.Value = elemlist[i]["itemID"].InnerText;
				cmd.Parameters.Add(parm1);
				
				parm1 = new SqlParameter("@units",System.Data.SqlDbType.Float);
				parm1.Value = System.Convert.ToDouble(elemlist[i]["availabilityDetail"]["itemQuantity"]["quantity"].InnerText);
				cmd.Parameters.Add(parm1);		
				
				parm1 = new SqlParameter("@uncost",System.Data.SqlDbType.Float);
				parm1.Value = System.Convert.ToDouble(elemlist[i]["availabilityDetail"]["unitCost"].InnerText);
				cmd.Parameters.Add(parm1);	
				
				parm1 = new SqlParameter("@expect_date",System.Data.SqlDbType.DateTime);
				parm1.Value = System.Convert.ToDateTime(elemlist[i]["availabilityDetail"]["expectedDate"].InnerText);
				cmd.Parameters.Add(parm1);	
					
				parm1 = new SqlParameter("@mod_date",System.Data.SqlDbType.DateTime);
				parm1.Value = DateTime.Now;
				cmd.Parameters.Add(parm1);	
				
				try {
					cmd.ExecuteNonQuery();
				} catch (Exception e) {
					//Response.Write(e.ToString());
					mailLogReport(e.ToString());
				}

			}
			
				
				//Updating the uncost field with the new unit cost.
				cmd = new SqlCommand();
				cmd.Connection = con;
				
				//Inserting this record
				cmd.CommandText = "update master_inventory set uncost_flag='Y', uncost=@uncost where item_number=@item_number and uncost <> @uncost2";

				
				parm1 = new SqlParameter("@uncost",System.Data.SqlDbType.Float);
				parm1.Value = System.Convert.ToDouble(elemlist[i]["availabilityDetail"]["unitCost"].InnerText);
				cmd.Parameters.Add(parm1);	
				
				parm1 = new SqlParameter("@item_number",System.Data.SqlDbType.VarChar, 50);
				parm1.Value = elemlist[i]["itemID"].InnerText;
				cmd.Parameters.Add(parm1);
				
				parm1 = new SqlParameter("@uncost2",System.Data.SqlDbType.Float);
				parm1.Value = System.Convert.ToDouble(elemlist[i]["availabilityDetail"]["unitCost"].InnerText);
				cmd.Parameters.Add(parm1);	
					
					
				try {
					cmd.ExecuteNonQuery();
				} catch (Exception e) {
					//Response.Write(e.ToString());
					mailLogReport(e.ToString());
				}
				
				con.Close();
				
		}
	    	Response.StatusCode  = 200;
			
	} catch (Exception ex) {
				//Response.Write(ex.ToString());
		Response.StatusCode  = 800;
		mailLogReport(ex.ToString());
	}
}
	  	
private void processPool(String p_file) {
	try {
	
		// Create the validating reader and specify DTD validation.

		XmlTextReader txtReader = new XmlTextReader(HttpContext.Current.Request.MapPath(p_file));
		XmlValidatingReader reader = new XmlValidatingReader(txtReader);
		reader.ValidationType = ValidationType.DTD;
		
		// Pass the validating reader to the XML document.
		// Validation fails due to an undefined attribute, but the 
		// data is still loaded into the document.
		XmlDocument doc = new XmlDocument();
		doc.Load(reader);
		XmlNode root = doc.FirstChild;
		System.Xml.XmlNodeList elemlist;
		elemlist = doc.GetElementsByTagName("POOL");
		
		SqlCommand cmd;
		SqlDataReader dr;
		SqlConnection con2;
		SqlCommand cmd2;
		SqlParameter parm1;
		String sql;
		String connstring = "server=mssql01.1and1.com; initial catalog=db108114264;uid=dbo108114264;pwd=j7aQMZbs";
		
		String isbn;
		Double units;
		String unit_cost;
		String item_qty;
		System.Collections.Hashtable ht = new System.Collections.Hashtable();

		
		using (SqlConnection con = new SqlConnection(connstring))
		{
			con.Open();
			
			for (int i=0; i< elemlist.Count; i++) {
								
				cmd = new SqlCommand();
				cmd.Connection = con;
				
				sql = "insert into fb_pools (pool_owner, pool_name, pool_desc, pool_tsp, eligibility, pool_logo, pool_banner, feed_id, standings_tsp, updatescore_tsp, scorer) values (";
				sql = sql + "@pool_owner, @pool_name, @pool_desc, @pool_tsp, @eligibility, @pool_logo, @pool_banner, @feed_id, @standings_tsp, @updatescore_tsp, @scorer)";

				cmd.CommandText = sql;

				cmd.Parameters.Add(new SqlParameter("@pool_owner",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["POOL_OWNER"].InnerText;	
				cmd.Parameters.Add(new SqlParameter("@pool_name",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["POOL_NAME"].InnerText;	
				cmd.Parameters.Add(new SqlParameter("@pool_desc",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["POOL_DESC"].InnerText;	
				cmd.Parameters.Add(new SqlParameter("@pool_tsp",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["POOL_TSP"].InnerText.Substring(0,19);	
				cmd.Parameters.Add(new SqlParameter("@eligibility",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["ELIGIBILITY"].InnerText;	
				cmd.Parameters.Add(new SqlParameter("@pool_logo",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["POOL_LOGO"].InnerText;	
				cmd.Parameters.Add(new SqlParameter("@pool_banner",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["POOL_BANNER"].InnerText;	
				cmd.Parameters.Add(new SqlParameter("@feed_id",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["FEED_ID"].InnerText;	
				cmd.Parameters.Add(new SqlParameter("@standings_tsp",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["STANDINGS_TSP"].InnerText.Substring(0,19);	
				cmd.Parameters.Add(new SqlParameter("@updatescore_tsp",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["UPDATESCORE_TSP"].InnerText.Substring(0,19);	
				cmd.Parameters.Add(new SqlParameter("@scorer",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["SCORER"].InnerText;	

				cmd.ExecuteNonQuery();

				Int32 pool_id = -1;

				sql = "select cast( IDENT_CURRENT('fb_pools') as int)";
				sql = "select cast( @@IDENTITY as int)";
				cmd = new SqlCommand(sql, con);

				pool_id = (Int32) cmd.ExecuteScalar();
				ht.Add("POOL_ID", pool_id);
			}

			elemlist = doc.GetElementsByTagName("FASTKEY_ROW");
			for (int i=0; i< elemlist.Count; i++) {
								
				cmd = new SqlCommand();
				cmd.Connection = con;
				
				sql = "insert into fb_fastkeys values (";
				sql = sql + "@fastkey,";
				sql = sql + "@pool_id,";
				sql = sql + "@username,";
				sql = sql + "@week_id";
				sql = sql + ")";

				cmd.CommandText = sql;
				cmd.Parameters.Add(new SqlParameter("@fastkey",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["FASTKEY"].InnerText;	
				cmd.Parameters.Add(new SqlParameter("@pool_id",System.Data.SqlDbType.Int)).Value = ht["POOL_ID"];
				cmd.Parameters.Add(new SqlParameter("@username",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["USERNAME"].InnerText;	
				cmd.Parameters.Add(new SqlParameter("@week_id",System.Data.SqlDbType.Int)).Value = elemlist[i]["WEEK_ID"].InnerText;	

				cmd.ExecuteNonQuery();
			}

			elemlist = doc.GetElementsByTagName("OPTION_ROW");
			for (int i=0; i< elemlist.Count; i++) {
								
				cmd = new SqlCommand();
				cmd.Connection = con;
				
				sql = "insert into fb_options (optionname, pool_id, optionvalue) values (";
				sql = sql + "@optionname,";
				sql = sql + "@pool_id,";
				sql = sql + "@optionvalue";
				sql = sql + ")";

				cmd.CommandText = sql;

				cmd.Parameters.Add(new SqlParameter("@optionname",System.Data.SqlDbType.VarChar, 30));
				cmd.Parameters["@optionname"].Value = elemlist[i]["OPTIONNAME"].InnerText;	

				cmd.Parameters.Add(new SqlParameter("@pool_id",System.Data.SqlDbType.Int)).Value = ht["POOL_ID"];
				cmd.Parameters.Add(new SqlParameter("@optionvalue",System.Data.SqlDbType.VarChar, 255)).Value = elemlist[i]["OPTIONVALUE"].InnerText;	

				cmd.ExecuteNonQuery();
			}


			elemlist = doc.GetElementsByTagName("INVITE_ROW");
			for (int i=0; i< elemlist.Count; i++) {
								
				cmd = new SqlCommand();
				cmd.Connection = con;
				
				sql = "insert into fb_invites (email, pool_id, invite_key, invite_tsp)  values (";
				sql = sql + "@email,";
				sql = sql + "@pool_id,";
				sql = sql + "@invite_key,";
				sql = sql + "@invite_tsp";
				sql = sql + ")";

				cmd.CommandText = sql;
				cmd.Parameters.Add(new SqlParameter("@email",System.Data.SqlDbType.VarChar, 255)).Value = elemlist[i]["EMAIL"].InnerText;	
				cmd.Parameters.Add(new SqlParameter("@pool_id",System.Data.SqlDbType.Int)).Value = ht["POOL_ID"];
				cmd.Parameters.Add(new SqlParameter("@invite_key",System.Data.SqlDbType.VarChar, 40)).Value = elemlist[i]["INVITE_KEY"].InnerText;	
				cmd.Parameters.Add(new SqlParameter("@invite_tsp",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["INVITE_TSP"].InnerText.Substring(0,19);	

				cmd.ExecuteNonQuery();
			}

			elemlist = doc.GetElementsByTagName("PLAYER_TIEBREAKER_ROW");
			for (int i=0; i< elemlist.Count; i++) {
								
				cmd = new SqlCommand();
				cmd.Connection = con;
				
				sql = "insert into fb_player_tiebreakers (mod_user, pool_id, score, username, week_id)  values (";
				sql = sql + "@mod_user,";
				sql = sql + "@pool_id,";
				sql = sql + "@score,";
				sql = sql + "@username,";
				sql = sql + "@week_id";
				sql = sql + ")";

				cmd.CommandText = sql;
				cmd.Parameters.Add(new SqlParameter("@mod_user",System.Data.SqlDbType.VarChar, 50)).Value = elemlist[i]["MOD_USER"].InnerText;	
				cmd.Parameters.Add(new SqlParameter("@pool_id",System.Data.SqlDbType.Int)).Value = ht["POOL_ID"];
				cmd.Parameters.Add(new SqlParameter("@score",System.Data.SqlDbType.Int)).Value = elemlist[i]["SCORE"].InnerText;	
				cmd.Parameters.Add(new SqlParameter("@username",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["USERNAME"].InnerText;
				cmd.Parameters.Add(new SqlParameter("@week_id",System.Data.SqlDbType.Int)).Value = elemlist[i]["WEEK_ID"].InnerText;

				cmd.ExecuteNonQuery();
			}

			elemlist = doc.GetElementsByTagName("PLAYER_ROW");
			for (int i=0; i< elemlist.Count; i++) {
								
				cmd = new SqlCommand();
				cmd.Connection = con;
				
				sql = "insert into fb_players (avatar, nickname, pool_id, username)  values (";
				sql = sql + "@avatar,";
				sql = sql + "@nickname,";
				sql = sql + "@pool_id,";
				sql = sql + "@username";
				sql = sql + ")";

				cmd.CommandText = sql;
				cmd.Parameters.Add(new SqlParameter("@avatar",System.Data.SqlDbType.VarChar, 255)).Value = elemlist[i]["AVATAR"].InnerText;	
				cmd.Parameters.Add(new SqlParameter("@pool_id",System.Data.SqlDbType.Int)).Value = ht["POOL_ID"];
				cmd.Parameters.Add(new SqlParameter("@nickname",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["NICKNAME"].InnerText;	
				cmd.Parameters.Add(new SqlParameter("@username",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["USERNAME"].InnerText;

				cmd.ExecuteNonQuery();

				Int32 player_id = -1;

				sql = "select cast( @@IDENTITY as int)";
				cmd = new SqlCommand(sql, con);

				player_id = (Int32) cmd.ExecuteScalar();
				ht.Add("OLD_PLAYER_ID:" + elemlist[i]["PLAYER_ID"].InnerText, player_id);
				ht.Add("NEW_PLAYER_ID:" + player_id, elemlist[i]["PLAYER_ID"].InnerText);
			}

			elemlist = doc.GetElementsByTagName("TEAM_ROW");
			for (int i=0; i< elemlist.Count; i++) {
								
				cmd = new SqlCommand();
				cmd.Connection = con;
				
				sql = "insert into fb_teams (team_name, team_shortname, pool_id, url)  values (";
				sql = sql + "@team_name,";
				sql = sql + "@team_shortname,";
				sql = sql + "@pool_id,";
				sql = sql + "@url";
				sql = sql + ")";

				cmd.CommandText = sql;
				cmd.Parameters.Add(new SqlParameter("@team_name",System.Data.SqlDbType.VarChar, 40)).Value = elemlist[i]["TEAM_NAME"].InnerText;	
				cmd.Parameters.Add(new SqlParameter("@pool_id",System.Data.SqlDbType.Int)).Value = ht["POOL_ID"];
				cmd.Parameters.Add(new SqlParameter("@team_shortname",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["TEAM_SHORTNAME"].InnerText;	
				cmd.Parameters.Add(new SqlParameter("@url",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["URL"].InnerText;

				cmd.ExecuteNonQuery();

				Int32 team_id = -1;

				sql = "select cast( @@IDENTITY as int)";
				cmd = new SqlCommand(sql, con);

				team_id = (Int32) cmd.ExecuteScalar();
				ht.Add("OLD_TEAM_ID:" + elemlist[i]["TEAM_ID"].InnerText, team_id);
				ht.Add("NEW_TEAM_ID:" + team_id,  elemlist[i]["TEAM_ID"].InnerText);
			}

			elemlist = doc.GetElementsByTagName("GAME_ROW");
			for (int i=0; i< elemlist.Count; i++) {
								
				cmd = new SqlCommand();
				cmd.Connection = con;
				
				sql = "insert into fb_games (pool_id, away_id, home_id, game_tsp, game_url, week_id)  values (";
				sql = sql + "@pool_id,";
				sql = sql + "@away_id,";
				sql = sql + "@home_id,";
				sql = sql + "@game_tsp,";
				sql = sql + "@game_url,";
				sql = sql + "@week_id";
				sql = sql + ")";

				cmd.CommandText = sql;
				cmd.Parameters.Add(new SqlParameter("@pool_id",System.Data.SqlDbType.Int)).Value = ht["POOL_ID"];
				cmd.Parameters.Add(new SqlParameter("@away_id",System.Data.SqlDbType.Int)).Value = ht["OLD_TEAM_ID:" + elemlist[i]["AWAY_ID"].InnerText ];
				cmd.Parameters.Add(new SqlParameter("@home_id",System.Data.SqlDbType.Int)).Value = ht["OLD_TEAM_ID:" + elemlist[i]["HOME_ID"].InnerText ];
				cmd.Parameters.Add(new SqlParameter("@game_tsp",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["GAME_TSP"].InnerText.Substring(0,19);	
				cmd.Parameters.Add(new SqlParameter("@game_url",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["GAME_URL"].InnerText;	
				cmd.Parameters.Add(new SqlParameter("@week_id",System.Data.SqlDbType.Int)).Value = elemlist[i]["WEEK_ID"].InnerText;

				cmd.ExecuteNonQuery();

				Int32 game_id = -1;

				sql = "select cast( @@IDENTITY as int)";
				cmd = new SqlCommand(sql, con);

				game_id = (Int32) cmd.ExecuteScalar();
				ht.Add("OLD_GAME_ID:" + elemlist[i]["GAME_ID"].InnerText, game_id);
				ht.Add("NEW_GAME_ID:" + game_id,  elemlist[i]["GAME_ID"].InnerText);
			}

			elemlist = doc.GetElementsByTagName("SCORE_ROW");
			for (int i=0; i< elemlist.Count; i++) {
								
				cmd = new SqlCommand();
				cmd.Connection = con;
				
				sql = "insert into fb_scores (pool_id, game_id, away_score, home_score)  values (";
				sql = sql + "@pool_id,";
				sql = sql + "@game_id,";
				sql = sql + "@away_score,";
				sql = sql + "@home_score";
				sql = sql + ")";

				cmd.CommandText = sql;
				cmd.Parameters.Add(new SqlParameter("@pool_id",System.Data.SqlDbType.Int)).Value = ht["POOL_ID"];
				cmd.Parameters.Add(new SqlParameter("@game_id",System.Data.SqlDbType.Int)).Value = ht["OLD_GAME_ID:" + elemlist[i]["GAME_ID"].InnerText ];
				cmd.Parameters.Add(new SqlParameter("@away_score",System.Data.SqlDbType.Int)).Value = elemlist[i]["AWAY_SCORE"].InnerText;
				cmd.Parameters.Add(new SqlParameter("@home_score",System.Data.SqlDbType.Int)).Value = elemlist[i]["HOME_SCORE"].InnerText;
				try
				{
					cmd.ExecuteNonQuery();
				
				} catch (Exception ex)
				{
					insertLogReport("failed to load score for old game_id:" + elemlist[i]["GAME_ID"].InnerText + " new game_id:" + ht["OLD_GAME_ID:" + elemlist[i]["GAME_ID"].InnerText ]  +  ex.ToString());
				}
			}

			elemlist = doc.GetElementsByTagName("HISTORY_SCORE_ROW");
			for (int i=0; i< elemlist.Count; i++) {
								
				cmd = new SqlCommand();
				cmd.Connection = con;
				
				sql = "insert into fb_scores_history (pool_id, game_id, away_score, home_score, mod_tsp, mod_user)  values (";
				sql = sql + "@pool_id,";
				sql = sql + "@game_id,";
				sql = sql + "@away_score,";
				sql = sql + "@home_score,";
				sql = sql + "@mod_tsp,";
				sql = sql + "@mod_user";
				sql = sql + ")";

				cmd.CommandText = sql;
				cmd.Parameters.Add(new SqlParameter("@pool_id",System.Data.SqlDbType.Int)).Value = ht["POOL_ID"];
				cmd.Parameters.Add(new SqlParameter("@game_id",System.Data.SqlDbType.Int)).Value = ht["OLD_GAME_ID:" + elemlist[i]["GAME_ID"].InnerText ];
				cmd.Parameters.Add(new SqlParameter("@away_score",System.Data.SqlDbType.Int)).Value = elemlist[i]["AWAY_SCORE"].InnerText ;
				cmd.Parameters.Add(new SqlParameter("@home_score",System.Data.SqlDbType.Int)).Value = elemlist[i]["HOME_SCORE"].InnerText ;
				cmd.Parameters.Add(new SqlParameter("@mod_tsp",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["MOD_TSP"].InnerText.Substring(0,19) ;
				cmd.Parameters.Add(new SqlParameter("@mod_user",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["MOD_USER"].InnerText ;

				try
				{
					cmd.ExecuteNonQuery();
				
				} catch (Exception ex)
				{
					insertLogReport("failed to load score for old game_id:" + elemlist[i]["GAME_ID"].InnerText + " new game_id:" + ht["OLD_GAME_ID:" + elemlist[i]["GAME_ID"].InnerText ]  +  ex.ToString());
				}
			}

			elemlist = doc.GetElementsByTagName("TIEBREAKER_ROW");
			for (int i=0; i< elemlist.Count; i++) {
								
				cmd = new SqlCommand();
				cmd.Connection = con;
				
				sql = "insert into fb_tiebreakers (pool_id, game_id, tb_tsp, week_id)  values (";
				sql = sql + "@pool_id,";
				sql = sql + "@game_id,";
				sql = sql + "@tb_tsp,";
				sql = sql + "@week_id";
				sql = sql + ")";

				cmd.CommandText = sql;
				cmd.Parameters.Add(new SqlParameter("@pool_id",System.Data.SqlDbType.Int)).Value = ht["POOL_ID"];
				cmd.Parameters.Add(new SqlParameter("@game_id",System.Data.SqlDbType.Int)).Value = ht["OLD_GAME_ID:" + elemlist[i]["GAME_ID"].InnerText ];
				cmd.Parameters.Add(new SqlParameter("@tb_tsp",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["TB_TSP"].InnerText.Substring(0,19) ;
				cmd.Parameters.Add(new SqlParameter("@week_id",System.Data.SqlDbType.Int)).Value = elemlist[i]["WEEK_ID"].InnerText ;

				cmd.ExecuteNonQuery();
			}

			elemlist = doc.GetElementsByTagName("PICK_ROW");
			for (int i=0; i< elemlist.Count; i++) {
								
				cmd = new SqlCommand();
				cmd.Connection = con;
				
				sql = "insert into fb_picks (pool_id, game_id, team_id, username, mod_tsp, mod_user)  values (";
				sql = sql + "@pool_id,";
				sql = sql + "@game_id,";
				sql = sql + "@team_id,";
				sql = sql + "@username,";
				sql = sql + "@mod_tsp,";
				sql = sql + "@mod_user";
				sql = sql + ")";

				cmd.CommandText = sql;
				cmd.Parameters.Add(new SqlParameter("@pool_id",System.Data.SqlDbType.Int)).Value = ht["POOL_ID"];
				cmd.Parameters.Add(new SqlParameter("@game_id",System.Data.SqlDbType.Int)).Value = ht["OLD_GAME_ID:" + elemlist[i]["GAME_ID"].InnerText ];
				cmd.Parameters.Add(new SqlParameter("@team_id",System.Data.SqlDbType.Int)).Value = ht["OLD_TEAM_ID:" + elemlist[i]["TEAM_ID"].InnerText ];
				cmd.Parameters.Add(new SqlParameter("@username",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["USERNAME"].InnerText ;
				cmd.Parameters.Add(new SqlParameter("@mod_tsp",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["MOD_TSP"].InnerText.Substring(0,19) ;
				cmd.Parameters.Add(new SqlParameter("@mod_user",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["MOD_USER"].InnerText ;

				try
				{
					cmd.ExecuteNonQuery();
				
				} catch (Exception ex)
				{
					insertLogReport("failed to pick for old game_id:" + elemlist[i]["GAME_ID"].InnerText + " new game_id:" + ht["OLD_GAME_ID:" + elemlist[i]["GAME_ID"].InnerText ]  +  ex.ToString());
				}
			}

			elemlist = doc.GetElementsByTagName("HISTORY_PICK_ROW");
			for (int i=0; i< elemlist.Count; i++) {
								
				cmd = new SqlCommand();
				cmd.Connection = con;
				
				sql = "insert into fb_picks_history (pool_id, game_id, team_id, username, mod_tsp, mod_user)  values (";
				sql = sql + "@pool_id,";
				sql = sql + "@game_id,";
				sql = sql + "@team_id,";
				sql = sql + "@username,";
				sql = sql + "@mod_tsp,";
				sql = sql + "@mod_user";
				sql = sql + ")";

				cmd.CommandText = sql;
				cmd.Parameters.Add(new SqlParameter("@pool_id",System.Data.SqlDbType.Int)).Value = ht["POOL_ID"];
				cmd.Parameters.Add(new SqlParameter("@game_id",System.Data.SqlDbType.Int)).Value = ht["OLD_GAME_ID:" + elemlist[i]["GAME_ID"].InnerText ];
				cmd.Parameters.Add(new SqlParameter("@team_id",System.Data.SqlDbType.Int)).Value = ht["OLD_TEAM_ID:" + elemlist[i]["TEAM_ID"].InnerText ];
				cmd.Parameters.Add(new SqlParameter("@username",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["USERNAME"].InnerText ;
				cmd.Parameters.Add(new SqlParameter("@mod_tsp",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["MOD_TSP"].InnerText.Substring(0,19) ;
				cmd.Parameters.Add(new SqlParameter("@mod_user",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["MOD_USER"].InnerText ;

				try
				{
					cmd.ExecuteNonQuery();
				
				} catch (Exception ex)
				{
					insertLogReport("failed to pick for old game_id:" + elemlist[i]["GAME_ID"].InnerText + " new game_id:" + ht["OLD_GAME_ID:" + elemlist[i]["GAME_ID"].InnerText ]  +  ex.ToString());
				}
			}

			elemlist = doc.GetElementsByTagName("COMMENT_ROW");
			for (int i=0; i< elemlist.Count; i++) {
								
				cmd = new SqlCommand();
				cmd.Connection = con;
				
				sql = "insert into fb_comments (comment_text, comment_title, comment_tsp, pool_id, username, views)  values (";
				sql = sql + "@comment_text,";
				sql = sql + "@comment_title,";
				sql = sql + "@comment_tsp,";
				sql = sql + "@pool_id,";
				sql = sql + "@username,";
				sql = sql + "@views";
				sql = sql + ")";

				cmd.CommandText = sql;
				cmd.Parameters.Add(new SqlParameter("@pool_id",System.Data.SqlDbType.Int)).Value = ht["POOL_ID"];
				cmd.Parameters.Add(new SqlParameter("@comment_text",System.Data.SqlDbType.Text)).Value = elemlist[i]["COMMENT_TEXT"].InnerText;
				cmd.Parameters.Add(new SqlParameter("@comment_title",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["COMMENT_TITLE"].InnerText;	
				cmd.Parameters.Add(new SqlParameter("@comment_tsp",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["COMMENT_TSP"].InnerText.Substring(0,19);	
				cmd.Parameters.Add(new SqlParameter("@username",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["USERNAME"].InnerText;	
				cmd.Parameters.Add(new SqlParameter("@views",System.Data.SqlDbType.Int)).Value = elemlist[i]["VIEWS"].InnerText;

				cmd.ExecuteNonQuery();

				Int32 comment_id = -1;

				sql = "select cast( @@IDENTITY as int)";
				cmd = new SqlCommand(sql, con);

				comment_id = (Int32) cmd.ExecuteScalar();
				ht.Add("OLD_COMMENT_ID:" + elemlist[i]["COMMENT_ID"].InnerText, comment_id);
				ht.Add("NEW_COMMENT_ID:" + comment_id,  elemlist[i]["COMMENT_ID"].InnerText);
			}

			elemlist = doc.GetElementsByTagName("REPLY_ROW");
			for (int i=0; i< elemlist.Count; i++) {
								
				cmd = new SqlCommand();
				cmd.Connection = con;
				
				sql = "insert into fb_comments (comment_text, comment_title, comment_tsp, pool_id, username,ref_id, views)  values (";
				sql = sql + "@comment_text,";
				sql = sql + "@comment_title,";
				sql = sql + "@comment_tsp,";
				sql = sql + "@pool_id,";
				sql = sql + "@username,";
				sql = sql + "@ref_id,";
				sql = sql + "@views";
				sql = sql + ")";

				cmd.CommandText = sql;
				cmd.Parameters.Add(new SqlParameter("@pool_id",System.Data.SqlDbType.Int)).Value = ht["POOL_ID"];
				cmd.Parameters.Add(new SqlParameter("@ref_id",System.Data.SqlDbType.Int)).Value = ht["OLD_COMMENT_ID:" + elemlist[i]["REF_ID"].InnerText ];
				cmd.Parameters.Add(new SqlParameter("@comment_text",System.Data.SqlDbType.Text)).Value = elemlist[i]["COMMENT_TEXT"].InnerText;
				cmd.Parameters.Add(new SqlParameter("@comment_title",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["COMMENT_TITLE"].InnerText;	
				cmd.Parameters.Add(new SqlParameter("@comment_tsp",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["COMMENT_TSP"].InnerText.Substring(0,19);	
				cmd.Parameters.Add(new SqlParameter("@username",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["USERNAME"].InnerText;	
				cmd.Parameters.Add(new SqlParameter("@views",System.Data.SqlDbType.Int)).Value = elemlist[i]["VIEWS"].InnerText;

				cmd.ExecuteNonQuery();

				Int32 comment_id = -1;

				sql = "select cast( @@IDENTITY as int)";
				cmd = new SqlCommand(sql, con);

				comment_id = (Int32) cmd.ExecuteScalar();
				ht.Add("OLD_COMMENT_ID:" + elemlist[i]["COMMENT_ID"].InnerText, comment_id);
				ht.Add("NEW_COMMENT_ID:" + comment_id,  elemlist[i]["COMMENT_ID"].InnerText);
			}

//			elemlist = doc.GetElementsByTagName("USER_ROW");
//			for (int i=0; i< elemlist.Count; i++) {
//								
//				cmd = new SqlCommand();
//				cmd.Connection = con;
//				
//				sql = "insert into fb_users (password, username, created_at, email, last_seen, login_count, validated) values (' ',";
//				sql = sql + "@username,";
//				sql = sql + "@created_at,";
//				sql = sql + "@email,";
//				sql = sql + "@last_seen,";
//				sql = sql + "@login_count,";
//				sql = sql + "@validated";
//				sql = sql + ")";
//
//				cmd.CommandText = sql;
//				cmd.Parameters.Add(new SqlParameter("@username",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["USERNAME"].InnerText ;
//				cmd.Parameters.Add(new SqlParameter("@created_at",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["CREATED_AT"].InnerText.Substring(0,19) ;
//				cmd.Parameters.Add(new SqlParameter("@last_seen",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["LAST_SEEN"].InnerText.Substring(0,19) ;
//				cmd.Parameters.Add(new SqlParameter("@email",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["EMAIL"].InnerText ;
//				cmd.Parameters.Add(new SqlParameter("@login_count",System.Data.SqlDbType.Int)).Value = elemlist[i]["LOGIN_COUNT"].InnerText;
//				cmd.Parameters.Add(new SqlParameter("@validated",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["VALIDATED"].InnerText ;
//
//
//				cmd.ExecuteNonQuery();
//			}

//			elemlist = doc.GetElementsByTagName("COPY_TEAM_ROW");
//			for (int i=0; i< elemlist.Count; i++) {
//								
//				cmd = new SqlCommand();
//				cmd.Connection = con;
//				
//				sql = "insert into fb_copy_teams (division, team_name, team_shortname) values (";
//				sql = sql + "@division,";
//				sql = sql + "@team_name,";
//				sql = sql + "@team_shortname";
//				sql = sql + ")";
//
//				cmd.CommandText = sql;
//				cmd.Parameters.Add(new SqlParameter("@division",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["DIVISION"].InnerText ;
//				cmd.Parameters.Add(new SqlParameter("@team_name",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["TEAM_NAME"].InnerText ;
//				cmd.Parameters.Add(new SqlParameter("@team_shortname",System.Data.SqlDbType.VarChar)).Value = elemlist[i]["TEAM_SHORTNAME"].InnerText ;
//
//				cmd.ExecuteNonQuery();
//			}

		}

	    Response.StatusCode  = 200;
			
	} catch (Exception ex) {
		Response.StatusCode  = 800;
		insertLogReport(ex.ToString());
	}
}
</script>

<%
//processPool("pool.1000.xml");
//processPool("pool.200.xml");
//processPool("pool.435.xml");

//processxmlinventorystream(Request.InputStream);


%>

