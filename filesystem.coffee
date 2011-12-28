`"use strict";`
# Hook up FileSystem API

window.requestFileSystem = window.requestFileSystem || window.webkitRequestFileSystem
if not window.BlobBuilder
	window.BlobBuilder = window.WebKitBlobBuilder || window.MozBlobBuilder

if not window.requestFileSystem
	# No native support
	
	class jsFileException extends Error
		@base_exception: undefined
		
		constructor: (code, secondary) ->
			if secondary instanceof String
				super @msg
			else if secondary instanceof Error
				@base_exception = secondary
				super ''
			else
				super ''
			
			@code = code
	
	callEventLiberal = (fnct, arg) ->
		if fnct.handleEvent is undefined
			call = () ->
				fnct arg
		else
			call = () ->
				fnct.handleEvent arg
		call()
	
	defStaticReadonly = (clazz, name, value) ->
		Object.defineProperty clazz.prototype, name, { value: value }
		
	defStaticReadonly jsFileException, 'NOT_FOUND_ERR'              ,  1
	defStaticReadonly jsFileException, 'SECURITY_ERR'               ,  2
	defStaticReadonly jsFileException, 'ABORT_ERR'                  ,  3
	defStaticReadonly jsFileException, 'NOT_READABLE_ERR'           ,  4
	defStaticReadonly jsFileException, 'ENCODING_ERR'               ,  5
	defStaticReadonly jsFileException, 'NO_MODIFICATION_ALLOWED_ERR',  6
	defStaticReadonly jsFileException, 'INVALID_STATE_ERR'          ,  7
	defStaticReadonly jsFileException, 'SYNTAX_ERR'                 ,  8
	defStaticReadonly jsFileException, 'QUOTA_EXCEEDED_ERR'         , 10
	
	class jsFileError extends jsFileException
		constructor: (code, secondary) ->
			super code, secondary
		
	defStaticReadonly jsFileError, 'INVALID_MODIFICATION_ERR',  9
	defStaticReadonly jsFileError, 'TYPE_MISMATCH_ERR'       , 11
	defStaticReadonly jsFileError, 'PATH_EXISTS_ERR'         , 12
	
	class jsRequest
	
	class jsDataStorage
		#DSRequestEmul
		@put   : undefined
		#DSRequestEmul
		@get   : undefined
		@clear : undefined
		@remove: undefined

	class jsLocalDataStorage extends jsDataStorage
		constructor: (localStorage) ->
			super
			@storage = localStorage
		
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
			Object.defineProperty this, 'readyState', { get: () -> @dbrequest.readyState }
			Object.defineProperty this, 'LOADING'   , { value: @dbrequest.LOADING }
			Object.defineProperty this, 'DONE'      , { value: @dbrequest.DONE    }
		
		@onsuccess: undefined
		@onerror  : undefined
	
	class jsDatabaseDataStorage extends jsDataStorage
		constructor: (objectStore) ->
			@objectStore = objectStore
			super
		
		pathToKey: (path) ->
			path
		
		#DSRequestEmul
		put: (path, data) ->
			new jsDatabaseRequest @objectStore.put data, pathToKey path

		#DSRequestEmul
		get: (path, data) ->
			new jsDatabaseRequest @objectStore.get pathToKey path

		clear: () ->
			new jsDatabaseRequest @objectStore.clear

		remove: (path) ->
			new jsDatabaseRequest @objectStore.delete pathToKey path
	
	class jsMetadata
		constructor: () ->
			Object.defineProperty this, "modificationTime", { value : undefined }

	# Following the valid type flags
	FILE_ENTRY      = 1
	DIRECTORY_ENTRY = 2
	class jsEntry
		constructor: (parent, name, typeFlag) ->
			Object.defineProperty this, "parent", { value : parent }
			
			filesystem = parent.filesystem
			
			Object.defineProperty this, "filesystem", { value : filesystem }
			
			Object.defineProperty this, "fullPath", { value : parent.fullPath }
			
			Object.defineProperty this, "name", { value : name }
			
			Object.defineProperty this, "isFile", { value : typeFlag is FILE_ENTRY }
			Object.defineProperty this, "isDirectory", { value : typeFlag is DIRECTORY_ENTRY }
			
			@metadata = null
			@lastFileModificationDate = undefined
			
		# MetadataCallback, optional ErrorCallback
		getMetadata: (successCallback, errorCallback) ->
			func ->
				if not @metadata
					@metadata = {
						modificationTime: @lastFileModificationDate
					}
				callEventLiberal successCallback, @metadata
			setTimeout func, 0
		
		# DirectoryEntry, optional DOMString, optional EntryCallback, optional ErrorCallback
		moveTo: (parent, newName, successCallback, errorCallback) ->
		
		# DirectoryEntry, optional DOMString, optional EntryCallback, optional ErrorCallback
		copyTo: (parent, newName, successCallback, errorCallback) ->

		toURL: (mimeType) ->
		
		# VoidCallback, optional ErrorCallback
		remove: (successCallback, errorCallback) ->
			func = (entry) ->
				removedEntry = delete entry.children[@name]
				callEventLiberal successCallback, removedEntry
				
			getParent func, errorCallback
		
		# EntryCallback, optional ErrorCallback
		getParent: (successCallback, errorCallback) ->
			@parent
	
	class jsBlob
		data: []
		
	class jsFile extends jsBlob
		@_lastModifiedDate: null
		
		constructor: (name) ->
			Object.defineProperty this, "name", {value : name }
			Object.defineProperty this, "lastModifiedDate", { get: -> @_lastModifiedDate } 
		
	class jsFileSaver
		defStaticReadonly jsFileSaver, 'WRITE_START', 'FileSaverWriteStart'
		defStaticReadonly jsFileSaver, 'PROGRESS'   , 'FileSaverProgress'
		defStaticReadonly jsFileSaver, 'WRITE'      , 'FileSaverWrite'
		defStaticReadonly jsFileSaver, 'ABORT'      , 'FileSaverAbort'
		defStaticReadonly jsFileSaver, 'ERROR'      , 'FileSaverError'
		defStaticReadonly jsFileSaver, 'WRITE_END'  , 'FileSaverWriteEnd'
	
		defStaticReadonly jsFileSaver, 'INIT'   , 0
		defStaticReadonly jsFileSaver, 'WRITING', 1
		defStaticReadonly jsFileSaver, 'DONE'   , 2
		
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
		@_readyState = jsFileSaver.prototype.INIT
		@_error =      null
		
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
			
			Object.defineProperty this, 'readyState', { get: -> @_readyState }
			Object.defineProperty this, 'error'     , { get: -> @_error      }
		
		setError = (error) ->
			#only enable error setting here
			@_error = error
		
		setReadyState = (state) ->
			@_readyState = state
		
		abort: () ->
			@reader.abort
		
		@onwritestart: null
		@onprogress:   null
		@onwrite:      null
		@onabort:      null
		@onerror:      null
		@onwriteend:   null
	
	class jsFileWriter extends jsFileSaver
		defStaticReadonly jsFileWriter, 'DO_WRITE', 'FileWriterDoWrite'
		
		@_data     = null
		@_position = -1
		@_length   =  0
		
		setLength = (length) ->
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
					
					setLength size
				
				@readyState = DONE
				dispatch WRITE
				dispatch WRITE_END
			document.addEventListener DO_WRITE, fnct, false
			
			defineProperty this, 'length'  , { get: -> @_length   }
			defineProperty this, 'position', { get: -> @_position }
			
		add = (arraybuffer) ->
			if @_data
				oldData = @_data;
				@_length = oldData.byteLength + arraybuffer.byteLength
				@_data = new Uint8Array @length
			
				# Copy old data
				@_data.set oldData
				@_data.set arraybuffer, @position
				@_position += arraybuffer.byteLength
			else
				@_length arraybuffer.byteLength
				@_data = arraybuffer
				@_position = arraybuffer.byteLength
		
		handleError = (fileError) ->
			setError fileError
			@_readyState = DONE
			
			dispatch ERROR
			dispatch WRITE_END
		
		#Blob 
		write: (data) -> #raises (FileException)
			if @readyState is WRITING
				throw new FileException FileException.INVALID_STATE_ERR
			
			@_readyState = WRITING
			
			dispatch WRITE_START
			@reader.onload = () ->
				add @reader.result
				@_readyState = DONE
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
	
	class jsFileEntry extends jsEntry
		constructor: (parent, name) ->
			super parent, name, FILE_ENTRY
		
		# FileWriterCallback, optional ErrorCallback
		createWriter: (successCallback, errorCallback) ->
			writer = new FileWriter
			func = ->
				callEventLiberal successCallback, writer
			setTimeout func, 0
		
		# FileCallback, optional ErrorCallback
		file: (successCallback, errorCallback) ->
			setTimeout '' , 0
		

	class jsDirectoryEntry extends jsEntry
		constructor: (parent, name) ->
			super parent, name, DIRECTORY_ENTRY
		
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
						callEventLiberal errorCallback, error
					setTimeout func, 0
					return
				else if not options.create and entry.isFile
					func = ->
						error = new FileError FileError.ABORT_ERR "Not a Directory but a File."
						callEventLiberal errorCallback, error
					setTimeout func, 0
					return
			else
				if options.create
					new DirectoryEntry
				else
					func = ->
						error = new FileError FileError.ABORT_ERR "Directory does not exist."
						callEventLiberal errorCallback, error
					setTimeout func, 0
					return
			
			return entry
		
		# VoidCallback, optional ErrorCallback
		removeRecursively: (successCallback, errorCallback) ->
			remove successCallback, errorCallback
			
	class jsRootDirectoryEntry extends jsDirectoryEntry
		constructor: (filesystem, path, name) ->
			fake_parent = {
				parent:     this
				fullPath:   path
				filesystem: filesystem
			}
			super fake_parent, name
	
	class jsDirectoryReader
		constructor: (dirEntry) ->
			Object.defineProperty this, "dirEntry", {value : dirEntry }
		
		# EntriesCallback, optional ErrorCallback 
		readEntries: (successCallback, errorCallback) ->
			callEventLiberal successCallback, @dirEntry.children
			callEventLiberal successCallback, []

	class jsFileSystem
		@maxByteCount   = 0
		@availByteCount = 0
		@usedByteCount  = 0
		
		constructor: (byte_count, dataStorage) ->
			@maxByteCount = byte_count
			@availByteCount = @maxByteCount
			
			Object.defineProperty this, "name", { value : "whatever" }
			
			rootEntry = new jsRootDirectoryEntry this, "/", ''
			Object.defineProperty this, 'root', { get: -> rootEntry }
			Object.defineProperty this, 'max_byte_count'      , { get: -> @maxByteCount   }
			Object.defineProperty this, 'available_byte_count', { get: -> @availByteCount }
			Object.defineProperty this, 'used_byte_count'     , { get: -> @usedByteCount  }
			
		reserveBytes: (byteCount) ->
			if (@usedByteCount + byteCount) > maxByteCount
				return false
			
			@usedByteCount += byteCount
			@availByteCount -= byteCount
			return true

	window.TEMPORARY  = 0
	window.PERSISTENT = 1
	
	class jsLocalFileSystem
		constructor: () ->
		filesystems = []
		
		createFilesystem = (size, dataStorage) ->
			fs = new jsFileSystem dataStorage
			filesystems.append fs
			fs
		
		# unsigned short, unsigned long long, FileSystemCallback, optional ErrorCallback
		@requestFileSystem: (type, size, successCallback, errorCallback) ->
			if type is not PERSISTENT
				# TEMPORARY is not supported
				if errorCallback 
					func = ->
						error = new FileError FileError.ABORT_ERR "Only PERSISTENT type is supported."
						callEventLiberal errorCallback, error
					
					setTimeout func, 0
			
			else if window.indexedDB
				request = window.indexedDB.open "___jsLocalFileSystem___"
				request.onsuccess = ->
					database = request.result
					object_store = database.createObjectStore "FileSystem"
					fs = createFilesystem size, new jsDatabaseDataStorage object_storage
					callEventLiberal successCallback, fs
				
				request.onerror = ->
					error = new FileError FileError.ABORT_ERR ""
					callEventLiberal errorCallback, error
				
			else if window.localStorage
				fs = createFilesystem size, new jsLocalDataStorage window.localStorage
				func = ->
					callEventLiberal successCallback, fs
				setTimeout func, 0
			else
				func = ->
					error = new FileError FileError.ABORT_ERR "IndexedDB and localStorage are not supported."
					callEventLiberal errorCallback, error
				setTimeout func, 0

	window.requestFileSystem = jsLocalFileSystem.requestFileSystem
	window.useFileSystemEmulation = true

