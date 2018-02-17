<template>
<div>
	<div class="own-contribution" v-for="vote in ownContributions" :key="vote.at_date">
		<div class="value" v-if="isSpectrum">{{ Math.round((vote.choice || vote.relevance) * 100) }}%</div>
		<div class="value" v-else>{{ Math.round(vote.choice) }}</div>

		<div class="date">
			{{ moment(vote.at_date).format('MM/DD/YYYY') }}
		</div>

		<div class="remove">
			<i class="el-icon-circle-close" @click="remove(vote)"></i>
		</div>
	</div>

	<div class="cast-vote">
		<div class="date" v-if="hasDate === true || hasDate === 'true'">
			<el-date-picker v-model="new_date" type="date" class="datepicker" :clearable="false"></el-date-picker>
		</div>

		<div class="value" v-if="isSpectrum">
			<p class="spectrum-side">{{ results.negative }}</p>
			<el-slider class="range" v-model="new_value"></el-slider>
			<p class="spectrum-side">{{ results.positive }}</p>
		</div>
		<div class="value" v-else>
			<el-input v-model="new_value" class="number"></el-input>
		</div>

		<el-button @click="save()" class="button">Cast vote</el-button>
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
	props: ['hasDate', 'unit', 'isSpectrum', 'ownContributions', 'results'],
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
	margin: 20px auto;
	text-align: left;
	width: 350px;
	padding: 10px 20px;
	border: 1px solid #ccc;

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
	margin: 40px auto;
	padding: 20px 20px;
	border: 1px solid #ccc;

	.date {
		input {
			text-align: center;
			padding-left: 20px;
		}
	}

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
			width: 260px;
			margin: 20px;
		}
		.number {
			display: inline-block;
			vertical-align: middle;
			width: 200px;
			margin: 20px;

			input {
				text-align: center;
			}
		}
	}
}
</style>