<template>
<div>
	<div class="vote-choices">
		<div class="vote-choice" v-for="(vote, index) in votes_by_time">
			<div class="row" style="text-align: left; margin: 0px; margin-bottom: -20px;">
				<i class="el-icon-circle-close" @click="votes.splice(index, 1); remove(vote)"></i>
				<i class="el-icon-circle-check" @click="save(vote)"></i>
			</div>

			<div class="row" v-if="votes.length > 1">
				<el-date-picker v-model="vote.at_date" type="date" class="datepicker" :clearable="false"></el-date-picker>
			</div>

			<div class="row" v-if="node.default_unit && node.default_unit.type == 'spectrum'">
				<p class="spectrum-side">False</p>
				<div class="range">
					<el-slider v-model="vote.choice"></el-slider>
				</div>
				<p class="spectrum-side">True</p>
			</div>
			<div class="row" v-else>
				<div class="numeric">
					<el-input v-model="vote.choice"></el-input>
				</div>
			</div>

			<div class="row" style="font-size: 24px;" v-if="node.default_unit && node.default_unit.type == 'spectrum'">{{ Math.round(vote.choice) }}%</div>
			<div class="row" style="font-size: 20px;" v-else>{{ Math.round(vote.choice) }}</div>
		</div>
		<div class="new-choice" @click="votes.push({choice: 50, at_date: new Date()})">
			<p v-if="votes.length == 0"><i class="el-icon-plus"></i> Cast vote</p>
			<p v-else><i class="el-icon-plus"></i> Cast vote for another date</p>
		</div>
	</div>

	<div class="vote-container open">
		<div class="votes" v-if="node.default_unit && node.default_unit.results && node.default_unit.results.contributions.length > 0">
			<p class="ui-title">{{ Math.round(node.default_unit.results.turnout_ratio * 100) }}% turnout</p>
			<div class="contribution" v-for="contribution in node.default_unit.results.contributions" :key="contribution.username">
				<div class="weight">
					<el-progress :text-inside="true" :stroke-width="24" :percentage="Math.round(contribution.weight * 100)"></el-progress>
				</div>
				<div class="choice" v-html="contribution.embed" style="height: 40px;"></div>
				<div class="username"><router-link :to="'/identities/' + contribution.identity_username">{{ contribution.identity_username }}</router-link></div>
				<div class="date">{{ moment(new Date(contribution.datetime)).fromNow() }}</div>
			</div>
		</div>
	</div>
</div>
</template>

<script>
import Vue from 'vue'
import ElementUI from 'element-ui';
import locale from 'element-ui/lib/locale/lang/en'
let utils = require('utils.js')
var _ = require('lodash')

Vue.use(ElementUI, {locale})

export default {
	props: ['node'],
	data: function() {
		let self = this

		let votes = this.node && this.node.own_default_unit ? this.node.own_default_unit.results.contributions : []
		votes = _.map(votes, (v) => {
			if(self.node.default_unit.type == 'spectrum')
				v.choice *= 100
			v.at_date = new Date(v.at_date)
			return v
		})
		
		return {
			votes: votes,
			moment: require('moment'),
			save: function(vote) {
				if(self.node && self.node.default_unit) {
					let choice = parseFloat(vote.choice)
					if(self.node.default_unit.type == 'spectrum')
						choice /= 100
					self.$store.dispatch('setVote', {node: self.node, unit: self.node.default_unit.value, at_date: vote.at_date, choice: choice})
				}
			},
			remove: function(vote) {
				if(self.node && self.node.default_unit) {
					self.$store.dispatch('unsetVote', {node: self.node, unit: self.node.default_unit.value, at_date: vote.at_date})
				}
			}
		}
	},
	computed: {
		votes_by_time: function() {
			return _.sortBy(this.votes, (v) => v.at_date)
		}
	}
}
</script>

<style lang="less">
	.ui-title {
		margin-top: 50px;
		margin-bottom: 10px;
		font-weight: bold;
	}

	.title {
		display: block;
		margin: 10px 0px;
		font-size: 26px;
		font-weight: normal;
		color: #333;
		opacity: 1;
		word-wrap: break-word;
	}

	.contribution {
		text-align: left;
		padding: 10px 30px
	}
	
	.weight {
		width: 350px;
		display: inline-block;
	}
	.choice {
		height: 40px;
		width: 100px;
		display: inline-block;
		vertical-align: middle;
		margin-left: 30px;
	}
	.username {
		width: 150px;
		display: inline-block;
		margin-left: 25px;
	}
	.date {
		width: 120px;
		display: inline-block;
		margin-left: 10px;
	}

	.spectrum-side {
		display: inline-block;
		font-weight: bold;
		text-transform: lowercase;
	}

	.score-box {
		display: inline-block;
		margin: 20px;
		width: 250px;
		padding-top: 10px;
		padding-bottom: 20px;
		text-align: center;
		border: 1px solid rgba(0, 0, 0, 0.1);
		background-color: #ddd;
		vertical-align: top;

		.el-input__inner {
			background: transparent;
			border-color: #333;
			border-radius: 2px;
			color: black;
		}
		.el-input__icon {
			color: black;
		}
	}

	.vote-choices {
		width: 100%;
		text-align: center;

		.own-contribution-ratio {
			margin-top: 20px;
			font-size: 18px;
			display: inline;
		}

		.new-choice {
			margin-top: 30px;
		}

		.vote-choice {
			background-color: #d8d8d8;
			padding: 15px 20px;
			width: 600px;
			margin: 20px auto;
			display: block;

			.row {
				margin: 10px 0px;
			}

			.range {
				width: 250px;
				display: inline-block;
				vertical-align: middle;
				margin: 0 30px;
			}

			.numeric {
				display: inline-block;
				width: 220px;

				.el-input__inner {
					background-color: rgba(0, 0, 0, 0.2);
					border: none;
					text-align: center;
					font-weight: bold;
				}
			}

			.action {
				font-size: 20px;
			}
		}
	}

	.choose-units {
		margin-top: -2px;

		.el-input__inner {
			text-align: center;
			padding-left: 30px;
			border-radius: 0px;
			border-top: none;
		}
	}

	.number {
		font-size: 28px;
		line-height: 24px;
		display: inline-block;
		vertical-align: middle;
		width: 130px;
	}

	.subtext {
		font-weight: bold;
		font-size: 12px;
	}

	.vote-links {
		margin-top: 10px;
		border-top: 1px solid rgba(0, 0, 0, 0.1);
		padding-top: 2px;
	}

	.vote-action {
		width: 46%;
		font-size: 13px;
		display: inline-block;
		text-align: center;
		line-height: 30px;
	}
</style>