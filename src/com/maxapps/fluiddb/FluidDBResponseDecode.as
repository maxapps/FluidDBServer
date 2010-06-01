package com.maxapps.fluiddb {

	/**
	 * Static utility class defining constants for decoding HTTP response codes from FluidDB.
	 * 
	 * This is an internal class used by FluidDBError to help decode HTTP response status codes from 
	 * calls to the FluidDB API into more meaningful text messages.
	 * 
	 * The FluidDB API specification details what HTTP status codes are returned by calls to the API.
	 * The FluidDBError class uses this information along with the name of the FuidDBService method 
	 * which initiated the call to parse the data into the text messages.
	 * 
	 * You should not need to access this class directly.
	 * 
	 * @see	FluidDBError 
	 * @see	FluidDBService
	 * @see	http://api.fluidinfo.com/fluidDB/api/*\*\*
	 */
	public class FluidDBResponseDecode {

		// STATIC --------------------------------------------------------------------------------------
		
		// Defines textual response codes for each action type.
		public static const RESPONSE_MESSAGES:Object	= {
			checkForTag:{
				404:	"User does not have SEE permission for tag or tag is not on the object"
			},
			createNamespace:{
				400:	"Bad Request - Possible problems include\n"
						+ "\tFull path of namespace too long (cur max is 233 chars),\n"
						+ "\tError with the request payload,\n"
						+ "\tError with the request makes it impossible to respond",
				401:	"User does not have CREATE permission on parent namespace",
				404:	"Parent namespace does not exist",
				412:	"Namespace already exists"
			},
			createObject:{
				400:	"Error with the request or payload makes it impossible to respond"
			},
			createOpaqueObjectTag:{
				400:	"Error with the request payload",
				401:	"User has SEE but not UPDATE permission on the tag",
				404:	"User does not have SEE permission on the tag"
			},
			createTag:{
				400:	"Bad Request - Possible problems include\n"
						+ "\tFull path of new tag is too long (cur max is 233 chars),\n"
						+ "\tError with the request payload,\n"
						+ "\tError with the request makes it impossible to respond",
				401:	"User does not have CREATE permission on the containing (deepest) namespace",
				404:	"Containing or intermediate namespace does not exist",
				412:	"Tag already exists"
			},
			deleteNamespace:{
				401:	"User does not have DELETE permission on the namespace",
				404:	"Namespace or intermediate namespace does not exist",
				412:	"Namespace is not empty (contains other namespaces or tags"
			},
			deleteObjectTag:{
				401:	"Object has tag and user has SEE but not DELETE permission on the tag",
				404:	"Possible problems:\n"
						+ "\tObject does not exist"
						+ "\tAn intermediate namespace does not exist"
						+ "\tTag does not exist"
						+ "\tObject does not have an instance of the tag"
						+ "\tObject has instance of tag but user has neither SEE nor DELETE permission on tag"
			},
			deleteTag:{
				401:	"User does not have DELETE permission on the tag",
				404:	"Tag or intermediate namespace does not exist"
			},
			getNamespacePermits:{
				400:	"Error with the request makes it impossible to respond",
				401:	"User does not have CONTROL permission on the namespace",
				404:	"Namespace or intermediate namespace does not exist"
			},
			getNamespaces:{
				400:	"Error with the request makes it impossible to respond",
				401:	"User does not have LIST permission on the namespace",
				404:	"Namespace or intermediate namespace does not exist"
			},
			getObject:{
				400:	"Error with the request or payload makes it impossible to respond",
				404:	"No object with the given ID exists"
			},
			getObjectTag:{
				400:	"Error with the request makes it impossible to respond",
				401:	"User does has SEE but not READ permission for the tag",
				404:	"User does not have SEE permission for the tag",
				406:	"Accept header value not specified or doesn't allow tag value to be returned"
			},
			getPolicy:{
				400:	"Error with the request makes it impossible to respond",
				404:	"User does not exist or category/action pair is invalid or missing"
			},
			getTagInfo:{
				400:	"Error with the request makes it impossible to respond",
				404:	"Tag or intermediate namespace does not exist"
			},
			getTagPermits:{
				400:	"Error with the request makes it impossible to respond",
				401:	"User does not have CONTROL permission on the tag",
				404:	"Tag or intermediate namespace does not exist"
			},
			getTagValuePermits:{
				400:	"Error with the request makes it impossible to respond",
				401:	"User does not have CONTROL permission on the tag",
				404:	"Tag or intermediate namespace does not exist"
			},
			getUser:{
				400:	"Error with the request makes it impossible to respond",
				404:	"user does not exist"
			},
			queryForObject:{
				400:	"Bad Request - Possible problems include\n"
						+ "\tNo query given,\n"
						+ "\tQuery could not be parsed,\n"
						+ "\tError with the request makes it impossible to respond",
				401:	"User has SEE but not READ permission on a tag whose value or existence is needed",
				404:	"User does not have SEE permission on a tag whose value or existence is needed",
				413:	"Query (or it's sub-parts) results in too many objects (current limit is 1 million)"
			},
			setNamespacePermits:{
				400:	"Bad Request - Possible problems include\n"
						+ "\tThe policy argument not set to 'open' or 'closed',\n"
						+ "\tThe action argument is missing or invalid,\n"
						+ "\tError with the request payload",
				401:	"User does not have CONTROL permission on the namespace",
				404:	"Namespace or intermediate namespace does not exist"
			},
			setPolicy:{
				400:	"The category/action pair is invalid or there is an error with the request payload",
				401:	"User making request is not same as user to set policy for",
				404:	"The user does not exist"
			},
			setTagPermits:{
				400:	"Bad Request - Possible problems include\n"
						+ "\tThe policy argument not set to 'open' or 'closed',\n"
						+ "\tThe action argument is missing or invalid,\n"
						+ "\tError with the request payload",
				401:	"User does not have CONTROL permission on the tag",
				404:	"Tag or intermediate namespace does not exist"
			},
			setTagValuePermits:{
				400:	"Bad Request - Possible problems include\n"
						+ "\tThe policy argument not set to 'open' or 'closed',\n"
						+ "\tThe action argument is missing or invalid,\n"
						+ "\tError with the request payload",
				401:	"User does not have CONTROL permission on the tag",
				404:	"Tag or intermediate namespace does not exist"
			},
			updateNamespace:{
				400:	"Error with the request payload",
				401:	"User does not have UPDATE permission on the namespace",
				404:	"Namespace or intermediate namespace does not exist"
			},
			updateTagInfo:{
				400:	"Error with the request payload",
				401:	"User does not have UPDATE permission on the tag",
				404:	"Tag or intermediate namespace does not exist"
			}
		};
		
		
		
	}
}