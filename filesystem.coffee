# Hook up FileSystem API

window.requestFileSystem = window.requestFileSystem || window.webkitRequestFileSystem;

if not window.requestFileSystem
	# No native support

	namespace = (namespaceString) ->
		parts = namespaceString.split '.'
		parent = window
		currentPart = ''

		for i in [0, parts.length]
			currentPart = parts[i]
			parent[currentPart] = parent[currentPart] || {}
			parent = parent[currentPart]

		return parent

	class fs.FileError
		constructor: (code, msg) ->
			@code = code
			@msg = msg
		
		NOT_FOUND_ERR:               1
		SECURITY_ERR:                2
		ABORT_ERR:                   3
		NOT_READABLE_ERR:            4
		ENCODING_ERR:                5
		NO_MODIFICATION_ALLOWED_ERR: 6
		INVALID_STATE_ERR:           7
		SYNTAX_ERR:                  8
		INVALID_MODIFICATION_ERR:    9
		QUOTA_EXCEEDED_ERR:         10
		TYPE_MISMATCH_ERR:          11
		PATH_EXISTS_ERR:            12
		
		toString: () ->
			@msg

	class fs.Request

	class fs.DataStorage
		#DSRequestEmul
		put
		#DSRequestEmul
		get
		clear
		remove

	class fs.LocalDataStorage extends fs.DataStorage
		constructor: (localStorage) ->
			@storage = localStorage
			super
		
		pathToKey: (path) ->
			path

		#DSRequestEmul
		get: (path) ->
			data = @storage.getItem pathToKey path
			JSON.parse data
		
		#DSRequestEmul
		put: (path, data) ->
			@storage.setItem pathToKey path, data
		
		clear: () ->
			@storage.clear

		remove: (path) ->
			@storage.removeItem pathToKey path
	
	class fs.DatabaseRequest
		constructor: (dbrequest) ->
			@dbrequest = dbrequest
		
		LOADING: @dbrequest.LOADING
		DONE:    @dbrequest.DONE
		readyState: @dbrequest.readyState
		onsuccess: undefined
		onerror:   undefined
	
	class fs.DatabaseDataStorage extends fs.DataStorage
		constructor: (objectStore) ->
			@objectStore = objectStore
			super
		
		pathToKey: (path) ->
			path
		
		#DSRequestEmul
		put: (path, data) ->
			new DatabaseRequest @objectStore.put data, pathToKey path

		#DSRequestEmul
		get: (path, data) ->
			new DatabaseRequest @objectStore.get pathToKey path

		clear: () ->
			new DatabaseRequest @objectStore.clear

		remove: (path) ->
			new DatabaseRequest @objectStore.delete pathToKey path

	class fs.Entry
		constructor: (filesystem, fullPath) ->
			@fullPath = fullPath
		fullPath: @fullPath
		
		name: extractName @fullPath
		filesystem: undefined
		
		isFile:      undefined
		isDirectory: undefined
		
		# MetadataCallback, optional ErrorCallback
		getMetadata: (successCallback, errorCallback) ->
		
		# DirectoryEntry, optional DOMString, optional EntryCallback, optional ErrorCallback
		moveTo: (parent, newName, successCallback, errorCallback) ->
		
		# DirectoryEntry, optional DOMString, optional EntryCallback, optional ErrorCallback
		copyTo: (parent, newName, successCallback, errorCallback) ->

		toURL: (mimeType) ->
		
		# VoidCallback, optional ErrorCallback
		remove: (successCallback, errorCallback) ->
		
		# EntryCallback, optional ErrorCallback
		getParent: (successCallback, errorCallback) ->

	class fs.DirectoryReader

	class fs.File
	
	class fs.FileWriter

	class fs.FileEntry
		
		# FileWriterCallback, optional ErrorCallback
		createWriter: (successCallback, errorCallback) ->
			writer = new FileWriter
			setTimeout successCallback.handleEvent writer, 0
		
		# FileCallback, optional ErrorCallback
		file: (successCallback, errorCallback) ->
			setTimeout '' , 0

	class fs.DirectoryEntry
		constructor: (path) ->
			@path = path
		
		createReader: () ->
			return new DirectoryReader
		
		# DOMString, optional Flags, optional EntryCallback, optional ErrorCallback
		getFile: (path, options, successCallback, errorCallback) ->
			pathList = getPath path
			entry = findPath pathList
			if not entry instanceof FileEntryEmul
				setTimeout successCallback.handleEvent entry, 0
		
		# DOMString, optional Flags, optional EntryCallback, optional ErrorCallback
		getDirectory: (path, options, successCallback, errorCallback) ->
		
		# VoidCallback, optional ErrorCallback
		removeRecursively: (successCallback, errorCallback) ->

	class fs.FileSystem
		name: "whatever";
		root: new DirectoryEntry("/");

	class fs.LocalFileSystem
		TEMPORARY:  0
		PERSISTENT: 1
		
		# unsigned short, unsigned long long, FileSystemCallback, optional ErrorCallback
		requestFileSystem: (type, size, successCallback, errorCallback) ->
			if type is not PERSISTENT
				# Not supported
				if errorCallback 
					setTimeout errorCallback.handleEvent, 0
				return;
			else if window.indexedDB
			else if window.localStorage
			else
				setTimeout errorCallback.handleEvent, 0
			
			filesystem: new fs.FileSystem();
			
			setTimeout successCallback.handleEvent filesystem, 0

	fsEmul = new fs.LocalFileSystem
	window.requestFileSystem = fsEmul.requestFileSystem;

