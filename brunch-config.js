exports.config = {
	files: {
		javascripts: {
			joinTo: "js/app.js"
		},
		stylesheets: {
			joinTo: "css/app.css",
			order: {
				before: ['web/static/css/lib/pure.css', 'web/static/css/app.less']
			}
		}
	},

	conventions: {
		assets: /^(web\/static\/assets)/
	},

	paths: {
		watched: [
			"web/static",
			"test/static"
		],
		public: "priv/static"
	},
  
	plugins: {
		cleancss: {
			keepSpecialComments: 0,
			removeEmpty: true
		},
		less: {
			dumpLineNumbers: 'comments'
		},
		babel: {
			ignore: [/web\/static\/vendor/]
		}
	},

	modules: {
		autoRequire: {
			"js/app.js": ["web/static/js/app"]
		}
	},

	npm: {
		enabled: true
	}
};
