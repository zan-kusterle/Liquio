<template>
<app>
	<div v-if="node">
		<div class="main" v-if="node.title.length > 0">
			<div class="inset-top" style="text-align: left;">
				<liquio-list v-bind:nodes="node.inverse_references" v-bind:references-node="node"></liquio-list>
			</div>
			
			<liquio-node v-bind:node="node" results-key="main" class="main-node" id="main-node"></liquio-node>

			<div class="inset-bottom">
				<liquio-list v-bind:nodes="node.references" v-bind:referencing-node="node" style="text-align: left;"></liquio-list>
			</div>
		</div>
		<div class="main" v-else>
			<div class="main-node">
				<h1 class="fake-title">Everything</h1>
				<liquio-list v-bind:nodes="node.references" style="text-align: left;"></liquio-list>
			</div>
		</div>

		<calculation-options v-bind:opts="node.calculation_opts"></calculation-options>
	</div>
	<div class="main" v-else>
		<div class="main-node">
			<h1 class="fake-title" v-if="title">{{ title }}</h1>
			<i class="el-icon-loading loading"></i>
		</div>
	</div>
</app>
</template>

<script>
import App from '../vue/app.vue'
import CalculationOptions from '../vue/calculation-options.vue'
import LiquioNode from '../vue/liquio-node.vue'
import LiquioList from '../vue/liquio-list.vue'
let Api = require('api.js')

function updateNode(self) {
	function scrollToNode() {
		let element = document.getElementById('main-node')
		if(element)
			element.scrollIntoView({block: "start", behavior: "smooth"})
	}

	self.node = null
	if(self.$route.params.query) {
		Api.search(self.$route.params.query, (node) => {
			self.node = node
			setTimeout(scrollToNode, 0)
		})
		self.title = self.$route.params.query
	} else {
		let key = self.$route.params.key || ''
		self.$store.dispatch('fetchNode', key).then((node) => {
			self.node = node
			setTimeout(scrollToNode, 0)
		})
		self.title = key.replace('-Probability', '').replace('-Quantity', '').replace('-Time-Series', '').replace(/-/g, ' ')
	}
}

export default {
	components: {App, CalculationOptions, LiquioNode, LiquioList},
	data: function() {		
		this.$root.bus.$on('change', () => {
			updateNode(this)
		})
		updateNode(this)

		return {
			node: this.node,
			title: this.title
		}
	},
	watch: {
		'$route': function(to, from) {			
			updateNode(this)
		}
	}
}
</script>

<style scoped>
	.fake-title {
		display: block;
		font-size: 26px;
		font-weight: normal;
		color: #333;
		opacity: 1;
		word-wrap: break-word;
		margin: 40px 0px;
	}
</style>