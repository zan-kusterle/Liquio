import Vue from 'vue'
import { compareDefinition } from './utils'

export default {
	SET_NODE (state, node) {
		let index = state.nodes.findIndex(n => compareDefinition(n.definition, node.definition))
		if (index >= 0) {
			state.nodes.splice(index, 1)
		}
		state.nodes.push(node)
	},
	SET_DEFINITION (state, definition) {
		state.definition = definition
	},
	SET_CURRENT_PAGE (state, url) {
		state.currentPage = url
	},
	ADD_TO_HISTORY (state) {
		state.history.splice(state.historyIndex + 1, state.history.length - state.historyIndex)
		state.history.push(state.definition)
		state.historyIndex = state.history.length - 1
	},
	GO_TO_HISTORY_INDEX (state, index) {
		let boundedIndex = Math.max(0, Math.min(state.history.length - 1, index))
		state.definition = state.history[boundedIndex]
		state.historyIndex = boundedIndex
	},
	SET_DIALOG_VISIBLE (state, isVisible) {
		state.dialogVisible = isVisible
	},
	SET_CURRENT_SELECTION (state, text) {
		state.currentSelection = text
	},
}
