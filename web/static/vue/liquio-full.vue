<template>
<div>
	<div v-if="node">
		<div class="main">
			<div class="inset-top" v-if="inverseReferencesOpen">
				<liquio-list v-bind:nodes="node.inverse_references" v-bind:references-node="node"></liquio-list>
				<i class="fa fa-long-arrow-down" style="font-size: 48px; font-weight: bold; margin-top: 10px;"></i>
			</div>

			<div class="inset-top" style="padding: 15px 20px;" v-else-if="node.inverse_references.length > 0" @click="inverseReferencesOpen = true">
				<i class="fa fa-arrow-up" style="margin-right: 5px;"></i> {{ node.inverse_references.length }} incoming {{ node.inverse_references.length == 1 ? 'reference' : 'references' }}
			</div>
			
			<liquio-node v-bind:node="node" class="main-node"></liquio-node>

			<div class="inset-bottom">
				<i class="fa fa-long-arrow-down" style="font-size: 48px; font-weight: bold; margin-bottom: 15px;"></i>
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

let axios = require('axios')

function loadNode(vm, key) {
	axios.get('/api/nodes/' + key).then(function (response) {
		vm.node = response.data.data
	}).catch(function (error) {
	});
}

export default {
	props: ['urlKey'],
	components: {CalculationOptions, GetReference, LiquioNode, LiquioList},
	data: function() {
		loadNode(this, this.$route.params.urlKey)
		
		return {
			node: null,
			optionsOpen: false,
			inverseReferencesOpen: false,
			referencesOpen: true
		}
	},
	watch: {
		'$route' (to, from) {
			loadNode(this, to.params.urlKey)
		}
	}
}
</script>