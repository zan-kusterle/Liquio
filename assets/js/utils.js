export function getKey(title, choice_type) {
	return encodeURIComponent((title + ' ' + choice_type).trim().replace(/ /g, '-'))
}

export function getCompositeKey(key, referenceKey) {
	return encodeURIComponent(key) + (referenceKey ? '/references/' + encodeURIComponent(referenceKey) : '')
}

export function normalizeKey(key) {
	try {
		key = decodeURIComponent(key)
	} catch (e) {

	}
	return encodeURIComponent(key.toLowerCase())
}

export function getMultiKey(keys) {
	return _.map(keys, (k) => encodeURIComponent(k)).join('___')
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