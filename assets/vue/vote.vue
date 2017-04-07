<template>
<div>
	<div class="vote-choices">
		<div class="vote-choice" v-for="(vote, index) in votes">
			<el-tooltip class="action" effect="dark" content="Remove this choice" placement="top">
				<i @click="votes.splice(index, 1)" class="el-icon-circle-close"></i>
			</el-tooltip>

			<div class="number">
				<span>{{ Math.round(vote.choice) }}</span><span class="percent">%</span>
			</div>

			<div class="range" v-if="node.default_unit && node.default_unit.type == 'spectrum'">
				<el-slider v-model="vote.choice" />
			</div>
			<div class="numeric" v-else>
				<el-input v-model="vote.choice"></el-input>
			</div>

			<el-date-picker v-if="vote.at_date" v-model="vote.at_date" type="date" class="datepicker"></el-date-picker>
			<el-tooltip v-else class="action" effect="dark" content="Set specific date" placement="top">
				<i @click="vote.at_date = Date.now()" class="el-icon-date" style="margin-left: 5px;"></i>
			</el-tooltip>
		</div>
		<div class="vote-choice">
			<el-tooltip class="action" effect="dark" content="Add your choice" placement="top">
				<i @click="votes.push({choice: 0, at_date: null})" class="el-icon-plus"></i>
			</el-tooltip>

			<a class="action" v-on:click="set" style="width: 90px;">Save <i class="el-icon-circle-check"></i></a>
		</div>
	</div>

	<transition name="fade">
		<div class="vote-container" v-bind:class="{open: true}">
			<div class="votes" v-if="node.default_unit && node.default_unit.results.contributions.length > 0">
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
	</transition>
</div>
</template>

<script>
import Vue from 'vue'
import ElementUI from 'element-ui';
import locale from 'element-ui/lib/locale/lang/en'
let utils = require('utils.js')

Vue.use(ElementUI, {locale})

export default {
	props: ['node', 'title'],
	data: function() {
		let self = this
		return {
			votes: this.node && this.node.own_results ? this.node.own_results["count"].results.contributions : [],
			mean: 0.5,
			moment: require('moment'),
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

	.vote-choices {
		width: 750px;
    	margin: 0 auto;
		text-align: left;

		.own-contribution-ratio {
			margin-top: 20px;
			font-size: 18px;
			display: inline;
		}

		.vote-choice {
			margin-top: 30px;

			.range {
				width: 250px;
				display: inline-block;
				vertical-align: middle;
				margin-right: 30px;
			}

			.numeric {
				display: inline-block;
				vertical-align: baseline;
				width: 130px;
				margin-right: 30px;
			}

			.action {
				display: inline-block;
				font-size: 20px;
				vertical-align: baseline;
				margin-right: 40px;

				i {
					margin-left: 10px;
					vertical-align: baseline;
				}
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