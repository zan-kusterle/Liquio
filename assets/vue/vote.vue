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

			<div class="row" v-if="vote.unit_type == 'spectrum'">
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

			<div class="row" style="font-size: 24px;" v-if="vote.unit_type == 'spectrum'">{{ Math.round(vote.choice) }}%</div>
			<div class="row" style="font-size: 20px;" v-else>{{ Math.round(vote.choice) }}</div>
		</div>
		<div class="new-choice" @click="new_vote">
			<p v-if="votes.length == 0"><i class="el-icon-plus"></i> Cast vote</p>
			<p v-else><i class="el-icon-plus"></i> Cast vote for another date</p>
		</div>
	</div>

	<div class="vote-container open">
		<div class="votes" v-if="results && results.contributions && results.contributions.length > 0">
			<p class="ui-title">{{ Math.round(results.turnout_ratio * 100) }}% turnout</p>
			<div class="contribution" v-for="contribution in results.contributions" :key="contribution.username">
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
	props: ['votes', 'results'],
	data: function() {
		let self = this
		
		return {
			moment: require('moment'),
			new_vote: function() {
				let unit = self.votes.length > 0 ? self.votes[0] : {unit_type: 'spectrum', value: 'True-False'}
				let choice = unit.unit_type == 'spectrum' ? 50 : 0
				self.votes.push({choice: choice, unit: unit.value, unit_type: unit.unit_type, at_date: new Date()})
			},
			save: function(vote) {
				let choice = parseFloat(vote.choice)
				if(vote.unit_type == 'spectrum')
					choice /= 100
				this.$emit('set', {key: vote.key, unit: vote.unit, at_date: vote.at_date, choice: choice})
			},
			remove: function(vote) {
				this.$emit('unset', {key: vote.key, unit: vote.unit, at_date: vote.at_date})
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
			background-color: #eee;
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