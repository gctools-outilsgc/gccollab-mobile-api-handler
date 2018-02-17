<%@ WebHandler Language="C#" Class="gcconnex" %>

using System;
using System.Web;
using System.Collections.Generic;
using System.Data;


public class gcconnex : IHttpHandler {

    public void ProcessRequest (HttpContext context) {
        context.Response.ContentType = "application/javascript";
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
        context.Response.AppendHeader("Access-Control-Allow-Origin", "*");

        // Returns user registrations over time
        string guid = "";

        if (context.Request.QueryString["email"] != null)
        {
            guid = " where email='" + context.Request.QueryString["email"].Replace('\'',' ') + "'";
        }

        string sql = "select * from profiles" + guid;

        DataTable dt = MSdb.GetData(sql);

        System.Web.Script.Serialization.JavaScriptSerializer serializer = new System.Web.Script.Serialization.JavaScriptSerializer();
        serializer.MaxJsonLength = Int32.MaxValue;
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