package com.maxapps.fluiddb {
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequestHeader;
	
	
	/**
	 * FluidDB specific error which adds an instances of FluidDBAction and URLLoader.
	 * 
	 * FluidDBAction is a carrier mechanism for asynchronous calls and the URLLoader is used to 
	 * provide access to the Response headers.
	 * 
	 * @see	FluidDBAction
	 * @see	flash.net.URLLoader
	 */
	public class FluidDBError extends Error {

		// STATIC --------------------------------------------------------------------------------------
		
		// Error constants
		public static const	ERR_NOT_PRIMITIVE:int					= 100;
		public static const	ERR_NOT_PRIMITIVE_MSG:String	= "Value is not a valid FluidDB primitive";
		
		
		/**
		 * Constructor()
		 * 
		 * @param	sMsg			Message about error which occurred.
		 * @param	iID				[0] ID of error which occurred.
		 * @param	mdlAct		[null] Instance of FluidDBAction created by the FluidDBService method 
		 * 									which initiated a call to the FluidDB API.
		 * @param	urlLoad		[null] Instance of the URLLoader used to make the API call.
		 * 
		 * @see	FluidDBAction
		 * @see	FluidDBService
		 * @see	flash.net.URLLoader
		 */
		public function FluidDBError(
				sMsg:String, iID:int=0, mdlAct:FluidDBAction=null, urlLoad:URLLoader=null) {
			super(sMsg, iID);
			
			_action = mdlAct;
			if (_action) {
				_action.error = this;
			}
			
			_loader = urlLoad;
			_responseStatus = mdlAct.responseStatus;
			
			parseHeaders();
			setResponseInfo();
		}
		
		
		// PUBLIC --------------------------------------------------------------------------------------
		
		/**
		 * Instance of FluidDBAction which can be used to access information about the API call.
		 * 
		 * @see	FluidDBAction
		 */
		public function get action():FluidDBAction {
			return _action;
		}
		public function set action(mdlVal:FluidDBAction):void {
			_action = mdlVal;
		}
		
		
		/**
		 * Instance of URLLoader.
		 * 
		 * @see	flash.net.URLLoader
		 */
		public function get loader():URLLoader {
			return _loader;
		}
		public function set loader(objVal:URLLoader):void {
			_loader = objVal;
		}
		
		
		/**
		 * When calls to FluidDB are unsuccessful, the API often returns a response header with the 
		 * name of an error class. This property simply represents the value of the 
		 * "X-Fluiddb-Error-Class" response header.
		 */
		public function get responseErrorClass():String {
			return _responseErrorClass;
		}
		public function set responseErrorClass(sVal:String):void {
			_responseErrorClass = sVal;
		}
		
		
		/**
		 * A string description of the HTTP response code (responseStatus) in plain english.
		 * 
		 * @see responseStatus
		 */
		public function get responseInfo():String {
			return _responseInfo;
		}
		public function set responseInfo(sVal:String):void {
			_responseInfo = sVal;
		}
		
		
		/**
		 * Value of the "X-Fluiddb-Request-Id" response header from the API call.
		 */
		public function get responseRequestID():String {
			return _responseRequestID;
		}
		public function set responseRequestID(sVal:String):void {
			_responseRequestID = sVal;
		}
		
		
		/**
		 * The HTTP response code from the API call.
		 */
		public function get responseStatus():int {
			return _responseStatus;
		}
		public function set responseStatus(iVal:int):void {
			_responseStatus = iVal;
		}
		
		// PROTECTED -----------------------------------------------------------------------------------
		
		// PRIVATE -------------------------------------------------------------------------------------
		
		private var _action:FluidDBAction;
		private var _loader:URLLoader;
		private var _responseErrorClass:String;
		private var _responseInfo:String = "";
		private var _responseRequestID:String;
		private var _responseStatus:int;
		

		// parseHeaders()
		private function parseHeaders():void {
			var urlHdr:URLRequestHeader;
			
			if (_action.responseHeaders) {
				for (var i:int = 0; i < _action.responseHeaders.length; ++i) {
					urlHdr = _action.responseHeaders[i] as URLRequestHeader;
					switch (urlHdr.name) {
						case "X-Fluiddb-Error-Class":	_responseErrorClass = urlHdr.value;
						case "X-Fluiddb-Request-Id":	_responseRequestID = urlHdr.value;
					}
				}
			}
		}
		
		
		// setResponseInfo()
		private function setResponseInfo():void {
			var objInfo:Object;
			
			objInfo = FluidDBResponseDecode.RESPONSE_MESSAGES[_action.action];
			if (objInfo) {
				if (objInfo[_responseStatus]) {
					_responseInfo = objInfo[_responseStatus] as String;
				}
			}
		}
		
		
	}
}