<template>
<app>
	identity content {{ this.username }} a
</app>
</template>

<script>
import App from '../vue/app.vue'

let Api = require('api.js')

export default {
	components: {App},
	data: function() {
		let username = this.$route.params.username
		return {
			username: username
		}
	}
}
</script>