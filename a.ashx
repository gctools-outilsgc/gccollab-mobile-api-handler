<%@ WebHandler Language="C#" Class="a" %>

using System;
using System.Web;
using System.Net;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

public class a: IHttpHandler {

    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json";
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
        context.Response.AppendHeader("Access-Control-Allow-Origin", "*");

        //################## USER VALIDATION - throw ErrorInvalidUserKey() to end execution 
        string user = context.Request["user"]; //### Might depricate this and just get the user email from the key value in the DB
        string UserKey = context.Request["key"];
        if (!GCTUser.IsUserValid(user, UserKey))
        {
            ErrorInvalidUserKey();
        }

        string APIKey = Gen_Functions.GetAppropriateAPIKey(context);
        string postData = "";
        foreach (string key in context.Request.Form.Keys)
        {
            postData += key + "=" + context.Request.Form[key] + "&";
        }

        foreach (string key in context.Request.QueryString.Keys)
        {
            postData += key + "=" + context.Request.QueryString[key] + "&";
        } 

        postData += "api_key=" + APIKey;

        string method = context.Request["Method"];
        if (method == "block.user"){
            context.Response.Write("{\"status\":1,\"message\":\"User blocked.\"}");
            context.Response.End();
        }
        if(method == "report.post"){
            context.Response.Write("{\"status\":1,\"message\":\"Message Reported.\"}");
            Gen_Functions.SendMail("seankibbee@gmail.com", "Post Reported", "Post was reported as inappropriate: " + context.Request["guid"]);
            context.Response.End();
        }

        string APIData = "";
        string url = Gen_Functions.GetAppropriateAPIURL(context);
        using (MyWebClient wc = new MyWebClient())
        {
            wc.Headers[HttpRequestHeader.ContentType] = "application/x-www-form-urlencoded";
            APIData = wc.UploadString(url, postData);
        }

        JObject json = JObject.Parse(APIData);

        foreach (var obj in json.SelectTokens("result"))
        {
            foreach (var obj2 in obj.Children())
            {
                foreach (var img in obj2.SelectTokens("userDetails"))
                    img["iconURL"] = Gen_Functions.GetImageURL(img["iconURL"].ToString());
            }
        }

        context.Response.Write(json.ToString());
    }

    public bool IsReusable {
        get {
            return false;
        }
    }

    void ErrorInvalidUserKey()
    {
        HttpContext.Current.Response.Write("{\"status\":-1,\"message\":\"Invalid User Key\"}");
        HttpContext.Current.Response.End();
    }
}