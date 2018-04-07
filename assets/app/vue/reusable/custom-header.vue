<template>
    <div>
        <el-dialog ref="login" :visible.sync="loginVisible" width="600px" title="Login">
            <div class="login">
                <el-input class="words" v-model="words" @keyup.native.enter="login" placeholder="Enter a list of 13 words">
                    <el-button slot="append" icon="el-icon-caret-right" @click="login"></el-button>
                </el-input>

                <div class="identities">
                    <div class="identity" v-for="(keypair, index) in $store.getters.currentOpts.keypairs" :key="keypair.username">
                        <a @click="setCurrentIndex(index)">{{ keypair.username }}</a>
                        <i @click="removeIndex(index)" class="el-icon-close" aria-hidden="true"></i>
                    </div>
                </div>

                <div class="generate">
                    <template v-if="randomWords">
                        <p>Login with <b>{{ generatedUsername }}</b> the following words : <span>{{ randomWords }}</span></p>
                        <el-button size="small" @click="downloadIdentity()" style="margin-top: 10px;">Download words</el-button>
                    </template>
                    <el-button @click="randomWords = generateWords()" size="small">Generate new identity</el-button>
                </div>
            </div>
        </el-dialog>

        <el-dialog title="Options" :visible.sync="dialogVisible" width="600px">
            <!--<div class="block">
                <p class="demonstration">Change language</p>
                <el-select v-model="language" v-on:change="setLanguage()">
                    <el-option label="English" value="en"></el-option>
                    <el-option label="Slovenščina" value="si"></el-option>
                </el-select>
            </div>-->

            <div class="block">
                <p class="demonstration">View snapshot at any date</p>
                <el-date-picker type="date" placeholder="Pick a day" v-model="datetime"></el-date-picker>
            </div>

            <div class="block">
                <p class="demonstration">Trust metric URL</p>
                <el-input type="url" v-model="trustMetricURL"></el-input>
            </div>

            <div class="block">
                <p class="demonstration">Votes will lose half remaining power every {{ vote_weight_halving_days }} days.</p>
                <el-slider v-model="vote_weight_halving_days" :max="1000"></el-slider>
            </div>

            <div class="block">
                <p class="demonstration">Smooth reference relevance by adding {{ soft_quorum_t }} voting power.</p>
                <el-slider v-model="soft_quorum_t"></el-slider>
            </div>

            <span slot="footer" class="dialog-footer">
                <el-button @click="dialogVisible = false">Close</el-button>
                <el-button type="primary" @click="dialogVisible = false; saveOptions()">Save</el-button>
            </span>
        </el-dialog>
        
        <el-row>
            <el-col :span="12">
                <router-link to="/" class="logo"><img src="/images/logo.svg"></img></router-link>
            </el-col>
            <el-col :span="12">
                <div class="actions">
                    <router-link v-if="$store.getters.currentOpts.keypair" :to="'/identities/' + $store.getters.currentOpts.keypair.username">{{ $store.getters.currentOpts.keypair.username }}</router-link>

                    <a @click="loginVisible = true"><i class="el-icon-view"></i></a>

                    <a @click="dialogVisible = !dialogVisible"><i class="el-icon-setting"></i></a>
                </div>
            </el-col>
        </el-row>
    </div>
</template>

<script>
import bip39 from 'bip39'
import nacl from 'tweetnacl'

export default {
    data () {
		return {
            language: 'en',
            loginVisible: false,
			dialogVisible: false,
			datetime: new Date(),
			vote_weight_halving_days: 1000,
			soft_quorum_t: 0,
			minimum_relevance_score: 50,
			sort: 'top',
			sortDirection: 'most',
			words: '',
			randomWords: null,
			isDone: false,
			trustMetricURL: this.$store.getters.currentOpts.trustMetricURL
		}
    }
}
</script>

<style scoped lang="less">
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
    margin-top: 18px;
    text-align: right;

    .identity {
        display: inline-block;
        margin-left: 20px;

        a {
            margin-left: 15px;
        }

        i {
            font-size: 10px;
            color: rgba(0, 0, 0, 0.2);
        }
    }

    i {
        vertical-align: middle;
        font-size: 20px;
    }

    a {
        color: white;
        display: inline-block;
        vertical-align: middle;
        text-decoration: none;
        margin-left: 50px;
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


</style>