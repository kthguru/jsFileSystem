`"use strict";`
# Hook up FileSystem API

window.requestFileSystem = window.requestFileSystem || window.webkitRequestFileSystem
window.BlobBuilder = window.BlobBuilder || window.WebKitBlobBuilder || window.MozBlobBuilder

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
		
		valueOf: () ->
			@code
	
	callEventLiberal = (fnct, arg) ->
		if fnct.handleEvent is undefined
			call = () ->
				fnct arg
		else
			call = () ->
				fnct.handleEvent arg
		call()
	
	callLaterOn = (func) ->
		setTimeout func, 0
	
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
	
	# Check whether there is already a FileError available from
	# FileWriter
	class FileError extends jsFileException
		constructor: (code, secondary) ->
			super code, secondary
	
	if not window.FileError
		window.FileError = FileError
	
	defErrorCode = (name, value) ->
		if not window.FileError[name]
			Object.defineProperty window.FileError, name, { value: value }
	
	defErrorCode 'NOT_FOUND_ERR'              ,  1
	defErrorCode 'SECURITY_ERR'               ,  2
	defErrorCode 'ABORT_ERR'                  ,  3
	defErrorCode 'NOT_READABLE_ERR'           ,  4
	defErrorCode 'ENCODING_ERR'               ,  5
	defErrorCode 'NO_MODIFICATION_ALLOWED_ERR',  6
	defErrorCode 'INVALID_STATE_ERR'          ,  7
	defErrorCode 'SYNTAX_ERR'                 ,  8
	defErrorCode 'INVALID_MODIFICATION_ERR'   ,  9
	defErrorCode 'QUOTA_EXCEEDED_ERR'         , 10
	defErrorCode 'TYPE_MISMATCH_ERR'          , 11
	defErrorCode 'PATH_EXISTS_ERR'            , 12
	
	createFileError = (code, second) ->
		new FileError code, second
	
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
		constructor: (database) ->
			@objectStore = database.createObjectStore "FileSystem"
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
	SEPERATOR = '/'

	class jsEntry
		@_byteCount: 0
		
		constructor: (parent, name, typeFlag) ->

			if parent.reserveBytes
				filesystem = parent
				# According to spec this indicates the root
				parent     = this
			else
				filesystem = parent.filesystem
				
			Object.defineProperty this, "parent"    , { value : parent }
			Object.defineProperty this, "filesystem", { value : filesystem }
			Object.defineProperty this, "name", { value : name }
			
			#TODO: Move isRoot handling off - it's ugly design
			isRoot = @parent is this
			if isRoot
				fullpath = SEPERATOR
			else if parent.name is ''
				fullpath = parent.fullPath
			else
				fullpath = parent.fullPath + SEPERATOR
			
			fullpath += @name
			
			Object.defineProperty this, "fullPath", { value : fullpath }
			
			Object.defineProperty this, "isFile"     , { value : typeFlag is FILE_ENTRY }
			Object.defineProperty this, "isDirectory", { value : typeFlag is DIRECTORY_ENTRY }
			
			@metadata = null
			@lastFileModificationDate = undefined
			
			filesystem.reserveBytes this
			
			if not isRoot
				@parent.children.push this
		
		# MetadataCallback, optional ErrorCallback
		getMetadata: (successCallback, errorCallback) ->
			func = ->
				if not @metadata
					@metadata = {
						modificationTime: @lastFileModificationDate
					}
				callEventLiberal successCallback, @metadata
			callLaterOn func
		
		# DirectoryEntry, optional DOMString, optional EntryCallback, optional ErrorCallback
		moveTo: (parent, newName, successCallback, errorCallback) ->
		
		# DirectoryEntry, optional DOMString, optional EntryCallback, optional ErrorCallback
		copyTo: (parent, newName, successCallback, errorCallback) ->

		toURL: (mimeType) ->
		
		removeSync: (successCallback, errorCallback) ->
			index = @parent.children.indexOf this
			@parent.children.splice index, 1
			callEventLiberal successCallback, this
		
		# VoidCallback, optional ErrorCallback
		remove: (successCallback, errorCallback) ->
			obj = this
			func = ->
				obj.removeSync successCallback, errorCallback
			callLaterOn func
		
		# EntryCallback, optional ErrorCallback
		getParent: (successCallback, errorCallback) ->
			obj = this
			func = ->
				callEventLiberal successCallback, obj.parent
			callLaterOn func
	
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
				handleError createFileError window.FileError.ABORT_ERR, @reader.error
				
				# TODO: Not yet implemented:
				# On getting, the length and position attributes should indicate any fractional data successfully written to the file.
			
			@reader.readAsArrayBuffer data
		
		seek: (offset) -> #raises (FileException)
			if @readyState is WRITING
				throw new jsFileException jsFileException.INVALID_STATE_ERR
			
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
				throw new jsFileException jsFileException.INVALID_STATE_ERR
			
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
			callLaterOn func
		
		# FileCallback, optional ErrorCallback
		file: (successCallback, errorCallback) ->
			callLaterOn ''
		
	createNoParentError = ->
		createFileError window.FileError.NOT_FOUND_ERR, "Parent directory does not exist."

	class jsDirectoryEntry extends jsEntry
		constructor: (parent, name) ->
			@children = []
			super parent, name, DIRECTORY_ENTRY
		
		foldPath: (path) ->
			# First simplify parsing
			path = path.trim().replace(SEPERATOR + '.' + SEPERATOR, SEPERATOR)
			
			# Clean up beginning ./
			index = path.indexOf '.' + SEPERATOR
			if index is 0
				path = path.slice 2
			
			path
		
		getChildren: (name_entry) ->
			for child in this.children
				if child.name is name_entry
					return child
			null
		
		@findEntry: (currentEntry, list) ->
			
			for list_entry in list
				
				if list_entry is '..'
					currentEntry = currentEntry.parent
				else
					currentEntry = currentEntry.getChildren list_entry
				
				if currentEntry is null
					return null
			currentEntry
		
		createReader: () ->
			return new jsDirectoryReader this
		
		# DOMString, optional Flags, optional EntryCallback, optional ErrorCallback
		getFile: (path, options, successCallback, errorCallback) ->
			
			if not path
				throw new Error "getFile needs path argument"
			obj = this
			options = options || {} #Make sure we always have options
			func = ->
				path = obj.foldPath path
				path = path.split SEPERATOR
				
				if path[0] is ''
					path = path.splice 1
					currentEntry = obj.filesystem.root
				else
					currentEntry = obj
				
				entry = jsDirectoryEntry.findEntry currentEntry, path
				
				if entry is null and options.create
					name = path.pop()
					
					if path.length is 0
						entry = obj
					else
						entry = jsDirectoryEntry.findEntry currentEntry, path
					
						
					if entry
						entry = new jsFileEntry entry, name
					else
						error = createNoParentError()
						callEventLiberal errorCallback, error
						return
				
				if not (entry is null) and entry.isFile
					callEventLiberal successCallback, entry
					return
			
				if entry is null
					code = window.FileError.NOT_FOUND_ERR
					message = "File was not found"
				else if entry.isDirectory
					code = window.FileError.TYPE_MISMATCH_ERR
					message = "Trying to get directory as a file"
				else
					code = window.FileError.ABORT_ERR
					message = "Unkown error"
				
				error = createFileError code, message
				callEventLiberal errorCallback, error
			callLaterOn func
		
		# DOMString, optional Flags, optional EntryCallback, optional ErrorCallback
		getDirectory: (path, options, successCallback, errorCallback) ->
			
			if not path
				throw new Error "getDirectory needs path argument"
			obj = this
			options = options || {} #Make sure we always have options
			func = ->
				path = obj.foldPath path
				path = path.split SEPERATOR
				
				if path[0] is ''
					path = path.splice 1
					currentEntry = obj.filesystem.root
				else
					currentEntry = obj
				
				entry = jsDirectoryEntry.findEntry currentEntry, path
			
				if entry 
					if options.create and options.exclusive
						error = createFileError window.FileError.ABORT_ERR, "File already exists."
						callEventLiberal errorCallback, error
						return
					else if entry.isFile
						error = createFileError window.FileError.TYPE_MISMATCH_ERR, "Not a Directory but a File."
						callEventLiberal errorCallback, error
						return
				else 
					if not options.create
						error = createFileError window.FileError.NOT_FOUND_ERR, "Directory does not exist."
						callEventLiberal errorCallback, error
						return
					
					name = path.pop()
					entry = jsDirectoryEntry.findEntry currentEntry, path
					
					if entry
						entry = new jsDirectoryEntry entry, name
					else
						error = createNoParentError()
						callEventLiberal errorCallback, error
						return
				
				callEventLiberal successCallback, entry
			callLaterOn func
		
		removeSync: (successCallback, errorCallback) ->
			# According to spec removing with children is not allowed
			if this.children.length is 0
				super successCallback, errorCallback
				return
			callEventLiberal errorCallback, createFileError window.FileError.INVALID_MODIFICATION_ERR, "Removing directory containing children not allowed."
		removeRecursivelySync: (successCallback, errorCallback) ->
			this.children.length = 0
			this.removeSync successCallback, errorCallback
		
		# VoidCallback, optional ErrorCallback
		removeRecursively: (successCallback, errorCallback) ->
			obj = this
			func = ->
				obj.removeRecursivelySync successCallback, errorCallback
			callLaterOn func
			
	class jsRootDirectoryEntry extends jsDirectoryEntry
		constructor: (filesystem, path, name) ->
			super filesystem, name
		
		removeSync: (successCallback, errorCallback) ->
			callEventLiberal errorCallback, createFileError window.FileError.INVALID_MODIFICATION_ERR, "Removing root directory not allowed."
		
		removeRecursivelySync: (successCallback, errorCallback) ->
			# Reuse error handling in removeSync
			this.removeSync successCallback, errorCallback
		
	class jsDirectoryReader
		constructor: (dirEntry) ->
			Object.defineProperty this, "dirEntry", {value : dirEntry }
		
		@_allRead: false
		
		# EntriesCallback, optional ErrorCallback 
		readEntries: (successCallback, errorCallback) ->
			obj = this
			func = ->
				if obj._allRead
					callEventLiberal successCallback, []
				else
					obj._allRead = true;
					# Return copy so we can be sure that children are not modified
					# by invoker
					callEventLiberal successCallback, obj.dirEntry.children.slice 0
			callLaterOn func

	class jsFileSystem
		@_maxByteCount   = 0
		@_availByteCount = 0
		@_usedByteCount  = 0
		
		constructor: (type, byte_count, dataStorage) ->
			@_type = type
			@_maxByteCount = byte_count
			@_availByteCount = @_maxByteCount
			
			Object.defineProperty this, "name", { value : "whatever" }
			
			rootEntry = new jsRootDirectoryEntry this, "/", ''
			Object.defineProperty this, 'root', { get: -> rootEntry }
			
		reserveBytes: (byteCount) ->
			
			if not byteCount instanceof Number
				# Assume this is an Entry
				byteCount = byteCount._byteCount
			
			if (@_usedByteCount + byteCount) > @_maxByteCount
				return false
			
			@_usedByteCount += byteCount
			@_availByteCount -= byteCount
			return true

	window.TEMPORARY  = 0
	window.PERSISTENT = 1
	
	class jsLocalFileSystem
		constructor: () ->
		filesystems = []
		
		createFilesystem = (type, size, dataStorage) ->
			fs = new jsFileSystem type, size, dataStorage
			filesystems.push fs
			fs
		
		# unsigned short, unsigned long long, FileSystemCallback, optional ErrorCallback
		@requestFileSystem: (type, size, successCallback, errorCallback) ->
			if not (type is PERSISTENT or type is TEMPORARY)
				if errorCallback 
					func = ->
						error = createFileError window.FileError.ABORT_ERR, "Wrong type. <" + type + "> is not supported."
						callEventLiberal errorCallback, error
					
					callLaterOn func
			
			else if window.indexedDB
				request = window.indexedDB.open "filesystem.js_"
				request.onsuccess = ->
					fs = createFilesystem type, size, new jsDatabaseDataStorage request.result
					callEventLiberal successCallback, fs
				
				request.onerror = ->
					error = createFileError window.FileError.ABORT_ERR, ""
					callEventLiberal errorCallback, error
				
			else if window.localStorage
				fs = createFilesystem type, size, new jsLocalDataStorage window.localStorage
				func = ->
					callEventLiberal successCallback, fs
				callLaterOn func
			else
				func = ->
					error = createFileError window.FileError.ABORT_ERR, "IndexedDB and localStorage are not supported."
					callEventLiberal errorCallback, error
				callLaterOn func

	window.requestFileSystem = jsLocalFileSystem.requestFileSystem
	window.useFileSystemEmulation = true

