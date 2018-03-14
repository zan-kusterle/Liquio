<template>
<div class="login">
	<div class="vote-section" v-if="usernames.length > 0">
		<p class="login-title" style="margin-bottom: 15px;">Current user</p>

		<el-select class="select-user" v-model="currentUsername" placeholder="Select user">
			<el-option v-for="username in usernames" :key="username" :label="username" :value="username" />
		</el-select>

		<el-button class="main-button" size="small" type="danger" @click="$emit('logout')">Logout {{ currentUsername }}</el-button>
	</div>

	<el-row :gutter="40" v-if="randomWords">
		<el-col :span="12">
			<div class="vote-section">
				<p class="login-title">Login</p>

				<el-input class="login-field" v-model="words" @keyup.native.enter="login" placeholder="Login with 13 words">
					<el-button slot="append" icon="el-icon-caret-right" @click="login"></el-button>
				</el-input>
			</div>
		</el-col>
		<el-col :span="12">
			<div class="vote-section">
				<p class="login-title">New user</p>

				<p class="login-titlee">Login with username <b>{{ generatedUsername }}</b></p>

				<div class="login-words">{{ randomWords }}</div>

				<div class="login-extra">
					<p>This data is never sent to our servers</p>

					<el-button size="small" @click="downloadIdentity()" :disabled="wordsDownloaded" style="margin-top: 10px;">Download words</el-button>
				</div>
			</div>
		</el-col>
	</el-row>
</div>
</template>


<script>
import { Row, Col, Button, Input, Select, Option } from 'element-ui'
import bip39 from 'bip39'
import nacl from 'tweetnacl'
import { keypairFromSeed, wordsToSeed } from 'shared/identity'

export default {
	components: {
		elRow: Row,
		elCol: Col,
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

</style>