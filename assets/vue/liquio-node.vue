<template>
<div>
	<div v-if="node">
		<h1 class="title" style="vertical-align: middle;">{{ title || node.title || 'Everything' }}</h1>
		<a v-if="!title && node.title && node.title.startsWith('https://')" :href="node.key" target="_blank" class="title" style="vertical-align: middle;">View content</a>

		<div class="score-container">
			<div>
				<div v-if="this.node.choice_type != null || resultsKey == 'relevance'">
					<div v-html="this.node.results.embed" style="width: 300px; height: 120px; display: block; margin: 0px auto; font-size: 36px;"></div>
					<div style="width: 100%; display: block;" class="choose-units">
						<el-select v-model="unit_value" size="mini">
							<el-option-group v-for="unit_group in units" :key="unit_group.value_type" :label="unit_group.label">
								<el-option v-for="unit in unit_group.children" :key="unit.value" :label="unit.label" :value="unit.value"></el-option>
							</el-option-group>
						</el-select>
					</div>
				</div>
			</div>

			<div v-if="(node.choice_type != null || node.filter_key == 'relevance')">
				<div class="score-box" v-bind:style=" {'background-color': get_color(vote.choice / 100)}" v-for="(vote, index) in votes">
					<div v-if="first_node.unit_type == 'probability'">
						<div class="range">
							<el-slider v-model="vote.choice" style="width: 90%; margin: 0 auto;" />
						</div>
						<div class="number">
							<span class="number-value">{{ Math.round(vote.choice) }}</span><span class="percent">%</span>
						</div>
					</div>
					<div v-else>
						<div class="number">
							<input class="number-value" v-model="vote.choice" style="width: 140px; text-align: center;"></input>
						</div>
					</div>

					<div style="text-align: left; margin-top: -23px; margin-left: 10px;">
						<el-tooltip class="item" effect="dark" content="Remove this choice" placement="top">
							<i @click="votes.splice(index, 1)" class="el-icon-circle-close"></i>
						</el-tooltip>
					</div>
					<div style="text-align: right; margin-top: -24px; margin-right: 10px;">
						<el-tooltip class="item" effect="dark" content="Set specific date" placement="top">
							<i @click="vote.at_date_open = !vote.at_date_open" class="el-icon-date" style="margin-left: 5px;"></i>
						</el-tooltip>
					</div>

					<el-date-picker v-if="vote.at_date_open" v-model="vote.at_date" type="date" placeholder="Pick a day" class="datepicker" style="margin-top: 15px;"></el-date-picker>
				</div>
				<div v-if="votes.length == 0">
					<p>You have no vote</p>
				</div>

				<a @click="add_vote" style="display: block;"><i class="el-icon-document"></i> New vote</a>

				<a class="vote-action" v-on:click="set"><i class="el-icon-circle-check" style="margin-right: 6px;"></i> Save</a>
				<div class="subtext">{{ Math.round(this.first_node.own_contribution ? this.first_node.own_contribution.turnout_ratio * 100 : 0) }}% turnout</div>
			</div>

			<transition name="fade">
				<div class="vote-container" v-bind:class="{open: true}">
					<div class="votes" v-if="node.contributions && node.contributions.length > 0">
						<p class="ui-title">{{ Math.round(node.results.turnout_ratio * 100) }}% turnout</p>
						<div class="contribution" v-for="contribution in node.contributions" :key="contribution.username">
							<div class="weight">
								<el-progress :text-inside="true" :stroke-width="24" :percentage="Math.round(contribution.weight * 100)"></el-progress>
							</div>
							<div class="choice" v-html="contribution.results.embed" style="height: 40px;"></div>
							<div class="username"><router-link :to="'/identities/' + contribution.identity_username">{{ contribution.identity_username }}</router-link></div>
							<div class="date">{{ moment(contribution.datetime).fromNow() }}</div>
						</div>
					</div>
				</div>
			</transition>
		</div>
	</div>
</div>
</template>

<script>
import Vue from 'vue'
import ElementUI from 'element-ui';
import locale from 'element-ui/lib/locale/lang/en'
let utils = require('utils.js')

Vue.use(ElementUI, {locale})

export default {
	props: ['node', 'votableNodes', 'resultsKey', 'referenceKey', 'title', 'choiceType'],
	components: {},
	data: function() {
		let self = this
		let nodes = self.votableNodes || [self.node]
		let first_node = nodes[0]

		return {
			nodes: nodes,
			first_node: first_node,
			votes: [{
				choice: (first_node.own_contribution ? first_node.own_contribution.choice : 0.0) * 100,
				at_date: Date.now(),
				at_date_open: false
			}],
			mean: 0.5,
			moment: require('moment'),
			choice_type: self.choiceType || first_node.choice_type,
			set: function(event) {
				let choices = _.map(self.votes, (vote) => parseFloat(vote.choice) / 100)
				_.each(nodes, (node) => {
					_.each(choices, (choice) => self.$store.dispatch('setVote', {node: node, choice: choice}))
				})
			},
			unset: function(event) {
				_.each(nodes, (node) => self.$store.dispatch('unsetVote', node))
			},
			keyup: function(event) {
				updateInputs()
			},
			number_format: utils.formatNumber,
			get_color: utils.getColor,
			add_vote: function(event) {
				self.votes.push({choice: 0, at_date: Date.now(), at_date_open: false})
			},
			units: [{
				value_type: 'probability',
				label: 'Spectrum',
				children: [{
					value: 'true',
					label: 'False - True'
				}, {
					value: 'fact',
					label: 'Lie - Fact'
				}, {
					value: 'good',
					label: 'Bad - Good'
				}]
			}, {
				value_type: 'quantity',
				label: 'Quantity',
				children: [{
					value: 'length',
					label: 'Length (m)'
				}, {
					value: 'temperature',
					label: 'Temperature (°C)'
				}, {
					value: 'usd',
					label: 'US Dollars (USD)'
				}]
			}],
			unit_value: 'true'
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