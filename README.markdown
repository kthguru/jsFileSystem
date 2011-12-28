JavaScript FileSystem API
==========

This is a JavaScript implementation of the [FileSystem](http://dev.w3.org/2009/dap/file-system/pub/FileSystem/) API. It emulates the functionality be using _IndexedDB_ and _LocalStorage_ (whichever is available).

The purpose is to provide a common API for file system access. That said - even if we emulate this API, it is very much inferior to a native implementation of the API. Thus it currently is not designed for being used when a native implementation is available.

Code is written in _Coffeescript_. Produced _JavaScript_ is intended to run on _ECMAScript_ version *5* and above.
Should eventually be compatible with _Chrome_, _Firefox_, _Internet Explorer 9+_ and _Opera ?_.

