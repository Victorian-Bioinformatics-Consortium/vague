
DISTFILES = README.txt vague vague.jar COPYING.txt ChangeLog velvetk.pl velvet-binaries

VERSION := $(shell jruby -Ilib -e 'require "version"; puts VAGUE_VERSION')

DEPS := $(shell find . -name '*.rb')

vague.jar: $(DEPS)
	jruby -S warble compiled jar

dist: vague.jar
	@rm -rf tmp
	@mkdir -p tmp/vague-$(VERSION)
	@cp -a $(DISTFILES) tmp/vague-$(VERSION)
	tar czf vague-$(VERSION).tar.gz -C tmp vague-$(VERSION)

clean:
	rm -rf tmp vague.jar vague-$(VERSION).tar.gz
