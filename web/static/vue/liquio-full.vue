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
	<div v-else>
		<i class="el-icon-loading loading"></i>
	</div>
</div>
</template>

<script>
import CalculationOptions from '../vue/calculation-options.vue'
import GetReference from '../vue/get-reference.vue'
import LiquioNode from '../vue/liquio-node.vue'
import LiquioList from '../vue/liquio-list.vue'
let Api = require('api.js')

export default {
	components: {CalculationOptions, GetReference, LiquioNode, LiquioList},
	data: function() {
		let self = this
		if(this.$route.params.query) {
			Api.search(this.$route.params.query, (node) => self.node = node)
		} else {
			Api.getNode(this.$route.params.key || '', null, (node) => self.node = node)
			this.$root.bus.$on('change', () => {
				Api.getNode(self.$route.params.key || '', null, (node) => self.node = node)
			})
		}
		

		return {
			node: null
		}
	},
	watch: {
		'$route': function(to, from) {
			let self = this
			self.node = null
			if(self.$route.params.query) {
				Api.search(self.$route.params.query, (node) => self.node = node)
			} else {
				Api.getNode(to.params.key || '', null, (node) => self.node = node)
			}
		}
	}
}
</script>