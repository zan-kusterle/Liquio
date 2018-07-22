/* globals chrome */

chrome.tabs.onUpdated.addListener(function(tabId, changeInfo) {
	if (changeInfo.status == 'complete') {
		chrome.tabs.sendMessage(tabId, { name: 'update'})
	}
})

chrome.browserAction.onClicked.addListener(function(tab) {
	chrome.tabs.sendMessage(tab.id, { name: 'open' })
})

chrome.runtime.onMessage.addListener(function(request, sender) {
	if (request.name == 'score') {
		let score = request.score

		var color = [220, 220, 220, 255]
		var text = '?'
		if (score !== null) {
			if (score < 0.25)
				color = [237, 14, 40, 255]
			else if (score < 0.75)
				color = [252, 185, 17, 255]
			else
				color = [38, 188, 28, 255]
			text = Math.floor(100 * score) + ''
		}
        
		chrome.browserAction.setBadgeText({
			text: text,
			tabId: sender.tab.id
		})
		chrome.browserAction.setBadgeBackgroundColor({
			color: color,
			tabId: sender.tab.id
		})
	}
})
