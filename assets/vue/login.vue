<template>
<div class="login">
	<template v-if="usernames.length > 0">
		<p class="section-title">You are voting as</p>

		<el-select class="select-user" v-model="currentUsername" placeholder="Select user">
			<el-option v-for="username in usernames" :key="username" :label="username" :value="username" />
		</el-select>

		<el-button class="main-button" size="small" type="danger" @click="$emit('logout')">Logout {{ currentUsername }}</el-button>
	</template>

	<template v-if="randomWords">
		<p class="section-title">Login</p>

		<el-input class="login-field" v-model="words" @keyup.native.enter="login" placeholder="Enter a list of 13 words">
			<el-button slot="append" icon="el-icon-caret-right" @click="login"></el-button>
		</el-input>

		<p class="section-title">New user</p>

		<p class="login-title">Login with user <b>{{ generatedUsername }}</b> using the following 13 words</p>
		<div class="login-words">
			<span>{{ randomWords }}</span>
			<div class="login-extra">
				<el-button size="small" @click="downloadIdentity()" :disabled="wordsDownloaded">Download words</el-button>
				<span>This data is never sent to our servers</span>
			</div>
		</div>
    </template>
</div>
</template>


<script>
import { Button, Input, Select, Option } from 'element-ui'
import bip39 from 'bip39'
import nacl from 'tweetnacl'
import { keypairFromSeed, wordsToSeed } from 'shared/identity'

export default {
	components: {
        elButton: Button,
		elInput: Input,
		elSelect: Select,
        elOption: Option
	},
	props: {
		usernames: { type: Array, required: true },
		username: { type: String }
	},
    data () {
		return {
			words: '',
			randomWords: this.generateWords(),
			wordsDownloaded: false
		}
    },
    computed: {
		currentUsername: {
			get () {
				return this.username
			},
			set (v) {
				this.$emit('switch', v)
			}
		},
        generatedUsername () {
            if (!this.randomWords)
                return null
            return keypairFromSeed(wordsToSeed(this.randomWords)).username
        }
    },
    methods: {
		generateWords () {
			var randomBytes = nacl.randomBytes(32)
			var mnemonic = bip39.entropyToMnemonic(randomBytes)
            let fixedLength = mnemonic.split(' ').slice(0, 13).join(' ')
            
			return fixedLength
        },
		downloadIdentity () {
			this.wordsDownloaded = true

			var filename = `${this.generatedUsername}-login.txt`
			var text = this.randomWords
			var element = document.createElement('a')
			element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(text))
			element.setAttribute('download', filename)

			element.style.display = 'none'
			document.body.appendChild(element)

			element.click()

			document.body.removeChild(element)
		},
		login (event) {
			let seed = wordsToSeed(this.words)
            if (seed) {
				this.$emit('login', seed)
			}
			this.words = ''
			this.randomWords = this.generateWords()
			this.wordsDownloaded = false
		}
	}
}
</script>

<style lang="less" scoped>

.section-title {
	font-size: 22px;
	margin-bottom: 20px;
	margin-top: 50px;

	&:first-child {
		margin-top: 0px;
	}
}

.select-user {
	vertical-align: middle;
}

.main-button {
	margin-left: 30px;
	vertical-align: middle;
}

.login-words {
	margin-top: 5px;
	font-size: 12px;
	background-color: #eee;
	padding: 10px 20px;

	> span {
		margin-left: 2px;
		font-weight: bold;
	}
}

.login-extra {
	display: block;
	margin-top: 5px;

	> span {
		color: #c00;
		margin-left: 10px;
		font-size: 13px;
	}
}
</style>