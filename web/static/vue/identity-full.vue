<template>
<app>
	<div v-if="identity">
		<div class="main">
			<div class="main-node">
				<el-row :gutter="50">
					<el-col :span="8">
						dasd
					</el-col>
					<el-col :span="8">
						{{ identity.username }}<br>
						{{ identity.name }}

						<div style="margin-top: 60px;">
							I trust this identity<br>
							<el-button @click="set_trust(false)" :type="trust == false ? 'danger' : null">No</el-button>
							<el-button @click="set_trust(true)" :type="trust == true ? 'success' : null">Yes</el-button>
							<br>
							<el-button type="text" @click="unset_trust()" v-if="trust != null">Clear</el-button>
						</div>

						<div style="margin-top: 40px;">
							Delegation
							<el-slider v-model="weight"></el-slider>

							<el-tag
								:key="tag"
								v-for="tag in topics"
								:closable="true"
								:close-transition="false"
								@close="handleClose(tag)"
								>
							{{tag}}
							</el-tag>
							<el-input
								class="input-new-tag"
								v-if="inputVisible"
								v-model="inputValue"
								ref="saveTagInput"
								size="mini"
								@keyup.enter.native="handleInputConfirm"
								@blur="handleInputConfirm"
								>
							</el-input>
							<el-button v-else class="button-new-tag" size="small" @click="showInput">Add topic</el-button>
						</div>
					</el-col>
					<el-col :span="8">
						asdasd
					</el-col>
				</el-row>
			</div>
			<div class="inset-bottom">
				<liquio-list v-bind:nodes="identity.votes"></liquio-list>
			</div>
		</div>
	</div>
	<div class="main" v-else>
		<div class="main-node">
			<i class="el-icon-loading loading"></i>
		</div>
	</div>
</app>
</template>

<script>
import App from '../vue/app.vue'
import LiquioList from '../vue/liquio-list.vue'

let Api = require('api.js')

export default {
	components: {App, LiquioList},
	data: function() {
		let self = this
		let username = this.$route.params.username
		Api.getIdentity(username, (identity) => self.identity = identity)

		return {
			identity: null,
			username: username,
			topics: [],
			trust: null,
			weight: 100,

        	inputVisible: false,
        	inputValue: '',

			set_trust: function(v) {
				this.trust = v
			},
			unset_trust: function() {
				this.trust = null
			},

			handleClose: function(tag) {
				self.topics.splice(self.topics.indexOf(tag), 1);
			},

			showInput: function() {
				self.inputVisible = true;
				self.$nextTick(_ => {
					self.$refs.saveTagInput.$refs.input.focus();
				});
			},

			handleInputConfirm: function() {
				let inputValue = self.inputValue;
				if (inputValue) {
					self.topics.push(inputValue);
				}
				self.inputVisible = false;
				self.inputValue = '';
			}
		}
	}
}
</script>