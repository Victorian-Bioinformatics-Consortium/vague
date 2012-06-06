
DISTFILES = README.txt vague.sh vague.jar

VERSION := $(shell jruby -Ilib -e 'require "version"; puts VAGUE_VERSION')

vague.jar:
	jruby -S warble compiled jar

dist: vague.jar
	@rm -rf tmp
	@mkdir -p tmp/vague-$(VERSION)
	@cp $(DISTFILES) tmp/vague-$(VERSION)
	tar czf vague-$(VERSION).tar.gz -C tmp vague-$(VERSION)

clean:
	rm -rf tmp vague.jar vague-$(VERSION).tar.gz