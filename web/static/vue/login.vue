<template>
	<div>
		<el-input v-model="email"></el-input>
		<el-button @click="login">Get magic link</el-button>
	</div>
</template>

<script>
var Api = require('api.js')

export default {
	props: [],
	data: function() {
		var self = this

		return {
			email: '',
			login: function(event) {
				Api.login(self.email, function(token) {
					self.localStorage.setItem('auth-token', res.body.token);
				})
			}
		}
	}
}
</script>