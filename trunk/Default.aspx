<%@ Page Language="C#" AutoEventWireup="true"  CodeFile="Default.aspx.cs" Inherits="_Default" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>AJAX Streaming Proxy Test</title>
    
<style type="text/css">
body {
	background-color: #666600;
	color: #FFFFFF;
	font-family: Arial, Helvetica, sans-serif;
	}
#url { width: 15em }
#theform {
	background-color: #4F4F00;
	width: 50em;
	}
#theform fieldset {
	height: 20em;
	width: 14em;
	border: 0;
	margin: 0;
	padding: 1em;
	float: left;
	}
#theform fieldset legend {
	font-size: 4em;
	font-family: Georgia, "Times New Roman", Times, serif;
	color: #FFFFFF;
	}
#theform fieldset legend span {
	display: none;
	}
#theform fieldset h3 {
	height: 4em;
	font-size: 1em;
	}
#theform fieldset div.help {
	color: #FFFF99;
	font-size: 0.7em;
	font-weight: bold;
	min-height: 5em;
	}
#theform fieldset label {
	font-size: 0.7em;
	line-height: 1.5em;
	}
#theform fieldset input {
	font-size: 0.8em;
	height: 1.2em;
	}
#theform fieldset input.button {	
	height: 30px;
	font-size: 1em;
	width: 5em;

}
#theform #result {
	clear: both;
	width: 50em;
	height: 10em;
	border: 10px solid #666600;
	border-width: 10px 0;
	padding: 1em;
	
	}
#theform #result legend {
	display: none;
	}
#theform #result textarea {
    width: 28em;
    height: 7em;
    font-size: small;
}
#theform #result p {
 margin:0; padding:0;
}
#theform #result h3 {
 height: 1.5em;
}
#theform #result span.width50p 
{
	float:left; width: 50%;
}
#theform #result #statistics
{
	width: 28em;
    height: 7em;
    background:#4F4F00;
    border: solid 1px dimgray;
    color: White;
    
}

/* Error Styling */
#theform fieldset.error,
#theform fieldset.error legend,
#theform fieldset.error div.help {
	color: #FFCC33;
	}
#theform fieldset strong.error {
	color: #fff;
	background-color: #CC0000;
	padding: 0.2em;
	font-size: 0.7em;
	font-weight: bold;
	display: block;
	}

#copyright {
	clear: both;
	padding: 0.5em;
	font-size: 0.8em;
	color: #9F9F00;
	font-style: italic;
	}
</style>



</head>
<body>
    
    <h1>AJAX Streaming Proxy</h1>
    <h2>Continuously stream data from server side proxy</h2>
    
    <form id="theform" runat="server">
        <asp:ScriptManager runat="server" EnablePageMethods="false" EnablePartialRendering="false" EnableScriptGlobalization="false" EnableScriptLocalization="false" EnableViewState="false" LoadScriptsBeforeUI="false"></asp:ScriptManager>
        <fieldset>
            <legend><span>Step </span>1. <span>: Enter URL to download</span></legend>
            <h3>Enter URL of an endpoint which can deliver content over XMLHTTP</h3>
            <div class="help">This can be a static file or a REST web service end</div>
            
            <label for="url">URL of the source</label>
            <br />
            <textarea id="url" tabindex="1" rows="2" cols="25">http://msdn.microsoft.com/rss.xml</textarea>
        </fieldset>
        
        <fieldset>
            <legend><span>Step </span>2. <span>: What type of call</span></legend>
            <h3>Specify whether it's a JSON call or a regular HTTP GET</h3>
            <div class="help">For JSON call, special Content-Type Request Header is sent. For regular HTTP GET, no special content type is sent.</div>
            <br />
            <input id="httpGet" type="radio" name="type" checked="checked" tabindex="2"/><label for="httpGet">Plain HTTP GET</label>           
            <br />
            <input id="json" type="radio" name="type" tabindex="3" /><label for="httpGet">JSON</label>
            <br />
            <br />
            <input id="cache" type="checkbox" name="cache" tabindex="4" /><label for="cache">Cache response</label>
        </fieldset>
        
        <fieldset class="error">
		    <legend><span>Step </span>3. <span>: Hit the service</span></legend>
		    <h3>Choose the method of test</h3>
		    
		    <div class="help">Regular method delivers content after it has fully downloaded on server. The <em>Streaming</em> method streams the content to browser while it is being downloaded on the server.</div>
		    <br />
		    <input type="button" class="button" value="Regular" tabindex="5" onclick="downloadRegular()"/>
		    &nbsp;&nbsp;
		    <input type="button" class="button" value="Stream!" tabindex="6" onclick="downloadStreaming()"/>
	    </fieldset>	
    
        <fieldset id="result">
		    <legend>Result</legend>
		    <h3>Test Result</h3>
		    
		    <span class="width50p">
		    <p>Download Content</p>
		    <textarea id="resultContent" rows="10" cols="40" autocomplete="no"></textarea>
		    </span>
		    
		    <span class="width50p">
		    <strong>Statistics:</strong>
		    <textarea id="statistics" rows="5" cols="20" autocomplete="no"></textarea>
		    </span>
	    </fieldset>
	    
	    
	    <div id="copyright">
	    Copyright © 2008, Omar AL Zabir. All rights reserved.
	    <br />
	    CSS inspired by <a rel="nofollow">http://www.skyrocket.be/lab/semantic_horizontal_form.html</a>
	    </div>
    </form>
    
    <div id="blockUI" style="display: none; background-color: black;
        width: 100%; height: 100%; position: absolute; left: 0px; top: 0px; z-index: 50000;     
        -moz-opacity:0.5;opacity:0.5;filter:alpha(opacity=50);"
        onclick="return false" onmousedown="return false" onmousemove="return false"
        onmouseup="return false" ondblclick="return false">&nbsp;</div>
    <div id="message" style="z-index: 50001; display:none; left:50%; 
        top:50%; margin-left:-5em; margin-top:-2em; border: solid 4px dimgray; 
        background:white; position:absolute; text-align:center; width:10em; height:4em;
        color:Black; font-weight:bold; padding-top:1.5em">Loading...</div>


    <script type="text/javascript">
    function showProgress()
    {
        $get('message').style.display = $get('blockUI').style.display="block";        
    }
    function hideProgress()
    {
        $get('message').style.display = $get('blockUI').style.display="none";
    }
    
    function downloadRegular()
    {
        showProgress();
        appendStat("Regular mode\n");
        download("RegularProxy.ashx", $get('url').value, $get('json').checked, hideProgress );
    }   
    function downloadStreaming()
    {        
        showProgress();
        appendStat("Streaming mode\n");
        download("StreamingProxy.ashx", $get('url').value, $get('json').checked, hideProgress );  
    } 
    function download(proxyUrl, contentUrl, isJson, completeCallback)
    {
        var request = new Sys.Net.WebRequest();
        request.set_httpVerb("GET");
        
        var isCache = $get('cache').checked;
        var url = proxyUrl + "?u=" + escape(contentUrl) + (isJson ? "&t=" + escape("application/json") : "") + "&c=" + (isCache ? "10" : "0");        
        request.set_url(url);
    
        var startTime = new Date().getTime();
        
        request.add_completed( function( executor )
        {
            if (executor.get_responseAvailable()) 
            {                                
                var content = executor.get_responseData();
                var endTime = new Date().getTime();
                
                var statistics = "Duration: " + (endTime - startTime) + "ms" + '\n' +
                    "Length: " + content.length + " bytes" + '\n';
                appendStat(statistics);
                
                $get('resultContent').value = content;                
                completeCallback();
            }
        });
        
        var executor = new Sys.Net.XMLHttpExecutor();
        request.set_executor(executor); 
        executor.executeRequest();
    }
    function appendStat(msg)
    {
        $get("statistics").value += msg;
    }
    
    function pageLoad()
    {
        $get("statistics").value = $get("resultContent").value = "";
    }
    
    </script>
</body>
</html>
