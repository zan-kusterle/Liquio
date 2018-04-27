browser.tabs.onUpdated.addListener(function(tabId, changeInfo, tab) {
    if (changeInfo.status == 'complete') {
        browser.tabs.sendMessage(tabId, { name: 'update'})
    }
})

var isHidden = true
browser.browserAction.onClicked.addListener(function(tab) {
    browser.tabs.sendMessage(tab.id, { name: 'open' })
})

browser.runtime.onMessage.addListener(function(request, sender) {
    if (request.name == 'score') {
        let score = request.score

        var color = [220, 220, 220, 255]
        if (score !== null) {
            if (score < 0.25)
                color = [237, 14, 40, 255]
            else if (score < 0.75)
                color = [252, 185, 17, 255]
            else
                color = [38, 188, 28, 255]
        }
        
        browser.browserAction.setBadgeText({
            text: score ? Math.floor(100 * score) + '' : '?',
            tabId: sender.tab.id
        })
        browser.browserAction.setBadgeBackgroundColor({
            color: color,
            tabId: sender.tab.id
        })
    }
})