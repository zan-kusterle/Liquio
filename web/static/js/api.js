let axios = require('axios')

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

export function setVote(url_key, choice, cb) {
	for(var key in choice)
		choice[key + ''] = parseFloat(choice[key])
	
	axios.post('/api/nodes/' + url_key + '/votes', {choice: choice}).then(function (response) {
		cb(transformVote(response.data.data))
	}).catch(function (error) {
	})
}

export function unsetVote(url_key, cb) {
	axios.delete('/api/nodes/' + url_key + '/votes').then(function (response) {
		cb(transformVote(response.data.data))
	}).catch(function (error) {
	})
}

export function getKey(title, choice_type) {
	return (title + ' ' + choice_type).trim().replace(/ /g, '-')
}
