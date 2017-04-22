<template>
<div>
	<div class="header">
		<el-row>
			<el-col :span="12">
				<router-link to="/" class="logo"><img src="/images/logo.svg"></img></router-link>
			</el-col>
			<el-col :span="12">
				<div class="actions" v-if="$store.state.user">
					<a @click="dialogVisible = !dialogVisible"><i class="el-icon-setting"></i></a>
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

	<el-dialog title="Options" v-model="dialogVisible">
		<div class="block">
			<p class="demonstration">Sort</p>
			<el-select slot="prepend" placeholder="Select" v-model="sortDirection" style="width: 100px;">
				<el-option value="most" label="Most"></el-option>
				<el-option value="least" label="Least"></el-option>
			</el-select>
			<el-select slot="prepend" placeholder="Select" v-model="sort" style="width: 150px;">
				<el-option value="top" label="relevant"></el-option>
				<el-option value="new" label="new"></el-option>
				<el-option value="variance" label="controversial"></el-option>
			</el-select>
		</div>

		<div class="block">
			<p class="demonstration">View for specific date</p>
			<el-date-picker type="date" placeholder="Pick a day" v-model="datetime"></el-date-picker>
		</div>

		<div class="block">
			<p class="demonstration">Trust metric URL</p>
			<el-input type="url"></el-input>
		</div>

		<div class="block">
			<p class="demonstration">Expecting at least {{ minimum_turnout }}% turnout.</p>
			<el-slider v-model="minimum_turnout"></el-slider>
		</div>

		<div class="block">
			<p class="demonstration">Votes will lose half remaining power every {{ vote_weight_halving_days }} days.</p>
			<el-slider v-model="vote_weight_halving_days" max="1000"></el-slider>
		</div>

		<div class="block">
			<p class="demonstration">Include {{ soft_quorum_t }} fake votes with score 0 when calculating reference relevance.</p>
			<el-slider v-model="soft_quorum_t"></el-slider>
		</div>

		<div class="block">
			<p class="demonstration">At least {{ minimum_relevance_score }}% relevance score to include reference.</p>
			<el-slider v-model="minimum_relevance_score"></el-slider>
		</div>

		<span slot="footer" class="dialog-footer">
			<el-button @click="dialogVisible = false">Cancel</el-button>
			<el-button type="primary" @click="dialogVisible = false">Confirm</el-button>
		</span>
	</el-dialog>
</div>
</template>

<script>

export default {
	data: function() {		
		return {
			dialogVisible: false,
			datetime: new Date(),
			minimum_turnout: 50,
			vote_weight_halving_days: 1000,
			soft_quorum_t: 0,
			minimum_relevance_score: 50,
			sort: 'top',
			sortDirection: 'most'
		}
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
