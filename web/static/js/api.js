var axios = require('axios')

axios.defaults.headers.common['Authorization'] = 'Bearer ' + token;
axios.defaults.headers.post['Content-Type'] = 'application/json';

export function getNode(key, cb) {
	axios.get('/api/nodes/' + key).then(function (response) {
		cb(response.data.data)
	}).catch(function (error) {
	})
}

export function login(email, cb) {
	axios.post('/api/login', {email: email}).then(function (response) {
		axios.defaults.headers.common['Authorization'] = 'Bearer ' + response.data.data.access_token;
		cb()
	}).catch(function (error) {
	})
}

export function setVote(url_key, reference_url_key, choice, cb) {
	for(var key in choice)
		choice[key + ''] = parseFloat(choice[key])
	
	let url = '/api/nodes/' + url_key + (reference_url_key ? '/references/' + reference_url_key : '') + '/votes'
	
	axios.post(url, {choice: choice}).then(function (response) {
		cb(transformVote(response.data.data))
	}).catch(function (error) {
	})
}

export function unsetVote(url_key, reference_url_key, cb) {
	axios.delete('/api/nodes/' + url_key + '/votes').then(function (response) {
		cb(transformVote(response.data.data))
	}).catch(function (error) {
	})
}

export function getKey(title, choice_type) {
	return encodeURIComponent((title + ' ' + choice_type).trim().replace(/ /g, '-'))
}

export function formatNumber(number) {
	return Math.round(number * 10) / 10
}

export function getColor(mean) {
	if(mean == null) return "#ddd"
	if(mean < 0.25)
		return "rgb(255, 164, 164)"
	else if(mean < 0.75)
		return "rgb(249, 226, 110)"
	else
		return "rgb(140, 232, 140)"
}