<%@ WebHandler Language="C#" Class="gccollab" %>

using System;
using System.Web;
using System.Web.Script.Serialization;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using MySql;
using MySql.Data.MySqlClient;

public class gccollab : IHttpHandler {

    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/javascript";
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
        context.Response.AppendHeader("Access-Control-Allow-Origin", "*");

        // Returns user registrations over time
        string sql = "SELECT DISTINCT from_unixtime(e.time_created) AS Registered, count(*) AS cnt, date_format(from_unixtime(e.time_created),'%Y-%m-%d') AS RegisteredSmall FROM elggentities e JOIN elggusers_entity st ON e.guid = st.guid WHERE e.type = 'user' AND e.enabled = 'yes' GROUP BY RegisteredSmall ORDER BY Registered;";

        // Returns user registrations over time by the user's type (i.e. federal, student, academic, provincial)
        if (context.Request.QueryString["type"] != null)
            sql = "SELECT DISTINCT from_unixtime(e.time_created) AS Registered, count(*) AS cnt, date_format(from_unixtime(e.time_created),'%Y-%m-%d') AS RegisteredSmall FROM elggentities e JOIN elggusers_entity st ON e.guid = st.guid WHERE e.type = 'user' AND e.enabled = 'yes' GROUP BY RegisteredSmall ORDER BY Registered;";

        // Returns user registrations over time individually by user
        if (context.Request.QueryString["users"] != null)
            sql = "SELECT DISTINCT from_unixtime(e.time_created) AS Registered, date_format(from_unixtime(e.time_created),'%Y-%m-%d') AS RegisteredSmall, st.name, st.email, st.language FROM elggentities e JOIN elggusers_entity st ON e.guid = st.guid WHERE e.type = 'user' AND e.enabled = 'yes' ORDER BY e.time_created";

        DataTable dt = db.GetData(sql);

        System.Web.Script.Serialization.JavaScriptSerializer serializer = new System.Web.Script.Serialization.JavaScriptSerializer();
        List<Dictionary<string, object>> rows = new List<Dictionary<string, object>>();
        Dictionary<string, object> row;
        foreach (DataRow dr in dt.Rows)
        {
            row = new Dictionary<string, object>();
            foreach (DataColumn col in dt.Columns)
            {
                row.Add(col.ColumnName, dr[col]);
            }
            rows.Add(row);
        }

        context.Response.Write(serializer.Serialize(rows));

    }

    public bool IsReusable {
        get {
            return false;
        }
    }

}