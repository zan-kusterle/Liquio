<template>
<div>
	<input v-model="title" label="Title" required style="display: inline-block; width: 300px;"></input>
	<select v-model="choice_type">
		<option v-for="option in options" v-bind:value="option.value">
			{{ option.text }}
		</option>
	</select>
	<button v-on:click="view">View reference</paper-button>
</div>
</template>

<script>
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
				let path = '/' + self.node.url_key + '/references/' + getUrlKey(self.title, self.choice_type)
				document.location = path
			}
		}
	}
}
</script>