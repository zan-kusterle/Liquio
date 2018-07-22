import { allUnits } from './constants'
import * as utils from './utils'
import slug from '../../utils/slug'

export default {
	allUnits () {
		return allUnits
	},
	unitsByType () {
		let byType = {}
		allUnits.forEach(unit => {
			if (!byType[unit.type])
				byType[unit.type] = []
			byType[unit.type].push(unit)
		})

		let types = [
			{ key: 'spectrum', label: 'Spectrum' },
			{ key: 'quantity', label: 'Quantity' }
		]

		return types.map(type => {
			return {
				label: type.label,
				items: byType[type.key]
			}
		})
	},
	isSelectionAnchor (state): boolean {
		return state.currentSelection && state.currentSelection.length >= 10
	},
	currentAnchor (state, getters) {
		if (getters.isSelectionAnchor) {
			return slug(state.currentSelection).value
		} else if (state.currentVideoTime) {
            let minutes = Math.floor(this.currentVideoTime / 60)
            let seconds = Math.floor(this.currentVideoTime - minutes * 60)
            return `${('00' + minutes).slice(-2)}:${('00' + seconds).slice(-2)}`
		}
		return null
	},
	currentPageDefinition (state): NodeDefinition {
		return {
			title: state.currentPage,
			anchor: null,
			unit: 'Unreliable-Reliable',
			comments: []
		}
	},
	currentNode (state): NodeWithData {
		let stateNode = state.nodes.find(n => utils.compareDefinition(n.definition, state.definition, ['comments']))

		let data = null
		if (stateNode && stateNode.data) {
			let mapReferences = (references) => {
				return references.map(({ definition, referenceResults}) => {
					let stateNode = state.nodes.find(n => utils.compareDefinition(n.definition, definition))
					if (!stateNode)
						return null
					return {
						...stateNode,
						referenceResults,
					}
				}).filter(x => x)
			}
			data = {
				results: stateNode.data.results,
				references: mapReferences(stateNode.data.references),
				inverseReferences: mapReferences(stateNode.data.inverseReferences),
				comments: stateNode.data.comments
			}
		}

		return {
			definition: {
				...state.definition,
				isSpectrum: state.definition.unit.indexOf('-') >= 0,
			},
			data: data
		}
	},
	activeNode (state): NodeWithData {
		if (!state.activeDefinition)
			return null

		let stateNode = state.nodes.find(n => utils.compareDefinition(n.definition, state.activeDefinition))

		return {
			definition: state.activeDefinition,
			data: stateNode ? stateNode.data : null
		}
	},
	availableHistory (state): object {
		return {
			back: state.historyIndex > 0,
			forward: state.historyIndex < state.history.length - 1,
		}
	},
	recentDefinitions (state) {
		let uniqueDefinitions = []
		for (let i = state.history.length - 1; i >= 0; i--) {
			let definition = state.history[i]
			if (!(state.definition && utils.compareDefinition(state.definition, definition)) && !uniqueDefinitions.find(d => utils.compareDefinition(d, definition))) {
				uniqueDefinitions.push(definition)
			}
		}
		return uniqueDefinitions
	},
}
