import { slug } from 'shared/votes'

export function onAnchorInsert(node) {
}

export default function (nodesByText, domNode, setActive) {
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
            span.style.cursor = 'pointer'
            let isClicked = true
            span.addEventListener('mouseover', (e) => {
                isClicked = false
                setActive(node)
            })
            span.addEventListener('mouseout', (e) => {
                if (!isClicked) {
                    setActive(null)
                }
            })
            span.addEventListener('click', (e) => {
                isClicked = true
                setActive(node)
            })
        })
    }
}