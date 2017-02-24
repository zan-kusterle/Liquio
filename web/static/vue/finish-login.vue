<template>
	<app>
		<el-input v-model="username" class="username"></el-input>
		<el-input v-model="name" class="name"></el-input>
		<el-button @click="create">Create new identity</el-button>
	</app>
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
			create: function(event) {
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