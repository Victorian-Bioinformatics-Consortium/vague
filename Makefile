
all:
	rm -f Vgui.jar
	jruby -S warble compiled jar
