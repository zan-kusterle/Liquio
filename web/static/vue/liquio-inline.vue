<template>
<div class="reference">
	<router-link :to="'/' + node.url_key" class="main-link">
		<div v-html="this.node.results.embed" v-if="this.node.choice_type != null" style="width: 160px; height: 50px;"></div>
		<div class="content"><span v-if="this.node.choice_type == null">#</span>{{ node.title }}</div>
	</router-link>

	<router-link v-if="referencingNode" :to="'/' + referencingNode.url_key + '/references/' + node.url_key" class="reference-link"><i class="el-icon-edit" style="margin-left: 5px;"></i></router-link>
	<router-link v-else-if="referencesNode" :to="'/' + node.url_key + '/references/' + referencesNode.url_key" class="reference-link"><i class="el-icon-edit" style="margin-left: 5px;"></i></router-link>
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
		display: inline-block;
		width: 160px;
		margin: 10px;
		font-size: 15px;
		text-align: left;
		vertical-align: top;
	}
	.reference:hover {
		box-shadow: 0 2px 8px rgba(0, 0, 0, .33);
	}
	.main-link:hover {
		color: #337ab7;
	}

	.content {
		padding: 10px;
		background: white;
	}

	.reference-link {
		display: block;
		background: rgba(0, 0, 0, 0.1);
		text-align: center;
		font-size: 10px;
		padding-top: 8px;
		padding-bottom: 6px;
	}
</style>