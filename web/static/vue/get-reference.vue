<template>
<div>
	<el-input placeholder="Title" v-model="title" @keyup.native.enter="view" style="max-width: 800px;">
		<el-select slot="prepend" placeholder="Select" v-model="choice_type" style="width: 120px;">
			<el-option v-for="item in options" v-bind:value="item.value" v-bind:label="item.text"></el-option>
		</el-select>
		<el-button slot="append" icon="caret-right" @click="view"></el-button>
	</el-input>
</div>
</template>

<script>
let utils = require('utils.js')

export default {
	props: ['node', 'nodes'],
	data: function() {
		let ns = this.nodes ? this.nodes : (this.node ? [this.node]: [])
		let self = this
		let title = this.$route.params.query || ''
		return {
			title: title,
			choice_type: '',
			key: ns.length == 0 ? null : utils.getMultiKey(ns),
			view: function(event) {
				if(self.title.length >= 3) {
					if(self.choice_type == 'search') {
						let path = '/search/' + encodeURIComponent(self.title)
						self.$router.push(path)
					} else {
						if(self.key == null || self.$route.name == 'search') {
							let path = '/' + utils.getKey(self.title, self.choice_type)
							self.$router.push(path)
						} else {
							let path = '/' + self.key + '/references/' + utils.getKey(self.title, self.choice_type)
							self.$router.push(path)
						}
					}
				}
			}
		}
	},
	computed: {
		options: function() {
			let opts = []
			if(this.key == null || this.$route.name == 'search') {
				opts.push({text: 'Search', value: 'search'})
				opts.push({text: 'Group', value: ''})
			}
			opts.push({text: 'Probability', value: 'Probability'})
			opts.push({text: 'Quantity', value: 'Quantity'})
			opts.push({text: 'Time series', value: 'Time-Series'})

			this.choice_type = opts[0].value

			return opts
		}
	}
}
</script>