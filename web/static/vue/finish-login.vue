<template>
	<div>
		<el-input v-model="username"></el-input>
		<el-input v-model="name"></el-input>
		<el-button @click="login">Register and login</el-button>
	</div>
</template>

<script>
let Api = require('api.js')

export default {
	props: [],
	data: function() {
		let self = this

		return {
			username: '',
			name: '',
			login: function(event) {
			}
		}
	}
}
</script>