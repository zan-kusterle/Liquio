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
				
				<get-reference v-bind:node="node" style="margin-top: 20px;"></get-reference>
			</div>
		</div>

		<calculation-options v-bind:opts="node.calculation_opts"></calculation-options>
	</div>
	<div v-else>
		<i class="el-icon-loading" style="font-size: 100px; margin-top: 100px;"></i>
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
		Api.getNode(this.$route.params.key || '', (node) => self.node = node)
		this.$root.bus.$on('change', () => {
			Api.getNode(self.$route.params.key || '', (node) => self.node = node)
		})

		return {
			node: null,
			inverseReferencesOpen: true
		}
	},
	watch: {
		'$route': function(to, from) {
			let self = this
			self.node = null
			Api.getNode(to.params.key || '', function(node) {
				self.node = node
				self.inverseReferencesOpen = false
			})
		}
	}
}
</script>