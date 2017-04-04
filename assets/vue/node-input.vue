<template>
<div>
	<el-select v-if="title" v-model="choice_type" v-on:change="onPickUnit" size="mini">
		<el-option v-for="item in options" :key="item.value" v-bind:value="item.value" v-bind:label="item.text"></el-option>
	</el-select>
	<el-input v-else v-model="current_title" @keyup.native.enter="view" placeholder="Title" style="max-width: 800px;">
		<el-select slot="prepend" placeholder="Select" v-model="choice_type" style="width: 160px;">
			<el-option v-for="item in options" :key="item.value" v-bind:value="item.value" v-bind:label="item.text"></el-option>
		</el-select>
		<el-button slot="append" icon="caret-right" @click="view"></el-button>
	</el-input>
</div>
</template>

<script>
let utils = require('utils.js')

export default {
	props: ['id', 'ids', 'title', 'unit', 'isInverse', 'enableSearch', 'enableGroup', 'enableOthers'],
	data: function() {
		let self = this
		let title = (self.enableSearch === true || self.enableSearch == "true" ? this.$route.params.query : self.title) || '';

		return {
			current_title: title,
			choice_type: self.unit || null,
			onPickUnit: function(v) {
				self.$emit('pick-unit', v)
			},
			view: function(event) {
				if(self.title.length >= 3) {
					let clean_title = self.title.replace(/\-/, '').trim()
					let key = self.ids ? utils.getMultiKey(self.ids) : self.id
					if(self.choice_type == 'search') {
						let path = '/search/' + encodeURIComponent(clean_title)
						self.$router.push(path)
					} else {
						if(!self.id && !self.ids) {
							let path = '/' + utils.getKey(clean_title, self.choice_type)
							self.$router.push(path)
						} else {
							let input_key = encodeURIComponent(utils.getKey(clean_title, self.choice_type))
							let path = self.isInverse === true || self.isInverse == "true" ? '/' + input_key + '/references/' + key : '/' + key + '/references/' + input_key
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
			if(this.enableSearch !== false && this.enableSearch !== "false")
				opts.push({text: 'Search', value: 'search'})
			if(this.enableGroup !== false && this.enableGroup !== "false")
				opts.push({text: 'Meta', value: null, choice_type: 'meta'})
			if(this.enableOthers !== false && this.enableOthers !== "false") {
				opts = opts.concat(this.$store.state.units)
			}

			return opts
		}
	}
}
</script>