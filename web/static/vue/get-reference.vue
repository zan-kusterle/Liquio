<template>
<div>
	<el-input placeholder="Variable description" v-model="title">
		<el-select slot="prepend" placeholder="Select" v-model="choice_type">
			<el-option v-for="item in options" v-bind:value="item.value" v-bind:label="item.text"></el-option>
		</el-select>
		<el-button slot="append" icon="search" @click="view">View reference</el-button>
	</el-input>
</div>
</template>

<script>


const getUrlKey = function(title, choice_type) {
	return (title + ' ' + choice_type).replace(/ /g, '-')
}

export default {
	props: ['node'],
	data: function() {
		let self = this
		return {
			title: '',
			choice_type: 'Probability',
			options: [
				{ text: 'Probability', value: 'Probability' },
				{ text: 'Quantity', value: 'Quantity' },
				{ text: 'Time Series', value: 'Time-Series' }
			],
			view: function(event) {
				if(self.title.length >= 3) {
					let path = '/' + self.node.url_key + '/references/' + getUrlKey(self.title, self.choice_type)
					self.$router.push(path)
				}
			}
		}
	}
}
</script>