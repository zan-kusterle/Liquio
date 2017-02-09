<template>
<div>
	<div class="main">
		<div class="main-node">
			<liquio-list v-bind:nodes="nodes" style="margin: 40px 0px;"></liquio-list>
		</div>
	</div>

	<a @click="optionsOpen = true">Options</a>
	<calculation-opts v-bind:opts="nodes[0].calculation_opts" v-if="optionsOpen" @close="optionsOpen = false"></calculation-opts>
</div>
</template>

<script>
export default {
	data: function() {
		let self = this
		return {
			title: '',
			choice_type: 'search',
			optionsOpen: false,
			view: function(event) {
				if(self.choice_type == 'search') {
					let path = '/search/' + getUrlKey(self.title, '')
					self.$router.push(path)
				} else {
					let path = '/' + getUrlKey(self.title, self.choice_type)
					self.$router.push(path)
				}
			}
		}
	}
}
</script>