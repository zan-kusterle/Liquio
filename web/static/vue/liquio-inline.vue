<template>
<div class="reference">
	<div v-html="this.node.embed_html" v-if="this.node.choice_type != null" style="display: inline-block; vertical-align: middle; width: 120px; height: 45px;"></div>
	
	<router-link :to="'/' + node.url_key"><span v-if="this.node.choice_type == null">#</span>{{ node.title }}</router-link>
	
	<router-link v-if="referencingNode" :to="'/' + referencingNode.url_key + '/references/' + node.url_key" style="float: right;"><i class="el-icon-caret-right" style="margin-left: 10px;"></i></router-link>
	<router-link v-else-if="referencesNode" :to="'/' + node.url_key + '/references/' + referencesNode.url_key" style="float: right;"><i class="el-icon-caret-right" style="margin-left: 10px;"></i></router-link>
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