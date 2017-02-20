<template>
	<div>
		<el-input v-model="email"></el-input>
		<el-button @click="login">Get magic link</el-button>
	</div>
</template>

<script>
let Api = require('api.js')

export default {
	props: [],
	data: function() {
		let self = this

		return {
			email: '',
			login: function(event) {
				Api.login(self.email, function(token) {
					self.localStorage.setItem('auth-token', token);
				})
			}
		}
	}
}
</script>