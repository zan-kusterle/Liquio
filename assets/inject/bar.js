import * as utils from 'inject/utils'

const defaultTrustMetricURL = process.env.NODE_ENV === 'production' ? 'https://trust-metric.liqu.io' : 'http://127.0.0.1:8080/dev_trust_metric.html'

export function init(key, trustMetricURL, reliability_results, classes) {
    let rating = reliability_results ? reliability_results.average : null

    let red = 'ff2b2b',
        yellow = 'f9e26e',
        green = '43e643'
    let color = '33bae7'
    if (rating)
        color = rating < 0.5 ? utils.colorOnGradient(yellow, red, rating * 2) : utils.colorOnGradient(green, yellow, (rating - 0.5) * 2)

    let trustMetricInputElement = document.createElement('input')
    trustMetricInputElement.setAttribute('placeholder', 'Trust metric URL')
    trustMetricInputElement.value = trustMetricURL || defaultTrustMetricURL

    let optionsElement = document.createElement('div')
    optionsElement.className = 'options'
    optionsElement.appendChild(trustMetricInputElement)

    let viewElement = document.createElement('div')
    viewElement.className = 'view'
    viewElement.innerText = 'View on Liquio'

    let scoreElement = document.createElement('div')
    scoreElement.className = 'score'
    scoreElement.style['background-color'] = '#' + color
    scoreElement.innerHTML = rating ? (Math.round(rating * 100) / 10).toFixed(1) : '?'

    let togglableElement = document.createElement('div')
    togglableElement.className = 'togglable'
    togglableElement.appendChild(optionsElement)
    togglableElement.appendChild(viewElement)

    let barElement = document.createElement('div')
    barElement.id = 'liquio-bar'
    barElement.className = classes.liquio
    barElement.appendChild(togglableElement)
    barElement.appendChild(scoreElement)

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
        let isShown = togglableElement.style.display !== 'none'
        togglableElement.style.display = isShown ? 'none' : 'inline-block'
    })

    viewElement.addEventListener('click', function (e) {
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