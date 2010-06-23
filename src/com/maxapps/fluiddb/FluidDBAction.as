package com.maxapps.fluiddb {
	import flash.net.URLRequestHeader;
	
	
	/**
	 * Utility class for storing information about actions executed against FluidDB. 
	 * 
	 * An instance of this class is created for any method of FluidDBService which accesses the API.
	 * The instance is available via the methods' callback parameter or in the "action" property of 
	 * the FluidDBEvent and FluidDBErrorEvent instances.
	 * 
	 * The primary purpose of this class is to be a transfer mechanism for information about the API 
	 * call to asynchronous event handlers. As such it stores information about the name of the 
	 * FluidDBService method called, the HTTP method used, and response info from the API.
	 * 
	 * @see	FluidDBService
	 * @see	http://doc.fluidinfo.com/fluidDB/api/index.html
	 */
	public class FluidDBAction {
		
		// STATIC --------------------------------------------------------------------------------------
		
		/**
		 * Character used to replace spaces in Namespaces.
		 * 
		 * <b>Note:</b> This will probably be replaced by URI encoding in a future version.
		 * 
		 * @see	http://doc.fluidinfo.com/fluidDB/api/namespaces-and-tags.html
		 */
		public static var NS_SPC:String	= "_";
		
		
		/**
		 * Constructor()
		 * FluidDBAction instances are automatically created as needed. You should not need to access 
		 * this constructor directly.
		 * 
		 * @param	sAction		Action begin performed (ie createNamespace, getTag, etc).
		 * @param	sPath			Path used to perform action.
		 * @param	sMethod		Method to use (GET, POST, DELETE, etc).
		 * @param	fncCB			[null] Callback function supplied by method called on FluidDBService.
		 */
		public function FluidDBAction(
				sAction:String, sPath:String, sMethod:String, fncCB:Function=null) {
			_action = sAction;
			_method = sMethod;
			_callback = fncCB;
			
			_path = sPath.replace(/ /g, NS_SPC);
		}
		
		
		// PUBLIC --------------------------------------------------------------------------------------
		
		/**
		 * Name of the FluidDBService method which created this instance.
		 */
		public function get action():String {
			return _action;
		}
		public function set action(sVal:String):void {
			_action = sVal;
		}
		
		
		/**
		 * Callback function (if any) provided to the method which created this instance.
		 */
		public function get callback():Function {
			return _callback;
		}
		public function set callback(fncVal:Function):void {
			_callback = fncVal;
		}
		
		
		/**
		 * If the API call was unsuccessful, an instance of FluidDBError will be stored here. This is 
		 * helpful when callback functions are used instead of event handlers.
		 * 
		 * @see	FluidDBError
		 */
		public function get error():FluidDBError {
			return _error;
		}
		public function set error(errVal:FluidDBError):void {
			_error = errVal;
		}
		
		
		/**
		 * The HTTP method used in the API call (GET, PUT, etc).
		 */
		public function get method():String {
			return _method;
		}
		public function set method(sVal:String):void {
			_method = sVal;
		}
		
		
		/**
		 * The URI path used to perform call to the API.
		 */
		public function get path():String {
			return _path;
		}
		public function set path(sVal:String):void {
			_path = sVal;
		}
		
		
		/**
		 * Raw response data returned by the API call. Not all API calls return any data.
		 * In this version of the API, most calls which return data do so as a JSON formatted string.
		 * 
		 * The FluidDBService's decodeResponse() method can be used to convert the data to an object.
		 * 
		 * @see	FluidDBService
		 * @see	FluidDBService.decodeResponse()
		 * @see	http://doc.fluidinfo.com/fluidDB/api/http.html
		 */
		public function get response():String {
			return _response;
		}
		public function set response(sVal:String):void {
			_response = sVal;
		}
		
		
		/**
		 * An array of URLRequestHeader instances returned by the API response.
		 * 
		 * @see	flash.net.URLRequestHeader
		 */
		public function get responseHeaders():Array {
			return _responseHeaders;
		}
		public function set responseHeaders(arrVal:Array):void {
			_responseHeaders = arrVal;
		}
		
		
		/**
		 * Checks the responseHeaders to see if JSON formatted data was returned.
		 * Most payload data returned by calls to the API are returned as JSON formatted strings but 
		 * certain calls can return data in whatever format was used to store it. This is a quick way 
		 * to check.
		 * 
		 * @see	http://doc.fluidinfo.com/fluidDB/api/tag-values.html
		 * @see	http://doc.fluidinfo.com/fluidDB/api/http.html#payloads-containing-tag-values
		 */
		public function responseIsJSON():Boolean {
			return (responseType == "application/vnd.fluiddb.value+json");
		}
		
		
		/**
		 * The HTTP response code provided by the API call.
		 * 
		 * @see	http://doc.fluidinfo.com/fluidDB/api/http.html
		 */
		public function get responseStatus():int {
			return _responseStatus;
		}
		public function set responseStatus(iVal:int):void {
			_responseStatus = iVal;
		}
		
		
		/**
		 * Returns the value of the "Content-Type" response header.
		 */
		public function get responseType():String {
			return getHeaderValue("Content-Type", "unknown");
		}
		
		
		/**
		 * Uses value of reponseStatus as a quick and easy way to check if the API call was successful.
		 * 
		 * Some API calls, notably HEAD /objects/id/namespace1/namespace2/tag (used by checkForTag()) 
		 * use an error response to indicate a valid response. In this case, a value of false for the 
		 * success property might not be accurate.
		 * 
		 * @see	FluidDBService.checkForTag()
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\objects/HEAD
		 */
		public function get success():Boolean {
			return (int(_responseStatus / 100) == 2);
		}
		
		
		/**
		 * Get the value of the specified response header.
		 * 
		 * @param	sName			Name of response header to return value for.
		 * @param	sDefault	[''] Default value to return if header doesn't exist.
		 * 
		 * @return	Returns value of specified response header or default value if header 
		 * 					does not exist.
		 */
		public function getHeaderValue(sName:String, sDefault:String=""):String {
			var sRet:String;
			var urlHdr:URLRequestHeader;
			
			sRet = sDefault;
			
			if (_responseHeaders) {
				for (var i:int = 0; i < _responseHeaders.length; ++i) {
					urlHdr = _responseHeaders[i] as URLRequestHeader;
					if (urlHdr.name == sName) {
						sRet = urlHdr.value;
						break;
					}
				}
			}
			
			return sRet;
		}


		// PROTECTED -----------------------------------------------------------------------------------
		
		// PRIVATE -------------------------------------------------------------------------------------
		
		private var _action:String;
		private var _callback:Function;
		private var _error:FluidDBError;
		private var _method:String;
		private var _path:String;
		private var _response:String = "";
		private var _responseHeaders:Array;
		private var _responseStatus:int;
		
	}
}