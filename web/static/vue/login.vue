<template>
	<div>
		<el-input class="email" v-model="email" placeholder="Your email"></el-input>
		<el-button @click="login">Login</el-button>
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
				Api.login(self.email, function() {
				})
			}
		}
	}
}
</script>

<style scoped>
	.email {
		width: 400px;
	}
</style>