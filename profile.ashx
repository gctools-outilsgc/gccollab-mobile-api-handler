<%@ WebHandler Language="C#" Class="profile" %>

using System;
using System.Web;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Net;

public class profile : IHttpHandler
{
    private string user, UserKey, lang="en", ProfileEmail = "", method="get.user",prms, limit="", offset="";

    public void ProcessRequest(HttpContext context)
    {
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
        context.Response.AppendHeader("Access-Control-Allow-Origin", "*");

        if (string.IsNullOrEmpty(context.Request["key"]))
            SendError("Invalid Key");
        else
            UserKey = context.Request["key"];

        if (string.IsNullOrEmpty(context.Request["profileemail"]))
            SendError("Invalid profile email");
        else
            ProfileEmail = context.Request["profileemail"];

        string APIKey = Gen_Functions.GetAppropriateAPIKey(context);

        if (!string.IsNullOrEmpty(context.Request["lang"]))
            lang = context.Request["lang"];

        if (!string.IsNullOrEmpty(context.Request["limit"]))
            limit = context.Request["limit"];

        if (!string.IsNullOrEmpty(context.Request["offset"]))
            offset = context.Request["offset"];


        if (!string.IsNullOrEmpty(context.Request["method"]))
            method = context.Request["method"];

        if (string.IsNullOrEmpty(context.Request["user"]))
            SendError("Invalid user parameter");
        else
            user = context.Request["user"];





        // Commenting out for now, allows GetUserProfile function to pull other users beside themselves
        if (!GCTUser.IsUserValid(user, UserKey))
            SendError("Invalid User and Key");


        string url = Gen_Functions.GetAppropriateAPIURL(context);


        switch (method)
        {
            case "get.usergroups":
            case "get.useractivity":
            case "get.user":
                prms = string.Format("method={0}&api_key={1}&user={2}&profileemail={3}&lang={4}", method, APIKey, user, ProfileEmail, lang);
                break;
            default:
                SendError("Invalid Method");
                break;

        }


        string profile = "";

        using (WebClient wc = new WebClient())
        {
            wc.Headers[HttpRequestHeader.ContentType] = "application/x-www-form-urlencoded";
            profile = wc.UploadString(url, prms);
        }



        if (method == "get.user")
        {
            JObject jo = JObject.Parse(profile);
            //### Got lazy
            try
            {
                if (jo["result"] != null && jo["result"]["iconURL"] != null)
                    jo["result"]["iconURL"] = Gen_Functions.GetImageURL(jo["result"]["iconURL"].ToString());
                profile = jo.ToString();
            }
            catch (Exception e)
            {

            }
        }

        context.Response.Write(profile);


    }

    public bool IsReusable
    {
        get
        {
            return false;
        }
    }

    private void SendError(string ErrorMessage)
    {
        HttpContext.Current.Response.Write("{\"status\":-1,\"message\":\"" + ErrorMessage + "\"}");
        HttpContext.Current.Response.End();
    }

}