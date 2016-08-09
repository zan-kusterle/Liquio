exports.config = {
	files: {
		stylesheets: {
			joinTo: "css/app.css",
			order: {
				before: [
					'web/static/css/lib/pure.css'
				]
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
		}
	},

	modules: {},

	npm: {}
};
