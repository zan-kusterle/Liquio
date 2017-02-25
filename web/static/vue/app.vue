<template>
	<div>
		<div class="header">
			<div class="header-contents">
				<div class="pure-g">
					<div style="float: left;">
						<router-link to="/" class="logo"><img src="/images/logo.svg"></router-link>
						<h3 class="tagline">A liquid democracy where anyone can vote on anything.</h3>
					</div>

					<div style="float: right;">
						<div class="actions" v-if="$store.state.user">
							<router-link :to="'/identities/' + $store.state.user.username"><i class="el-icon-arrow-right" aria-hidden="true"></i>{{ $store.state.user.name }}</router-link>
							<a href="/api/logout" @click="$store.commit('logout')"><i class="el-icon-close" aria-hidden="true"></i> Logout</a>
						</div>
						<div class="actions" v-else>
							<a href="/login"><i class="el-icon-arrow-right" aria-hidden="true"></i> Login</a>
						</div>
					</div>
				</div>
			</div>
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
		this.$store.dispatch('fetchCurrentUser')
		return {}
	}
}
</script>
