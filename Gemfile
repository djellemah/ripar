def from_gemrc
  # auto-load from ~/.gemrc
  home_gemrc = Pathname('~/.gemrc').expand_path

  if home_gemrc.exist?
    require 'yaml'
    # use all the sources specified in .gemrc
    YAML.load_file(home_gemrc)[:sources]
  end
end

# use the gemrc source if defined or CANON is truthy in ENV
# otherwise just use the default
def preferred_sources
  rv = from_gemrc unless eval(ENV['CANON']||'')
  rv ||= []
  rv << 'http://rubygems.org' if rv.empty?
  rv
end

preferred_sources.each{|src| source src}

# Specify your gem's dependencies in ripar.gemspec
gemspec
