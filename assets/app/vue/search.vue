<template>
<div style="padding-top: 50px; padding-bottom: 100px;">
	<template v-if="node && !node.loading">
		<template v-if="node.references.length > 0">
			<div class="main">
				Results for '{{ query }}'
			</div>

			<div class="after">
				<div class="list-simple">
					<liquio-inline v-for="reference in node.references" :key="reference.key" v-bind:node="reference" v-bind:referencing-node="node.title === '' ? null : node" style="text-align: left;"></liquio-inline>
				</div>
			</div>
		</template>
		<div class="main" v-else>
			No results for '{{ query }}'.
		</div>
	</template>
	<template v-else>
		Loading...
	</template>
</div>
</template>

<script>
import LiquioInline from 'reusable/liquio-inline.vue'

export default {
	components: {LiquioInline},
	data: function() {
		return {
			query: ''
		}
	},
	computed: {
		node: function() {
			let node = this.$store.getters.currentNode
			node.loading = true
			let searchNode = this.$store.getters.searchResults(this.$store.getters.searchQuery)
			if(searchNode) {
				node = searchNode
				node.loading = false
			}

			node.path_segments = node.path.map((s, index) => {
				return {
					href: node.path.slice(0, index + 1).join('/').replace(':', '://'),
					text: index == 0 ? node.path[index].replace(':', '://') : node.path[index]
				}
			})

			node.url = node.path.join('/').replace(':', '://')
			
			return node
		}
	}
}
</script>