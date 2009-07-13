desc "Create mo-files for L10n"
task :makemo do
  require 'gettext_rails/tools'
  GetText.create_mofiles
end

desc "Update pot/po files to match new version."
task :updatepo do
  require 'gettext_rails/tools'
  ENV["MSGMERGE_PATH"] = "msgmerge --sort-output"
  GetText.update_pofiles("skip", Dir.glob("{app}/**/*.{rb,erb}") + ["lib/symbol.rb"] + ["config/environment.rb"], "skip 1.1.0")
end
