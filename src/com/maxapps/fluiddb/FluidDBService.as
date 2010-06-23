package com.maxapps.fluiddb {
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.net.URLRequestDefaults;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import com.adobe.serialization.json.JSON;
	import com.maxapps.fluiddb.FluidDBAction;
	import mx.utils.Base64Encoder;
	import flash.net.URLRequestHeader;
	import flash.events.HTTPStatusEvent;
	
	/**
	 * Adobe AIR library for communicating with the FluidDB API.
	 * 
	 * @author		Jeff Carver <maxapps@gmail.com>
	 * @version 	1.0.1
	 * @date			May 31, 2010
	 * @copyright	Copyright Jeff Carver 2010. All Rights Reserved.
	 */
		 
	/**
	 * FluidDBService
	 * 
	 * FluidDBService is an Adobe AIR specific AS3 library for communicating with the fantastic 
	 * FluidDB API. Unfortunately, AIR is required because of a need to to set specific request 
	 * headers and to view response headers. I could find no straight forward way of doing this 
	 * from vanilla flash. The JS libraries manage it by utilizing jQuery. An inspection of 
	 * which would probably lead to a valid method.
	 * 
	 * This service implements the entire FluidDB API as of version 20100109. I will try to keep it 
	 * updated as the FluidDB API matures but there are no guarantees. I also plan to add some 
	 * additional helper methods to do things like automatically creating tags if they don't already 
	 * exist when tagging an object, etc.
	 * 
	 * USAGE:
	 * 
	 * There are two different ways to use this service. The first (and probably best) way is to 
	 * create the service and add event listeners for the FluidDBEvent.COMPLETE and 
	 * FluidDBErrorEvent.ERROR events. Obviously, all methods which access the FluidDB API are 
	 * asynchronous and the appropriate event is fired as needed.
	 * 
	 * @example
	 * 		private var svcDB:FluidDBService;
	 * 		
	 * 		// The creationComplete event handler for the application.
	 * 		private function creationComplete():void {
	 * 			svcDB = new FluidDBService();
	 * 			svcDB.useSandbox = true;								// causes the service to use sandbox
	 * 			svcDB.setCredentials("test", "test");		// the sandbox credentials
	 * 			
	 * 			svcDB.addEventListener(FluidDBEvent.COMPLETE, handleComplete);
	 * 			svcDB.addEventListener(FluidDBErrorEvent.ERROR, handleError);
	 * 			
	 * 			svcDB.getUser("test");
	 *		}
	 * 		
	 * 		
	 * 		// handleComplete(evt)
	 * 		private function handleComplete(evt:FluidDBEvent):void {
	 * 			Alert.show("Call to " + evt.action.action + " was successful!\n\n"
	 * 					+ "RESPONSE:\n" + evt.response, "Success");
	 * 		}
	 * 		
	 * 		
	 * 		// handleError(evt)
	 * 		private function handleError(evt:FluidDBErrorEvent):void {
	 * 			if (!checkSandbox) {
	 * 				Alert.show("Error contacting FluidDB\n\n"
	 * 						+ "ACTION:\t" + evt.action.action + "\n"
	 * 						+ "STATUS:\t" + evt.error.responseStatus + "\n"
	 * 						+ "INFO:\t" + evt.error.responseInfo + "\n\n"
	 * 						+ "ERROR:\t" + evt.error.errorID + "\n"
	 * 						+ "MESSAGE:\t" + evt.error.message + "\n\n"
	 * 						+ "RESPONSE:\n" + evt.response, "Error");
	 * 			} else {
	 * 				checkSandbox = false;
	 * 				tbnMain.enabled = true;
	 * 			}
	 * 		}
	 * 
	 * 
	 * The second way involves the use of callback functions. All methods which access the API have 
	 * an optional parameter which accepts a callback function. This callback function nust accept 
	 * a single parameter which is an instance of FluidDBAction.
	 * 
	 * @example
	 * 		// The creationComplete event handler for the application.
	 * 		private function creationComplete():void {
	 * 			var svcDB:FluidDBService;
	 * 			
	 * 			function _onResponse(mdlAct:FluidDBAction):void {
	 * 				var objUser:Object;
	 * 				
	 * 				if (mdlAct.success) {
	 * 					objUser = svcDB.decodeResponse(mdlAct.response);
	 * 					Alert.show("NAME:\t" + objUser.name + "\nID:\t" + objUser.id, "Response");
	 * 				} else {
	 * 					Alert.show(mdlAct.error.responseInfo + "\n\n" + mdlAct.error.message);
	 * 				}
	 * 			}
	 * 			
	 * 			svcDB = new FluidDBService();
	 * 			svcDB.useSandbox = true;								// causes the service to use sandbox
	 * 			svcDB.setCredentials("test", "test");		// the sandbox credentials
	 * 			
	 * 			svcDB.getUser("jcarvers", _onResponse);
	 *		}
	 * 
	 * 
	 * RETURN VALUES:
	 * 
	 * Because of their asynchronous nature, no functions which access the API have a return value. 
	 * Instead, the documentation shows what is returned in the response from the API call.
	 * 
	 * Response info is available from the FluidDBAction class in the following properties:
	 * 		response				If call was successful, contains any response payload from API. Use the 
	 * 										FluidDBService's decodeResponse() method to convert this to the type of 
	 * 										data indicated by the contentType property (JSON only for now).
	 * 		responseIsJSON	Indicates whether the response payload is in JSON format. Even though this 
	 * 										is the only native format supported, it is possible to store any MIME type 
	 * 										data in FluidDB. Certain methods, such as getObjectTag() will return the 
	 * 										data in it's original format. This is a quick way to check.
	 * 		responseStatus	The HTTP response code returned by the API. Should always be a 200 series 
	 * 										number on success and, normally, a 400 series for errors.
	 * 		responseType		The value of the "Content-Type" response header. A value of 
	 * 										"application/vnd.fluiddb.value+json" indicates a JSON primitive value.
	 * 										Any other value indicates an opaque data type was stored. See 
	 * 										http://doc.fluidinfo.com/fluidDB/api/tag-values.html for more info.
	 * 		success					A quick way to check if the call was successful. Note that this just checks 
	 * 										for a 200 series number in the responseStatus. Some methods, such as 
	 * 										checkForTag() can use an error response to indicate meaningful information.
	 * 
	 * An instance of FluidDBAction is passed to the optional callback parameter of all methods 
	 * which access the API. The FluidDBEvent and FluidDBErrorEvent both contain an instance of 
	 * FluidDBAction in their "action" properties.
	 * 
	 * 
	 * @see http://fluidinfo.com/developers/documentation
	 */
	public class FluidDBService extends EventDispatcher {
		
		// STATIC --------------------------------------------------------------------------------------
		
		// Version constants
		public static const VERSION:String		= "1.0.1";
		public static const VERSION_DB:String	= "20100109";
		
				
		/**
		 * Constructor()
		 */
		public function FluidDBService(objTarget:IEventDispatcher=null) {
			super(objTarget);
		}


		// PUBLIC --------------------------------------------------------------------------------------
		
		/**
		 * The type of content returned by the response. JSON is the only option for now but the 
		 * property exists to help with future changes of the API.
		 * 
		 * This property will help allow the decodeResponse() method to convert responses from 
		 * the API into meaningful data.
		 *  
		 * @see decodeResponse()
		 * @see	http://doc.fluidinfo.com/fluidDB/api/http.html
		 */
		public function get contentType():String {
			return _contentType;
		}
		public function set contentType(sVal:String):void {
			// do nothing for now...
		}
		
		
		/**
		 * Set to true for secure access using https://fluiddb.fluidinfo.com
		 * 
		 * @see http://doc.fluidinfo.com/fluidDB/api/http.html
		 */
		public var useHttps:Boolean = false;
		
		
		/**
		 * If set to true, the sandbox instance of FluidDB is used. The sandbox always contains 
		 * a user named "test" with a password of "test".
		 * 
		 * @see http://doc.fluidinfo.com/fluidDB/api/sandbox.html
		 */
		public var useSandbox:Boolean = false;
		
		
		/**
		 * Checks for the existence of a tag on an object.
		 * 
		 * This function will check if the named tag exists on the object specified. Note that the 
		 * tag must already be defined BEFORE it can be checked for.
		 * 
		 * @param	sID			Unique ID of the object to check.
		 * @param	sTag		Full path of the tag to check for.
		 * @param	fncCB		[null] Optional callback function. If provided, the function must accept 
		 * 								an instance of FluidDBAction.
		 * 
		 * @return	API doesn't actually return a payload for this method. If the call is successful, 
		 * 					the tag exists. If the HTTP response status code is 404, the tag either does not 
		 * 					exist or the user does not have SEE permission for the tag. In this version of 
		 * 					the API, there is no way to tell the difference.
		 * 					The FluidDBAction instance (provided to callback function or via action property of 
		 * 					the FluidDBErrorEvent) exposes the response code in it's responseStatus property.
		 * 
		 * @see createObjectTag()
		 * @see	FluidDBAction
		 * @see	FluidDBEvent
		 * @see	FluidDBErrorEvent
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\objects/HEAD
		 */
		public function checkForTag(sID:String, sTag:String, fncCB:Function=null):void {
			var mdlAct:FluidDBAction;
			
			mdlAct = new FluidDBAction("checkForTag", DB_OBJECTS + sID + "/" + sTag, METHOD_HEAD, fncCB);
			callAPI(mdlAct);
		}
		
		
		/**
		 * Creates a new namespace.
		 * 
		 * @param	sPath		Path to create namespace on (existing namespace delimited by "/"). 
		 * 								Namespaces are used in the URI for many other methods of the API so cannot 
		 * 								contain spaces or other "special" characters. At the moment, spaces are 
		 * 								replaced by underscores (_) but a better implementation is probably needed.
		 * @param	sName		Name for the new namespace.
		 * @param	sDesc		Description of this namespace.
		 * @param	fncCB		[null] Optional callback function. If provided, the function must accept 
		 * 								an instance of FluidDBAction.
		 * 
		 * @return	API returns:
		 * 						id		The id of the object which corresponds to the new namespace.
		 * 						URI		The URI of the new namespace.
		 * 
		 * @see	deleteNamespace()
		 * @see	updateNamespace()
		 * @see	http://doc.fluidinfo.com/fluidDB/namespaces.html
		 * @see	http://doc.fluidinfo.com/fluidDB/api/namespaces-and-tags.html
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\namespaces/POST
		 * 
		 * @example
		 * 		svcDB.createNamespace("test/jcarver", "testing", "Description of testing...");
		 */
		public function createNamespace(
				sPath:String, sName:String, sDesc:String, fncCB:Function=null):void {
			var mdlAct:FluidDBAction;
			
			sName = sName.replace(/ /g, FluidDBAction.NS_SPC);
			
			mdlAct = new FluidDBAction("createNamespace", DB_NAMESPACES + sPath, METHOD_POST, fncCB);
			callAPI(mdlAct, null, {name:sName, description:sDesc});
		}
		
		
		/**
		 * Creates a new object.
		 * 
		 * @param	sAbout	[''] Optional information about the new object.
		 * @param	fncCB		[null] Optional callback function. If provided, the function must accept 
		 * 								an instance of FluidDBAction.
		 * 
		 * @return	API returns:
		 * 						id		The id of the new object.
		 * 						URI		The URI of the new object.
		 * 
		 * @see	getObject()
		 * @see	queryForObject()
		 * @see	http://doc.fluidinfo.com/fluidDB/objects.html
		 * @see	http://doc.fluidinfo.com/fluidDB/api/objects.html
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\objects/POST
		 */
		public function createObject(sAbout:String="", fncCB:Function=null):void {
			var objPayload:Object;
			var mdlAct:FluidDBAction;
			
			objPayload = {};
			if (sAbout != "") objPayload.about = sAbout;
			
			mdlAct = new FluidDBAction("createObject", DB_OBJECTS, METHOD_POST, fncCB);
			callAPI(mdlAct, null, objPayload);
		}
		
		
		/**
		 * Creates or updates a primitive tag on an object. Use this method to assign any of the 
		 * FluidDB primitive value types (null|boolean|int|float|string|set). To store any other type 
		 * of information, use the createOpaqueObjectTag() which allows you to specify the MIME type. 
		 * See the links below for more information in the API docs.
		 * 
		 * There is an alias for this method named tagObject() which might sound better syntactically.
		 * 
		 * @param	sID			Unique ID of object to assign tag to.
		 * @param	sTag		Tag to assign to the object. Note that the tag must already exist.
		 * @param	vValue	Value to associate with this tag assignment.
		 * @param	fncCB		[null] Optional callback function. If provided, the function must accept 
		 * 								an instance of FluidDBAction.
		 * 
		 * @return	API returns no data.
		 * 
		 * @see	createOpaqueObjectTag()
		 * @see createTag()
		 * @see tagObject()
		 * @see	http://doc.fluidinfo.com/fluidDB/api/tag-values.html
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\objects/PUT
		 */
		public function createObjectTag(sID:String, sTag:String, vValue:*, fncCB:Function=null):void {
			if (isPrimitive(vValue)) {
				createOpaqueObjectTag(sID, sTag, vValue, CONTENT_TYPE_JSON_VAL, null, fncCB);
			} else {
				throw new FluidDBError(FluidDBError.ERR_NOT_PRIMITIVE_MSG, FluidDBError.ERR_NOT_PRIMITIVE);
			}
		}
		
		
		/**
		 * Creates or updates an opaque tag on an object. An opaque tag assignment can be used to store 
		 * any type of information by allowing you to specify the MIME tag. Use createObjectTag() or 
		 * tagObject() to store any of the primitive value types.
		 * 
		 * There is an alias for this method named tagObjectOpaque() which might sound 
		 * better syntactically.
		 *  
		 * @param	sID					Unique ID of object to assign tag to.
		 * @param	sTag				Tag to assign to the object. Note that the tag must already exist.
		 * @param	vValue			Value to associate with this tag assignment.
		 * @param	sType				MIME type of the object. Used to identify type when value is retrieved.
		 * @param	fncEndcode	[null] An optional callback function used to convert the value supplied 
		 * 										to a string for passing to the API. Function must accept:
		 * 											A variant with the value to convert.
		 * 											A string indicating the MIME type.
		 *										The function must also return a string.
		 * @param	fncCB				[null] Optional callback function. If provided, the function must accept 
		 * 										an instance of FluidDBAction.
		 * 
		 * @return	API returns no data.
		 * 
		 * @see	createObjectTag()
		 * @see createTag()
		 * @see tagObject()
		 * @see tagObjectOpaque()
		 * @see	http://doc.fluidinfo.com/fluidDB/api/tag-values.html
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\objects/PUT
		 */
		public function createOpaqueObjectTag(sID:String, sTag:String, vValue:*, 
				sType:String, fncEncode:Function=null, fncCB:Function=null):void {
			var sValue:String;
			var mdlAct:FluidDBAction;
			var urlHdr:URLRequestHeader;
			
			sValue = (fncEncode == null) ? String(vValue) : fncEncode(vValue, sType);
			urlHdr = new URLRequestHeader("Content-Type", sType);
			
			mdlAct = new FluidDBAction(
					"createOpaqueObjectTag", DB_OBJECTS + sID + "/" + sTag, METHOD_PUT, fncCB);
			callAPI(mdlAct, null, sValue, [urlHdr]);
		}
		
		
		/**
		 * Creates a new tag on the namespace provided.
		 * 
		 * Note that this method creates a tag itself, NOT the value of a tag on a particular object 
		 * (for that, use createObjectTag() or tagObject().
		 * 
		 * @param	sPath		Path to create tag on.
		 * @param	sName		Name of tag to create.
		 * @param	sDesc		Description of the new tag.
		 * @param	fIndex	[false] Optional parameter indicating whether the tag should be indexed.
		 * @param	fncCB		[null] Optional callback function. If provided, the function must accept 
		 * 								an instance of FluidDBAction.
		 * 
		 * @return	API returns:
		 * 						id		The id of the object that corresponds to the new tag.
		 * 						URI		The URI of the new object.
		 * 
		 * @see	createObjectTag()
		 * @see	tagObject()
		 * @see	updateTagInfo() 
		 * @see	http://doc.fluidinfo.com/fluidDB/tags.html#tag-types
		 * @see	http://doc.fluidinfo.com/fluidDB/api/namespaces-and-tags.html
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\tags/POST
		 */
		public function createTag(
				sPath:String, sName:String, sDesc:String, fIndex:Boolean=false, fncCB:Function=null):void {
			var mdlAct:FluidDBAction;
			
			mdlAct = new FluidDBAction("createTag", DB_TAGS + sPath, METHOD_POST, fncCB);
			callAPI(mdlAct, null, {name:sName, indexed:fIndex, description:sDesc});
		}
		
		
		/**
		 * Decodes a response returned by successfully calling any method which accesses 
		 * the FluidDB API.
		 * 
		 * Currently, the FluidDB API only returns responses as JSON formatted strings. This function 
		 * provides for future expansion to additional formats.
		 * 
		 * @param	vResponse		Response from call to FluidDB API.
		 * 
		 * @return	Returns the response converted to the type of data specfied by the 
		 * 					contentType property (at the moment, only JSON is supported by the API).
		 * 
		 * @see	contentType
		 * @see	http://doc.fluidinfo.com/fluidDB/api/http.html
		 * 
		 * @example
		 * 		svcDB.createObject("New Test Object", onResponse);
		 * 		
		 * 		function onResponse(mdlAct:FluidDBAction):void {
		 * 			var sNewID:String;
		 * 			
		 * 			if (mdlAct.success) {
		 * 				// the API returned an object with id and uri properties.
		 * 				sNewID = svcDB.decodeResponse(mdlAct.response).id;
		 *			}
		 * 		} 
		 */
		public function decodeResponse(vResponse:*):* {
			var vRet:*;
			
			// AT PRESENT, THE ONLY FORMAT AVAILABLE IS JSON...
			if (_contentType == CONTENT_TYPE_JSON) {
				vRet = JSON.decode(vResponse as String);
			}
			
			return vRet;
		}
		
		
		/**
		 * Deletes the specified namespace.
		 * 
		 * Note that a namespace can only be deleted if it is empty which means it cannot contain any 
		 * sub-namespaces or tags.
		 * 
		 * @param	sNS			Namespace to delete (full path).
		 * @param	fncCB		[null] Optional callback function. If provided, the function must accept 
		 * 								an instance of FluidDBAction.
		 * 
		 * @return	API returns no data.
		 * 
		 * @see	createNamespace()
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\namespaces/DELETE
		 */
		public function deleteNamespace(sNS:String, fncCB:Function=null):void {
			var mdlAct:FluidDBAction;
			
			mdlAct = new FluidDBAction("deleteNamespace", DB_NAMESPACES + sNS, METHOD_DELETE, fncCB);
			callAPI(mdlAct);
		}
		
		
		/**
		 * Deletes a tag from an object.
		 * 
		 * Note that it is NOT possible to delete a FluidDB object.
		 * 
		 * @param	sID			Unique ID of object to remove tag from.
		 * @param	sTag		Name of tag to remove from object.
		 * @param	fncCB		[null] Optional callback function. If provided, the function must accept 
		 * 								an instance of FluidDBAction.
		 * 
		 * @return	API returns no data.
		 * 
		 * @see	createObjectTag()
		 * @see	deleteTag()
		 * @see	http://doc.fluidinfo.com/fluidDB/objects.html#objects-are-never-deleted
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\objects/DELETE
		 */
		public function deleteObjectTag(sID:String, sTag:String, fncCB:Function=null):void {
			var mdlAct:FluidDBAction;
			
			mdlAct = new FluidDBAction(
					"deleteObjectTag", DB_OBJECTS + sID + "/" + sTag, METHOD_DELETE, fncCB);
			callAPI(mdlAct);
		}
		
		
		/**
		 * Deletes a tag. The tag name is removed from it's containing namespace and all occurences 
		 * of the tag on objects are deleted.
		 * 
		 * @param	sTag		Name of tag to remove.
		 * @param	fncCB		[null] Optional callback function. If provided, the function must accept 
		 * 								an instance of FluidDBAction.
		 * 
		 * @return	API returns no data.
		 * 
		 * @see	createTag()
		 * @see	deleteObjectTag()
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\tags/DELETE
		 */
		public function deleteTag(sTag:String, fncCB:Function=null):void {
			var mdlAct:FluidDBAction;
			
			mdlAct = new FluidDBAction("deleteTag", DB_TAGS + sTag, METHOD_DELETE, fncCB);
			callAPI(mdlAct);
		}
		
		
		/**
		 * Gets permission info (policy and exceptions) for the specified action on a namespace.
		 * 
		 * @param	sNS				Namespace to get permission info for.
		 * @param	sAction		Action to get permission info for (create|update|delete|list|control).
		 * @param	fncCB			[null] Optional callback function. If provided, the function must accept 
		 * 									an instance of FluidDBAction.
		 * 
		 * @return	API returns:
		 * 						exceptions	The names of users who are exceptions to the policy.
		 * 						policy			The policy (either 'open' or 'closed').
		 * 
		 * @see	setNamespacePermits()
		 * @see	http://doc.fluidinfo.com/fluidDB/permissions.html
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\permissions/GET
		 */
		public function getNamespacePermits(sNS:String, sAction:String, fncCB:Function=null):void {
			var mdlAct:FluidDBAction;
			
			mdlAct = new FluidDBAction(
					"getNamespacePermits", DB_PERMISSIONS + "namespaces/" + sNS, METHOD_GET, fncCB);
			callAPI(mdlAct, {action:sAction});
		}
		
		
		/**
		 * Gets a user's default namespace permission policy for the specified action.
		 * 
		 * Just an alias for the getPolicy() method which eliminates the need to specify the category.
		 * 
		 * @param	sUser			User to get policy for.
		 * @param	sAction		Action to get policy for (create|update|delete|list).
		 * @param	fncCB			[null] Optional callback function. If provided, the function must accept 
		 * 									an instance of FluidDBAction.
		 * 
		 * @return	See getPolicy()
		 * 
		 * @see	getPolicy()
		 * @see	setNamespacePolicy()
		 */
		public function getNamespacePolicy(sUser:String, sAction:String, fncCB:Function=null):void {
			getPolicy(sUser, CAT_NAMESPACES, sAction, fncCB);
		}
		
		
		/**
		 * Gets information about the specified namespace.
		 * 
		 * @param	sNS			Namespace to get information for.
		 * @param	fDesc		[false] If true, response includes the namespace description.
		 * @param	fNS			[false]	If true, response includes sub-namespaces in this namespace.
		 * @param	fTags		[false] If true, response includes names of tags in this namespace.
		 * @param	fncCB		[null] Optional callback function. If provided, the function must accept 
		 * 								an instance of FluidDBAction.
		 * 
		 * @return	API returns:
		 * 						id								The ID of the FluidDB object corresponding to the namespace.
		 * 						[description]			A description of the namespace.
		 * 						[namespaceNames]	The names of sub-namespaces in this namespace.
		 * 						[tagNames]				The names of tags in this namespace.
		 * 
		 * @createNamespace()
		 * @updateNamespace()
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\namespaces/GET
		 */
		public function getNamespaces(sNS:String, 
				fDesc:Boolean=false, fNS:Boolean=false, fTags:Boolean=false, fncCB:Function=null):void {
			var objArgs:Object;
			var mdlAct:FluidDBAction;
			
			objArgs = {};
			if (fDesc) objArgs.returnDescription = "true";
			if (fNS) objArgs.returnNamespaces = "true";
			if (fTags) objArgs.returnTags = "true";
			
			mdlAct = new FluidDBAction("getNamespaces", DB_NAMESPACES + sNS, METHOD_GET, fncCB);
			callAPI(mdlAct, objArgs);
		}
		
		
		/**
		 * Gets information about an object using it's unique ID.
		 * 
		 * @param	sID			Unique ID for the object 
		 * @param	fAbout	[false] If true, response includes the value of the about tag on the object.
		 * @param	fncCB		[null] Optional callback function. If provided, the function must accept 
		 * 								an instance of FluidDBAction.
		 * 
		 * @return	API returns:
		 * 						tagPaths	The full path names of the tags on this object (for which the user 
		 * 											has SEE permission).
		 * 						[about]		The value of the about tag on the object (if any).
		 * 
		 * @see	queryForObject()
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\objects/GET
		 */
		public function getObject(sID:String, fAbout:Boolean=false, fncCB:Function=null):void {
			var objArgs:Object;
			var mdlAct:FluidDBAction;
			
			objArgs = {};
			if (fAbout) objArgs.showAbout = "true";
			
			mdlAct = new FluidDBAction("getObject", DB_OBJECTS + sID, METHOD_GET, fncCB);
			callAPI(mdlAct, objArgs);
		}
		
		
		/**
		 * Gets the value of a tag from an object.
		 * 
		 * @param	sID			Unique ID for the object to get value of tag from.
		 * @param	sTag		Name of tag (note that the actual tag must already exist)
		 * @param	fncCB		[null] Optional callback function. If provided, the function must accept 
		 * 								an instance of FluidDBAction.
		 * 
		 * @return	How the API returns the data depends on what type of value was stored. Primitive 
		 * 					values (stored using createObjectTag() or tagObject()) are returned in the 
		 * 					format specified by the contentType property (JSON only for now). 
		 * 					Opaque values (those stored using createOpaqueObjectTag() or tagObjectOpaque()) are 
		 * 					returned exactly as they were stored. The FluidDBAction's responseIsJSON and 
		 * 					responseType properties should be used to determine the type of data returned.
		 * 
		 * @see contentType
		 * @see	createObjectTag()
		 * @see	createOpaqueObjectTag()
		 * @see	tagObject()
		 * @see	tagObjectOpaque()
		 * @see	FluidDBAction
		 * @see	http://doc.fluidinfo.com/fluidDB/api/tag-values.html
		 * @see	http://doc.fluidinfo.com/fluidDB/api/http.html#payloads-containing-tag-values
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\objects/GET
		 */
		public function getObjectTag(sID:String, sTag:String, fncCB:Function=null):void {
			var mdlAct:FluidDBAction;
			
			mdlAct = new FluidDBAction("getObjectTag", DB_OBJECTS + sID + "/" + sTag, METHOD_GET, fncCB);
			callAPI(mdlAct);
		}
		
		
		/**
		 * Gets a user's default permission policy for a specified category and action. These are the 
		 * permissions which will be assigned to new tags and namespaces created by the user.
		 * 
		 * There are also three alias methods: getNamespacePolicy(), getTagPolicy() and 
		 * getTagValuePolicy() which eliminate the need to specify the category.
		 * 
		 * @param	sUser				User to get policy for.
		 * @param	sCategory		Category to get policy for (namespaces|tags|tag-values).
		 * @param	sAction			Action to get policy for. Actions vary by category as follows:
		 * 											For namespaces:	create|update|delete|list
		 * 											For tags:				update|delete
		 * 											For tag_values:	see|create|read|update|delete
		 * @param	fncCB				[null] Optional callback function. If provided, the function must accept 
		 * 										an instance of FluidDBAction.
		 * 
		 * @return	API returns:
		 * 						exceptions	The names of users who are exceptions to the policy.
		 * 						policy			The policy (either 'open' or 'closed').
		 * 
		 * @see	getNamespacePolicy()
		 * @see	getTagPolicy()
		 * @see	getTagValuePolicy()
		 * @see	setPolicy()
		 * @see	http://doc.fluidinfo.com/fluidDB/permissions.html
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\policies/GET
		 */
		public function getPolicy(
				sUser:String, sCategory:String, sAction:String, fncCB:Function=null):void {
			var mdlAct:FluidDBAction;
			
			mdlAct = new FluidDBAction(
					"getPolicy", DB_POLICIES + sUser + "/" + sCategory + "/" + sAction, METHOD_GET, fncCB);
			callAPI(mdlAct);
		}
		
		
		/**
		 * Gets information about a tag.
		 * 
		 * <b>Note:</b> This method retrieves information about the tag itself, NOT the value of a tag 
		 * on an object. To get that value, use the getObjectTag() method.
		 * 
		 * @param	sTag		Name of tag to get info for.
		 * @param	fDesc		[false] If true, response includes the tag's description.
		 * @param	fncCB		[null] Optional callback function. If provided, the function must accept 
		 * 								an instance of FluidDBAction.
		 * 
		 * @return	API returns:
		 * 						id							The ID of the of the FluidDB object corresponding to the tag.
		 * 						indexed					Indicates if the tag values are indexed.
		 * 						[description]		Description of the tag.
		 * 
		 * @see	createTag()
		 * @see	getObjectTag()
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\tags/GET
		 */
		public function getTagInfo(sTag:String, fDesc:Boolean=false, fncCB:Function=null):void {
			var objArgs:Object;
			var mdlAct:FluidDBAction;
			
			objArgs = {};
			if (fDesc) objArgs.returnDescription = "true";
			
			mdlAct = new FluidDBAction("getTagInfo", DB_TAGS + sTag, METHOD_GET, fncCB);
			callAPI(mdlAct, objArgs);
		}
		
		
		/**
		 * Gets permission info (policy and exceptions) for the specified action on a tag.
		 * 
		 * <b>Note:</b> This method gets permissions for the tag itself NOT for the instances of 
		 * of the tag used to assign values to an object. See the getTagValuePermits() method 
		 * for that functionality.
		 * 
		 * @param	sTag			Tag to get permission info for.
		 * @param	sAction		Action to get permission info for (update|delete|control).
		 * @param	fncCB			[null] Optional callback function. If provided, the function must accept 
		 * 									an instance of FluidDBAction.
		 * 
		 * @return	API returns:
		 * 						exceptions	The names of users who are exceptions to the policy.
		 * 						policy			The policy (either 'open' or 'closed').
		 * 
		 * @see	getTagValuePermits()
		 * @see	setTagPermits()
		 * @see	http://doc.fluidinfo.com/fluidDB/permissions.html
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\permissions/GET
		 */
		public function getTagPermits(sTag:String, sAction:String, fncCB:Function=null):void {
			var mdlAct:FluidDBAction;
			
			mdlAct = new FluidDBAction(
					"getTagPermits", DB_PERMISSIONS + "tags/" + sTag, METHOD_GET, fncCB);
			callAPI(mdlAct, {action:sAction});
		}
		
		
		/**
		 * Gets a user's default tag permission policy for the specified action.
		 * 
		 * Just an alias for the getPolicy() method which eliminates the need to specify the category.
		 * 
		 * @param	sUser			User to get policy for.
		 * @param	sAction		Action to get policy for (update|delete).
		 * @param	fncCB			[null] Optional callback function. If provided, the function must accept 
		 * 									an instance of FluidDBAction.
		 * 
		 * @return	See getPolicy()
		 * 
		 * @see	getPolicy()
		 * @see	getTagValuePolicy()
		 * @see	setTagPolicy()
		 */
		public function getTagPolicy(sUser:String, sAction:String, fncCB:Function=null):void {
			getPolicy(sUser, CAT_TAGS, sAction, fncCB);
		}
		
		
		/**
		 * Gets permission info (policy and exceptions) for the specified action on instances of a 
		 * tag used to assign values to an object.
		 * 
		 * <b>Note:</b> This method gets permissions for instances of the tags used to assign values 
		 * to an object. Use the getTagPermits() method to get permissions for the tag itself.
		 * 
		 * @param	sTag			Tag to get permission info for.
		 * @param	sAction		Action to get permission info for (see|create|read|update|delete|control).
		 * @param	fncCB			[null] Optional callback function. If provided, the function must accept 
		 * 									an instance of FluidDBAction.
		 * 
		 * @return	API returns:
		 * 						exceptions	The names of users who are exceptions to the policy.
		 * 						policy			The policy (either 'open' or 'closed').
		 * 
		 * @see	setTagPermits()
		 * @see	getTagValuePermits() 
		 * @see	http://doc.fluidinfo.com/fluidDB/permissions.html
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\permissions/GET
		 */
		public function getTagValuePermits(sTag:String, sAction:String, fncCB:Function=null):void {
			var mdlAct:FluidDBAction;
			
			mdlAct = new FluidDBAction(
					"getTagValuePermits", DB_PERMISSIONS + "tag-values/" + sTag, METHOD_GET, fncCB);
			callAPI(mdlAct, {action:sAction});
		}
		
		
		/**
		 * Gets a user's default tag-value permission policy for the specified action.
		 * 
		 * Just an alias for the getPolicy() method which eliminates the need to specify the category.
		 * 
		 * @param	sUser			User to get policy for.
		 * @param	sAction		Action to get policy for (see|create|read|update|delete).
		 * @param	fncCB			[null] Optional callback function. If provided, the function must accept 
		 * 									an instance of FluidDBAction.
		 * 
		 * @return	See getPolicy()
		 * 
		 * @see	getPolicy()
		 * @see	getTagPolicy()
		 * @see	setTagValuePolicy()
		 */
		public function getTagValuePolicy(sUser:String, sAction:String, fncCB:Function=null):void {
			getPolicy(sUser, CAT_TAG_VALUES, sAction, fncCB);
		}
		
		
		/**
		 * Gets information about the specified user.
		 * 
		 * @param	sUser		Name of user to get information about.
		 * @param	fncCB		[null] Optional callback function. If provided, the function must accept 
		 * 								an instance of FluidDBAction.
		 * 
		 * @return	API returns:
		 * 						id		The ID of the object corresponding to the user.
		 * 						name	The user's name.
		 * 
		 * @see	http://doc.fluidinfo.com/fluidDB/users.html
		 * @see	http://doc.fluidinfo.com/fluidDB/api/users.html
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\users/GET
		 */
		public function getUser(sUser:String, fncCB:Function=null):void {
			var mdlAct:FluidDBAction;
			
			mdlAct = new FluidDBAction("getUser", DB_USERS + sUser, METHOD_GET, fncCB);
			callAPI(mdlAct);
		}
		
		
		/**
		 * Searches for objects matching a query.
		 * 
		 * @param	sQry		A query string specifying objects to return. See the links below for 
		 * 								detailed information about the query language.
		 * @param	fncCB		[null] Optional callback function. If provided, the function must accept 
		 * 								an instance of FluidDBAction.
		 * 
		 * @return	API returns:
		 * 						ids		A list of IDs for objects which matched the query.
		 * 
		 * @see getObject()
		 * @see	http://doc.fluidinfo.com/fluidDB/queries.html
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\objects/GET
		 */
		public function queryForObject(sQry:String, fncCB:Function=null):void {
			var mdlAct:FluidDBAction;
			
			mdlAct = new FluidDBAction("queryForObject", DB_OBJECTS, METHOD_GET, fncCB);
			callAPI(mdlAct, {query:sQry});
		}
		
		
		/**
		 * Sets the user credentials for accessing the FluidDB API. If credentials are not provided, 
		 * the API attempts the request as the anonymous user. This method needs to be called BEFORE 
		 * any methods which access the API.
		 * 
		 * @param	sUser		[''] The username selected when FluidDB account was created.
		 * @param	sPW			[''] The password for the account indicated by the username.
		 * 
		 * <b>Note: </b> Setting either the username or password to an empty string results in 
		 * credentials for an anonynous user.
		 * 
		 * @see	http://doc.fluidinfo.com/fluidDB/api/http.html
		 * @see	http://doc.fluidinfo.com/fluidDB/api/users.html
		 * @see	http://doc.fluidinfo.com/fluidDB/api/users.html#anon-user
		 * @see	http://fluidinfo.com/accounts/new/
		 */
		public function setCredentials(sUser:String="", sPW:String=""):void {
			var b64:Base64Encoder;
			
			if (sUser == "" || sPW == "") {
				credentials = "";
			} else {
				b64 = new Base64Encoder();
				b64.encode(sUser + ":" + sPW);
				credentials = b64.toString();
			}
		}
		
		
		/**
		 * Sets the permissions info (policy and exceptions) for the specified action on a namespace.
		 * 
		 * @param	sNS				Namespace to set permission info for.
		 * @param	sAction		Action to set permission info for (create|update|delete|list|control).
		 * @param	sPolicy		The new policy value (open|closed).
		 * @param	arrEx			[null] Array of names of users who are exceptions to the specified policy. 
		 * @param	fncCB			[null] Optional callback function. If provided, the function must accept 
		 * 									an instance of FluidDBAction.
		 * 
		 * @return	API returns no data.
		 *
		 * @see getNamespacePermits() 
		 * @see	http://doc.fluidinfo.com/fluidDB/permissions.html
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\permissions/PUT
		 */
		public function setNamespacePermits(
				sNS:String, sAction:String, sPolicy:String, arrEx:Array=null, fncCB:Function=null):void {
			var mdlAct:FluidDBAction;
			
			mdlAct = new FluidDBAction(
					"setNamespacePermits", DB_PERMISSIONS + "namespaces/" + sNS, METHOD_PUT, fncCB);
			callAPI(mdlAct, {action:sAction}, {policy:sPolicy, exceptions:arrEx});
		}
		
		
		/**
		 * Sets a user's default namespace permission policy for a specified action.
		 * 
		 * Just an alias for the setPolicy() method which eliminates the need to specify the category.
		 * 
		 * @param	sUser				User to set policy for.
		 * @param	sAction			Action to set policy for (create|update|delete|list).
		 * @param	sPolicy			The new default policy value (open|closed).
		 * @param	arrEx				[null] Array of names of users who are exceptions to the specified policy. 
		 * @param	fncCB				[null] Optional callback function. If provided, the function must accept 
		 * 										an instance of FluidDBAction.
		 * 
		 * @return	API returns no data.
		 *
		 * @see	getNamespacePolicy()
		 * @see	setPolicy()
		 */
		public function setNamespacePolicy(
				sUser:String, sAction:String, sPolicy:String, arrEx:Array=null, fncCB:Function=null):void {
			setPolicy(sUser, CAT_NAMESPACES, sAction, sPolicy, arrEx, fncCB);
		}
		
		
		/**
		 * Sets a user's default permission policy for a specified category and action.
		 * 
		 * There are also three alias methods: setNamespacePolicy(), setTagPolicy() and 
		 * setTagValuePolicy() which eliminate the need to specify the category.
		 * 
		 * @param	sUser				User to set policy for.
		 * @param	sCategory		Category to set policy for (namespaces|tags|tag-values).
		 * @param	sAction			Action to set policy for. Actions vary by category as follows:
		 * 											For namespaces:	create|update|delete|list
		 * 											For tags:				update|delete
		 * 											For tag_values:	see|create|read|update|delete
		 * @param	sPolicy			The new default policy value (open|closed).
		 * @param	arrEx				[null] Array of names of users who are exceptions to the specified policy. 
		 * @param	fncCB				[null] Optional callback function. If provided, the function must accept 
		 * 										an instance of FluidDBAction.
		 * 
		 * @return	API returns no data.
		 *
		 * @see	getPolicy()
		 * @see	setNamespacePolicy()
		 * @see	setTagPolicy()
		 * @see	setTagValuePolicy()
		 * @see	http://doc.fluidinfo.com/fluidDB/permissions.html
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\policies/PUT
		 */
		public function setPolicy(sUser:String, sCategory:String, 
				sAction:String, sPolicy:String, arrEx:Array=null, fncCB:Function=null):void {
			var mdlAct:FluidDBAction;
			
			mdlAct = new FluidDBAction(
					"setPolicy", DB_POLICIES + sUser + "/" + sCategory + "/" + sAction, METHOD_PUT, fncCB);
			callAPI(mdlAct, null, {policy:sPolicy, exceptions:arrEx});
		}
		
		
		/**
		 * Sets the permissions info (policy and exceptions) for the specified action on a tag.
		 * 
		 * <b>Note:</b> This method sets permissions for the tag itself NOT for instances of the tag 
		 * used to assign values to an object. See setTagValuePermits() for that functionality.
		 * 
		 * @param	sTag			Tag to set permission info for.
		 * @param	sAction		Action to set permission info for (update|delete|control).
		 * @param	sPolicy		The new policy value (open|closed).
		 * @param	arrEx			[null] Array of names of users who are exceptions to the specified policy. 
		 * @param	fncCB			[null] Optional callback function. If provided, the function must accept 
		 * 									an instance of FluidDBAction.
		 * 
		 * @return	API returns no data.
		 *
		 * @see getTagPermits()
		 * @see setTagValuePermits()
		 * @see	http://doc.fluidinfo.com/fluidDB/permissions.html
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\permissions/PUT
		 */
		public function setTagPermits(
				sTag:String, sAction:String, sPolicy:String, arrEx:Array=null, fncCB:Function=null):void {
			var mdlAct:FluidDBAction;
			
			mdlAct = new FluidDBAction(
					"setTagPermits", DB_PERMISSIONS + "tags/" + sTag, METHOD_PUT, fncCB);
			callAPI(mdlAct, {action:sAction}, {policy:sPolicy, exceptions:arrEx});
		}
		
		
		/**
		 * Sets a user's default tag permission policy for the specified action.
		 * 
		 * Just an alias for the setPolicy() method which eliminates the need to specify the category.
		 * 
		 * @param	sUser				User to set policy for.
		 * @param	sAction			Action to set policy for (update|delete).
		 * @param	sPolicy			The new default policy value (open|closed).
		 * @param	arrEx				[null] Array of names of users who are exceptions to the specified policy. 
		 * @param	fncCB				[null] Optional callback function. If provided, the function must accept 
		 * 										an instance of FluidDBAction.
		 * 
		 * @return	API returns no data.
		 *
		 * @see	getTagPolicy()
		 * @see	setPolicy()
		 * @see	setTagValuePolicy()
		 */
		public function setTagPolicy(
				sUser:String, sAction:String, sPolicy:String, arrEx:Array=null, fncCB:Function=null):void {
			setPolicy(sUser, CAT_TAGS, sAction, sPolicy, arrEx, fncCB);
		}
		
		
		/**
		 * Sets the permissions info (policy and exceptions) for the specified action on instances of a 
		 * tag used to assign values to an object.
		 * 
		 * <b>Note:</b> This method sets permissions for instances of the tags used to assign values 
		 * to an object. Use the setTagPermits() method to set permissions for the tag itself.
		 * 
		 * @param	sTag			Tag to set permission info for. Note that the actual tag must already exist.
		 * @param	sAction		Action to set permission info for (see|create|read|update|delete|control).
		 * @param	sPolicy		The new policy value (open|closed).
		 * @param	arrEx			[null] Array of names of users who are exceptions to the specified policy. 
		 * @param	fncCB			[null] Optional callback function. If provided, the function must accept 
		 * 									an instance of FluidDBAction.
		 * 
		 * @return	API returns no data.
		 *
		 * @see getTagValuePermits()
		 * @see	setTagPermits()
		 * @see	http://doc.fluidinfo.com/fluidDB/permissions.html
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\permissions/PUT
		 */
		public function setTagValuePermits(
				sTag:String, sAction:String, sPolicy:String, arrEx:Array=null, fncCB:Function=null):void {
			var mdlAct:FluidDBAction;
			
			mdlAct = new FluidDBAction(
					"setTagValuePermits", DB_PERMISSIONS + "tag-values/" + sTag, METHOD_PUT, fncCB);
			callAPI(mdlAct, {action:sAction}, {policy:sPolicy, exceptions:arrEx});
		}
		
		
		/**
		 * Sets a user's default tag-value permission policy for the specified action.
		 * 
		 * Just an alias for the setPolicy() method which eliminates the need to specify the category.
		 * 
		 * @param	sUser				User to set policy for.
		 * @param	sAction			Action to set policy for (see|create|read|update|delete).
		 * @param	sPolicy			The new default policy value (open|closed).
		 * @param	arrEx				[null] Array of names of users who are exceptions to the specified policy. 
		 * @param	fncCB				[null] Optional callback function. If provided, the function must accept 
		 * 										an instance of FluidDBAction.
		 * 
		 * @return	API returns no data.
		 *
		 * @see	getTagPolicy()
		 * @see	setPolicy()
		 * @see	setTagPolicy()
		 */
		public function setTagValuePolicy(
				sUser:String, sAction:String, sPolicy:String, arrEx:Array=null, fncCB:Function=null):void {
			setPolicy(sUser, CAT_TAG_VALUES, sAction, sPolicy, arrEx, fncCB);
		}
		
		
		/**
		 * Creates or updates a primitive tag on an object. Just an alias for createObjectTag(), see 
		 * that method for detailed information.
		 * 
		 * @param	sID			Unique ID of object to assign tag to.
		 * @param	sTag		Tag to assign to the object. Note that the tag must already exist.
		 * @param	vValue	Value to associate with this tag assignment.
		 * @param	fncCB		[null] Optional callback function. If provided, the function must accept 
		 * 								an instance of FluidDBAction.
		 * 
		 * @return	API returns no data.
		 * 
		 * @see createObjectTag
		 * @see createTag()
		 * @see tagObject()
		 * @see tagObjectOpaque()
		 * @see	http://doc.fluidinfo.com/fluidDB/api/tag-values.html
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\objects/PUT
		 */
		public function tagObject(sID:String, sTag:String, vValue:*, fncCB:Function=null):void {
			createObjectTag(sID, sTag, vValue, fncCB);
		}
		
		
		/**
		 * Creates or updates an opaque tag on an object. Just an alias for createOpaqueObjectTag(),
		 * see that method for more information.
		 * 
		 * @param	sID					Unique ID of object to assign tag to.
		 * @param	sTag				Tag to assign to the object. Note that the tag must already exist.
		 * @param	vValue			Value to associate with this tag assignment.
		 * @param	sType				MIME type of the object. Used to identify type when value is retrieved.
		 * @param	fncEndcode	[null] An optional callback function used to convert the value supplied 
		 * 										to a string for passing to the API. Function must accept:
		 * 											A variant with the value to convert.
		 * 											A string indicating the MIME type.
		 *										The function must also return a string.
		 * @param	fncCB				[null] Optional callback function. If provided, the function must accept 
		 * 										an instance of FluidDBAction.
		 * 
		 * @return	API returns no data.
		 * 
		 * @see	createOpaqueObjectTag()
		 * @see createTag()
		 * @see tagObject()
		 * @see	http://doc.fluidinfo.com/fluidDB/api/tag-values.html
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\objects/PUT
		 */
		public function tagObjectOpaque(sID:String, sTag:String, vValue:*, 
				sType:String, fncEncode:Function=null, fncCB:Function=null):void {
			createOpaqueObjectTag(sID, sTag, vValue, sType, fncEncode, fncCB);
		}
		
		
		/**
		 * Updates the description of the specified namespace.
		 * 
		 * @param	sPath		Full path of the namespace to update description for.
		 * @param	sDesc		New description for the namespace.
		 * @param	fncCB		[null] Optional callback function. If provided, the function must accept 
		 * 								an instance of FluidDBAction.
		 * 
		 * @return	API returns no data.
		 *
		 * @see	createNamepsace() 
		 * @see	http://doc.fluidinfo.com/fluidDB/namespaces.html
		 * @see	http://doc.fluidinfo.com/fluidDB/api/namespaces-and-tags.html
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\namespaces/PUT
		 */
		public function updateNamespace(sPath:String, sDesc:String, fncCB:Function=null):void {
			var mdlAct:FluidDBAction;
			
			mdlAct = new FluidDBAction("updateNamespace", DB_NAMESPACES + sPath, METHOD_PUT, fncCB);
			callAPI(mdlAct, null, {description:sDesc});
		}
		
		
		/**
		 * Updates information about a tag.
		 * 
		 * <b>Note:</b> This changes the description of the tag itself. It does not have anything to do 
		 * with changing the value of a tag assigned to an object. Use createObjectTag(), 
		 * createTagOpaqueObject() or tagObjectOpaque() for that purpose.
		 * 
		 * @param	sTag		Name of tag to update information for.
		 * @param	sDesc		New description for the tag.
		 * @param	fIndex	[false] Indicates whether the tag should be indexed. Note that changing 
		 * 								whether a tag is indexed after it is created is NOT currently supported 
		 * 								by the API. The parameter has been included here in case the ability is 
		 * 								added to a later version.
		 * @param	fncCB		[null] Optional callback function. If provided, the function must accept 
		 * 								an instance of FluidDBAction.
		 * 
		 * @return	API returns no data.
		 *
		 * @see createObjectTag()
		 * @see createOpaqueObjectTag()
		 * @see	tagObject()
		 * @see	tagObjectOpaque()
		 * @see	http://api.fluidinfo.com/fluidDB/api/*\tags/PUT
		 */
		public function updateTagInfo(
				sTag:String, sDesc:String, fIndex:Boolean=false, fncCB:Function=null):void {
			var mdlAct:FluidDBAction;
			
			mdlAct = new FluidDBAction("updateTagInfo", DB_TAGS + sTag, METHOD_PUT, fncCB);
			callAPI(mdlAct, null, {description:sDesc});
		}
		
		
		// PROTECTED -----------------------------------------------------------------------------------
		
		protected var _useSandbox:Boolean = false;
		
		
		/**
		 * Make a request to FluidDB API.
		 * 
		 * @param	mdlAct
		 * @param	objArgs		[null]
		 * @param	vPayload	[null]
		 * @param	arrHdr		[null[
		 */
		protected function callAPI(mdlAct:FluidDBAction, 
				objArgs:Object=null, vPayload:*=null, arrHdr:Array=null):void {
			var fError:Boolean;
			var sUrl:String;
			var urlLoad:URLLoader;
			var urlReq:URLRequest;
			
			function _handleComplete(evt:Event):void {
				if (!fError) handleComplete(mdlAct, urlLoad);
			}
			
			function _handleIOError(evt:IOErrorEvent):void {
				handleIOError(mdlAct, urlLoad, evt);
			}
			
			function _handleResponseStatus(evt:HTTPStatusEvent):void {
				fError = !handleResponseStatus(mdlAct, urlLoad, evt);
			}
			
			sUrl = ((useHttps) ? PROTOCOL_HTTPS : PROTOCOL_HTTP)
					+ ((useSandbox) ? DOMAIN_SANDBOX : DOMAIN_FLUIDDB) + mdlAct.path;
			urlReq = getRequest(sUrl, mdlAct, vPayload, objArgs, arrHdr);
			
			urlLoad = new URLLoader();
			urlLoad.addEventListener(Event.COMPLETE, _handleComplete);
			urlLoad.addEventListener(IOErrorEvent.IO_ERROR, _handleIOError);
			urlLoad.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, _handleResponseStatus);
			urlLoad.load(urlReq);
		}
		
		
		// encodePayload(vPayload)
		// Encode payload into format supported by current contentType.
		protected function encodePayload(vPayload:*):String {
			var sRet:String;
			
			// AT PRESENT, THE ONLY FORMAT AVAILABLE IS JSON...
			if (_contentType == CONTENT_TYPE_JSON) {
				sRet = JSON.encode(vPayload);
			}
			
			return sRet;
		}
		
		
		// isPrimitive(vVal[, fArray])
		// Checks if the supplied value is one of the FluidDB primitive value types.
		//		vVal			- Value to check.
		//		[fArray]	- [true] If true, allow an Array as primitive.
		// RETURNS:	true if value is a primitive.
		protected function isPrimitive(vVal:*, fArray:Boolean=true):Boolean {
			var fRet:Boolean;
			var arrVal:Array;
			
			if (vVal == null || vVal is Boolean || vVal is int || vVal is Number || vVal is String) {
				fRet = true;
			} else if (fArray && vVal is Array) {
				arrVal = vVal as Array;
				for (var i:int = 0; i < arrVal.length; ++i) {
					fRet = (arrVal[i] is String);
					if (!fRet) break;
				}
			} else {
				fRet = false;
			}
			
			return fRet;
		}
		
		
		// PRIVATE -------------------------------------------------------------------------------------
		
		private static const CONTENT_TYPE_JSON:String			= "application/json";
		private static const CONTENT_TYPE_JSON_VAL:String	= "application/vnd.fluiddb.value+json";
		
		private static const DB_NAMESPACES:String		= "/namespaces/";
		private static const DB_OBJECTS:String			= "/objects/";
		private static const DB_PERMISSIONS:String	= "/permissions/";
		private static const DB_POLICIES:String			= "/policies/";
		private static const DB_TAGS:String					= "/tags/";
		private static const DB_USERS:String				= "/users/";
		
		private static const DOMAIN_FLUIDDB:String	= "fluiddb.fluidinfo.com";
		private static const DOMAIN_SANDBOX:String	= "sandbox.fluidinfo.com";

		private static const PROTOCOL_HTTP:String		= "http://";
		private static const PROTOCOL_HTTPS:String	= "https://";
		
		private static const METHOD_DELETE:String	= "DELETE";
		private static const METHOD_GET:String		= "GET";
		private static const METHOD_HEAD:String		= "HEAD";
		private static const METHOD_POST:String		= "POST";
		private static const METHOD_PUT:String		= "PUT";
		
		private static const CAT_NAMESPACES:String	= "namespaces";
		private static const CAT_TAGS:String				= "tags";
		private static const CAT_TAG_VALUES:String	= "tag-values";
		
		private var _contentType:String = CONTENT_TYPE_JSON;

		private var credentials:String = "";


		// getRequest(sUrl, mdlAct[, vPayload[, objArgs[, arrHdr]])
		// Get a URLRequest object for the specified url.
		private function getRequest(sUrl:String, mdlAct:FluidDBAction, 
				vPayload:*=null, objArgs:Object=null, arrHdr:Array=null):URLRequest {
			var sPayload:String;
			var urlRet:URLRequest;
			var urlVar:URLVariables;
			var urlHdr:URLRequestHeader;
			
			if (objArgs != null) {
				sUrl += "?" + objectToURIArgs(objArgs);
			}
			
			urlRet = new URLRequest(sUrl);
			urlRet.authenticate = false;
			urlRet.cacheResponse = false;
			urlRet.useCache = false;
			urlRet.contentType = _contentType;
			urlRet.method = mdlAct.method;
			
			if (credentials != "") {
				urlHdr = new URLRequestHeader("Authorization", "Basic " + credentials);
				urlRet.requestHeaders.push(urlHdr);
			}
			
			if (arrHdr) {
				for (var i:int = 0; i < arrHdr.length; ++i) {
					urlHdr = arrHdr[i] as URLRequestHeader;
					urlRet.requestHeaders.push(urlHdr);
				}
			}
			
			if (vPayload != null) {
				sPayload = encodePayload(vPayload);
				urlHdr = new URLRequestHeader("Content-Length", sPayload.length.toString());
				urlRet.requestHeaders.push(urlHdr);
				urlRet.data = sPayload;
			}
			
			return urlRet;
		}
		
		
		// handleComplete(mdlAct, urlLoad)
		// Dispatches FluidDBEvent(COMPLETE) and calls callback function (if provided).
		private function handleComplete(mdlAct:FluidDBAction, urlLoad:URLLoader):void {
			dispatchEvent(new FluidDBEvent(FluidDBEvent.COMPLETE, mdlAct, urlLoad));

			if (mdlAct.callback != null) {
				mdlAct.callback(mdlAct);
			}
		}
		
		
		// handleIOError(mdlAct, urlLoad, evt)
		// Dispatches FluidDBErrorEvent(ERROR) and calls callback function (if provided).
		private function handleIOError(mdlAct:FluidDBAction, urlLoad:URLLoader, evt:IOErrorEvent):void {
			var errFluid:FluidDBError;
			
			errFluid = new FluidDBError(evt.text, evt.errorID, mdlAct, urlLoad);
			dispatchEvent(new FluidDBErrorEvent(FluidDBErrorEvent.ERROR, errFluid));
			
			if (mdlAct.callback != null) {
				mdlAct.callback(mdlAct);
			}
		}
		
		
		// handleResponseStatus(mdlAct, urlLoad, evtSts)
		// Adds response headers to instance of FluidDBAction provided. If headers indicate an error 
		// response from server, dispatches a FluidDBErrorEvent.
		// RETURNS: true if headers indicate a successful call; false if not.
		private function handleResponseStatus(
				mdlAct:FluidDBAction, urlLoad:URLLoader, evtSts:HTTPStatusEvent):Boolean {
			var fRet:Boolean;
			var sMsg:String;
			var evtIO:IOErrorEvent;
			var urlHdr:URLRequestHeader;
			
			fRet = true;
			mdlAct.responseStatus = evtSts.status;
			mdlAct.responseHeaders = evtSts.responseHeaders;
			
			if (int(evtSts.status / 100) != 2) {
				fRet = false;
				sMsg = "FluidDB returned error response(s):\n";
				for (var i:int = 0; i < evtSts.responseHeaders.length; ++i) {
					urlHdr = evtSts.responseHeaders[i] as URLRequestHeader;
					sMsg += "\n\t\t" + urlHdr.name + " = " + urlHdr.value;
				}
				
				evtIO = new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, sMsg, evtSts.status);
				handleIOError(mdlAct, urlLoad, evtIO);
			}
			
			return fRet;
		}
		
		
		// objectToURIArgs(objSrc[, arrEx])
		// Convert an object to a string suitable for use as arguments in a URI.
		// -- Pulled from MaxMiscUtils library --
		private function objectToURIArgs(objSrc:Object, arrEx:Array=null):String {
			var sRet:String;
			var arrArgs:Array;
			
			sRet = "";
			if (objSrc) {
				arrArgs = [];
				for (var s:String in objSrc) {
					if (arrEx == null || arrEx.indexOf(s) < 0) {
						arrArgs.push(encodeURIComponent(s) + "=" + encodeURIComponent(String(objSrc[s])));
					}
				}
				if (arrArgs.length > 0) sRet = arrArgs.join("&");
			}
			
			return sRet;
		}


	}
}