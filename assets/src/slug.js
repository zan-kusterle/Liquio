export default function (x) {
	let mappings = []
	let canAddMinus = false
	for (var i = 0; i < x.length; i++) {
		let c = x[i]
		if (/[a-zA-Z0-9:]/.test(c)) {
			mappings.push({
				char: c,
				index: i
			})
			canAddMinus = true
		} else if (/\s/.test(c) && canAddMinus) {
			mappings.push({
				char: '-',
				index: i
			})
			canAddMinus = false
		}
	}
	if (!canAddMinus && mappings.length > 0) {
		mappings = mappings.slice(0, mappings.length - 1)
	}

	let indexMap = {}
	for (var mappingIndex = 0; mappingIndex < mappings.length; mappingIndex++) {
		indexMap[mappingIndex] = mappings[mappingIndex].index
	}

	if (mappings.length === 0) {
		return null
	}
	return {
		value: mappings.map(m => m.char).join('').toLowerCase(),
		mappings: indexMap
	}
}
