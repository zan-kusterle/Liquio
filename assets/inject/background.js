browser.tabs.onUpdated.addListener(function(tabId, changeInfo, tab) {
    if (changeInfo.status == 'complete') {
        browser.tabs.sendMessage(tabId, { name: 'update'})
    }
})

var off = true
browser.browserAction.onClicked.addListener(function(tab) {
    off = !off

    browser.tabs.sendMessage(tab.id, { name: 'toggle' })

    if (off) {
        browser.browserAction.setIcon({ path: "icons/off.png", tabId: tab.id })
    } else {
        browser.browserAction.setIcon({ path: "icons/on.png", tabId: tab.id })
    }
})
