<template>
	<div>
		identity content {{ this.username }} a
	</div>
</template>

<script>
var Api = require('api.js')

export default {
	data: function() {
		var username = this.$route.params.username
		return {
			username: username
		}
	}
}
</script>