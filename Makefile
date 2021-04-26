all:server

server:clean
	@hexo g
	@hexo server
.PHONY:server

clean:
	@rm -rf public
.PHONY:clean
