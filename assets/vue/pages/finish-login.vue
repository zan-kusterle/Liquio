<template>
	<div class="login">
		<h3 class="title">Register new identity</h3>
		<el-input v-model="username" class="username" placeholder="Username"></el-input>
		<el-input v-model="name" class="name" placeholder="Full name"></el-input>
		<el-button @click="create" class="button">Finish registration</el-button>
	</div>
</template>


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

	.login .username, .login .name {
		display: block;
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
	components: {App},
	props: [],
	data: function() {
		let self = this

		return {
			username: '',
			name: '',
			create: function(event) {
				self.$router.go('/identities/' + self.username)
				Api.register(self.$route.params.token, self.username, self.name, function() {
				})
			}
		}
	}
}
</script>


<style scoped>
	.username, .name {
		width: 400px;
	}
</style>