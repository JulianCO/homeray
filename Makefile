homeray: debug

debug: homeray.d myheap.d
	dmd -unittest -ofhomeray homeray.d myheap.d tracer.d simple_solids.d pigment.d types.d finish.d

release: homeray.d myheap.d
	dmd -O homeray.d myheap.d

image: homeray
	./homeray


