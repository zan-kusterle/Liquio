<template>
	<div>
		<div class="header">
			<el-row>
				<el-col :span="12">
					<router-link to="/" class="logo"><img src="/images/logo.svg"></img></router-link>
				</el-col>
				<el-col :span="12">
					<div class="actions" v-if="$store.state.user">
						<router-link :to="'/identities/' + $store.state.user.username"><i class="el-icon-arrow-right" aria-hidden="true"></i>{{ $store.state.user.name }}</router-link>
						<a href="/api/logout" @click="$store.commit('logout')"><i class="el-icon-close" aria-hidden="true"></i> Logout</a>
					</div>
					<div class="actions" v-else>
						<a href="/login"><i class="el-icon-arrow-right" aria-hidden="true"></i> Login</a>
					</div>
				</el-col>
			</el-row>
		</div>
		
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
export default {
	data: function() {		
		return {}
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

	.logo {
		margin-top: 18px;
		margin-left: 30px;
		display: inline-block;
		vertical-align: middle;
		filter: brightness(0) invert(1);

		img {
			width: 100px;
		}
	}

	.actions {
		font-size: 14px;
		line-height: 35px;
		margin-right: 30px;
		margin-top: 20px;
		text-align: right;

		a {
			color: white;
			display: inline-block;
			text-decoration: none;
			margin: 0px 25px;
		}

		a:hover {
			text-decoration: none;
			color: white !important;
			opacity: 1;
		}
	}

	.not-in-trust-metric {
		line-height: 0px;
		display: block;
		font-size: 11px;
		color: white;
		font-weight: bold;
	}
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
