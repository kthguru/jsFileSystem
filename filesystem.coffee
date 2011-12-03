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
		constructor: (parent, fullPath) ->
			Object.defineProperty this, "parent", {value : parent,
			writable : false}
			
			filesystem = parent.filesystem
			
			Object.defineProperty this, "filesystem", {value : filesystem,
			writable : false}
			
			Object.defineProperty this, "fullPath", {value : fullPath,
			writable : false}
			
			name = extractName @fullPath
			Object.defineProperty this, "name", {value : name,
			writable : false}
			
			Object.defineProperty this, "isFile", {value : false,
			writable : false}
			
			Object.defineProperty this, "isDirectory", {value : false,
			writable : false}
		
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

	class fs.File
	
	class fs.FileWriter

	class fs.FileEntry
		constructor: () ->
			super
			Object.defineProperty this, "isFile", {value : true,
			writable : false}
		
		# FileWriterCallback, optional ErrorCallback
		createWriter: (successCallback, errorCallback) ->
			writer = new FileWriter
			setTimeout successCallback.handleEvent writer, 0
		
		# FileCallback, optional ErrorCallback
		file: (successCallback, errorCallback) ->
			setTimeout '' , 0
		

	class fs.DirectoryEntry
		constructor: (parent, path) ->
			super parent, path
			Object.defineProperty this, "isDirectory", {value : true,
			writable : false}
		
		children: new Object
		
		createReader: () ->
			return new DirectoryReader this
		
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
			func = {
				handleEvent: (entry) ->
					removedEntry = entry.children.remove this.name
					successCallback.handleEvent removedEntry
			}
				
			getParent func, errorCallback
	
	class fs.RootDirectoryEntry
		constructor: (filesystem, path) ->
			fake_parent = {
				parent:     this
				filesystem: filesystem
			}
			super fake_parent, path
	
	class fs.DirectoryReader
		constructor: (dirEntry) ->
			Object.defineProperty this, "dirEntry", {value : dirEntry,
			writable : false}
		
		# EntriesCallback, optional ErrorCallback 
		readEntries: (successCallback, errorCallback) ->
			successCallback.handleEvent @dirEntry.children
			successCallback.handleEvent []

	class fs.FileSystem
		constructor: () ->
			Object.defineProperty this, "name", {value : "whatever",
			writable : false}
			
			rootEntry = new RootDirectoryEntry this, "/"
			
			Object.defineProperty this, "root", {value : rootEntry,
			writable : false}

	class fs.LocalFileSystem
		constructor: () ->
			Object.defineProperty this, "TEMPORARY", {value : 0,
			writable : false}
			
			Object.defineProperty this, "PERSISTENT", {value : 1,
			writable : false}
		
		setDataStorage: (dataStorage, successCallback) ->
			filesystem: new fs.FileSystem dataStorage
			setTimeout successCallback.handleEvent filesystem, 0
		
		# unsigned short, unsigned long long, FileSystemCallback, optional ErrorCallback
		requestFileSystem: (type, size, successCallback, errorCallback) ->
			if type is not @PERSISTENT
				# Not supported
				if errorCallback 
					func = ->
						error = new FileError FileError.ABORT_ERR "Only PERSISTENT type is supported."
						errorCallback.handleEvent error
					
					setTimeout func, 0
			
			else if window.indexedDB
				request = window.indexedDB.open "___jsLocalFileSystem___"
				request.onsuccess = ->
					database = request.result
					object_store = database.createObjectStore "FileSystem"
					setDataStorage new DatabaseDataStorage object_storage, successCallback
				
				request.onerror = ->
					error = new FileError FileError.ABORT_ERR ""
					errorCallback.handleEvent error
				
			else if window.localStorage
				setDataStorage new LocalDataStorage window.localStorage, successCallback
			else
				func = ->
					error = new FileError FileError.ABORT_ERR "IndexedDB and localStorage are not supported."
					errorCallback.handleEvent error
				setTimeout func, 0

	fsEmul = new fs.LocalFileSystem
	window.requestFileSystem = fsEmul.requestFileSystem;

