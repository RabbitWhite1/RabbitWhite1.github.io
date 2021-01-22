clean:
	@bundle exec jekyll clean
	@rm -r posts

copy_post: clean
	@cp -r _posts posts

install:
	@bundler install

build:
	@bundler exec jekyll build

serve:
	@bundler exec jekyll serve -P4001
