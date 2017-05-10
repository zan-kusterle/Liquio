<template>
	<div class="login">
		<div v-if="!isDone">
			<div>
				<h3 class="title">Login With Email</h3>
				<el-input class="email" v-model="email" @keyup.native.enter="login">
					<el-button slot="append" icon="caret-right" @click="login"></el-button>
				</el-input>
			</div>

			<div style="margin-top: 50px;">
				<h3 class="title">Login With Google</h3>
				<div class="g-signin2" ref="signinBtn"></div>
			</div>
		</div>
		<div v-else>
			<h3 class="title">Get your magic link in your inbox at {{ email }}.</h3>
		</div>
	</div>
</template>

<style>
	.g-signin2 > div {
		margin: 20px auto 0px auto;
	}
</style>
<style scoped>
	.login {
		background-color: white;
		padding: 50px;
	}

	.login .title {
		margin: 0;
		font-weight: normal;
		font-size: 20px;
	}

	.login .email {
		width: 300px;
		margin: 20px auto 0px auto;
		text-align: center;
	}

	.login .button {
		display: block;
		margin: 20px auto 0px auto;
	}
</style>

<script>
import App from '../app.vue'
let Api = require('api.js')

export default {
	props: [],
	components: {App},
	data: function() {
		let self = this

		return {
			email: '',
			isDone: false,
			login: function(event) {
				self.isDone = true
				Api.login(self.email, function() {
				})
			},
			onSignIn: function (googleUser) {
				
			}
		}
	},
	mounted: function() {
		window.gapi.load('auth2', () => {
			const auth2 = window.gapi.auth2.init(this.params)
			auth2.attachClickHandler(this.$refs.signinBtn, {}, (googleUser) => {
				let token = googleUser.getAuthResponse().id_token
				let name = googleUser.getBasicProfile().getName()
				Api.loginGoogle(token)
			}, (error) => {
				console.log(error)
			})
        })
	}
}
</script>

<style scoped>
	.email {
		width: 400px;
	}
</style>