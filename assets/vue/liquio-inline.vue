<template>
<div class="node">
	<div v-if="node.path[0].startsWith('http:') || node.path[0].startsWith('https:')" class="webpage-link">
		<a :href="'/page/' + encodeURIComponent(node.path.join('/').replace(':', '://'))" target="_blank"><img alt="Visit with Liquio" src="/images/icon.svg" style="width: 20px; vertical-align: middle; margin-right: 20px; -webkit-filter: brightness(0%); opacity: 0.5;"></img></a>
		<a :href="node.path.join('/').replace(':', '://')" target="_blank">Visit webpage <i class="el-icon-arrow-right"></i></a>
	</div>
	<router-link :to="'/v/' + encodeURIComponent(node.key)" class="link">
		<div class="content">
			<span>{{ node.path.join('/').replace(/-/g, ' ') }}</span>
			<router-link v-if="referencingNode" :to="'/v/' + encodeURIComponent(referencingNode.key) + '/references/' + encodeURIComponent(node.key)" class="reference-link"><i class="el-icon-edit" style="margin-left: 5px;"></i></router-link>
			<router-link v-else-if="referencesNode" :to="'/v/' + encodeURIComponent(node.key) + '/references/' + encodeURIComponent(referencesNode.key)" class="reference-link"><i class="el-icon-edit" style="margin-left: 5px;"></i></router-link>
		</div>
		<div v-html="this.node.default_unit.embeds.value" v-if="this.node.default_unit && this.node.default_unit.embeds" style="width: 100%; font-size: 0;"></div>
	</router-link>
	
	<div class="references" v-if="node.references">
		<router-link
			:to="'/v/' + encodeURIComponent(node.key) + '/references/' + encodeURIComponent(reference.key)"
			class="link"
			v-for="reference in node.references"
			:key="reference.key"
			v-if="reference.reference_result && reference.reference_result.by_keys['relevance'] && reference.reference_result.by_keys['relevance'].embed"
		>
			<div class="content">{{ reference.path.join('/').replace(/-/g, ' ') }}</div>
			<div style="font-size: 0px;">
				<div class="reference-result">
					<div v-html="reference.reference_result.by_units['relevance'].embed" style="width: 100%; height: 30px;"></div>
				</div>
			</div>
		</router-link>
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

<style scoped lang="less">
.node {
	display: inline-block;
	width: 100%;
	margin: 15px 0px;
	font-size: 20px;
	text-align: left;
	background: #f0f0f0;
	vertical-align: top;
	border-radius: 2px;
}

.link {
	display: block;
}

.link:hover {
	color: #337ab7;
}

.content {
	padding: 15px 25px;
	word-wrap: break-word;
}

.references > .link > .content {
	font-size: 12px;
	background: rgba(205, 235, 255, 0.3);
	border-top: 4px solid rgba(0, 0, 0, 0.5);
}

.reference-link {
	font-size: 15px;
	margin-left: 10px;
}

.reference-result {
	display: block;
	width: 100%;
	font-size: 13px;
	font-weight: bold;
	opacity: 0.9;
}

.webpage-link {
	font-size: 16px;
	width: 100%;
	background-color: #ddd;
	display: block;
	text-align: center;
	padding: 10px 0px;

	i {
		vertical-align: middle;
		margin-left: 5px;
		font-size: 20px;
		color: #555;
	}
}
</style>