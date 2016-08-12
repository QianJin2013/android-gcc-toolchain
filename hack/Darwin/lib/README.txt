Some wrongly configured project use linux link option "-lrt" (librt),
but Mac does not have librt, so link with "-lrt" option will cause error:
 "ld: library not found for -lrt".

It's boring to dig into the build system(such as gyp etc.) and fix it, 
also it will take too much time for pull-request to be accepted.

So i prepared a dummy librt without any export symbols, just a link to 
the most commonly used lib: /usr/lib/libSystem.B.dylib, so should be no harm.
