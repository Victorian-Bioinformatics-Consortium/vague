
DISTFILES = README.txt vague.sh vague.jar

VERSION := $(shell jruby -Ilib -e 'require "version"; puts VAGUE_VERSION')

vague.jar:
	jruby -S warble compiled jar

dist: vague.jar
	@rm -rf tmp
	@mkdir -p tmp/vague
	@cp $(DISTFILES) tmp/vague
	tar czf vague-$(VERSION).tar.gz -C tmp vague

clean:
	rm -rf tmp vague.jar vague-$(VERSION).tar.gz