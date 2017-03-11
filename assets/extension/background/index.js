chrome.contextMenus.onClicked.addListener(function(info, tab) {
	var url = tab.url;
	if(!url.endsWith('/'))
		url = url + '/';
	let text = info.selectionText;
	let rootUrl = 'https://liqu.io';
	let topicUrl = rootUrl + '/' + encodeURIComponent(url + text);
	chrome.tabs.create({active: true, url: topicUrl});	
});

chrome.contextMenus.create({
	id: 'open',
	title: "Link Liquio poll to text '%s'",
	contexts: ['selection'],
});
