<template>
<div class="node">
	<router-link :to="'/' + encodeURIComponent(node.key)" class="link">
		<div class="content">{{ node.title }}</div>
		<div v-html="this.node.default_unit.results.embed" v-if="this.node.default_unit != null" style="width: 100%; height: 50px; font-weight: bold;"></div>
	</router-link>

	<div class="references" v-if="node.references">
		<router-link
			:to="'/' + encodeURIComponent(node.key) + '/references/' + encodeURIComponent(reference.key)"
			class="link"
			v-for="reference in node.references"
			:key="reference.key"
			v-if="reference.reference_result && reference.reference_result.by_keys['relevance'] && reference.reference_result.by_keys['relevance'].embed"
		>
			<div class="content">{{ reference.title }}</div>
			<div style="font-size: 0px;">
				<div v-if="reference.reference_result.by_keys['for_choice'] && reference.reference_result.by_keys['for_choice'].embed" class="reference-result" style="border-bottom: 1px solid rgba(255, 255, 255, 0.9);">
					<div v-html="reference.reference_result.by_keys['for_choice'].embed" style="width: 100%; height: 30px;"></div>
				</div>
				<div class="reference-result">
					<div v-html="reference.reference_result.by_keys['relevance'].embed" style="width: 100%; height: 30px;"></div>
				</div>
			</div>
		</router-link>
	</div>

	<router-link v-if="referencingNode" :to="'/' + encodeURIComponent(referencingNode.key) + '/references/' + encodeURIComponent(node.key)" class="reference-link"><i class="el-icon-edit" style="margin-left: 5px;"></i></router-link>
	<router-link v-else-if="referencesNode" :to="'/' + encodeURIComponent(node.key) + '/references/' + encodeURIComponent(referencesNode.key)" class="reference-link"><i class="el-icon-edit" style="margin-left: 5px;"></i></router-link>
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
		margin: 10px 0px;
		font-size: 15px;
		text-align: left;
		vertical-align: top;
		border: 1px solid rgba(0, 0, 0, 0.12);
	}

	.link {
		display: block;
	}

	.link:hover {
		color: #337ab7;
	}

	.content {
		padding: 8px 10px;
		background: white;
		word-wrap: break-word;
	}

	.references > .link > .content {
		font-size: 12px;
		background: rgba(205, 235, 255, 0.3);
		border-top: 4px solid rgba(0, 0, 0, 0.5);
	}

	.reference-link {
		display: block;
		background: rgba(0, 0, 0, 0.1);
		text-align: center;
		font-size: 10px;
		padding-top: 8px;
		padding-bottom: 6px;
	}

	.reference-result {
		display: block;
		width: 100%;
		font-size: 13px;
		font-weight: bold;
		opacity: 0.9;
	}	
</style>