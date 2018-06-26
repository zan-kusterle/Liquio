import slug from './slug'

export default {
	resetTransforms () {
		let elements = document.getElementsByClassName('liquio-highlight')
		while (elements.length > 0) {
			for (let element of elements) {
				let parent = element.parentNode
	
				while (element.firstChild)
					parent.insertBefore(element.firstChild, element)
	
				parent.removeChild(element)
				parent.normalize()
			}

			elements = document.getElementsByClassName('liquio-highlight')
		}
	},
	transformText (text) {
		let getDeepestNodeWithText = (node, text) => {
			if (node.innerText && node.innerText.length > 0) {
				let slugData = slug(node.innerText)
				if (slugData.value.indexOf(text) >= 0) {
					for (let child of node.childNodes) {
						let childNode = getDeepestNodeWithText(child, text)
						if (childNode) {
							return childNode
						}
					}
					return node
				}
			}
			return null
		}

		let getDeepOffset = (node, offset) => {
			if (node.nodeType === Node.TEXT_NODE) {
				let nodeText = node.textContent
				if (nodeText.length >= offset) {
					return { node: node, offset: offset }
				}
			} else {
				let currentOffset = 0
				for (let child of node.childNodes) {
					let childText = child.innerText || child.textContent
					if (currentOffset + childText.length >= offset) {
						return getDeepOffset(child, offset - currentOffset)
					}
					currentOffset += childText.length
				}
			}
		}

		let getTextRangeInNode = (node, text) => {
			let nodeText = node.innerText || node.textContent
			if (nodeText && nodeText.length > 0) {
				let slugData = slug(nodeText)
				if (slugData.value.length > 0) {
					let indexOf = slugData.value.indexOf(text)
					if(indexOf >= 0) {
						let start = getDeepOffset(node, slugData.mappings[indexOf])
						let end = getDeepOffset(node, slugData.mappings[indexOf + text.length - 1] + 1)

						let range = document.createRange()
						range.setStart(start.node, start.offset)
						range.setEnd(end.node, end.offset)
						return range
					}
				}
			}

			let firstNode = null
			let firstOffset = null
			let currentIndex = 0
			for (let child of node.childNodes) {
				let childText = child.innerText || child.textContent
				if (childText && childText.length > 0) {
					let slugData = slug(childText)
					if (slugData.value.length > 0) {
						if (firstNode) {
							let remainingText = text.substring(currentIndex)
							let startsWithDash = remainingText.charAt(0) === '-'
							let textIndex = remainingText.indexOf(slugData.value.substring(0, startsWithDash ? remainingText.length - 1 : remainingText.length))

							if (textIndex === 0 || textIndex === 1 && startsWithDash) {
								currentIndex += slugData.value.length + textIndex
								if (currentIndex >= text.length) {
									let start = getDeepOffset(firstNode, firstOffset)
									let end = getDeepOffset(child, slugData.mappings[remainingText.length - textIndex - 1] + 1)

									let range = document.createRange()
									range.setStart(start.node, start.offset)
									range.setEnd(end.node, end.offset)
									return range
								}
							} else {
								currentIndex = 0
								firstNode = null
								firstOffset = null
							}
						} else {
							let intersectionLength = null
							for (var i = text.length; i > 0; i--) {
								if (slugData.value.endsWith(text.substring(0, i))) {
									intersectionLength = i
									break
								}
							}
							if (intersectionLength > 0) {
								firstNode = child
								firstOffset = slugData.mappings[slugData.value.length - intersectionLength]
								currentIndex += intersectionLength
							}
						}
					}
				}
			}
			return null
		}

		let node = getDeepestNodeWithText(document.documentElement, text)
		if (node) {
			let range = getTextRangeInNode(node, text)
			if (range) {
				let span = document.createElement('span')
				span.className = 'liquio-highlight'
				span.appendChild(range.extractContents())
				range.insertNode(span)
				return span
			}
		}
		return null
	}
}