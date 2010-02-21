<%@ Page Language="C#" AutoEventWireup="true" CodeFile="GetPutDeleteTest.aspx.cs"
    Inherits="_Default" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>AJAX Streaming Proxy Test</title>
    <style type="text/css">
        body
        {
            background-color: #666600;
            color: #FFFFFF;
            font-family: Arial, Helvetica, sans-serif;
        }
        #url
        {
            width: 15em;
        }
        #theform
        {
            background-color: #4F4F00;
            width: 50em;
        }
        #theform fieldset
        {
            min-height: 20em;
            width: 14em;
            border: 0;
            margin: 0;
            padding: 1em;
            float: left;
        }
        #theform fieldset legend
        {
            font-size: 4em;
            font-family: Georgia, "Times New Roman" , Times, serif;
            color: #FFFFFF;
        }
        #theform fieldset legend span
        {
            display: none;
        }
        #theform fieldset h3
        {
            height: 4em;
            font-size: 1em;
        }
        #theform fieldset div.help
        {
            color: #FFFF99;
            font-size: 0.7em;
            font-weight: bold;
            min-height: 5em;
        }
        #theform fieldset label
        {
            font-size: 0.7em;
            line-height: 1.5em;
        }
        #theform fieldset input
        {
            font-size: 0.8em;
            height: 1.2em;
        }
        #theform fieldset input.button
        {
            height: 30px;
            font-size: 1em;
            width: 5em;
        }
        #theform fieldset input.text
        {
            font-size: 1.2em;
            height: 1.5em;
        }
        #theform #result
        {
            clear: both;
            width: 50em;
            height: 10em;
            border: 10px solid #666600;
            border-width: 10px 0;
            padding: 1em;
        }
        #theform #result legend
        {
            display: none;
        }
        #theform #result textarea
        {
            width: 28em;
            height: 7em;
            font-size: small;
        }
        #theform #result p
        {
            margin: 0;
            padding: 0;
        }
        #theform #result h3
        {
            height: 1.5em;
        }
        #theform #result span.width50p
        {
            float: left;
            width: 50%;
        }
        #theform #result #statistics
        {
            width: 28em;
            height: 12em;
            background: #4F4F00;
            border: solid 1px dimgray;
            color: White;
        }
        /* Error Styling */#theform fieldset.error, #theform fieldset.error legend, #theform fieldset.error div.help
        {
            color: #FFCC33;
        }
        #theform fieldset strong.error
        {
            color: #fff;
            background-color: #CC0000;
            padding: 0.2em;
            font-size: 0.7em;
            font-weight: bold;
            display: block;
        }
        #copyright
        {
            clear: both;
            padding: 0.5em;
            font-size: 0.8em;
            color: #9F9F00;
            font-style: italic;
        }
        .clear
        {
            clear: both;
        }
    </style>
</head>
<body>
    <h1>
        AJAX Streaming Proxy</h1>
    <h2>
        Continuously stream data from server side proxy supporting GET, POST, PUT, DELETE</h2>
    <form id="theform" runat="server">
    <asp:ScriptManager runat="server" EnablePageMethods="false" EnablePartialRendering="false"
        EnableScriptGlobalization="false" EnableScriptLocalization="false" EnableViewState="false"
        LoadScriptsBeforeUI="false">
    </asp:ScriptManager>
    <fieldset>
        <legend><span>Step </span>1. <span>: Enter URL to download</span></legend>
        <h3>
            POST Test</h3>
        <div class="help">
            Define the URL and the payload and test if POST works.</div>
        <label for="postUrl">
            URL for POST</label>
        <br />
        <textarea id="postUrl" tabindex="1" rows="2" cols="25">http://localhost:8080/AjaxStreamingProxy/Echo.ashx</textarea>
        <label for="postPayload">
            POST Payload</label>
        <br />
        <textarea id="postPayload" tabindex="1" rows="5" cols="25">This is sample payload for POST</textarea>
        <input id="postJson" type="checkbox" name="type" tabindex="3" /><label for="postJson">JSON</label>
        <br />
        <input type="button" class="button" value="POST" tabindex="5" onclick="testPOST()" />
        <div class="clear">
        </div>
    </fieldset>
    <fieldset>
        <legend>2. <span>: Enter URL to download</span></legend>
        <h3>
            PUT Test</h3>
        <div class="help">
            Define the URL and the payload and test if PUT works.</div>
        <label for="putUrl">
            URL for PUT</label>
        <br />
        <textarea id="putUrl" tabindex="1" rows="2" cols="25">http://localhost:8080/AjaxStreamingProxy/Echo.ashx</textarea>
        <label for="putPayload">
            PUT Payload</label>
        <br />
        <textarea id="putPayload" tabindex="1" rows="5" cols="25">This is sample payload for PUT</textarea>
        <input id="putJson" type="checkbox" name="type" tabindex="3" /><label for="postJson">JSON</label>
        <br />
        <input type="button" class="button" value="PUT" tabindex="5" onclick="testPUT()" />
    </fieldset>
    <fieldset class="error">
        <legend>3. <span>: Enter URL to hit</span></legend>
        <h3>
            DELETE Test</h3>
        <div class="help">
            Define the URL to test DELETE</div>
        <label for="deleteUrl">
            URL to send DELETE</label>
        <br />
        <textarea id="deleteUrl" tabindex="1" rows="2" cols="25">http://localhost:8080/AjaxStreamingProxy/Echo.ashx</textarea>&nbsp;
        <input type="button" class="button" value="DELETE" tabindex="5" onclick="testDELETE()" />
        
        <br />
        <br />        
        <br />
        <p>Define Cookies</p>
        <label>Name</label> <input id="cookieName" class="text" type="text" value="SMSESSION" />
        
        <label>Value</label><input id="cookieValue" class="text" type="text" value="XXXX12312312" /><br /> <br />
        <input type="button" class="button" value="Create" onclick="setCookie()" />
    </fieldset>    
        
    <fieldset id="result">
        <legend>Result</legend>
        <h3>
            Test Result</h3>
        <span class="width50p">
            <p>
                Download Content</p>
            <textarea id="resultContent" rows="10" cols="40" autocomplete="no"></textarea>
        </span><span class="width50p"><strong>Statistics:</strong>
            <textarea id="statistics" rows="5" cols="20" autocomplete="no"></textarea>
        </span>
    </fieldset>
    <div id="copyright">
        Copyright © 2008, Omar AL Zabir. All rights reserved.
        <br />
        CSS inspired by <a rel="nofollow">http://www.skyrocket.be/lab/semantic_horizontal_form.html</a>
    </div>
    </form>
    <div id="blockUI" style="display: none; background-color: black; width: 100%; height: 100%;
        position: absolute; left: 0px; top: 0px; z-index: 50000; -moz-opacity: 0.5; opacity: 0.5;
        filter: alpha(opacity=50);" onclick="return false" onmousedown="return false"
        onmousemove="return false" onmouseup="return false" ondblclick="return false">
        &nbsp;
    </div>
    <div id="message" style="z-index: 50001; display: none; left: 50%; top: 50%; margin-left: -5em;
        margin-top: -2em; border: solid 4px dimgray; background: white; position: absolute;
        text-align: center; width: 10em; height: 4em; color: Black; font-weight: bold;
        padding-top: 1.5em">
        Loading...
    </div>

    <script type="text/javascript">

        var proxyUrl = "StreamingProxy.ashx";

        function showProgress() {
            $get('message').style.display = $get('blockUI').style.display = "block";
        }
        function hideProgress() {
            $get('message').style.display = $get('blockUI').style.display = "none";
        }

        function testPOST() {
            showProgress();
            appendStat("Making POST...\n");
            download("POST", proxyUrl, $get('postUrl').value, $get('postJson').checked, $get('postPayload').value, hideProgress);
        }

        function testPUT() {
            showProgress();
            appendStat("Making PUT...\n");
            download("PUT", proxyUrl, $get('putUrl').value, $get('putJson').checked, $get('putPayload').value, hideProgress);
        }

        function testDELETE() {
            showProgress();
            appendStat("Making DELETE...\n");
            download("DELETE", proxyUrl, $get('deleteUrl').value, false, '', hideProgress);
        }
        
        function download(method, proxyUrl, contentUrl, isJson, bodyContent, completeCallback) {
            var request = new Sys.Net.WebRequest();
            
            if (method == "POST" || method == "PUT")
                request.set_httpVerb("POST");
            else
                request.set_httpVerb("GET");

            var url = proxyUrl + "?m=" + method + (isJson ? "&t=" + escape("application/json") : "") + "&u=" + escape(contentUrl);

            request.set_url(url);

            if (bodyContent.length > 0) {
                request.set_body(bodyContent);
                request.get_headers()["Content-Length"] = bodyContent.length;
            }

            var startTime = new Date().getTime();

            request.add_completed(function(executor) {
                if (executor.get_responseAvailable()) {
                    var content = executor.get_responseData();
                    var endTime = new Date().getTime();

                    var statistics =
                    "Duration: " + (endTime - startTime) + "ms" + '\n' +
                    "Length: " + content.length + " bytes" + '\n' +
                    "Status Code: " + executor.get_statusCode() + " " + '\n' +
                    "Status: [" + executor.get_statusText() + "]" + '\n';
                    appendStat(statistics);

                    $get('resultContent').value = content;
                    completeCallback();
                }
            });

            var executor = new Sys.Net.XMLHttpExecutor();
            request.set_executor(executor);
            executor.executeRequest();
        }

        function appendStat(msg) {
            $get("statistics").value += msg;
        }

        function pageLoad() {
            $get("statistics").value = $get("resultContent").value = "";
        }

        function createCookie(name, value, days) {
            if (days) {
                var date = new Date();
                date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
                var expires = "; expires=" + date.toGMTString();
            }
            else var expires = "";
            document.cookie = name + "=" + value + expires + "; path=/";
        }

        function setCookie() {
            createCookie($get('cookieName').value, $get('cookieValue').value);
        }
    
    </script>

</body>
</html>
