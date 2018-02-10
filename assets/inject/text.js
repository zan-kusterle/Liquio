import * as utils from 'shared/votes'
import * as note from 'inject/note'
import styles from 'inject/styles'
import { updateState } from 'inject/state'

var nodesByText, classes

export function init(_nodesByText, _classes) {
    nodesByText = _nodesByText
    classes = _classes

    document.addEventListener('click', (e) => {
        let nodes = document.getElementsByClassName('liquio-note')
        for (let node of nodes)
            node.style.display = 'none'
    })
}

export function onAnchorInsert(node) {
    let is_http = node.protocol === 'http:' || node.protocol === 'https:'
    let is_blank = node.target == "_blank"

    let a_hostname = node.hostname.split('.')
    let a_domain = a_hostname[a_hostname.length - 2]

    let current_hostname = window.location.hostname.split('.')
    let current_domain = current_hostname.length >= 2 ? current_hostname[current_hostname.length - 2] : ''

    if (is_http && (a_domain !== current_domain || is_blank)) {
        let url = utils.cleanUrl(node.origin + node.pathname)

        let startsWith = LIQUIO_URL.replace('://', ':') + '/'
        if (url.startsWith(startsWith)) {
            url = url.substring(startsWith.length)
        }

        Api.getNode(url, null, (node) => {
            let view = tag.getAttribute('liquio-view') || 'default'
            let defaultUnit = utils.defaultUnit(node)

            if (defaultUnit) {
                if (view == 'default') {
                    let red = 'B51212'
                    let yellow = 'FCF119'
                    let green = '44DD25'
                    let color = defaultUnit.average < 0.5 ? utils.colorOnGradient(yellow, red, defaultUnit.average * 2) : utils.colorOnGradient(green, yellow, (defaultUnit.average - 0.5) * 2)

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

export function onTextInsert(nodesByText, domNode, classes) {
    let text = domNode.textContent.toLowerCase()

    let nodesToAdd = Object.keys(nodesByText).filter((k) => {
        return text.indexOf(k) >= 0
    }).map(k => {
        let start = text.indexOf(k)
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