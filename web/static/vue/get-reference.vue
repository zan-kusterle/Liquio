<template>
<div>
	<el-input placeholder="Reference title" v-model="title" v-if="node.title">
		<el-select slot="prepend" placeholder="Select" v-model="choice_type" style="width: 200px;">
			<el-option v-for="item in options" v-bind:value="item.value" v-bind:label="item.text"></el-option>
		</el-select>
		<el-button slot="append" icon="d-arrow-right" @click="view"></el-button>
	</el-input>

	<el-input placeholder="Title" v-model="title" v-else>
		<el-select slot="prepend" placeholder="Select" v-model="choice_type" style="width: 200px;">
			<el-option label=" " value="search"></el-option>
			<el-option label="Group" value=""></el-option>
			<el-option label="Probability" value="probability"></el-option>
			<el-option label="Quantity" value="quantity"></el-option>
			<el-option label="Time series" value="time_quantity"></el-option>
		</el-select>
		<el-button slot="append" icon="search" @click="view"></el-button>
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
				{ text: 'Time series', value: 'Time-Series' }
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