<template>
<div>
	<div v-if="node && !node.loading" class="main">
		Results for {{ query }}
	</div>

	<div class="after" v-if="node && !node.loading">
		<div class="list-simple">
			<liquio-inline v-for="reference in node.references" :key="reference.key" v-bind:node="reference" v-bind:referencing-node="node.title === '' ? null : node" style="text-align: left;"></liquio-inline>
		</div>
	</div>
</div>
</template>

<script>
import App from '../app.vue'
import LiquioInline from '../liquio-inline.vue'

export default {
	components: {App, LiquioInline},
	data: function() {
		let self = this

		return {
			query: ''
		}
	},
	computed: {
		node: function() {
			let node = getNode(this.$store)
			
			return node
		}
	}
}

let getNode = ($store) => {
	let node = $store.getters.currentNode
	node.loading = true
	let searchNode = $store.getters.searchResults($store.getters.searchQuery)
	if(searchNode) {
		node = searchNode
		node.loading = false
	}

	node.path_segments = _.map(node.path, (s, index) => {
		return {
			href: node.path.slice(0, index + 1).join('/').replace(':', '://'),
			text: index == 0 ? node.path[index].replace(':', '://') : node.path[index]
		}
	})

	node.url = node.path.join('/').replace(':', '://')
	
	return node
}
</script>