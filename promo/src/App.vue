<template>
	<div id="app">
		<div class="header">
			<h1>Vote on anything, anywhere on the web.</h1>
		</div>

		<div v-if="isDemoOpen && !canReplayDemo" :style="{ left: `${currentCursorX}px`, top: `${currentCursorY}px`, transition: `all ${transitionTime}ms ${transitionEasing || 'ease'}` }" class="cursor">
			<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 720.711 1079.449" width="15" height="20">
				<path d="M0 0v1041.422L232.422 809l111.904 270.45 169.764-84.884-114.094-273.855h320.715z" />
			</svg>
		</div>

		<div class="demo-wrap">
			<button :style="isDemoOpen ? { opacity: 0, pointerEvents: 'none' } : { opacity: 1 }" class="button" @click="startDemo">Watch Demo</button>
			<button :style="!canReplayDemo ? { opacity: 0, pointerEvents: 'none' } : { opacity: 1 }" class="button replay-button" @click="startDemo">Replay Demo</button>

			<div class="content-wrap" :style="isDemoOpen ? { height: '420px', marginTop: 0, opacity: isTextDim ? 0.3 : 1 } : { height: '0px' }">
				<div class="content" :style="isHighlighted ? { color: '#888' } : {}">
					<h3 class="title">Flat Earth</h3>

					<p>
						The flat Earth model is an archaic conception of Earth's shape as a plane or disk. Many ancient cultures subscribed to a flat Earth cosmography, including Greece until the classical period, the Bronze Age and Iron Age civilizations of the Near East until the Hellenistic period, India until the Gupta period (early centuries AD), and China until the 17th century.
					</p>
					<p>
						The idea of a spherical Earth appeared in Greek philosophy with Pythagoras (6th century BC), although most pre-Socratics (6th–5th century BC) retained the flat Earth model. Aristotle provided
						<span id="text" :style="isHighlighted ? { backgroundColor: 'yellow', color: '#333' } : {}">evidence for the spherical shape of the Earth on empirical grounds</span>
						by around 330 BC. Knowledge of the spherical Earth gradually began to spread beyond the Hellenistic world from then on.
					</p>
					<p>
						In the modern era, pseudoscientific flat Earth theories have been espoused by modern flat Earth societies and, increasingly, by unaffiliated individuals using social media.
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
			<video id="video" src="./assets/reference-vote.mp4" />
		</div>
	</div>
</template>

<script>
export default {
	name: 'app',
	data () {
		return {
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
		startDemo () {
			this.isDemoOpen = true
			this.canReplayDemo = false

			this.isTextDim = false
			this.isButtonShown = false
			this.isInputShown = false
			this.isHighlighted = false
			this.isHighlightActive = false

			let steps = [
				this.selectTextStep,
				this.openReferenceStep,
				this.voteVideoStep,
				this.demoHighlightStep,
			]

			let executeStep = (index) => {
				let step = steps[index]
				this.$nextTick(() => {
					step().then(() => {
						if (index + 1 < steps.length) {
							executeStep(index + 1)
						} else {
							setTimeout(() => {
								this.canReplayDemo = true
							}, 2000)
						}
					})
				})
			}
			setTimeout(() => {
				executeStep(0)
			}, 1000)
		},
		selectTextStep () {
			return new Promise((resolve, reject) => {
				let textElement = document.getElementById('text')
				let textBounds = this.getElementBounds(textElement)

				this.animateCursor(textBounds.x, textBounds.y).then(() => {
					let selectionTime = 1000

					this.animateCursor(textBounds.x + textBounds.width, textBounds.y + textBounds.height, selectionTime, 'linear')

					let index = 0
					let textLength = textElement.innerText.length
					this.repeat(index => {
						let range = document.createRange()
						range.setStart(textElement.childNodes[0], 0)
						range.setEnd(textElement.childNodes[0], index + 1)
						window.getSelection().removeAllRanges()
						window.getSelection().addRange(range)
					}, textLength, this.TIME_FACTOR * selectionTime).then(() => {
						this.isButtonShown = true
						resolve()
					})
				})
			})
		},
		openReferenceStep () {
			return new Promise(resolve => {
				let buttonElement = document.getElementById('button')
				let buttonBounds = this.getElementBounds(buttonElement)

				setTimeout(() => {
					this.isTextDim = true
				}, this.TIME_FACTOR * 400)

				this.animateCursor(buttonBounds.x + buttonBounds.width / 2, buttonBounds.y + buttonBounds.height / 2).then(() => {
					window.getSelection().removeAllRanges()
					this.isInputShown = true

					this.$nextTick(() => {
						let inputElement = document.getElementById('input')
						this.repeat(index => {
							inputElement.value = this.nodeTitle.substring(0, index + 1)
						}, this.nodeTitle.length, 1000).then(() => {
							let buttonBounds = this.getElementBounds(buttonElement)
							this.animateCursor(buttonBounds.x + buttonBounds.width / 2, this.targetY).then(() => {
								this.isInputShown = false
								this.isButtonShown = false
								resolve()
							})
						})
					})
				})
			})
		},
		voteVideoStep () {
			return new Promise(resolve => {
				let videoElement = document.getElementById('video')
				let videoBounds = this.getElementBounds(videoElement)
				videoElement.playbackRate = 1 / this.TIME_FACTOR
				videoElement.parentNode.style.opacity = 1;
				videoElement.play()
				videoElement.addEventListener('ended', () => {
					videoElement.parentNode.style.opacity = 0;
					resolve()
				})

				this.animateCursor(videoBounds.x + videoBounds.width / 2, videoBounds.y + videoBounds.height * 0.85, 300)

				setTimeout(() => {
					this.animateCursor(videoBounds.x + videoBounds.width * 0.67, this.targetY, 200)

					setTimeout(() => {
						this.animateCursor(videoBounds.x + videoBounds.width / 2, videoBounds.y + videoBounds.height * 0.93)
					}, this.TIME_FACTOR * 400)
				}, this.TIME_FACTOR * 800)
			})
		},
		demoHighlightStep () {
			return new Promise(resolve => {
				this.isHighlighted = true
				setTimeout(() => {
					this.isTextDim = false
				}, this.TIME_FACTOR * 100)

				let textElement = document.getElementById('text')
				let textBounds = this.getElementBounds(textElement)

				this.animateCursor(textBounds.x + textBounds.width / 2, textBounds.y + textBounds.height / 2).then(() => {
					this.isHighlightActive = true
					resolve()
				})
			})
		},
		getElementBounds (element) {
			let rect = element.getBoundingClientRect()
			return {
				x: rect.left / document.documentElement.clientWidth, y: rect.top / document.documentElement.clientHeight,
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
					duration = 1000 * Math.pow(distance, 0.2)
				}
	
				this.transitionTime = this.TIME_FACTOR * duration
				this.transitionEasing = easing
				this.targetX = x
				this.targetY = y

				setTimeout(resolve, this.transitionTime)
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

.promo {
	text-align: center;
}

.header {
	text-align: center;
}

h1 {
	font-weight: normal;
	margin-top: 30px;
	margin-bottom: 0px;
	font-size: 48px;
	color: #444;
}

.get-extension {
	margin: 0 auto;
	display: inline-block;
	background-color: #eee;
	border: 1px solid #ddd;
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
	height: 420px;
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
}

.button:hover {
	background: #27baea;
	text-decoration: none;
}

.replay-button {
	transition: opacity 300ms ease;
	margin-top: -50px;
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
	width: 665px;
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
	display: inline-block;
	padding: 9px 15px;
    margin: 0;
	font-size: 13px;
    line-height: 1;
    background-color: #409eff;
    border: 1px solid #409eff;
    border-radius: 3px;
	color: #fff;
    cursor: pointer;
    text-align: center;
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
	width: 800px;
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
}

.result-title {
	color: white;
	background-color: rgba(0, 0, 0, 0.75);
	padding: 0px 20px;
	display: inline;
	font-size: 15px;
    line-height: 44px;
}
</style>
