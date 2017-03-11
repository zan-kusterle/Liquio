<template>
<div>
	<el-button type="text" @click="dialogVisible = !dialogVisible">Options</el-button>

	<el-dialog title="Options" v-model="dialogVisible">
		<div class="block">
			<p class="demonstration">Sort</p>
			<el-select slot="prepend" placeholder="Select" v-model="sortDirection" style="width: 100px;">
				<el-option value="most" label="Most"></el-option>
				<el-option value="least" label="Least"></el-option>
			</el-select>
			<el-select slot="prepend" placeholder="Select" v-model="sort" style="width: 150px;">
				<el-option value="top" label="relevant"></el-option>
				<el-option value="new" label="new"></el-option>
				<el-option value="variance" label="controversial"></el-option>
			</el-select>
		</div>

		<div class="block">
			<p class="demonstration">View for specific date</p>
			<el-date-picker type="date" placeholder="Pick a day" v-model="datetime"></el-date-picker>
		</div>

		<div class="block">
			<p class="demonstration">Trust metric URL</p>
			<el-input type="url"></el-input>
		</div>

		<div class="block">
			<p class="demonstration">Expecting at least {{ minimum_turnout }}% turnout.</p>
			<el-slider v-model="minimum_turnout"></el-slider>
		</div>

		<div class="block">
			<p class="demonstration">Votes will lose half remaining power every {{ vote_weight_halving_days }} days.</p>
			<el-slider v-model="vote_weight_halving_days" max="1000"></el-slider>
		</div>

		<div class="block">
			<p class="demonstration">Include {{ soft_quorum_t }} fake votes with score 0 when calculating reference relevance.</p>
			<el-slider v-model="soft_quorum_t"></el-slider>
		</div>

		<div class="block">
			<p class="demonstration">At least {{ minimum_relevance_score }}% relevance score to include reference.</p>
			<el-slider v-model="minimum_relevance_score"></el-slider>
		</div>

		<span slot="footer" class="dialog-footer">
			<el-button @click="dialogVisible = false">Cancel</el-button>
			<el-button type="primary" @click="dialogVisible = false">Confirm</el-button>
		</span>
	</el-dialog>
</div>
</template>

<script>
export default {
	props: ['opts'],
	data: function() {
		return {
			dialogVisible: false,
			datetime: new Date(),
			minimum_turnout: 50,
			vote_weight_halving_days: 1000,
			soft_quorum_t: 0,
			minimum_relevance_score: 50,
			sort: 'top',
			sortDirection: 'most'
		}
	}
}
</script>

<style scoped>
	.block {
		margin-bottom: 30px;
	}

	.demonstration {
		display: inline;
	}
</style>