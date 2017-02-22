<template>
<div class="node">
	<router-link :to="'/' + node.url_key" class="link">
		<div class="content">{{ node.title }}</div>
		<div v-html="this.node.results.embed" v-if="this.node.choice_type != null" style="width: 100%; height: 50px;"></div>
	</router-link>

	<div class="references">
		<router-link
			:to="'/' + node.url_key + '/references/' + reference.url_key"
			class="link"
			v-for="reference in node.references"
			v-if="reference.reference_result && reference.reference_result.by_keys['relevance'] && reference.reference_result.by_keys['relevance'].embed"
		>
			<div class="content">{{ reference.title }}</div>
			<div style="font-size: 0px;">
				<div style="display: inline-block; width: 50%; font-size: 14px;">
					<div v-html="reference.reference_result.by_keys['for_choice'].embed" v-if="reference.reference_result.by_keys['for_choice'] && reference.reference_result.by_keys['for_choice'].embed" style="width: 100%; height: 35px;"></div>
				</div>
				<div style="display: inline-block; width: 50%; font-size: 14px;">
					<div v-html="reference.reference_result.by_keys['relevance'].embed" style="width: 100%; height: 35px;"></div>
				</div>
			</div>
		</router-link>
	</div>

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
	.node {
		display: inline-block;
		width: 100%;
		margin: 0 0 1em;
		font-size: 15px;
		text-align: left;
		vertical-align: top;
	}
	.node:hover {
		box-shadow: 0 2px 5px rgba(0, 0, 0, .25);
	}
	.link:hover {
		color: #337ab7;
	}

	.references {
		padding-right: 30px;
	}

	.content {
		padding: 10px;
		background: rgba(255, 255, 255, 0.6);
		word-wrap: break-word;
	}

	.references > .link > .content {
		font-size: 12px;
		padding: 5px;
		margin-top: 10px;
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