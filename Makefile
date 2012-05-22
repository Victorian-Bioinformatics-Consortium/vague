
all:
	rm -f vague.jar
	jruby -S warble compiled jar
