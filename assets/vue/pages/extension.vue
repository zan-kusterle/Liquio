<template>
<div class="extension">
	<el-row :gutter="50">
		<el-col :span="8" class="get-extension">
			<el-button type="primary" size="large" @click="install"  v-if="!isInstalled">
				<img src="/images/google-chrome-icon.png" style="vertical-align: middle; width: 50px; opacity: 0.7;"></img>
				<span style="vertical-align: middle; margin-left: 10px; font-size: 22px;">Get free extension</span>
			</el-button>
			<div style="font-size: 13px; margin-top: 10px; margin-right: 15px;">
				<router-link to="/" style="color: #888;">return to Liquio</router-link>
			</div>
		</el-col>
		<el-col :span="16" class="features">
			<ul>
				<li>See relevant polls for any link or paragraph of text on the web.</li>
				<li>Spot unreliable, biased or fake news instantly.</li>
				<li>Fair democracy with zero moderation.</li>
				<li>Ability to choose the people you trust.</li>
			</ul>
		</el-col>
	</el-row>
</div>
</template>

<script>
import App from '../app.vue'

export default {
	components: {App},
	props: [],
	data: function() {
		return {
			isInstalled: chrome.app.isInstalled,
			install: function() {
				chrome.webstore.install()
			}
		}
	}
}
</script>

<style lang="less">
.extension {
	margin-top: 50px;
}

.features {
	text-align: left;

	ul {
		list-style: none;
		font-size: 16px;
		padding: 0px;

		li {
			margin: 15px 0px;
		}
	}
}

.get-extension {
	text-align: right;
	margin-top: 30px;
}
</style>
