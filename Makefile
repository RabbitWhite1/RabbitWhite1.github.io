POSTS_DIR="posts"

clean:
	@bundle exec jekyll clean
	@rm -r _posts

copy_post: clean
	@cp -r $(POSTS_DIR) _posts

install:
	@bundler install

build:
	@bundler exec jekyll build

serve: copy_post
	@bundler exec jekyll serve

