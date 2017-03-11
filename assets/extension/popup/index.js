function getCurrentTabUrl(callback) {
	chrome.tabs.query({
		active: true,
		currentWindow: true
	}, function(tabs) {
		var tab = tabs[0];
		var url = tab.url;
		console.assert(typeof url == 'string', 'tab.url should be a string');
		callback(tab);
	});
}

var html_cache = {};

function getLinks(rootUrl, topic, callback, errorCallback) {
	var topicUrl = rootUrl + '/' + encodeURIComponent(topic);
	var x = new XMLHttpRequest();
	x.open('GET', topicUrl);
	x.onload = function() {
		var data = JSON.parse(x.response);
		var html = data.embed;
		html = html.split('a href="').join('a href="' + rootUrl);
		document.getElementById("container").innerHTML = html;
		let count = data.references.length;
		if(count == 0) {
			document.getElementById("container").innerHTML = "";
		} else {
			html_cache[topic] = html;
			chrome.storage.local.set({'count': count}, function() {
			});
			chrome.storage.local.set({'html_cache': html_cache}, function() {
			});
		}
		callback(count);
	};
	x.onerror = function() {
		errorCallback('Network error.');
	};
	x.send();
}

function makeLinksClickable() {
	var links = document.getElementsByTagName("a");
	for (var i = 0; i < links.length; i++) {
		(function () {
			var ln = links[i];
			var location = ln.href;
			ln.onclick = function () {
				chrome.tabs.create({active: true, url: location});
			};
		})();
	}
}

document.addEventListener('DOMContentLoaded', function() {
	getCurrentTabUrl(function(tab) {
		var rootUrl = 'https://liqu.io';
		var topicUrl = rootUrl + '/' + encodeURIComponent(tab.url) + '/references';
		var html = '<a href="' + topicUrl + '"><b>View this page on Liquio</b>: ' + tab.title + '</a>';
		document.getElementById("url").innerHTML = html;

		chrome.storage.local.get('html_cache', function(result) {
			html_cache = result.html_cache;
			document.getElementById("container").innerHTML = html_cache[tab.url] || '<img id="loading" src="loading.gif"></img>';
			makeLinksClickable();
		});

		chrome.storage.local.get('count', function(result) {
			let count = result.count;
			let count_text = count == 0 ? "" : (count > 10 ? "10+" : count + "");
			chrome.browserAction.setBadgeText({text: count_text, tabId: tab.id});
		});

		makeLinksClickable();

		getLinks(rootUrl, tab.url, function(count) {
			let count_text = count == 0 ? "" : (count > 10 ? "10+" : count + "");
			chrome.browserAction.setBadgeText({text: count_text, tabId: tab.id});
			makeLinksClickable();
		}, function(errorMessage) {
		});
	});
});