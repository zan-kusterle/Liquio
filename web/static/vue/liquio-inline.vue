<template>
<div class="reference">
	<div v-html="this.node.results.embed" v-if="this.node.choice_type != null" style="display: inline-block; vertical-align: middle; width: 120px; height: 45px;"></div>
	<div style="display: inline-block; width: 120px;" v-else></div>
	<router-link :to="'/' + node.url_key" class="reference-text"><span v-if="this.node.choice_type == null">#</span>{{ node.title }}</router-link>

	<router-link v-if="referencingNode" :to="'/' + referencingNode.url_key + '/references/' + node.url_key" class="reference-link"><i class="el-icon-caret-right" style="margin-left: 10px;"></i></router-link>
	<router-link v-else-if="referencesNode" :to="'/' + node.url_key + '/references/' + referencesNode.url_key" class="reference-link"><i class="el-icon-caret-right" style="margin-left: 10px;"></i></router-link>
</div>
</template>

<script>
export default {
	props: ['node', 'referencingNode', 'referencesNode'],
	data: function() {
		return {}
	}
}
</script>

<style scoped>
	.reference {
		display: block;
		width: 95%;
		margin: 10px 0px;
		font-size: 14px;
		text-align: left;
		background: rgba(255, 255, 255, 0.6);
	}

	.reference-text {
		color: #333;
		display: inline-block;
		vertical-align: middle;
		padding: 10px;
		width: calc(100% - 190px);
	}

	.reference-link {
		display: inline-block;
		vertical-align: middle;
		width: 30px;
	}
</style>