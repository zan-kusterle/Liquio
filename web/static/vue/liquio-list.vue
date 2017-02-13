<template>
	
<div>
	<!--
	<p class="heading">
		<a href="relevant" class="sort active">relevant</a>
		<a href="top" class="sort">top</a>
		<a href="new" class="sort">new</a>
		<a href="most-certain" class="sort">most certain</a>
		<a href="least-certain" class="sort">least certain</a>
	</p>
	-->

	<el-row class="references" v-if="referencingNode != null && referencingNode.choice_type == 'probability'">
		<el-col :span="12">
			<h3 class="pole-heading">Negative</h3>
		
			<div class="pole-list">
				<div class="reference-a" v-for="node in nodes">
					<liquio-inline v-if="node.reference_result.by_keys['for_choice'].mean <= 0.5" v-bind:node="node" v-bind:referencing-node="referencingNode" v-bind:references-node="referencesNode" style="display: block; text-align: left;"></liquo-inline>
				</div>
			</div>
		</el-col>
		<el-col :span="12">
			<h3 class="pole-heading">Positive</h3>
		
			<div class="pole-list">
				<div class="reference-a" v-for="node in nodes">
					<liquio-inline v-if="node.reference_result.by_keys['for_choice'].mean > 0.5" v-bind:node="node" v-bind:referencing-node="referencingNode" v-bind:references-node="referencesNode" style="display: block; text-align: left;"></liquo-inline>
				</div>
			</div>
		</el-col>
	</el-row>
	<div class="references-list" v-else>
		<liquio-inline v-for="node in nodes" v-bind:node="node" v-bind:referencing-node="referencingNode" v-bind:references-node="referencesNode" style="display: block; text-align: left;"></liquo-inline>
	</div>
</div>
</template>

<script>
import LiquioInline from '../vue/liquio-inline.vue'

export default {
	props: ['nodes', 'referencingNode', 'referencesNode'],
	components: { LiquioInline },
	data: function() {
		return {}
	}
}
</script>

<style scoped>
	.references {
		text-align: inherit;
	}

	.references, .pole {
		padding: 0 15px;
	}
	.references, .pole, .pole-heading {
		text-align: left;
		font-size: 18px;
		font-weight: normal;
		margin: 0px;
		margin-bottom: 15px;
	}

	.references-list {
		padding: 0px 20px;
	}

	.references-list, .reference-text {
			width: initial !important;
		}

	.reference-a:hover {
		color: inherit;
	}

	.reference-a, .reference-text {
		color: #4aa5f3 !important;
	}

	.reference {
		display: inline-block;
		margin: 12px 0px;
		font-size: 0px;
		background: rgba(255, 255, 255, 0.75);
		margin-right: 25px;
	}


	.reference, .reference-text {
		font-size: 16px;
		width: calc("100% - 90px");
		line-height: 16px;
		min-width: 200px;
		text-align: left;
	}

	.reference, .reference-score {
		height: 40px;
	}

	.reference-text {
		color: #333;
		display: inline-block;
		padding: 0px 20px;
		vertical-align: middle;
	}

	.reference-score {
		font-weight: bold;
		display: inline-block;
		text-align: center;
		font-size: 13px;
		color: #333;
		vertical-align: middle;
		width: 80px;
		height: 40px;
		line-height: 42px;
	}
</style>