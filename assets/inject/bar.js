import j2c from 'j2c'
import * as utils from 'shared/votes'

let styles = {
    main: {
        cursor: 'default',
        fontFamily: 'Helvetica Neue, Helvetica, Arial, sans-serif',
        position: 'fixed',
        bottom: '0px',
        zIndex: '1000',
        width: '100%',
        backgroundColor: 'white',
        borderTop: '1px solid rgba(220, 220, 220, 0.6)'
    },
    wrap: {
        display: 'flex',
        alignItems: 'center',
        padding: '10px 20px'
    },
    score: {
        'width': '50px',
        'height': '50px',
        'line-height': '50px',
        'border-radius': '50%',
        'text-align': 'center',
        'font-size': '20px',
        'display': 'inline-block',
        'vertical-align': 'middle'
    },
    options: {
        'display': 'inline-block',
        'vertical-align': 'middle',
        'margin-right': '30px',

        'input': {
            'width': '400px',
            'border': 'none',
            'outline': 'none',
            'padding': '6px 12px',
            'font-family': 'Helvetica Neue, Helvetica, Arial, sans-serif',

            '&:focus': {
                'box-shadow': 'none'
            }
        }
    },
    node: {
        flex: '1'
    },
    embeds: {
        width: '140px',
        display: 'inline-block',
        verticalAlign: 'middle',
        marginLeft: '10px'
    }
}

let elements = {}

export function init() {
    let trustMetricInputElement = document.createElement('input')
    trustMetricInputElement.setAttribute('placeholder', 'Trust metric URL')
    elements.trustMetricInput = trustMetricInputElement

    let optionsElement = document.createElement('div')
    optionsElement.style = j2c.inline(styles.options)
    optionsElement.appendChild(trustMetricInputElement)

    let nodeElement = document.createElement('div')
    nodeElement.style = j2c.inline(styles.node)
    elements.node = nodeElement

    let scoreElement = document.createElement('div')
    scoreElement.style = j2c.inline(styles.score)
    scoreElement.style['background-color'] = '#33bae7'
    scoreElement.innerHTML = '?'
    elements.score = scoreElement

    let wrapElement = document.createElement('div')
    wrapElement.style = j2c.inline(styles.wrap)
    wrapElement.appendChild(nodeElement)
    //wrapElement.appendChild(optionsElement)
    wrapElement.appendChild(scoreElement)

    let barElement = document.createElement('div')
    barElement.id = 'liquio-bar'
    barElement.style = j2c.inline(styles.main)
    barElement.appendChild(wrapElement)

    document.getElementsByTagName('body')[0].appendChild(barElement)

    let previousSelection = null
    let currentSelection = null
    document.addEventListener('keyup', function () {
        previousSelection = currentSelection
        currentSelection = window.getSelection().toString() || null
    })
    document.addEventListener('mouseup', function () {
        previousSelection = currentSelection
        currentSelection = window.getSelection().toString() || null
    })

    scoreElement.addEventListener('click', function (e) {
        let time = 0
        var anchor = ''
        if (time > 0) {
            let minutes = Math.floor(time / 60)
            let seconds = Math.floor(time - minutes * 60)
            anchor = '/' + minutes + ':' + seconds
        } else {
            if (previousSelection && previousSelection.length < 200) {
                anchor = '/' + utils.slug(previousSelection)
            }
        }

        let url = LIQUIO_URL + '/v/' + encodeURIComponent(key + anchor) + '/Reliable-Unreliable'
        var win = window.open(url, '_blank')
        win.focus()
    })

    trustMetricInputElement.addEventListener('keyup', function (e) {
        if (e.keyCode === 13) {
            storage.onConnect().then(function () {
                storage.set('', trustMetricInputElement.value)
            })
        }
    })
}

export function updateState(state) {
    if (state.trustMetricURL) {
        elements.trustMetricInput.value = state.trustMetricURL
    }

    if (state.node) {
        let reliabilityResults = state.node.results.by_units['reliable']
        if (reliabilityResults) {
            let rating = reliabilityResults.average

            let red = 'ff2b2b',
                yellow = 'f9e26e',
                green = '43e643'
            let color = rating < 0.5 ? utils.colorOnGradient(yellow, red, rating * 2) : utils.colorOnGradient(green, yellow, (rating - 0.5) * 2)
    
            elements.score.style.backgroundColor = color
            elements.score.innerHTML = (Math.round(rating * 100) / 10).toFixed(1)
        }
    }

    if (state.currentNode) {
        let byUnits = state.currentNode.results.by_units
        let unitResults = byUnits[Object.keys(byUnits)[0]]
        elements.node.innerHTML = state.currentNode.title + '<div style="' + j2c.inline(styles.embeds) + '">' + unitResults.embeds.value + '</div>'
    } else {
        elements.node.innerHTML = ''
    }
}