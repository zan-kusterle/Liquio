<template>
	<app>
		<el-input class="email" v-model="email" placeholder="Your email"></el-input>
		<el-button @click="login">Login</el-button>
	</app>
</template>

<script>
import App from '../vue/app.vue'
let Api = require('api.js')

export default {
	props: [],
	components: {App},
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