<%@ WebHandler Language="C#" Class="register" %>

using System;
using System.Web;
using System.Data.SQLite;
using System.Data;
using System.Net;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;


public class register : IHttpHandler {

    public void ProcessRequest(HttpContext context)
    {

        context.Response.ContentType = "application/javascript";
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
        context.Response.AppendHeader("Access-Control-Allow-Origin", "*");

        if (string.IsNullOrEmpty(context.Request["email"]))
            SendError("email missing");

        string email = context.Request["email"];

        GCTUser.Lang lang = GCTUser.Lang.en;
        Enum.TryParse<GCTUser.Lang>(HttpContext.Current.Request["lang"], false, out lang);

        string info = context.Request["userdata"];
        string prms = string.Format("method=register.user&userdata={0}", info);
        using (MyWebClient wc = new MyWebClient())
        {
            wc.Headers[HttpRequestHeader.ContentType] = "application/x-www-form-urlencoded";
            string result = wc.UploadString(Gen_Functions.GetAppropriateAPIURL(context), prms);
            var json = JObject.Parse(result);
            if (result.Contains("result\":true"))
            {
                //GCTUser.SendUserCode(email, lang);
                SendSuccess("Email Sent");
            }
            else if (result.Contains("MariaDB server version"))
            {
                SendError("Invalid From ELGG:" + context.Server.UrlEncode(result));
            }
            else
            {
                SendJSONObject(json["result"].ToString());
            }
        }
    }

    public bool IsReusable {
        get {
            return false;
        }
    }

    private void SendError(string error)
    {
        HttpContext.Current.Response.Write("{\"status\":-1,\"message\":\"" + error + "\"}");
        HttpContext.Current.Response.End();
    }

    private void SendJSONObject(string error)
    {
        HttpContext.Current.Response.Write("{\"status\":-1,\"message\":" + error + "}");
        HttpContext.Current.Response.End();
    }

    private void SendSuccess(string Message)
    {
        HttpContext.Current.Response.Write("{\"status\":1,\"message\":\"" + Message + "\"}");
        HttpContext.Current.Response.End();
    }


}