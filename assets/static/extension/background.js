chrome.tabs.onUpdated.addListener(function(tabId, changeInfo, tab) {
    if (changeInfo.status == 'complete') {
        chrome.tabs.sendMessage(tabId, { name: 'update'})
    }
})

var off = true
chrome.browserAction.onClicked.addListener(function(tab) {
    off = !off

    chrome.tabs.sendMessage(tab.id, { name: 'toggle' })

    if (off) {
        chrome.browserAction.setIcon({ path: "icons/off.png", tabId: tab.id })
    } else {
        chrome.browserAction.setIcon({ path: "icons/on.png", tabId: tab.id })
    }
})
