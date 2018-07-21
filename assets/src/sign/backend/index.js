/* globals DEFAULT_WHITELIST_URL, chrome */

import storage from '../popup/storage'

let currentMessages = {}
let currentPort = null
let crossExtensionResponses = []
let onUpdate = (tabId) => {
	if (tabId) {
		storage.isAlertDismissed().then(v => {
			if (!v) {
				chrome.tabs.sendMessage(tabId, { name: 'show-alert' })
			}
		})
	}

	if (currentPort)
		currentPort.postMessage({ messages: Object.values(currentMessages) })
}

chrome.storage.local.get('username', (data) => {
	crossExtensionResponses.push({
		request_name: 'whitelist',
		url: DEFAULT_WHITELIST_URL,
		username: data.username || null
	})
})

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
	if (request.name === 'hide') {
		onUpdate(sender.tab.id)
	} else if (request.name === 'cross-extension') {
		let data = request.data
		if (data.name === 'sign') {
			data.messages.forEach(message => {
				let keyValue = message.key.map(k => message[k]).join(',')
				currentMessages[keyValue] = message
			})

			chrome.browserAction.setBadgeText({
				text: Object.keys(currentMessages).length.toString(),
				tabId: sender.tab.id
			})
			chrome.browserAction.setBadgeBackgroundColor({
				color: '#16799e',
				tabId: sender.tab.id
			})

			onUpdate(sender.tab.id)
		}
	} else if (request.name === 'cross-extension-respond') {
		crossExtensionResponses.push(request.data)
	} else if (request.name === 'cross-extension-get-responses') {
		sendResponse({
			responses: crossExtensionResponses
		})
	} else if (request.name === 'dismiss-alert') {
		storage.dismissAlert()
	}
})

chrome.extension.onConnect.addListener(port => {
	currentPort = port
	onUpdate()
})
