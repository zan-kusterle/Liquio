/* global IS_EXTENSION, LIQUIO_URL, chrome */

declare var LIQUIO_URL: string
declare var IS_EXTENSION: boolean

import { makeRequest } from '../sign/api'
import transformContent from '../../utils/transform_content'
import * as utils from './utils'
import state from '../sign/state';

let lastSelectionSetTime = 0
let definitionsByText = {}
let canUpdateHighlights = true
let transformedTexts = []

let transformDefinitionToVote = (definition) => {
	let data: any = {
		title: definition.title,
		unit: definition.unit
	}
	if (definition.anchor)
		data.anchor = definition.anchor
	return data
}

let sign = (data) => {
	let event = new CustomEvent('liquio-sign', { detail: [data] })
	window.dispatchEvent(event)
	return new Promise((resolve) => {
		window.addEventListener('liquio-sign-done', () => {
			resolve()
		})
	})
}

export default {
	initialize ({ commit, dispatch, state }) {
		window.addEventListener('keydown', (e) => {
			if (state.definition && state.dialogVisible) {
				e.stopPropagation()
			}
		}, true)

		function updateHighlights () {
			for (let text in definitionsByText) {
				if (!transformedTexts.includes(text)) {
					let definition = definitionsByText[text]
					let span = transformContent.transformText(text)

					if (span) {
						transformedTexts.push(text)
						span.style.backgroundColor = 'rgba(255, 255, 0, 0.7)'
						span.style.cursor = 'pointer'
	
						span.addEventListener('mouseover', () => {
							state.activeDefinition = definition
						})
						span.addEventListener('mouseout', () => {
							state.activeDefinition = null
						})
	
						span.addEventListener('click', () => {
							state.activeDefinition = definition
	
							dispatch('setDefinition', definition)
							commit('SET_DIALOG_VISIBLE', true)
						})
					}
				}
			}
		}

		setInterval(() => {
			if (canUpdateHighlights) {
				canUpdateHighlights = false		
				updateHighlights()
			}
		}, 1000)

		updateHighlights()

		if (IS_EXTENSION) {
			chrome.runtime.onMessage.addListener(function(message) {
				if (message.name === 'update') {
					onUrlChange(document.location.href)
					setTimeout(() => {
						onUrlChange(document.location.href)
					}, 1000)
				} else if (message.name === 'open') {
					dispatch('setDefinition', { title: state.currentPage, unit: 'reliable' })
					commit('SET_DIALOG_VISIBLE', true)
				}
				return false
			})
		}
		
		function onUrlChange (url) {
			let liquioMeta = document.head.querySelector('[name=liquio]')
			state.isUnavailable = !IS_EXTENSION && document.getElementById('liquio-bar-extension') || liquioMeta && liquioMeta.textContent === 'disable'

			let safeUrl = decodeURIComponent(url).replace(/\/$/, '')

			commit('SET_CURRENT_PAGE', safeUrl)
			dispatch('loadNode', { title: safeUrl, anchor: null, unit: 'Unreliable-Reliable', comments: [] })
		}
		
		let MutationObserver = (window as any).MutationObserver || (window as any).WebKitMutationObserver
		let eventListenerSupported = window.addEventListener
		
		if (MutationObserver) {
			let obs = new MutationObserver(() => {
				canUpdateHighlights = true
			})
			obs.observe(document, {
				childList: true,
				subtree: true
			})
		} else if (eventListenerSupported) {
			document.addEventListener('DOMNodeInserted', () => {
				canUpdateHighlights = true
			}, false)
		}
		
		window.addEventListener('hashchange', () => onUrlChange(document.location.href), false)
		onUrlChange(document.location.href)
		
		document.addEventListener('keyup', e => {
			if (e.keyCode === 8) {
				dispatch('navigateHistory', -1)
			}
		})

		function getSelection () {
            let selection = window.getSelection()
            if (selection.anchorNode) {
                if (selection.isCollapsed)
					return null

				let el = document.getElementById(IS_EXTENSION ? 'liquio-bar-extension' : 'liquio-bar')
				if (el && el.contains(selection.anchorNode))
					return null

                return selection.toString()
            } else {
                return null
            }
        }

		function onClick (event) {
            let el = document.getElementById(IS_EXTENSION ? 'liquio-bar-extension' : 'liquio-bar')
            let isOutside = el && !(el === event.target || el.contains(event.target))
            if (isOutside && Date.now() > lastSelectionSetTime + 50) {
                setTimeout(() => {
                    if (!getSelection()) {
						commit('SET_CURRENT_SELECTION', null)
                    }
                }, 50)
            }
		}
		
		function updateSelection (event) {
            let selection = getSelection()

            if (selection) {
                if (selection !== state.currentSelection) {
					commit('SET_CURRENT_SELECTION', selection)
                    lastSelectionSetTime = Date.now()
                }
			}

			if (event) {
                setTimeout(updateSelection, 100)
            }
        }

		document.addEventListener('click', onClick)
        document.addEventListener('keyup', updateSelection)
        document.addEventListener('mouseup', updateSelection)
		
		const VIDEO_NODE_SHOW_DURATION = 10
		let isCurrentVideoNode = false
		
		let intervalId = setInterval(() => {
			let videos = document.getElementsByTagName('video')
			if (videos.length === 1) {
				clearInterval(intervalId)
		
				let video = videos[0]
		
				setInterval(() => {
					let closestTime = null
					let closestDefinition = null
					for (let text in definitionsByText) {
						let parts = text.split(':')
						if (parts.length === 2) {
							let minutes = parseInt(parts[0])
							let seconds = parseInt(parts[1])
							let time = isNaN(minutes) || isNaN(seconds) ? null : minutes * 60 + seconds
		
							let delta = video.currentTime - time
							if (delta >= 0 && delta < VIDEO_NODE_SHOW_DURATION && (closestTime === null || delta < closestTime)) {
								closestTime = delta
								closestDefinition = definitionsByText[text]
							}
						}
					}
		
					state.currentVideoTime = video.currentTime
					if (closestDefinition) {
						state.activeDefinition = closestDefinition
						isCurrentVideoNode = true
					} else if (isCurrentVideoNode) {
						state.activeDefinition = null
					}
				}, 100)
			}
		}, 100)		
	},
	loadNode ({ state, commit, getters }, definition) {
		let transformReference = (reference) => {
			return {
				definition: reference.definition,
				referenceResults: reference.reference_results,
			}
		}

		let flattenNode = (node) => {
			let nodes: NodeWithData[] = []
			let existingNode = state.nodes.find(n => utils.compareDefinition(n.definition, node.definition))

			if (node.results) {
				nodes.push({
					definition: node.definition,
					data: {
						results: {
							mean: node.results.mean,
							median: node.results.median,
							votingPower: node.results.voting_power,
							contributions: node.results.contributions.map(contribution => {
								return {
									username: contribution.username,
									votingPower: contribution.voting_power,
									choice: contribution.choice,
									atDate: contribution.at_date,
								}
							})
						},
						comments: node.comments,
						references: node.references !== null ? node.references.map(transformReference) : existingNode ? existingNode.data.references : [],
						inverseReferences: node.inverse_references !== null ? node.inverse_references.map(transformReference): existingNode ? existingNode.data.inverseReferences: []
					}
				})
			}

			if (node.references)
				for (let reference of node.references) {
					for (let flatReferenceNode of flattenNode(reference)) {
						if (!nodes.find(n => utils.compareDefinition(n.definition, flatReferenceNode.definition))) {
							nodes.push(flatReferenceNode)
						}
					}
				}

			if (node.inverse_references)
				for (let inverseReference of node.inverse_references) {
					for (let flatInverseReferenceNode of flattenNode(inverseReference)) {
						if (!nodes.find(n => utils.compareDefinition(n.definition, flatInverseReferenceNode.definition))) {
							nodes.push(flatInverseReferenceNode)
						}
					}
				}

			return nodes
		}

		return new Promise((resolve) => {
			makeRequest('GET', LIQUIO_URL + '/api/nodes', {
				title: definition.title,
				depth: 2
			}).then(nodes => {
				for (let node of nodes) {
					for (let flatNode of flattenNode(node)) {
						commit('SET_NODE', flatNode)

						if (IS_EXTENSION && utils.compareDefinition(getters.currentPageDefinition, flatNode.definition)) {
							chrome.runtime.sendMessage({ name: 'score', score: flatNode.data.results.mean })
						}

						if (flatNode.definition.anchor && flatNode.data.references.length > 0 && utils.compareDefinition(getters.currentPageDefinition, { ...flatNode.definition, anchor: null })) {
							definitionsByText[flatNode.definition.anchor] = flatNode.data.references[0].definition
							canUpdateHighlights = true
						}
					}
				}

				if (!nodes.find(n => utils.compareDefinition(n.definition, definition))) {
					commit('SET_NODE', {
						definition: definition,
						data: {
							results: {
								mean: null,
								median: null,
								votingPower: 0,
								contributions: []
							},
							references: [],
							inverseReferences: [],
							comments: [],
						},
					})
				}

				resolve(nodes)
			}).catch(() => {})
		})
	},
	openDialog ({ commit }) {
		commit('SET_DIALOG_VISIBLE', true)
	},
	clearCurrentSelection ({ commit }) {
		setTimeout(() => {
			commit('SET_CURRENT_SELECTION', null)
		}, 50)
	},
	setDefinition({ commit, dispatch }, payload) {
		let definition = {
			title: payload.title,
			unit: payload.unit,
			anchor: payload.anchor || null,
			comments: payload.comments || [],
		}

		if (!state.definition || !utils.compareDefinition(definition, state.definition)) {
			commit('SET_DEFINITION', definition)
			commit('ADD_TO_HISTORY')
			dispatch('loadNode', definition)
		}
	},
	navigateHistory ({ state, commit }, delta) {
		commit('GO_TO_HISTORY_INDEX', state.historyIndex + delta)
	},
	search (_, query) {
		return makeRequest('GET', LIQUIO_URL + '/api/search/' + encodeURIComponent(query), {})
	},
	setVote ({ state, dispatch }, payload) {
		let definition = payload.definition || state.definition

		sign({
			name: 'vote',
			key: ['title', 'unit'],
			...transformDefinitionToVote(definition),
			choice: payload.choice
		}).then(() => {
			dispatch('loadNode', state.definition)
		})
	},
	setReferenceVote ({ state, dispatch }, payload) {
		let payloadData = transformDefinitionToVote(payload.definition)
		let referenceData = {}
		Object.keys(payloadData).forEach(key => referenceData['reference_' + key] = payloadData[key])

		sign({
			name: 'reference_vote',
			key: ['title', 'reference_title'],
			...transformDefinitionToVote(state.definition),
			...referenceData,
			relevance: payload.relevance
		}).then(() => {
			dispatch('loadNode', state.definition)
		})
	},
	setCommentVote ({ state, dispatch }, payload) {
		sign({
			name: 'vote',
			key: ['title', 'unit', 'comments'],
			...transformDefinitionToVote(state.definition),
			comments: [payload.text],
			choice: payload.score
		}).then(() => {
			dispatch('loadNode', state.definition)
		})
	},
}
