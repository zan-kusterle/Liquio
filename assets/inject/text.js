import * as utils from 'inject/utils'
import * as note from 'inject/note'
import styles from 'inject/styles'

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

        utils.getUrl(LIQUIO_URL + '/api/nodes/' + encodeURIComponent(url), (data) => {
            let view = tag.getAttribute('liquio-view') || 'default'
            let defaultUnit = utils.defaultUnit(data.data)

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
    let text = domNode.textContent

    let nodesToAdd = Object.keys(nodesByText).filter((k) => {
        return text.toLowerCase().indexOf(k) >= 0
    }).reduce((a, k) => a.concat(nodesByText[k]), [])

    if (nodesToAdd.length > 0) {
        note.prepareContainer(domNode, classes)
        for (let nodeToAdd of nodesToAdd)
            note.addToContainer(domNode, nodeToAdd)
    }
}