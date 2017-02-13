<template>
	<div>
		identity content {{ this.username }} a
	</div>
</template>

<script>
let Api = require('api.js')

export default {
	data: function() {
		let username = this.$route.params.username
		return {
			username: username
		}
	}
}
</script>