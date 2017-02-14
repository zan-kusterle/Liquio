<template>
<div class="reference">
	<div v-html="this.node.embed_html" v-if="this.node.choice_type != null" style="display: inline-block; vertical-align: middle; width: 120px; height: 45px;"></div>
	
	<div class="content">
		<router-link :to="'/' + node.url_key" class="reference-text"><span v-if="this.node.choice_type == null">#</span>{{ node.title }}</router-link>
		
		<router-link v-if="referencingNode" :to="'/' + referencingNode.url_key + '/references/' + node.url_key" class="reference-link"><i class="el-icon-caret-right" style="margin-left: 10px;"></i></router-link>
		<router-link v-else-if="referencesNode" :to="'/' + node.url_key + '/references/' + referencesNode.url_key" class="reference-link"><i class="el-icon-caret-right" style="margin-left: 10px;"></i></router-link>
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
		margin: 12px 0px;
		font-size: 16px;
		margin-right: 25px;
		text-align: left;
	}

	.content {
		display: inline-block;
		background: rgba(255, 255, 255, 0.75);
		min-width: 200px;
		padding-right: 20px;
		margin-left: -5px;
		height: 45px;
		line-height: 45px;
		vertical-align: middle;
	}

	.reference-text {
		color: #333;
		display: inline-block;
		margin-left: 20px;
		vertical-align: middle;
	}

	.reference-link {
		vertical-align: middle;
	}
</style>