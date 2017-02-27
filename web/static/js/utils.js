export function getKey(title, choice_type) {
	return encodeURIComponent((title + ' ' + choice_type).trim().replace(/ /g, '-'))
}

export function getCompositeKey(key, referenceKey) {
	return encodeURIComponent(key) + (referenceKey ? '/references/' + encodeURIComponent(referenceKey) : '')
}

export function normalizeKey(key) {
	return key.replace(/ /g, '-').replace(/_/g, '-').toLowerCase()
}

export function getMultiKey(nodes) {
	var keys = _.map(nodes, (node) => getKey(node.title, node.choice_type))
	return keys.join('_')
}

export function formatNumber(number) {
	return Math.round(number * 10) / 10
}

export function getColor(mean) {
	if(mean == null) return "#ddd"
	if(mean < 0.25)
		return "rgb(255, 164, 164)"
	else if(mean < 0.75)
		return "rgb(249, 226, 110)"
	else
		return "rgb(140, 232, 140)"
}