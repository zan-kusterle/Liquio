<template>
<div>
	<div class="own-contribution" v-for="vote in ownContributions">
		<div class="value" v-if="isSpectrum">{{ Math.round(vote.choice * 100) }}%</div>
		<div class="value" v-else>{{ Math.round(vote.choice) }}</div>

		<div class="date">
			{{ moment(vote.at_date).format('MM/DD/YYYY') }}
		</div>

		<div class="remove">
			<i class="el-icon-circle-close" @click="remove(vote)"></i>
		</div>
	</div>

	<div class="cast-vote">
		<div class="date">
			<el-date-picker v-model="new_date" type="date" class="datepicker" :clearable="false"></el-date-picker>
		</div>

		<div class="value" v-if="isSpectrum">
			<p class="spectrum-side">{{ results.negative }}</p>
			<el-slider class="range" v-model="new_value"></el-slider>
			<p class="spectrum-side">{{ results.positive }}</p>
		</div>
		<div class="value" v-else>
			<el-input v-model="new_value"></el-input>
		</div>

		<el-button @click="save()" class="button">Cast vote</el-button>
	</div>

	<div class="contributions" v-if="results && results.contributions_by_identities">
		<p class="turnout">{{ Math.round(results.turnout_ratio * 100) }}% turnout</p>
		<div class="contribution" v-for="(identity_data, identity_id) in results.contributions_by_identities" :key="identity_id">
			<div class="weight">
				<el-progress :text-inside="true" :stroke-width="24" :percentage="Math.round(identity_data.contributions[0].weight * 100)"></el-progress>
			</div>
			<div v-if="identity_data.embeds.by_time" v-html="identity_data.embeds.by_time" class="choice"></div>
			<div v-html="identity_data.contributions[identity_data.contributions.length - 1].embeds.value" class="choice"></div>
			<div class="username"><router-link :to="'/identities/' + identity_data.contributions[0].identity_username">{{ identity_data.contributions[0].identity_username }}</router-link></div>
			<div class="date">{{ moment(new Date(identity_data.contributions[identity_data.contributions.length - 1].datetime)).fromNow() }}</div>
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
	props: ['single', 'unit', 'isSpectrum', 'ownContributions', 'results'],
	data: function() {
		let self = this
		
		return {
			moment: require('moment'),
			new_date: new Date(),
			new_value: self.isSpectrum ? 50 : 0,
			save: function(vote) {
				let choice = parseFloat(self.new_value)
				if(self.isSpectrum)
					choice /= 100
				this.$emit('set', {unit: self.unit, at_date: self.new_date, choice: choice})
			},
			remove: function(vote) {
				this.$emit('unset', {unit: vote.unit, at_date: new Date(vote.at_date)})
			}
		}
	}
}
</script>

<style lang="less">
.own-contribution {
	background-color: #eee;
	margin: 10px auto;
	text-align: left;
	width: 350px;
	padding: 10px 20px;

	.remove {
		display: inline-block;
		vertical-align: middle;
		float: right;
		line-height: 36px;
	}
	.date {
		display: inline-block;
		vertical-align: middle;
		margin-left: 30px;
	}
	.value {
		display: inline-block;
		vertical-align: middle;
		font-size: 24px;
	}
}

.cast-vote {
	background-color: #eee;
	width: 500px;
	margin: 20px auto;
	padding: 20px 40px;

	.value {
		.spectrum-side {
			display: inline-block;
			vertical-align: middle;
			font-size: 20px;
			text-transform: lowercase;
		}
		.range {
			display: inline-block;
			vertical-align: middle;
			width: 300px;
			margin: 20px;
		}
	}
}

.contributions {
	margin-top: 50px;

	.turnout {
		font-size: 18px;
		font-weight: bold;
		margin-bottom: 50px;
	}

	.contribution {
		margin: 10px 0px;

		.weight {
			width: 300px;
			display: inline-block;
			vertical-align: middle;
		}
		.choice {
			width: 140px;
			height: 40px;
			display: inline-block;
			vertical-align: middle;
			margin-left: 20px;
		}
		.username {
			width: 120px;
			display: inline-block;
			vertical-align: middle;
			margin-left: 20px;
			text-align: left;
		}
		.date {
			display: inline;
			vertical-align: middle;
			text-align: left;
		}
	}
}
</style>