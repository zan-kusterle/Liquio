<template>
<div>
	<div class="vote-choices">
		<div class="vote-choice" v-for="vote in votes_by_time">
			<div class="row" style="text-align: left; margin: 0px; margin-bottom: -20px;">
				<i class="el-icon-circle-close" @click="remove(vote)"></i>
				<i class="el-icon-circle-check" v-if="vote.needs_save" @click="save(vote)" style="margin-left: 10px;"></i>
			</div>

			<div class="row" v-if="votes.length > 1">
				<el-date-picker v-model="vote.at_date" v-on:change="vote.needs_save = true" type="date" class="datepicker" :clearable="false"></el-date-picker>
			</div>

			<div class="row" v-if="vote.unit_type == 'spectrum'">
				<p class="spectrum-side">{{ results.negative }}</p>
				<div class="range">
					<el-slider v-model="vote.choice" v-on:change="vote.needs_save = true"></el-slider>
				</div>
				<p class="spectrum-side">{{ results.positive }}</p>
			</div>
			<div class="row" v-else>
				<div class="numeric">
					<el-input v-model="vote.choice" v-on:change="vote.needs_save = true"></el-input>
				</div>
			</div>

			<div class="row" style="font-size: 24px;" v-if="vote.unit_type == 'spectrum'">{{ Math.round(vote.choice) }}%</div>
			<div class="row" style="font-size: 20px;" v-else>{{ Math.round(vote.choice) }}</div>
		</div>
		<div class="new-choice" @click="new_vote">
			<p v-if="votes.length == 0"><i class="el-icon-plus" style="margin-right: 10px;"></i> Cast your vote</p>
			<p v-else-if="!single"><i class="el-icon-plus" style="margin-right: 10px;"></i> Cast vote for another date</p>
		</div>
	</div>

	<div class="vote-container open">
		<div class="votes" v-if="results && results.contributions_by_identities">
			<p class="ui-title">{{ Math.round(results.turnout_ratio * 100) }}% turnout</p>
			<div class="contribution" v-for="(identity_data, identity_id) in results.contributions_by_identities" :key="identity_id">
				<div class="weight">
					<el-progress :text-inside="true" :stroke-width="24" :percentage="Math.round(identity_data.contributions[0].weight * 100)"></el-progress>
				</div>
				<div v-if="identity_data.embeds.by_time" v-html="identity_data.embeds.by_time" class="graph-choice"></div>
				<div v-html="identity_data.contributions[identity_data.contributions.length - 1].embeds.value" class="choice"></div>
				<div class="username"><router-link :to="'/identities/' + identity_data.contributions[0].identity_username">{{ identity_data.contributions[0].identity_username }}</router-link></div>
				<div class="date">{{ moment(new Date(identity_data.contributions[identity_data.contributions.length - 1].datetime)).fromNow() }}</div>
			</div>
		</div>
	</div>
</div>
</template>

<script>
import Vue from 'vue'
import ElementUI from 'element-ui';
import locale from 'element-ui/lib/locale/lang/en'
var _ = require('lodash')

Vue.use(ElementUI, {locale})

export default {
	props: ['single', 'votes', 'results'],
	data: function() {
		let self = this
		
		return {
			moment: require('moment'),
			new_vote: function() {
				let unit = self.votes.length > 0 ? self.votes[0].unit : self.results.value
				let unit_type = self.votes.length > 0 ? self.votes[0].unit_type : self.results.type
				let date = new Date()
				while(_.some(self.votes, (vote) => vote.at_date.toDateString() === date.toDateString())) {
					date.setDate(date.getDate() + 1)
				}
				self.votes.push({
					unit: unit,
					unit_type: unit_type,
					choice: unit_type == 'spectrum' ? 50 : 0,
					at_date: date,
					needs_save: true
				})
			},
			save: function(vote) {
				let choice = parseFloat(vote.choice)
				if(vote.unit_type == 'spectrum')
					choice /= 100
				this.$emit('set', {unit: vote.unit, at_date: vote.at_date, choice: choice})
				vote.needs_save = false
			},
			remove: function(vote) {
				let index = self.votes.indexOf(vote)
				if(index >= 0) self.votes.splice(index, 1)
				this.$emit('unset', {unit: vote.unit, at_date: vote.at_date})
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
	.graph-choice {
		height: 40px;
		width: 100px;
		display: inline-block;
		vertical-align: middle;
		margin-left: 30px;
		margin-right: -20px;
	}
	.choice {
		height: 40px;
		width: 140px;
		display: inline-block;
		vertical-align: middle;
		margin-left: 30px;
		font-weight: bold;
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