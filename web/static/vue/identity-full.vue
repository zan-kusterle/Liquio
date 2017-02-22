<template>
<app>
	<div v-if="identity">
		{{ username }}
		<liquio-list v-bind:nodes="identity.vote_nodes"></liquio-list>
	</div>
	<div class="main" v-else>
		<div class="main-node">
			<i class="el-icon-loading loading"></i>
		</div>
	</div>
</app>
</template>

<script>
import App from '../vue/app.vue'
import LiquioList from '../vue/liquio-list.vue'

let Api = require('api.js')

export default {
	components: {App, LiquioList},
	data: function() {
		let self = this
		let username = this.$route.params.username
		Api.getIdentity(username, (identity) => self.identity = identity)

		return {
			identity: null,
			username: username
		}
	}
}
</script>