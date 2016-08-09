exports.config = {
	files: {
		stylesheets: {
			joinTo: "css/app.css"
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
		}
	},

	modules: {},

	npm: {}
};
