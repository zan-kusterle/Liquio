import annotate from './annotate/index.js'
import sign from './sign/index.js'

export default {
	modules: {
		annotate,
		sign
	},
	state: {
		messagesToSign: []
	},
	getters: {
		colorOnSpectrum() {
			let colorOnGradient = (colorA, colorB, ratio) => {
				let hex = (x) => {
					x = x.toString(16)
					return (x.length == 1) ? '0' + x : x
				}

				let r = Math.ceil(parseInt(colorB.substring(0, 2), 16) * ratio + parseInt(colorA.substring(0, 2), 16) * (1 - ratio))
				let g = Math.ceil(parseInt(colorB.substring(2, 4), 16) * ratio + parseInt(colorA.substring(2, 4), 16) * (1 - ratio))
				let b = Math.ceil(parseInt(colorB.substring(4, 6), 16) * ratio + parseInt(colorA.substring(4, 6), 16) * (1 - ratio))

				return hex(r) + hex(g) + hex(b)
			}

			return (ratio) => {
				let neutral = '33bae7',
					red = 'ff2b2b',
					yellow = 'f9e26e',
					green = '43e643'

				if (!ratio)
					return neutral
				return ratio < 0.5 ? colorOnGradient(red, yellow, ratio * 2) : colorOnGradient(yellow, green, (ratio - 0.5) * 2)
			}
		}
	},
	actions: {
		initialize ({ dispatch }) {
			dispatch('annotate/initialize')
			dispatch('sign/initialize')
		}
	},
	mutations: {
		ADD_MESSAGE_TO_SIGN (state, message) {
			state.messagesToSign.push(message)
		},
		CLEAR_MESSAGES_TO_SIGN (state) {
			state.messagesToSign = []
		}
	}
}
