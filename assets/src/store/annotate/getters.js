import { allUnits } from './constants'

export default {
	allUnits () {
		return allUnits
	},
	nodeByTitle (state) {
		return (title) => {
			return state.nodesByKey[title] || { title: title, results: {}, references: [], inverse_references: [], mock: true }
		}
	},
	usernames (state) {
		return state.whitelist.username.split(',')
	},
	currentTitle (state) {
		return state.currentTitle || state.currentPage
	},
	canNavigateBack (state) {
		return state.historyIndex > 0
	},
}
