function showCopyLinks(el, mid) {
	var d = document;
	var links_mid = d.getElementById('links_mid');
	var urlbb = "[url=http://www.sql.ru/forum/actualutils.aspx?action=gotomsg&tid=910932&msg="+mid+"]??? ????? ??????? ???????????[/url]";
	var url = "http://www.sql.ru/forum/actualutils.aspx?action=gotomsg&tid=910932&msg="+mid;
	var msg = "[msg="+mid+"]";

	el.parentNode.appendChild(links_mid);
	links_mid.setAttribute("style", "top:"+getElementPosition(el)+"px;");
	links_mid.style.display = "block";
	var input = links_mid.getElementsByTagName('input');
	input[0].value = msg;
    input[1].value = urlbb;
    input[2].value = url;
    input[0].select();
    
}

function hideCopyLinks(el) {
    el.style.display = "none";
}


function getElementPosition(elem)
{

    var l = 0;
    var t = 15;

    while (elem)
    {
        l += elem.offsetLeft;
        t += elem.offsetTop;
        elem = elem.offsetParent;
    }

    return {"left":l, "top":t};
}


	function load_lightbox(el) {
		if(!document.getElementById('lightbox')) {
			var head= document.getElementsByTagName('head')[0];
			var script= document.createElement('script');
			var styles= document.createElement('link');

			styles.type= 'text/css';
			styles.rel= 'stylesheet';
			styles.href= "/css/lightbox.css";
			styles.media= "screen";

			script.type= 'text/javascript';
			script.src= '/js/lightbox.js';

			window.lbImageShow = el;
			head.appendChild(script);
			head.appendChild(styles);
		}
	}

	function Cpy(val) {
	    document.getElementById("tt").value = val;
	    if (document.selection) {
	        rng = document.getElementById("tt").createTextRange(); rng.execCommand("Copy");
	    } else {
	        try { netscape.security.PrivilegeManager.enablePrivilege("UniversalXPConnect"); } catch (e) { }
	        var clipboard = Components.classes["@mozilla.org/widget/clipboard;1"].getService();
	        if (clipboard) {
	            clipboard = clipboard.QueryInterface(Components.interfaces.nsIClipboard);
	        }
	        var transferable = Components.classes["@mozilla.org/widget/transferable;1"].createInstance();
	        if (transferable) {
	            transferable = transferable.QueryInterface(Components.interfaces.nsITransferable);
	        }
	        if (clipboard && transferable) {
	            transferable.addDataFlavor("text/unicode");
	            var textObj = new Object();
	            var textObj = Components.classes["@mozilla.org/supports-string;1"].createInstance(Components.interfaces.nsISupportsString);
	            if (textObj) {
	                textObj.data = document.getElementById("tt").value;
	                transferable.setTransferData("text/unicode", textObj, textObj.data.length * 2);
	                var clipid = Components.interfaces.nsIClipboard;
	                clipboard.setData(transferable, null, clipid.kGlobalClipboard);
	            }
	        }

	    }
	}