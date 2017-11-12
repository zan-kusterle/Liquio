import _ from 'lodash'
import jss from 'jss'
import preset from 'jss-preset-default'
import * as utils from 'inject/utils'

jss.setup(preset())

const styles = {
    overlay: {
        'z-index': 100,
        'display': 'none',
        'cursor': 'default',
        'font-family': 'Helvetica Neue, Helvetica, Arial, sans-serif',
        'font-weight': 'normal',
        'border-radius': '3px',
        'font-size': '14px',
        'position': 'absolute',
        'left': '0',
        'top': '100px',

        '& > .node': {
            'margin': '5px 0px',
            'display': 'table',

            '& > .value': {
                'width': '192px',
                'height': '48px',
                'display': 'table-cell',
                'vertical-align': 'middle',
                'font-weight': 'bold',
                'font-size': '0'
            },

            '& > .title': {
                'display': 'table-cell',
                'background-color': 'rgba(20, 20, 20, 0.9)',
                'padding': '5px 20px',
                'max-width': '400px',
                'vertical-align': 'middle',

                '& > a': {
                    'color': 'white !important',
                    'vertical-align': 'middle',
                    'font-size': '14px !important',
                    'line-height': '28px',
                    'text-decoration': 'none !important',

                    '&:hover': {
                        'color': '#ddd !important'
                    }
                }
            }
        }
    }
}

const { classes } = jss.createStyleSheet(styles).attach()

var nodesByText
var instance

function setup() {
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
            if (currentNode == null || !_.isEqual(newNode.path, currentNode.path)) {
                overlay.innerHTML = utils.renderNode(newNode)
                overlay.style.opacity = 1
            }
        }
        currentNode = newNode
    }

    setInterval(update, 1000)
    player.click(function(event) { update() })
}

export function setData(d) {
    nodesByText = d
    if (instance)
        setup()
}

export function onYouTubeIframeAPIReady() {
    let player = new YT.Player('main-video-frame', {
        events: {
            'onReady': onPlayerReady
        }
    })

    function onPlayerReady(event) {
        instance = player
        if (nodesByText)
            setup()
    }
}

export function getTime() {
    return instance ? instance.getCurrentTime() : 0
}