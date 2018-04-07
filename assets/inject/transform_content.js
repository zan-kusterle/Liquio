import slug from 'shared/slug'

export default {
    resetTransforms () {
        var elements = document.getElementsByClassName('liquio-highlight')
        for (let element of elements) {
            let parent = element.parentNode

            while (element.firstChild)
                parent.insertBefore(element.firstChild, element)

            parent.removeChild(element)
        }
    },
    transformNode (nodesByText, domNode, setActive) {
        let text = domNode.textContent.toLowerCase().replace(/[^\x00-\x7F]/g, '')
        let slugText = slug(text)

        let nodesToAdd = Object.keys(nodesByText).filter((k) => {
            return slugText.indexOf(k) >= 0
        }).map(k => {
            let slugStart = slugText.indexOf(k)
            let start = 0
            let end = 0
            for(var i = 0; i < slugStart + k.length; i++) {
                if (i === slugStart) {
                    start = end
                }
                let slugChar = slugText[i]
                while (end < text.length) {
                    let textChar = text[end].replace(' ', '-').toLowerCase()
                    end++
                    if (textChar === slugChar) {
                        break
                    }
                }
            }

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
                if (range.commonAncestorContainer.nodeType === Node.TEXT_NODE && range.commonAncestorContainer.parentNode.className !== 'liquio-highlight') {
                    let span = document.createElement('span')
                    range.surroundContents(span)
                    span.className = 'liquio-highlight'
                    span.style.backgroundColor = 'rgba(57, 164, 255, 0.25)'
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
                }
            })
        }
    }
}