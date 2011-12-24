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
		
		@_lastModifiedDate: null
		
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
		
		get WRITE_START: 'FileSaverWriteStart'
		get PROGRESS   : 'FileSaverProgress'
		get WRITE      : 'FileSaverWrite'
		get ABORT      : 'FileSaverAbort'
		get ERROR      : 'FileSaverError'
		get WRITE_END  : 'FileSaverWriteEnd'
		
		dispatch: (eventName) ->
			# If your browser does not support CustomEvent I don't like you!
			event = document.createEvent 'CustomEvent'
			event.initCustomEvent eventName, true, true, null
			document.dispatchEvent event
		
		get INIT    : 0
		get WRITING : 1
		get DONE    : 2
		
		constructor: () ->
			@reader = new FileReader
			registerFunctions @reader
			
			fnct = () ->
				if @onwritestart
					@onwritestart
			document.addEventListener WRITE_START, fnct, false
			
			fnct = () ->
				if @onprogress
					@onprogress
			document.addEventListener PROGRESS   , fnct, false
			
			fnct = () ->
				if @onwrite
					@onwrite
			document.addEventListener WRITE      , fnct, false
			
			fnct = () ->
				if @onabort
					@onabort
			document.addEventListener ABORT      , fnct, false
			
			fnct = () ->
				if @onerror
					@onerror
			document.addEventListener ERROR      , fnct, false
			
			fnct = () ->
				if @onwriteend
					@onwriteend
			document.addEventListener WRITE_END  , fnct, false
			
			set @error = (error) ->
				#only enable error setting here
				@_error = error
			
			set @readyState = (state) ->
				@_readyState = state
		
		@_readyState: INIT
		@_error:      null
		
		abort: () ->
			@reader.abort
		
		get readyState: () ->
			@_readyState
		
		#FileError
		get error: () ->
			@_error
		
		@onwritestart: null
		@onprogress:   null
		@onwrite:      null
		@onabort:      null
		@onerror:      null
		@onwriteend:   null
	
	class fs.FileWriter extends fs.FileSaver
		
		DO_WRITE: 'FileWriterDoWrite'
		@_data: null
		
		constructor: () ->
			super
			
			set @length: (length) ->
				@_length = length
			
			fnct = () ->
				if size is not @length
					# Needs to do something
					if size < @length
						@_data = @_data.subarray 0, size
					else
						@_data = new Uint8Array @_data, 0, size
					
					@length = size
				
				@readyState = DONE
				dispatch WRITE
				dispatch WRITE_END
			document.addEventListener DO_WRITE, fnct, false
			
			add = (arraybuffer) ->
				if @_data
					oldData = @_data;
					@_data = new Uint8Array oldData.byteLength + arraybuffer.byteLength
				
					# Copy old data
					@_data.set oldData
					@_data.set arraybuffer, @position
				else
					@_data = arraybuffer
			
		@_position: -1
		@_length: 0
		
		get @length: () ->
			@_length
		
		get position: () ->
			@_position
		
		get length: () ->
			@_length
		
		#Blob 
		write: (data) -> #raises (FileException)
			@reader.onload = () ->
				add @reader.result
				
			@reader.readAsArrayBuffer data
		
		createError: (fileError) ->
			@error = fileError
			@readyState = DONE
			
			dispatch ERROR
			dispatch WRITE_END
		
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
			
			# Since in the spec there is no shortcut for length == size
			# we won't implement one
			#if size is @_data.length
				
			if @readyState is WRITING
				throw new FileException INVALID_STATE_ERR
			
			@_readyState = WRITING
			
			dispatch WRITE_START
			
			dispatch DO_WRITE

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
			
			@rootEntry = new RootDirectoryEntry this, "/"
			
		get root: () ->
			@rootEntry

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

