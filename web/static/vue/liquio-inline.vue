<template>
<div class="reference">
	<div v-html="this.node.results.embed" v-if="this.node.choice_type != null" style="width: 160px; height: 50px;"></div>
	<div class="content">
		<router-link :to="'/' + node.url_key" class="reference-text"><span v-if="this.node.choice_type == null">#</span>{{ node.title }}</router-link>

		<router-link v-if="referencingNode" :to="'/' + referencingNode.url_key + '/references/' + node.url_key" class="reference-link"><i class="el-icon-caret-right" style="margin-left: 5px;"></i></router-link>
		<router-link v-else-if="referencesNode" :to="'/' + node.url_key + '/references/' + referencesNode.url_key" class="reference-link"><i class="el-icon-caret-right" style="margin-left: 5px;"></i></router-link>
	</div>
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
		margin: 0px 15px 15px 0px;
		font-size: 14px;
		text-align: left;
		background: rgba(255, 255, 255, 0.3);
		border: 1px solid rgba(255, 255, 255, 0.4);
		vertical-align: top;
	}

	.content {
		padding: 15px;
	}

	.reference-text {
		display: inline;
		color: #333;
	}

	.reference-link {
		display: inline;
		vertical-align: middle;
	}
</style>