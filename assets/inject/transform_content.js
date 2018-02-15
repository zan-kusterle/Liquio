import { cleanUrl, defaultUnit, colorOnGradient, slug } from 'shared/votes'
import { updateState } from 'inject/state'

export function onAnchorInsert(node) {
    return

    let is_http = node.protocol === 'http:' || node.protocol === 'https:'
    let is_blank = node.target == "_blank"

    let a_hostname = node.hostname.split('.')
    let a_domain = a_hostname[a_hostname.length - 2]

    let current_hostname = window.location.hostname.split('.')
    let current_domain = current_hostname.length >= 2 ? current_hostname[current_hostname.length - 2] : ''

    if (is_http && (a_domain !== current_domain || is_blank)) {
        let url = cleanUrl(node.origin + node.pathname)

        let startsWith = LIQUIO_URL.replace('://', ':') + '/'
        if (url.startsWith(startsWith)) {
            url = url.substring(startsWith.length)
        }

        Api.getNode(url, null, (node) => {
            let view = tag.getAttribute('liquio-view') || 'default'
            let defaultUnit = defaultUnit(node)

            if (defaultUnit) {
                if (view == 'default') {
                    let red = 'B51212'
                    let yellow = 'FCF119'
                    let green = '44DD25'
                    let color = defaultUnit.average < 0.5 ? colorOnGradient(yellow, red, defaultUnit.average * 2) : colorOnGradient(green, yellow, (defaultUnit.average - 0.5) * 2)

                    node.css('border-top', '3px solid #' + color).css('padding-top', '2px')
                    node.parent().css('overflow', 'visible')
                } else if (view == 'current') {
                    node.after($('<div style="width: 150px; display: inline-block;">' + defaultUnit.embeds.value + '</div>'))
                } else if (view == 'graph') {
                    node.after($('<div style="width: 150px; display: inline-block;">' + defaultUnit.embeds.by_time + '</div>'))
                }
            }
        })
    }
}

export default function (nodesByText, domNode) {
    let text = domNode.textContent.toLowerCase()
    let slugText = slug(text)

    let nodesToAdd = Object.keys(nodesByText).filter((k) => {
        return slugText.indexOf(k) >= 0
    }).map(k => {
        let slugStart = slugText.indexOf(k)
        let start = 0
        for(var i = 0; i < slugStart; i++) {
            let slugChar = slugText[i]
            while (true) {
                let textChar = text[start].replace(' ', '-').toLowerCase()
                start++
                if (textChar === slugChar) {
                    break
                }
            }
        }
        let end = start + k.length

        let range = document.createRange()
        range.setStart(domNode, start)
        range.setEnd(domNode, end)
        return {
            text: k,
            node: nodesByText[k][0],
            range: range
        }
    })

    if (nodesToAdd.length > 0) {
        nodesToAdd.forEach(({ range, node }) => {
            let span = document.createElement('span')
            range.surroundContents(span)
            span.style.backgroundColor = 'rgba(57, 164, 255, 0.25)'
            let isClicked = true
            span.addEventListener('mouseover', (e) => {
                isClicked = false
                updateState({ currentNode: node })
            })
            span.addEventListener('mouseout', (e) => {
                if (!isClicked) {
                    updateState({ currentNode: null })
                }
            })
            span.addEventListener('click', (e) => {
                isClicked = true
                updateState({ currentNode: node })
            })
        })
    }
}
/*
import * as utils from 'shared/votes'

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
*/