<template>
<div>
	<custom-header class="header"></custom-header>
	
	<div class="main-wrap" id="main-wrap">
		<div class="scrollable">
			<div class="main-container" style="padding-top: 50px; padding-bottom: 100px;">
				<slot>There is nothing here.</slot>
			</div>
		</div>
	</div>
</div>
</template>

<script>
import Vue from 'vue'
import CustomHeader from 'custom-header.vue'
import utils from 'shared/utils'

export default {
	components: {
		customHeader: CustomHeader
	}
}
</script>

<style lang="less">
.loading {
	font-size: 48px;
	color: #2a9fec;
}

p {
	margin: 0px;
}

.header {
	width: 100%;
	background-color: #2a9fec;
	text-align: left;
	height: 70px;
}

a {
	color: #333;
	text-decoration: none;
}

a:hover {
	color: #337ab7;
}

table {
	border-collapse: collapse
}

hr {
	margin: 20px 0px;
	border: 0;
	border-top: 1px solid #ddd;
}

.main-wrap {
	position: absolute;
	left: 0px;
	right: 0px;
	bottom: 0px;
	top: 70px;
	overflow-y: scroll;

	.scrollable {
		height: 100%;
	}

	.main-container {
		margin: 0px auto;
		max-width: 1200px;
		min-height: 100%;
		background-color: rgba(255, 255, 255, 0.85);
		border: 1px solid rgba(0, 0, 0, 0.05);
		border-top: 0px;
	}

	.main {
		margin: 0px;
		padding: 40px 20px;
		background-color: rgba(255, 255, 255, 1);
		box-shadow: 0px 0px 4px 0px #bbb;
	}

	.before, .after {
		padding: 30px;
	}

	.footer {
		border-top: 1px solid rgba(0, 0, 0, 0.12);
		padding: 20px;
	}

	.main-g {
		max-width: 1200px;
		margin: 0 auto;
	}
}
</style>
