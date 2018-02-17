<%@ WebHandler Language="C#" Class="git" %>

using System;
using System.Web;
using System.Diagnostics;

public class git : IHttpHandler {

    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "text/plain";
       // context.Response.Write("Hello World");
        //>git -C C:/inetpub/wwwroot/gctoolkit fetch
        string gitCommand = @"C:\Program Files\Git\cmd\git.exe";
        string gitDir = "-C C:/inetpub/API pull";


        Process p = new Process();
        p.StartInfo.RedirectStandardOutput = true;
        p.StartInfo.RedirectStandardError = true;

        p.StartInfo.UseShellExecute = false;
        p.StartInfo.FileName = gitCommand;
        p.StartInfo.Arguments = gitDir;
        p.Start();
        string output = p.StandardOutput.ReadToEnd();
        string error = p.StandardError.ReadToEnd();
        p.WaitForExit();

        context.Response.Write("output: " + output + "-----\n" + "Error: " + error + "-----");

    }

    public bool IsReusable {
        get {
            return false;
        }
    }

}