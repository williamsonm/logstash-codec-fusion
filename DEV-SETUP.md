### MacOS Setup Instructions
Setup JRuby using Homebrew.
```bash
# install rbenv and setup jruby
brew install rbenv
rbenv install jruby-9.1.8.0
rbenv global jruby-9.1.8.0
echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
. ~/.bash_profile

# install bundle dependencies
gem install bundler
bundle install

# run tests
bundle exec rspec
```

## Character Encoding Issues on Linux
You may need to force the default Java file encoding to UTF-8.
```bash
export JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF8
```
