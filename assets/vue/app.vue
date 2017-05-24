<template>
<div>
	<el-popover ref="login" placement="bottom-end" width="500" trigger="click" :visible-arrow=false>
		<div class="login">
			<el-input class="words" v-model="words" @keyup.native.enter="login" placeholder="Login with a list of 13 words">
				<el-button slot="append" icon="caret-right" @click="login"></el-button>
			</el-input>

			<a class="generate-new" @click="generate">Generate new identity</a>
			<p v-if="randomWords" class="mnemonic">{{ randomWords }}</p>

			<div class="identity" v-for="(keypair, index) in $store.getters.availableKeyPairs">
				<a @click="$store.commit('removeKeyPair(index)')"><i class="el-icon-close" aria-hidden="true"></i></a>
				<router-link :to="'/identities/' + keypair.username">{{ keypair.username }}</router-link>
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
					<router-link v-if="$store.getters.currentKeyPair" :to="'/identities/' + $store.getters.currentKeyPair.username">{{ $store.getters.currentKeyPair.username }}</router-link>

					<a v-popover:login><i class="el-icon-plus" aria-hidden="true"></i></a>

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
			<p class="demonstration">View snapshot at any day</p>
			<el-date-picker type="date" placeholder="Pick a day" v-model="datetime"></el-date-picker>
		</div>

		<div class="block">
			<p class="demonstration">Trust metric URL</p>
			<el-input type="url"></el-input>
		</div>

		<div class="block">
			<p class="demonstration">Votes will lose half remaining power every {{ vote_weight_halving_days }} days.</p>
			<el-slider v-model="vote_weight_halving_days" max="1000"></el-slider>
		</div>

		<div class="block">
			<p class="demonstration">Smooth reference relevance by adding {{ soft_quorum_t }} voting power.</p>
			<el-slider v-model="soft_quorum_t"></el-slider>
		</div>

		<span slot="footer" class="dialog-footer">
			<el-button @click="dialogVisible = false">Cancel</el-button>
			<el-button type="primary" @click="dialogVisible = false">Confirm</el-button>
		</span>
	</el-dialog>
</div>
</template>

<script>
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
			dialogVisible: false,
			datetime: new Date(),
			minimum_turnout: 50,
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
			login: function(event) {
				var bip39 = require('bip39')

				let words = _.filter(_.map(self.words.split(' '), (w) => w.replace(/\s/g, '')), (w) => w.length > 0)

				if(words.length == 13) {
					let seed = bip39.mnemonicToSeed(words.join(' '))
					let encoded = utils.encodeBase64(seed)

					let value = localStorage.seeds || ''
					if(value.indexOf(encoded) === -1) {
						let newValue = value + encoded + ';'
						localStorage.setItem('seeds', newValue)
					}
				}
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

	.mnemonic {
		margin-top: 10px;
		display: block;
		font-size: 16px;
	}

	.generate-new {
		display: inline-block;
		margin-top: 50px;
		font-size: 14px;
		font-weight: bold;
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
