<template>
<div>
	<div v-if="node">
		<div class="main">
			<transition name="fade">
				<div class="inset-top" v-if="inverseReferencesOpen">
					<liquio-list v-bind:nodes="node.inverse_references" v-bind:references-node="node"></liquio-list>
					<i class="el-icon-arrow-down" style="font-size: 48px; font-weight: bold; margin-top: 10px;"></i>
				</div>
			</transition>
			
			<div class="inset-top" style="padding: 15px 20px;" v-if="node.choice_type != null && !inverseReferencesOpen && node.inverse_references.length > 0" @click="inverseReferencesOpen = true">
				<i class="el-icon-arrow-up" style="margin-right: 5px;"></i> {{ node.inverse_references.length }} incoming {{ node.inverse_references.length == 1 ? 'reference' : 'references' }}
			</div>

			<liquio-node v-if="node.title.length > 0" v-bind:node="node" class="main-node"></liquio-node>

			<div class="inset-bottom">
				<i class="el-icon-arrow-down" v-if="node.title.length > 0" style="font-size: 48px; font-weight: bold; margin-bottom: 15px;"></i>
				<liquio-list v-bind:nodes="node.references" v-bind:referencing-node="node.title.length > 0 && node" style="text-align: left;"></liquio-list>
				
				<get-reference v-bind:node="node"></get-reference>
			</div>
		</div>

		<calculation-options v-bind:opts="node.calculation_opts"></calculation-options>
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
		
		return {
			node: null,
			inverseReferencesOpen: false
		}
	},
	watch: {
		'$route' (to, from) {
			let self = this
			Api.getNode(to.params.key || '', function(node) {
				self.node = node
				self.inverseReferencesOpen = false
			})
		}
	}
}
</script>