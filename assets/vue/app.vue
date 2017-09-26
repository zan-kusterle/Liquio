<template>
<div>
	<el-popover ref="login" placement="bottom-end" width="500" trigger="click">
		<div class="login">
			<el-input class="words" v-model="words" @keyup.native.enter="login" placeholder="Login with a list of 13 words">
				<el-button slot="append" icon="caret-right" @click="login"></el-button>
			</el-input>

			<div class="identities">
				<div class="identity" v-for="(keypair, index) in $store.getters.currentOpts.keypairs" :key="keypair.username">
					<a @click="setCurrentIndex(index)">{{ keypair.username }}</a>
					<i @click="removeIndex(index)" class="el-icon-close" aria-hidden="true"></i>
				</div>
			</div>

			<div class="generate">
				<el-button @click="generate()" size="small">Generate new identity</el-button>
				<div v-if="randomWords">
					<p>Use the following words to login: <span>{{ randomWords }}</span></p>
					<el-button size="small" @click="downloadIdentity()" style="margin-top: 10px;">Download words</el-button>
				</div>
			</div>
		</div>
	</el-popover>

	<div class="header">
		<el-row>
			<el-col :span="12">
				<router-link to="/" class="logo"><img src="/images/logo.svg"></img></router-link>
			</el-col>
			<el-col :span="12">
				<div class="actions">
					<router-link v-if="$store.getters.currentOpts.keypair" :to="'/identities/' + $store.getters.currentOpts.keypair.username">{{ $store.getters.currentOpts.keypair.username }}</router-link>

					<a v-popover:login><i class="fa fa-user"></i></a>

					<a @click="dialogVisible = !dialogVisible"><i class="el-icon-setting"></i></a>
				</div>
			</el-col>
		</el-row>
	</div>
	
	<div class="main-wrap" id="main-wrap">
		<div class="scrollable">
			<div class="main-container" style="padding-top: 50px; padding-bottom: 100px;">
				<slot>There is nothing here.</slot>
			</div>
		</div>
	</div>

	<el-dialog title="Options" v-model="dialogVisible">
		<div class="block">
			<p class="demonstration">Change language</p>
			<el-select v-model="language" v-on:change="setLanguage()">
				<el-option label="English" value="en"></el-option>
				<el-option label="Slovenščina" value="si"></el-option>
			</el-select>
		</div>
		<div class="block">
			<p class="demonstration">View snapshot at any date</p>
			<el-date-picker type="date" placeholder="Pick a day" v-model="datetime"></el-date-picker>
		</div>

		<div class="block">
			<p class="demonstration">Trust metric URL</p>
			<el-input type="url" v-model="trustMetricURL"></el-input>
		</div>

		<div class="block">
			<p class="demonstration">Votes will lose half remaining power every {{ vote_weight_halving_days }} days.</p>
			<el-slider v-model="vote_weight_halving_days" :max=1000></el-slider>
		</div>

		<div class="block">
			<p class="demonstration">Smooth reference relevance by adding {{ soft_quorum_t }} voting power.</p>
			<el-slider v-model="soft_quorum_t"></el-slider>
		</div>

		<span slot="footer" class="dialog-footer">
			<el-button @click="dialogVisible = false">Close</el-button>
			<el-button type="primary" @click="dialogVisible = false; saveOptions()">Save</el-button>
		</span>
	</el-dialog>
</div>
</template>

<script>
import Vue from 'vue'

let generateWords = () => {
	var bip39 = require('bip39')
	var nacl = require('tweetnacl')

	var randomBytes = nacl.randomBytes(32)
	var mnemonic = bip39.entropyToMnemonic(randomBytes)
	let fixedLength = mnemonic.split(' ').slice(0, 13).join(' ')

	return fixedLength
}

let utils = require('utils.js')

export default {
	data: function() {
		let self = this
		return {
			language: 'en',
			dialogVisible: false,
			datetime: new Date(),
			trustMetricURL: self.$store.getters.currentOpts.trustMetricURL,
			vote_weight_halving_days: 1000,
			soft_quorum_t: 0,
			minimum_relevance_score: 50,
			sort: 'top',
			sortDirection: 'most',
			words: '',
			randomWords: null,
			isDone: false,
			generate: function() {
				self.randomWords = generateWords()
			},
			downloadIdentity: function() {
				var filename = 'liquio-login'
				var text = self.randomWords
				var element = document.createElement('a')
				element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(text))
				element.setAttribute('download', filename)

				element.style.display = 'none'
				document.body.appendChild(element)

				element.click()

				document.body.removeChild(element)
			},
			login: function(event) {
				var bip39 = require('bip39')

				let words = _.filter(_.map(self.words.split(' '), (w) => w.replace(/\s/g, '')), (w) => w.length > 0)

				if(words.length == 13) {
					let seed = bip39.mnemonicToSeed(words.join(' '))
					let encoded = utils.encodeBase64(seed)

					if(self.$store.state.storageSeeds.indexOf(encoded) === -1) {
						self.$store.state.storageSeeds = self.$store.state.storageSeeds + encoded + ';'
						localStorage.setItem('seeds', self.$store.state.storageSeeds)
					} else {
						self.randomWords = generateWords()
					}
				}

				self.words = ''
			},
			removeIndex: function(index) {
				let seeds = _.filter(_.map(self.$store.state.storageSeeds.split(';'), (w) => w.replace(/\s/g, '')), (w) => w.length > 0)
				if(index < seeds.length) {
					self.$store.state.storageSeeds = self.$store.state.storageSeeds.replace(seeds[index] + ';', '')
					localStorage.setItem('seeds', self.$store.state.storageSeeds)

					if(index <= self.$store.state.currentKeyPairIndex) {
						self.$store.state.currentKeyPairIndex -= 1
					}
				}
			},
			setCurrentIndex: function(index) {
				if(index !== self.$store.state.currentKeyPairIndex) {
					self.$store.state.currentKeyPairIndex = index
					localStorage.setItem('currentIndex', index)
				}
			},
			saveOptions: function() {
				if(self.$store.state.trustMetricURL !== self.trustMetricURL) {
					self.$store.state.trustMetricURL = self.trustMetricURL
					localStorage.setItem('trustMetricURL', self.trustMetricURL)
				}
			},
			setLanguage: function() {
				self.$i18n.locale = self.language
			}
		}
	}
}
</script>

<style lang="less">
.loading {
	font-size: 48px;
	color: #2a9fec;
}

p {
	margin: 0px;
}

.login {
	padding: 15px;

	.identities {
		margin-top: 30px;

		.identity {
			font-size: 16px;
			margin-top: 10px;

			i {
				margin-left: 10px;
				font-size: 10px;
			}
		}
	}

	.generate {
		margin-top: 30px;

		p {
			margin-top: 20px;
			display: block;
			font-size: 20px;

			span {
				margin-top: 10px;
				display: block;
				font-weight: bold;
				font-size: 14px;
			}
		}
	}
}

.header {
	width: 100%;
	background-color: #2a9fec;
	text-align: left;
	height: 70px;

	.logo {
		margin-top: 18px;
		margin-left: 30px;
		display: inline-block;
		vertical-align: middle;
		filter: brightness(0) invert(1);

		img {
			width: 100px;
		}
	}

	.actions {
		font-size: 14px;
		line-height: 35px;
		margin-right: 30px;
		margin-top: 18px;
		text-align: right;

		.identity {
			display: inline-block;
			margin-left: 20px;

			a {
				margin-left: 15px;
			}

			i {
				font-size: 10px;
				color: rgba(0, 0, 0, 0.2);
			}
		}

		i {
			vertical-align: middle;
			font-size: 20px;
		}

		a {
			color: white;
			display: inline-block;
			vertical-align: middle;
			text-decoration: none;
			margin-left: 50px;
		}

		a:hover {
			text-decoration: none;
			color: white !important;
			opacity: 1;
		}
	}

	.not-in-trust-metric {
		line-height: 0px;
		display: block;
		font-size: 11px;
		color: white;
		font-weight: bold;
	}
}

a {
	color: #333;
	text-decoration: none;
}

a:hover {
	color: #337ab7;
}

table {
	border-collapse: collapse
}

hr {
	margin: 20px 0px;
	border: 0;
	border-top: 1px solid #ddd;
}

.main-wrap {
	position: absolute;
	left: 0px;
	right: 0px;
	bottom: 0px;
	top: 70px;
	overflow-y: scroll;

	.scrollable {
		height: 100%;
	}

	.main-container {
		margin: 0px auto;
		max-width: 1200px;
		min-height: 100%;
		background-color: rgba(255, 255, 255, 0.85);
		border: 1px solid rgba(0, 0, 0, 0.05);
		border-top: 0px;
	}

	.main {
		margin: 0px;
		padding: 40px 20px;
		background-color: rgba(255, 255, 255, 1);
		box-shadow: 0px 0px 4px 0px #bbb;
	}

	.before, .after {
		padding: 30px;
	}

	.footer {
		border-top: 1px solid rgba(0, 0, 0, 0.12);
		padding: 20px;
	}

	.main-g {
		max-width: 1200px;
		margin: 0 auto;
	}
}
</style>
