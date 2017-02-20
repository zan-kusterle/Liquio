<template>
<div>
	<div v-if="node">
		<div class="main">
			<div class="inset-top" style="text-align: left;">
				<liquio-list v-bind:nodes="node.inverse_references" v-bind:references-node="node"></liquio-list>
			</div>
			
			<liquio-node v-if="node.title.length > 0" v-bind:node="node" results-key="main" class="main-node"></liquio-node>

			<div class="inset-bottom">
				<liquio-list v-bind:nodes="node.references" v-bind:referencing-node="node.title.length > 0 && node" style="text-align: left;"></liquio-list>
				
				<get-reference v-bind:node="node" style="margin-top: 20px; opacity: 0.9;"></get-reference>
			</div>
		</div>

		<calculation-options v-bind:opts="node.calculation_opts"></calculation-options>
	</div>
	<div class="main" v-else>
		<div class="main-node" v-if="title">
			<h1 class="fake-title">{{ title }}</h1>
			<i class="el-icon-loading loading"></i>
		</div>
	</div>
</div>
</template>

<script>
import CalculationOptions from '../vue/calculation-options.vue'
import GetReference from '../vue/get-reference.vue'
import LiquioNode from '../vue/liquio-node.vue'
import LiquioList from '../vue/liquio-list.vue'
let Api = require('api.js')

function updateNode(self) {
	self.node = null
	if(self.$route.params.query) {
		Api.search(self.$route.params.query, (node) => self.node = node)
		self.title = self.$route.params.query
	} else {
		let key = self.$route.params.key || ''
		Api.getNode(key, null, (node) => self.node = node)
		self.title = key.replace('-Probability', '').replace('-Quantity', '').replace('-Time-Series', '').replace(/-/g, ' ')
	}
}

export default {
	components: {CalculationOptions, GetReference, LiquioNode, LiquioList},
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