package com.maxapps.fluiddb {
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequestHeader;
	
	/**
	 * Error event generated by FluidDBService for calls to the FluidDB API which result in 
	 * an error response.
	 * 
	 * @see	FluidDBAction
	 * @see	FluidDBService
	 */
	public class FluidDBErrorEvent extends FluidDBEvent {

		// STATIC --------------------------------------------------------------------------------------
		
		public static const ERROR:String	= "error";

	
		/**
		 * Constructor()
		 * 
		 * @param	sType			Type of event.
		 * @param	errFluid	Instance of FluidDBError with information about the error.
		 * 
		 * @see	FluidDBError
		 */
		public function FluidDBErrorEvent(sType:String, errFluid:FluidDBError) {
			super(sType, errFluid.action, errFluid.loader);
			
			_error = errFluid;
		}


		// PUBLIC --------------------------------------------------------------------------------------
		
		/**
		 * Instance of FluidDBError associated with this event.
		 * 
		 * @see	FluidDBError
		 */
		public function get error():FluidDBError {
			return _error;
		}
		public function set error(errVal:FluidDBError):void {
			_error = errVal;
		}

		// PROTECTED -----------------------------------------------------------------------------------
		
		// PRIVATE -------------------------------------------------------------------------------------
		
		private var _error:FluidDBError;

	}
}