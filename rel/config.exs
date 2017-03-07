use Mix.Releases.Config,
	default_release: :liquio,
	default_environment: Mix.env,

environment :dev do
	set dev_mode: true set include_erts: false
	set include_system_libs: false
	set cookie: :dev
end
environment :prod do
	set include_erts: true
	set include_system_libs: true
	set cookie: :prod
end

release :liquio do
	set version: current_version(:liquio)
end