<template>
<div>
	<div v-if="node">
		<div class="main">
			<transition name="fadeDown">
				<div class="inset-top" v-if="inverseReferencesOpen">
					<liquio-list v-bind:nodes="node.inverse_references" v-bind:references-node="node"></liquio-list>
					<i class="el-icon-arrow-down" style="font-size: 48px; font-weight: bold; margin-top: 10px;"></i>
				</div>
			</transition>
			
			<div class="inset-top" style="padding: 15px 20px;" v-if="!inverseReferencesOpen && node.inverse_references.length > 0" @click="inverseReferencesOpen = true">
				<i class="el-icon-arrow-up" style="margin-right: 5px;"></i> {{ node.inverse_references.length }} incoming {{ node.inverse_references.length == 1 ? 'reference' : 'references' }}
			</div>

			<liquio-node v-bind:node="node" class="main-node"></liquio-node>

			<div class="inset-bottom">
				<i class="el-icon-arrow-down" style="font-size: 48px; font-weight: bold; margin-bottom: 15px;"></i>
				<liquio-list v-bind:nodes="node.references" v-bind:referencing-node="node" style="text-align: left;"></liquio-list>
				
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
	props: ['urlKey'],
	components: {CalculationOptions, GetReference, LiquioNode, LiquioList},
	data: function() {
		let self = this
		Api.getNode(this.$route.params.urlKey || '', (node) => self.node = node)
		
		return {
			node: null,
			optionsOpen: false,
			inverseReferencesOpen: false,
			referencesOpen: true,

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
	},
	watch: {
		'$route' (to, from) {
			loadNode(this, to.params.urlKey)
		}
	}
}
</script>