Some wrongly configured project does not honor $AR_target when make *.a files,
instead, they just call Mac-side ar command, so cause wrong *.a files.

This ar utility detect input *.o file format, Mac or Android.
If Android file, then call $AR_target which is Android-ar,
otherwise call $_AR_host which is Mac-ar
