<template>
	<div>
		<div class="before" v-if="!node.loading">
			<el-input v-model="inverse_reference_title" @keyup.native.enter="view_inverse_reference" style="max-width: 800px;">
				<el-button slot="append" icon="caret-right" @click="view_inverse_reference"></el-button>
			</el-input>
			
			<liquio-list v-if="node.path[0] !== ''" v-bind:nodes="node.inverse_references" v-bind:references-node="node"></liquio-list>
		</div>

		<div v-if="!node.loading" class="main">
			<liquio-node v-bind:node="node" v-bind:unit="node.unit"></liquio-node>
		</div>
		<div v-else class="main">
			<h1 class="fake-title">{{ node.title }}</h1>
			<i class="el-icon-loading loading"></i>
		</div>

		<div class="after" v-if="node">
			<liquio-list v-bind:nodes="node.references" v-bind:referencing-node="node.path[0] === '' || node.path[0].toLowerCase() === 'search' ? null : node" style="text-align: left;"></liquio-list>
			
			<el-input v-if="node.path[0] !== '' && node.path[0].toLowerCase() !== 'search'" v-model="reference_title" @keyup.native.enter="view_reference" style="max-width: 800px;">
				<el-button slot="append" icon="caret-right" @click="view_reference"></el-button>
			</el-input>
		</div>

		<div class="footer">
			<calculation-options v-bind:opts="$store.state.calculation_opts"></calculation-options>
		</div>
	</div>
</template>

<script>
import App from '../app.vue'
import CalculationOptions from '../calculation-options.vue'
import LiquioNode from '../liquio-node.vue'
import LiquioList from '../liquio-list.vue'
let utils = require('utils.js')

let getCurrentNode = ($store) => {
	let key = $store.getters.currentNode.key
	if($store.getters.searchQuery) {
		$store.dispatch('search', $store.getters.searchQuery)
		return $store.getters.searchResults($store.getters.searchQuery)
	} else if(!$store.getters.hasNode(key)) {
		$store.dispatch('fetchNode', key)
		return $store.getters.currentNode
	} else {
		return $store.getters.getNodeByKey(key)
	}
}

export default {
	components: {App, CalculationOptions, LiquioNode, LiquioList},
	data: function() {
		let self = this

		return {
			reference_title: '',
			inverse_reference_title: '',
			view_reference: (event) => {
				let clean_key = self.reference_title.trim().replace(/\s+/g, '-')
				if(clean_key.length >= 3) {
					let path = '/' + encodeURIComponent(self.node.key) + '/references/' + encodeURIComponent(clean_key)
					self.$router.push(path)
				}
			},
			view_inverse_reference: (event) => {
				let clean_key = self.inverse_reference_title.trim().replace(/\s+/g, '-')
				if(clean_key.length >= 3) {
					let path = '/' + encodeURIComponent(clean_key) + '/references/' + encodeURIComponent(self.node.key)
					self.$router.push(path)
				}
			}
		}
	},
	watch: {
		'$route': function() {
			getCurrentNode(this.$store)
		}
	},
	computed: {
		node: function() {
			return getCurrentNode(this.$store)
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
		margin: 10px 0px;
	}

	.subtitle {
		font-size: 20px;
	}
</style>