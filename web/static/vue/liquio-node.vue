<template>
<div>
	<div v-if="node">
		<router-link :to="'/' + node.url_key" v-if="link == 'true'" class="title" style="vertical-align: middle;">{{ title || node.title }}</router-link>
		<h1 v-else class="title" style="vertical-align: middle;">{{ title || node.title }}</h1>

		<div class="score-container">
			<div>
				<div v-if="this.node.choice_type != null || resultsKey == 'relevance'" v-html="this.node.results.by_keys[resultsKey] ? this.node.results.by_keys[resultsKey].embed : this.node.results.embed" style="width: 300px; height: 120px; margin: 10px auto; font-size: 36px;"></div>
			</div>

			<div v-if="(node.choice_type != null || resultsKey == 'relevance') && votable != 'false'">
				<i v-if="!isOpen" class="el-icon-caret-bottom" @click="isOpen = true"></i>
				<i v-else class="el-icon-caret-top" @click="isOpen = false"></i>
			</div>

			<transition name="fade">
				<div class="vote-container" v-if="isOpen" v-bind:class="{open: isOpen}">
					<p class="ui-title">Your choice</p>
					
					<own-vote v-bind:node="node" v-bind:results-key="resultsKey" v-bind:reference-key="referenceKey" v-bind:choice-type="choiceType"></own-vote>
					<div class="votes" ng-if="node.results.contributions && node.results.contributions.length > 0">
						<p class="ui-title">{{ Math.round(node.results.turnout_ratio * 100) }}% turnout</p>
						<div class="contribution" v-for="contribution in node.contributions">
							<div class="weight">
								<el-progress :text-inside="true" :stroke-width="24" :percentage="Math.round(contribution.weight * 100)"></el-progress>
							</div>
							<div class="choice" v-html="contribution.results.by_keys[resultsKey] ? contribution.results.by_keys[resultsKey].embed : contribution.results.embed" style="height: 40px;"></div>
							<div class="username"><router-link :to="'/identities/' + contribution.identity.username">{{ contribution.identity.username }}</router-link></div>
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
import OwnVote from '../vue/own-vote.vue'

import Vue from 'vue'
import ElementUI from 'element-ui';
import locale from 'element-ui/lib/locale/lang/en'

Vue.use(ElementUI, {locale})

export default {
	props: ['node', 'resultsKey', 'referenceKey', 'votable', 'link', 'title', 'choiceType'],
	components: {OwnVote},
	data: function() {
		return {
			isOpen: false,
			mean: 0.5,
			moment: require('moment')
		}
	},
	watch: {
		'$route': function(to, from) {
			this.isOpen = false
		}
	}
}
</script>

<style scoped>
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
</style>