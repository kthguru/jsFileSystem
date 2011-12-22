# Hook up FileSystem API

window.requestFileSystem = window.requestFileSystem || window.webkitRequestFileSystem
if not window.BlobBuilder
	window.BlobBuilder = window.WebKitBlobBuilder || window.MozBlobBuilder

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
	
	class fs.FileException
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
		QUOTA_EXCEEDED_ERR:         10
		
		toString: () ->
			@msg
	
	class fs.FileError extends fs.FileException
		constructor: (code, msg) ->
			super code, msg
		
		INVALID_MODIFICATION_ERR:    9
		TYPE_MISMATCH_ERR:          11
		PATH_EXISTS_ERR:            12
	
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
	
	class js.Metadata
		constructor: () ->
			Object.defineProperty this, "modificationTime", {value : undefined,
			writable : false}

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
			
			@metadata = null
			@lastFileModificationDate = undefined
			
		# MetadataCallback, optional ErrorCallback
		getMetadata: (successCallback, errorCallback) ->
			func ->
				if not @metadata
					@metadata = {
						modificationTime: @lastFileModificationDate
					}
				successCallback.handleEvent @metadata
			setTimeout func, 0
		
		# DirectoryEntry, optional DOMString, optional EntryCallback, optional ErrorCallback
		moveTo: (parent, newName, successCallback, errorCallback) ->
		
		# DirectoryEntry, optional DOMString, optional EntryCallback, optional ErrorCallback
		copyTo: (parent, newName, successCallback, errorCallback) ->

		toURL: (mimeType) ->
		
		# VoidCallback, optional ErrorCallback
		remove: (successCallback, errorCallback) ->
			func = {
				handleEvent: (entry) ->
					removedEntry = delete entry.children[@name]
					successCallback.handleEvent removedEntry
			}
				
			getParent func, errorCallback
		
		# EntryCallback, optional ErrorCallback
		getParent: (successCallback, errorCallback) ->
			@parent
	class fs.Blob
		data: []
		
	class fs.File extends fs.Blob
		constructor: (name) ->
			Object.defineProperty this, "name", {value : name,
			writable : false}
		
		_lastModifiedDate:
		
		get lastModifiedDate: () ->
			@_lastModifiedDate
	
	class fs.FileSaver
		registerFunctions: (fileReader) ->
			fileReader.onabort = (event) ->
				if @onabort
					@onabort event
			
			fileReader.onloadstart = (event) ->
				if @onwritestart
					@onwritestart event
			
			fileReader.onprogress = (event) ->
				if @onprogress
					@onprogress event
			
			fileReader.onload = (event) ->
				@onload event
				if @onwrite
					@onwrite event
			
			fileReader.onabort = (event) ->
				if @onabort
					@onabort event
			
			fileReader.onerror = (event) ->
				if @onerror
					@onerror event
			
			fileReader.onloadend = (event) ->
				if @onwriteend
					@onwriteend event
		
		constructor: () ->
			Object.defineProperty this, "INIT", {value : 0,
			writable : false}
			
			Object.defineProperty this, "WRITING", {value : 1,
			writable : false}
			
			Object.defineProperty this, "DONE", {value : 2,
			writable : false}
			@reader = new FileReader
			registerFunctions @reader
		
		_readyState: @INIT
		_error:      null
		
		abort: () ->
			@reader.abort
		
		get readyState: () ->
			@_readyState
		
		#FileError
		get error: () ->
			@_error
		
		onwritestart: (event) ->
		onprogress:   (event) ->
		onwrite:      (event) ->
		onabort:      (event) ->
		onerror:      (event) ->
		onwriteend:   (event) ->
	
	class fs.FileWriter extends fs.FileSaver
		constructor: () ->
			
			Object.defineProperty this, "length", {value : undefined,
			writable : false}
			
			
		_data: null
		_position: -1
		
		add: (arraybuffer) ->
			if _data is null
				@_data = arraybuffer
			else
				oldData = @_data;
				@_data = new Uint8ArrayBuffer oldData.byteLength + arraybuffer.byteLength
				
				# Copy old data
				@_data.set oldData
				@_data.set arraybuffer, @position
		
		get position: () ->
			@_position
		
		get length: () ->
			@_length
		
		onload: (event) ->
			add @reader.result
		
		onabort: () ->
			
		
		onerror: () ->
			
		
		#Blob 
		write: (data) -> #raises (FileException)
			@reader.readAsArrayBuffer data
		
		seek: (offset) -> #raises (FileException)
			if @readyState is WRITING
				throw new FileException INVALID_STATE_ERR
			
			if offset > @length
				offset = @length
			else if offset < 0 # Limit to file index
				offset += @length # Negative is from other end
				offset = Math.min offset, 0
			
			@_position = offset
		
		truncate: (size) -> #raises (FileException)
			if @readyState is WRITING
				throw new FileException INVALID_STATE_ERR
			
			@readyState = WRITING
			
			#If an error occurs during truncate,
			 proceed to the error steps below.
Set the error attribute; on getting the error attribute must be a FileError object with a valid error code that indicates the kind of file error that has occurred.
			@readyState = DONE
			#Dispatch a progress event called error.
			#Dispatch a progress event called writeend
On getting, the length and position attributes should indicate any modification to the file.
Terminate this overall set of steps.

			#Dispatch a progress event called writestart.
Return from the truncate method, but continue processing the other steps in this algorithm.
			
Upon successful completion:
length must be equal to size.
position must be the lesser of
its pre-truncate value,
size.
			@readyState = DONE.
Dispatch a progress event called write
Dispatch a progress event called writeend
Terminate this overall set of steps.

			@reader.result.slice 0, size - 1
			@_length = size

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
			entry = findPath pathList
			
			if entry 
				if options.create and options.exclusive
					func = ->
						error = new FileError FileError.ABORT_ERR "File already exists."
						errorCallback.handleEvent error
					setTimeout func, 0
					return
				else if not options.create and entry.isFile
					func = ->
						error = new FileError FileError.ABORT_ERR "Not a Directory but a File."
						errorCallback.handleEvent error
					setTimeout func, 0
					return
			else
				if options.create
					new DirectoryEntry
				else
					func = ->
						error = new FileError FileError.ABORT_ERR "Directory does not exist."
						errorCallback.handleEvent error
					setTimeout func, 0
					return
			
			return entry
		
		# VoidCallback, optional ErrorCallback
		removeRecursively: (successCallback, errorCallback) ->
			remove successCallback, errorCallback
			
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
		
		createFilesystem: (dataStorage) ->
			filesystem: new fs.FileSystem dataStorage
		
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
					createFilesystem new DatabaseDataStorage object_storage
					successCallback.handleEvent @filesystem
				
				request.onerror = ->
					error = new FileError FileError.ABORT_ERR ""
					errorCallback.handleEvent error
				
			else if window.localStorage
				createFilesystem new LocalDataStorage window.localStorage
				func ->
					successCallback.handleEvent @filesystem
				setTimeout func, 0
			else
				func = ->
					error = new FileError FileError.ABORT_ERR "IndexedDB and localStorage are not supported."
					errorCallback.handleEvent error
				setTimeout func, 0

	fsEmul = new fs.LocalFileSystem
	window.requestFileSystem = fsEmul.requestFileSystem;

