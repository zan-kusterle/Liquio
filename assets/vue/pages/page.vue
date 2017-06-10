<template>
<div>
	<div ref="pageHtml"></div>
</div>
</template>

<script>
var axios = require('axios')

export default {
	components: {},
	props: [],
	data: function() {
		let self = this
		let url = this.$store.getters.pageUrl

		console.log(url)

		axios.get(url).then(function(response) {
			self.$refs.pageHtml.innerHTML = response.data
		}).catch(function(error) {})

		return {
			url: url
		}
	}
}
</script>

<style lang="less" scoped>

</style>