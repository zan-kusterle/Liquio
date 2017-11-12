export function prepareContainer(container, classes) {
    let buttonElement = document.createElement('a')
    buttonElement.className = 'liquio-button ' + classes.button
    buttonElement.innerHTML = '<img src="' + LIQUIO_URL + '/images/icon.svg" width="24" height="24"></img>'

    let noteElement = document.createElement('div')
    noteElement.className = 'liquio-note ' + classes.note

    container.parentNode.insertBefore(buttonElement, container.nextSibling)
    container.parentNode.insertBefore(noteElement, container.nextSibling)

    buttonElement.addEventListener('click', (e) => {
        let isShown = noteElement.style.display === 'block'

        let nodes = document.getElementsByClassName('liquio-note')
        for (let node of nodes)
            node.style.display = 'none'

        if (!isShown) {
            let buttonPosition = buttonElement.getBoundingClientRect()

            noteElement.style.top = (buttonPosition.top - 15) + 'px'
            noteElement.style.left = (buttonPosition.left + 35) + 'px'
            noteElement.style.display = 'block'

            e.preventDefault()
            e.stopPropagation()
        }
    })

    noteElement.addEventListener('click', (e) => {
        if (!e.target || e.target.tagName !== 'A')
            e.preventDefault()
        e.stopPropagation()
    })
}

export function addToContainer(container, node) {
    let note = container.parentNode.getElementsByClassName('liquio-note')[0]

    let units = node.results ? Object.values(node.results.by_units) : []
    let bestUnit = _.maxBy(units, (u) => u.turnout_ratio)

    let anchorElement = document.createElement('a')
    anchorElement.setAttribute('href', LIQUIO_URL + '/' + encodeURIComponent(node.path.join('/')))
    anchorElement.setAttribute('target', '_blank')
    anchorElement.innerText = node.path.join('/').replace(/-/g, ' ')

    let titleElement = document.createElement('div')
    titleElement.className = 'title'
    titleElement.appendChild(anchorElement)

    let nodeElement = document.createElement('div')
    nodeElement.className = 'node'
    nodeElement.innerText

    if (bestUnit && bestUnit.turnout_ratio > 0) {
        let valueElement = document.createElement('value')
        valueElement.className = 'value'
        valueElement.innerHTML = bestUnit.embeds.value
        nodeElement.appendChild(valueElement)
    }

    nodeElement.appendChild(titleElement)

    note.appendChild(nodeElement)
}