import slug from './slug'

export default {
    resetTransforms () {
        var elements = document.getElementsByClassName('liquio-highlight')
        for (let element of elements) {
            let parent = element.parentNode

            while (element.firstChild)
                parent.insertBefore(element.firstChild, element)

            parent.removeChild(element)
            parent.normalize()
        }
    },
    transformNode (nodesByText, domNode, setActive) {
        let slugData = slug(domNode.textContent)
        if (slugData) {
            for (let k in nodesByText) {
                let index = slugData.value.indexOf(k)

                if (index >= 0) {
                    let start = slugData.mappings[index]
                    let end = slugData.mappings[index + k.length - 1]

                    let range = document.createRange()
                    range.setStart(domNode, start)
                    range.setEnd(domNode, end + 1)

                    let node = nodesByText[k][0]

                    let commonParent = range.commonAncestorContainer.parentNode
                    if (range.commonAncestorContainer.nodeType === Node.TEXT_NODE && commonParent && commonParent.className !== 'liquio-highlight') {
                        let span = document.createElement('span')
                        range.surroundContents(span)
                        span.className = 'liquio-highlight'
                        span.style.backgroundColor = 'rgba(255, 255, 0, 0.5)'
                        span.style.cursor = 'pointer'
                        span.addEventListener('mouseover', (e) => {
                            setActive(node, false)
                        })
                        span.addEventListener('mouseout', (e) => {
                            setActive(null, false)
                        })
                        span.addEventListener('click', (e) => {
                            setActive(node, true)
                        })

                        return true
                    }
                }
            }
        }
    }
}