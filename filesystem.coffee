`"use strict";`
# Hook up FileSystem API

window.requestFileSystem = window.requestFileSystem || window.webkitRequestFileSystem
if not window.BlobBuilder
	window.BlobBuilder = window.WebKitBlobBuilder || window.MozBlobBuilder

if not window.requestFileSystem
	# No native support
	
	class jsFileException
		constructor: (code, msg) ->
			@code = code
			@msg = msg
		
	defProp = (clazz, name, value) ->
		Object.defineProperty clazz.prototype, name, { get: -> value }
		
	defProp jsFileException, 'NOT_FOUND_ERR'              ,  1
	defProp jsFileException, 'SECURITY_ERR'               ,  2
	defProp jsFileException, 'ABORT_ERR'                  ,  3
	defProp jsFileException, 'NOT_READABLE_ERR'           ,  4
	defProp jsFileException, 'ENCODING_ERR'               ,  5
	defProp jsFileException, 'NO_MODIFICATION_ALLOWED_ERR',  6
	defProp jsFileException, 'INVALID_STATE_ERR'          ,  7
	defProp jsFileException, 'SYNTAX_ERR'                 ,  8
	defProp jsFileException, 'QUOTA_EXCEEDED_ERR'         , 10
		
		toString: () ->
			@msg
	
	class jsFileError extends jsFileException
		constructor: (code, msg) ->
			super code, msg
		
	defProp jsFileError, 'INVALID_MODIFICATION_ERR',  9
	defProp jsFileError, 'TYPE_MISMATCH_ERR'       , 11
	defProp jsFileError, 'PATH_EXISTS_ERR'         , 12
	
	class jsRequest
	
	class jsDataStorage
		#DSRequestEmul
		put
		#DSRequestEmul
		get
		clear
		remove

	class jsLocalDataStorage extends jsDataStorage
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
	
	class jsDatabaseRequest
		constructor: (dbrequest) ->
			@dbrequest = dbrequest
		
		@getter_readyState: -> @dbrequest.readyState
		onsuccess: undefined
		onerror  : undefined
	
	defProp jsDatabaseRequest, 'LOADING', @dbrequest.LOADING
	defProp jsDatabaseRequest, 'DONE'   , @dbrequest.DONE
	
	class jsDatabaseDataStorage extends jsDataStorage
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

	class jsEntry
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
	
	class jsBlob
		data: []
		
	class jsFile extends jsBlob
		constructor: (name) ->
			Object.defineProperty this, "name", {value : name,
			writable : false}
		
		@_lastModifiedDate: null
		
		@getter_lastModifiedDate: () ->
			@_lastModifiedDate
	
	defProp jsFileSaver, 'WRITE_START', 'FileSaverWriteStart'
	defProp jsFileSaver, 'PROGRESS'   , 'FileSaverProgress'
	defProp jsFileSaver, 'WRITE'      , 'FileSaverWrite'
	defProp jsFileSaver, 'ABORT'      , 'FileSaverAbort'
	defProp jsFileSaver, 'ERROR'      , 'FileSaverError'
	defProp jsFileSaver, 'WRITE_END'  , 'FileSaverWriteEnd'
	
	defProp jsFileSaver, 'INIT'   , 0
	defProp jsFileSaver, 'WRITING', 1
	defProp jsFileSaver, 'DONE'   , 2
	
	class jsFileSaver
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
		
		dispatch: (eventName) ->
			# If your browser does not support CustomEvent I don't like you!
			event = document.createEvent 'CustomEvent'
			event.initCustomEvent eventName, true, true, null
			document.dispatchEvent event
		
		@reader = new FileReader
		
		constructor: () ->
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
		
		@getter_readyState: () ->
			@_readyState
			
		#FileError
		@getter_error: () ->
			@_error
		
		@onwritestart: null
		@onprogress:   null
		@onwrite:      null
		@onabort:      null
		@onerror:      null
		@onwriteend:   null
	
	defProp jsFileWriter, 'DO_WRITE', 'FileWriterDoWrite'
	
	class jsFileWriter extends jsFileSaver
		
		@_data: null
		
		set @length = (length) ->
				@_length = length
		
		constructor: () ->
			super
			
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
				@length = oldData.byteLength + arraybuffer.byteLength
				@_data = new Uint8Array @length
			
				# Copy old data
				@_data.set oldData
				@_data.set arraybuffer, @position
				@position += arraybuffer.byteLength
			else
				@length = arraybuffer.byteLength
				@_data = arraybuffer
				@position = arraybuffer.byteLength
		
		handleError = (fileError) ->
			@error = fileError
			@readyState = DONE
			
			dispatch ERROR
			dispatch WRITE_END
			
		@_position: -1
		@_length: 0
		
		@getter_length: () ->
			@_length
		
		@getter_position: () ->
			@_position
		
		@getter_length: () ->
			@_length
		
		#Blob 
		write: (data) -> #raises (FileException)
			if @readyState is WRITING
				throw new FileException FileException.INVALID_STATE_ERR
			
			@readyState = WRITING
			
			dispatch WRITE_START
			@reader.onload = () ->
				add @reader.result
				@readyState = DONE
				dispatch WRITE
				dispatch WRITE_END
			
			@reader.onprogress = (progressEvent) ->
				# TODO: see whether this is benefitial
				# Make progress notifications. On getting, while processing the write method, the length and position attributes should indicate the progress made in writing the file as of the last progress notification
			
			@reader.onerror = () ->
				handleError new FileError ABORT_ERR @reader.error
				
				# TODO: Not yet implemented:
				# On getting, the length and position attributes should indicate any fractional data successfully written to the file.
			
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
			
			# Since in the spec there is no shortcut for length == size
			# we won't implement one
			#if size is @_data.length
				
			if @readyState is WRITING
				throw new FileException INVALID_STATE_ERR
			
			@_readyState = WRITING
			
			dispatch WRITE_START
			
			dispatch DO_WRITE

	class jsFileEntry
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
		

	class jsDirectoryEntry
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
			
	class jsRootDirectoryEntry
		constructor: (filesystem, path) ->
			fake_parent = {
				parent:     this
				filesystem: filesystem
			}
			super fake_parent, path
	
	class jsDirectoryReader
		constructor: (dirEntry) ->
			Object.defineProperty this, "dirEntry", {value : dirEntry,
			writable : false}
		
		# EntriesCallback, optional ErrorCallback 
		readEntries: (successCallback, errorCallback) ->
			successCallback.handleEvent @dirEntry.children
			successCallback.handleEvent []

	class jsFileSystem
		constructor: () ->
			Object.defineProperty this, "name", {value : "whatever",
			writable : false}
			
			@rootEntry = new RootDirectoryEntry this, "/"
			
		getter_root: () ->
			@rootEntry

	defProp jsLocalFileSystem, 'TEMPORARY' , 0
	defProp jsLocalFileSystem, 'PERSISTENT', 1

	class jsLocalFileSystem
		constructor: () ->
		
		createFilesystem = (dataStorage) ->
			filesystem: new jsFileSystem dataStorage
		
		# unsigned short, unsigned long long, FileSystemCallback, optional ErrorCallback
		requestFileSystem: (type, size, successCallback, errorCallback) ->
			if type is not @PERSISTENT
				# TEMPORARY is not supported
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

	window.requestFileSystem = jsLocalFileSystem.requestFileSystem;

