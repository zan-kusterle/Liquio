<template>
	<div id="app">
		<div class="header">
			<transition name="heading">
				<h1 :key="headingText" class="heading-text">{{ headingText }}</h1>
			</transition>
		</div>

		<div ref="cursor" v-if="isDemoOpen" :style="{ left: `${currentCursorX}px`, top: `${currentCursorY}px`, transition: `all ${transitionTime}ms ${transitionEasing || 'ease'}` }" class="cursor">
			<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 720.711 1079.449" width="15" height="20">
				<path d="M0 0v1041.422L232.422 809l111.904 270.45 169.764-84.884-114.094-273.855h320.715z" />
			</svg>
		</div>

		<div class="demo-wrap">
			<button :style="isDemoOpen ? { opacity: 0, pointerEvents: 'none' } : { opacity: 1 }" class="button" @click="startDemo">Watch demo</button>
			<button :style="!canReplayDemo ? { opacity: 0, pointerEvents: 'none' } : { opacity: 1 }" class="button" @click="startDemo">Watch again</button>

			<div class="content-wrap" :style="isDemoOpen ? { marginTop: 0, opacity: isTextDim ? 0.3 : 1 } : { height: '0px' }">
				<div class="content" :style="isHighlighted ? { color: '#888' } : {}">
					<h3 class="title">Flat Earth</h3>

					<p>
						The flat Earth model is an archaic conception of Earth's shape as a plane or disk. Many ancient cultures subscribed to a flat Earth cosmography. 
					</p>
					<p>
						The idea of a spherical Earth appeared with Pythagoras, although most pre-Socratics retained the flat Earth model.
						Aristotle provided
						<span id="text" :style="isHighlighted ? { backgroundColor: 'yellow', color: '#333' } : {}">evidence for the spherical shape of the Earth on empirical grounds</span>
						by around 330 BC. Knowledge of the spherical Earth gradually began to spread from then on.
						In the modern era, pseudoscientific flat Earth theories have been espoused by modern flat Earth societies and,
						increasingly, by unaffiliated individuals using social media.
					</p>
				</div>
			</div>
		</div>

		<div class="promo">
			<div class="get-extension">
				<a href="https://chrome.google.com/webstore/detail/liquio/gpnnencpnfcpdpdfbaefalokcilkkege" target="_blank">
					<img src="./assets/chrome-web-store-badge.png" />
				</a>
			</div>

			<div class="view-github">
				<a class="view-github" href="https://github.com/zan-kusterle/Liquio" target="_blank">
					<img src="./assets/github-logo.png" />
					View source on GitHub
				</a>
			</div>

			<Features />
		</div>

		<div v-if="isHighlightActive" class="vote">
			<div class="result">
				<span class="result-percentage">98%</span>
				<span class="result-unit">fact</span>
			</div>
			<div class="result-title">
				{{ nodeTitle }}
			</div>
		</div>
		<div v-else class="vote">
			<input v-if="isInputShown" type="text" placeholder="Annotation title" id="input" />
			<div v-if="isButtonShown" id="button">Vote on selection</div>
		</div>

		<div class="video-wrap">
			<video id="video" src="./assets/reference-vote.mp4" muted="true" />
		</div>
	</div>
</template>

<script>
import Features from './Features.vue'

const tagline = 'Vote on anything, anywhere on the web.'

export default {
	name: 'app',
	components: { Features },
	data () {
		return {
			headingText: tagline,

			isDemoOpen: false,
			canReplayDemo: false,

			isTextDim: false,
			isButtonShown: false,
			isInputShown: false,
			isHighlighted: false,
			isHighlightActive: false,

			targetX: 0.5,
			targetY: 0.5,
			transitionTime: 1000,
			transitionEasing: null,
		}
	},
	created () {
		this.TIME_FACTOR = 1.5

		this.nodeTitle = 'Earth is not flat'

		window.addEventListener('scroll', this.onRecalculate)
		window.addEventListener('resize', this.onRecalculate)
	},
	beforeDestroy () {
		window.removeEventListener('scroll', this.onRecalculate)
		window.removeEventListener('resize', this.onRecalculate)
	},
	computed: {
		currentCursorX () {
			return this.targetX * document.documentElement.clientWidth
		},
		currentCursorY () {
			return this.targetY * document.documentElement.clientHeight
		},
	},
	methods: {
		onRecalculate () {
			if (this.recalculationFn) {
				return new Promise((resolve) => {
					this.recalculationFn(resolve)
				})
			}
		},
		setRecalculation (fn) {
			fn()
			this.recalculationFn = fn
			return new Promise((resolve) => {
				let cursorElement = this.$refs.cursor
				if (cursorElement) {
					(function x () {
						cursorElement.addEventListener('transitionend', () => {
							cursorElement.removeEventListener('transitionend', x)
							resolve()
						})
					})()
				}
			})
		},
		startDemo () {
			this.isDemoOpen = true
			this.canReplayDemo = false

			this.isTextDim = false
			this.isButtonShown = false
			this.isInputShown = false
			this.isHighlighted = false
			this.isHighlightActive = false

			setTimeout(() => {
				this.selectTextStep()
			}, this.TIME_FACTOR * 800)
		},
		selectTextStep () {
			let textElement = document.getElementById('text')

			this.headingText = 'Select any text on any webpage'
			this.setRecalculation(() => {
				let textBounds = this.getElementBounds(textElement)
				this.animateCursor(textBounds.x, textBounds.y)
			}).then(() => {
				let selectionTime = this.TIME_FACTOR * 1000

				this.setRecalculation(() => {
					let textBounds = this.getElementBounds(textElement)
					this.animateCursor(textBounds.x + textBounds.width, textBounds.y + textBounds.height, selectionTime, 'linear')
				}).then(() => {
					let index = 0
					let textLength = textElement.innerText.length
					this.repeat(index => {
						let range = document.createRange()
						range.setStart(textElement.childNodes[0], 0)
						range.setEnd(textElement.childNodes[0], index + 1)
						window.getSelection().removeAllRanges()
						window.getSelection().addRange(range)
					}, textLength, selectionTime).then(() => {
						this.isButtonShown = true
						
						this.$nextTick(() => {
							this.openReferenceStep()
						})
					})
				})
			})
		},
		openReferenceStep () {
			let buttonElement = document.getElementById('button')

			setTimeout(() => {
				this.isTextDim = true
			}, this.TIME_FACTOR * 400)

			this.setRecalculation((done) => {
				let buttonBounds = this.getElementBounds(buttonElement)
				this.animateCursor(buttonBounds.x + buttonBounds.width / 2, buttonBounds.y + buttonBounds.height / 2)
			}).then(() => {
				window.getSelection().removeAllRanges()
				this.isInputShown = true

				this.$nextTick(() => {
					this.headingText = 'Annotate it with fact checked data'

					let inputElement = document.getElementById('input')
					this.repeat(index => {
						inputElement.value = this.nodeTitle.substring(0, index + 1)
					}, this.nodeTitle.length, 1000).then(() => {
						this.setRecalculation(() => {
							let bounds = this.getElementBounds(buttonElement)
							this.animateCursor(bounds.x + bounds.width / 2, this.targetY)
						}).then(() => {
							this.isInputShown = false
							this.isButtonShown = false
							this.voteVideoStep()
						})
					})
				})
			})
		},
		voteVideoStep () {
			let videoElement = document.getElementById('video')
			videoElement.load()
			//videoElement.playbackRate = 1 / this.TIME_FACTOR
			let hasEnded = false
			videoElement.parentNode.style.opacity = 1;
			videoElement.play()
			videoElement.addEventListener('ended', () => {
				videoElement.parentNode.style.opacity = 0;
				hasEnded = true
				this.demoHighlightStep()
			})

			setTimeout(() => {
				if (!hasEnded) {
					this.setRecalculation(() => {
						let videoBounds = this.getElementBounds(videoElement)
						this.animateCursor(videoBounds.x + videoBounds.width / 2, videoBounds.y + videoBounds.height * 0.85)
					}).then(() => {
						setTimeout(() => {
							if (!hasEnded) {
								this.setRecalculation(() => {
									let videoBounds = this.getElementBounds(videoElement)
									this.animateCursor(videoBounds.x + videoBounds.width * 0.67, this.targetY, 200)
								}).then(() => {
									setTimeout(() => {
										if (!hasEnded) {
											this.setRecalculation(() => {
												let videoBounds = this.getElementBounds(videoElement)
												this.animateCursor(videoBounds.x + videoBounds.width * 0.48, videoBounds.y + videoBounds.height * 0.93)
											})
										}
									}, 200)
								})
							}
						}, 200)
					})
				}
			}, 500)
		},
		demoHighlightStep () {
			this.headingText = 'Other people will see the annotation'

			this.isHighlighted = true
			setTimeout(() => {
				this.isTextDim = false
			}, this.TIME_FACTOR * 100)

			let textElement = document.getElementById('text')

			this.setRecalculation(() => {
				let textBounds = this.getElementBounds(textElement)
				this.animateCursor(textBounds.x + textBounds.width / 2, textBounds.y + textBounds.height / 2)
			}).then(() => {
				this.isHighlightActive = true

				setTimeout(() => {
					this.headingText = tagline
					this.canReplayDemo = true
				}, this.TIME_FACTOR * 3000)
			})
		},
		getElementBounds (element) {
			let rect = element.getBoundingClientRect()
			return {
				x: rect.left / document.documentElement.clientWidth, y: (rect.top + document.documentElement.scrollTop) / document.documentElement.clientHeight,
				width: rect.width / document.documentElement.clientWidth, height: rect.height / document.documentElement.clientHeight
			}
		},
		repeat (fn, ticks, duration) {
			return new Promise(resolve => {
				let index = 0
				let intervalId = setInterval(() => {
					if (index >= ticks) {
						clearInterval(intervalId)
						resolve()
					} else {
						fn(index)
					}
					index++
				}, duration / ticks)
			})
		},
		animateCursor (x, y, duration, easing) {
			return new Promise(resolve => {
				if (!duration) {
					let dx = this.targetX - x
					let dy = this.targetY - y
					let distance = Math.sqrt(dx * dx + dy * dy)
					duration = this.TIME_FACTOR * 1000 * Math.pow(distance, 0.2)
				}
	
				this.transitionTime = duration
				this.transitionEasing = easing
				this.targetX = x
				this.targetY = y
			})
		}
	}
}
</script>

<style>
body {
	margin: 0;
	background-color: #fff;
	cursor: default;
	line-height: 1.4;
	font-family: "Helvetica Neue",Helvetica,"PingFang SC","Hiragino Sans GB","Microsoft YaHei","微软雅黑",Arial,sans-serif;
	color: #333;
}

.heading-leave-active     { animation: heading-leave-animation 500ms ease; }
.heading-enter-active     { animation: heading-enter-animation 500ms ease; }

@keyframes heading-leave-animation {
    0% {
        transform: translate3d(0, 0, 0);
        opacity: 1;
    }
    100% {
        transform: translate3d(400px, 0, 0);
        opacity: 0;
    }
}

@keyframes heading-enter-animation {
    0% {
        transform: translate3d(-400px, 0, 0);
        opacity: 0;
    }

    100% {
        transform: translate3d(0, 0, 0);
        opacity: 1;
    }
}


.promo {
	text-align: center;
}

.header {
	text-align: center;
	margin-top: 100px;
	position: relative;
	height: 120px;
	overflow: hidden;
}

.heading-text {
	font-weight: normal;
	margin: 0;
	font-size: 48px;
	color: #444;
	position: absolute;
	width: calc(100% - 40px);
	padding: 0px 20px;
}

.get-extension {
	margin: 0 auto;
	display: inline-block;
	background-color: #f8f8f8;
	box-shadow: 1px 2px 5px 0 rgba(0, 0, 0, 0.25);
}

.get-extension > a > img {
	width: 260px;
	display: block;
	margin: 0 auto;
}

.get-extension > a {
	text-decoration: none;
}

.demo-wrap {
	position: relative;
	height: 310px;
	display: flex;
	justify-content: center;
	margin: 40px 0;
}

.button {
	outline: none;
	border: none;
	-webkit-border-radius: 0;
	-moz-border-radius: 0;
	border-radius: 0px;
	color: #ffffff;
	font-size: 28px;
	background: #409eff;
	padding: 25px 80px;
	text-decoration: none;
	cursor: pointer;
	margin: 0 auto;
	position: absolute;
	top: calc(50% - 28px);
	transition: opacity 200ms ease-out;
	box-shadow: 1px 2px 5px 0 rgba(0, 0, 0, 0.25);
	margin-top: -100px;
}

.button:hover {
	background: #27baea;
	text-decoration: none;
}

.view-github {
	width: fit-content;
	margin: 0 auto;
}

.view-github > a {
	display: flex;
	align-items: center;
	justify-content: center;
	text-decoration: none;
	color: #333;
	margin-top: 10px;
	margin-bottom: 10px;
	font-size: 14px;
}
.view-github > a:visited {
	color: #333;
}
.view-github > a:hover {
	opacity: 0.8;
}

.view-github > a > img {
	margin-right: 10px;
	width: 25px;
}

.cursor {
	position: absolute;
	z-index: 10;
}

.title {
	font-size: 28px;
	font-weight: normal;
	margin: 0;
	margin-bottom: 30px;
}

.content-wrap {
	background-color: #eee;
	overflow: hidden;
	transition: all 400ms ease-out, opacity 800ms ease;
	width: 100%;
	margin-top: 100px;
}

.content {
	margin: 30px auto;
	display: block;
	max-width: 730px;
}

.content > p {
	text-align: justify;
}

.vote {
	position: fixed;
	left: 12px;
	bottom: 12px;
	display: flex;
	align-items: center;
}

#button {
	display: flex;
    align-items: center;
	padding: 0px 15px;
    margin: 0;
	font-size: 13px;
    background-color: #409eff;
    border: 1px solid #409eff;
    border-radius: 3px;
	color: #fff;
    cursor: pointer;
    text-align: center;
	height: 40px;
}

#input {
	height: 40px;
	padding: 0px 15px;
	outline: none;
	border-radius: 3px;
	border: 1px solid #409eff;
	margin-right: 5px;
	width: 368px;
	font-size: 15px;
}

.video-wrap {
	pointer-events: none;
	position: absolute;
	width: 100%;
	height: 100%;
	top: 0;
	left: 0;
	display: flex;
	align-items: center;
	justify-content: center;
	background-color: rgba(0, 0, 0, 0.5);
	transition: opacity 0.3s ease-in-out;
	opacity: 0;
}

#video {
	max-width: 800px;
	width: 96%;
}

.result {
	min-width: 60px;
	background-color: rgb(140, 232, 140);
	padding: 8px 10px;
	display: flex;
	align-items: center;
	justify-content: center;
}

.result-percentage {
	font-size: 20px;
}

.result-unit {
	font-size: 14px;
	margin-left: 5px;
	margin-top: 2px;
}

.result-title {
	color: white;
	background-color: rgba(0, 0, 0, 0.75);
	padding: 0px 20px;
	display: inline;
	font-size: 15px;
    line-height: 44px;
}

.features {
	background: linear-gradient(white 0%, #94eefd 20%, #b6f3fc 60%, white);
	padding-top: 70px;
	padding-bottom: 100px;
	margin-top: 20px;
}


@media only screen and (max-width: 800px) {
	.header {
		height: 80px;
	}

	.heading-text {
		font-size: 28px;
	}

	.title {
		font-size: 22px;
	}

	.demo-wrap {
		height: 300px;
	}

	.content {
		margin: 15px auto;
		padding: 0px 10px;

		max-width: 395px;
		font-size: 13px;
	}

	#button {
		height: 30px;
	}

	#input {
		height: 30px;

		width: 200px;
	}
}

@media only screen and (max-width: 450px) {
	.demo-wrap {
		height: 260px;
	}

	.content {
		max-width: 300px;
		font-size: 10px;
	}

	#input {
		width: 130px;
	}
}
</style>
