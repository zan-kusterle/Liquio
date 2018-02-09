import * as utils from 'inject/utils'

export function init(nodesByText, videoPlayer, classes) {
    let player = document.getElementById('player')
    player.prepend('<div class="liquio-video-note ' + classes.overlay + '"></div>')
    let overlay = player.getElementsByClassName('liquio-video-note')[0]

    let isOverlayOpen = false
    let currentNode = null

    let update = function() {
        let time = instance.getCurrentTime()

        var newNode = null
        for (var key in nodesByText) {
            let key_parts = key.replace('/', '').split(":")
            if (key_parts.length == 2) {
                let key_time = parseInt(key_parts[0]) * 60 + parseInt(key_parts[1])
                let delta = time - key_time
                if (delta >= 0 && delta <= 10) {
                    newNode = nodesByText[key][0]
                }
            }
        }

        if (newNode == null) {
            if (!isOverlayOpen)
                overlay.style.opacity = 0
        } else {
            let isEqual = newNode.path.length === currentNode.path.length
            if (isEqual) {
                for(var i = 0; i < node.path.length; i++) {
                    if (newNode.path[i] !== currentNode.path[i]) {
                        isEqual = false
                        break
                    }
                }
            }
            
            if (currentNode == null || !isEqual) {
                overlay.innerHTML = utils.renderNode(newNode)
                overlay.style.opacity = 1
            }
        }
        currentNode = newNode
    }

    setInterval(update, 1000)
    player.click(function(event) { update() })
}
