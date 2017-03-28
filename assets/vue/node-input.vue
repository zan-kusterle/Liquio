<template>
<div>
	<el-select v-if="title" v-model="choice_type" size="mini">
		<el-option v-for="item in options" :key="item.value" v-bind:value="item.value" v-bind:label="item.text"></el-option>
	</el-select>
	<el-input v-else v-model="current_title" @keyup.native.enter="view" placeholder="Title" style="max-width: 800px;">
		<el-select slot="prepend" placeholder="Select" v-model="choice_type" style="width: 120px;">
			<el-option v-for="item in options" :key="item.value" v-bind:value="item.value" v-bind:label="item.text"></el-option>
		</el-select>
		<el-button slot="append" icon="caret-right" @click="view"></el-button>
	</el-input>
</div>
</template>

<script>
let utils = require('utils.js')

export default {
	props: ['id', 'ids', 'title', 'isInverse', 'enableSearch', 'enableGroup', 'enableOthers'],
	data: function() {
		let self = this
		let title = (self.enableSearch === true || self.enableSearch == "true" ? this.$route.params.query : self.title) || '';

		return {
			current_title: title,
			choice_type: '',
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
				opts.push({text: 'List', value: ''})
			if(this.enableOthers !== false && this.enableOthers !== "false") {
				opts.push({text: 'True - False', value: 'True', choice_type: 'probability'})
				opts.push({text: 'Count', value: 'Count', choice_type: 'quantity'})
				opts.push({text: 'Fact - Lie', value: 'Fact', choice_type: 'probability'})
				opts.push({text: 'Reliable - Unreliable', value: 'Reliable', choice_type: 'probability'})
				opts.push({text: 'Temperature (°C)', value: 'Temperature', choice_type: 'quantity'})
				opts.push({text: 'US Dollars (USD)', value: 'USD', choice_type: 'quantity'})
				opts.push({text: 'Length (m)', value: 'Length', choice_type: 'quantity'})
				opts.push({text: 'Approve - Disapprove', value: 'Approve', choice_type: 'probability'})
				opts.push({text: 'Agree - Disagree', value: 'Agree', choice_type: 'probability'})
			}

			this.choice_type = opts[0].value

			return opts
		}
	}
}
</script>