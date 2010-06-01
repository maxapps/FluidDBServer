package com.maxapps.fluiddb {
	
	/**
	 * Static utility class defining constants for permission action values.
	 * 
	 * The first set of constants: CONTROL, CREATE, DELETE, LIST, READ, SEE and UPDATE define all 
	 * possible actions which can be used by the permission related methods of FluidDBService.
	 * 
	 * The second set: OPEN and CLOSED define policy values which can be used by those same methods.
	 * 
	 * There are also several convenience constants which define lists of actions appropriate for 
	 * permission related methods specific to each group. The ACTION_NS const, for instance, is an 
	 * array of actions which can be used to assign Namespace permissions.
	 * 
	 * The POLICY_ACTIONS_??? constants define lists of actions appropriate for methods which get 
	 * or set policies. POLICY_ACTIONS_TAG, for instance, contains all the actions which can be 
	 * passed to methods which relate to policies for tags.
	 * 
	 * All of the lists are provided so you can easily create ArrayCollections for use when building 
	 * GUIs which access the FluidDB API.
	 * 
	 * @see	FluidDBService
	 * @see	FluidDBService.getPolicy()
	 * @see	FluidDBService.setPolicy()
	 * @see	FluidDBService.getNamespacePermits()
	 * @see	FluidDBService.getTagPermits()
	 * @see	FluidDBService.getTagValuePermits()
	 * @see	FluidDBService.setNamespacePermits(
	 * @see	FluidDBService.setTagPermits()
	 * @see	FluidDBService.setTagValuePermits()
	 * @see	http://doc.fluidinfo.com/fluidDB/permissions.html
	 */
	public class FluidDBPermits {
		
		// STATIC --------------------------------------------------------------------------------------
		
		// Action Values
		public static const CONTROL:String	= "control";
		public static const CREATE:String		= "create";
		public static const DELETE:String		= "delete";
		public static const LIST:String			= "list";
		public static const READ:String			= "read";
		public static const SEE:String			= "see";
		public static const UPDATE:String		= "update";
		

		// Action lists for Permissions
		public static const ACTIONS_ALL:Array		= [CONTROL, CREATE, DELETE, LIST, READ, SEE, UPDATE];
		public static const ACTIONS_NS:Array		= [CONTROL, CREATE, DELETE, LIST, UPDATE];
		public static const ACTIONS_TAG:Array		= [CONTROL, DELETE, UPDATE];
		public static const ACTIONS_VALUE:Array	= [CONTROL, CREATE, DELETE, READ, SEE, UPDATE];
		
		
		// Action lists for Policies
		public static const POLICY_ACTIONS_NS:Array			= ACTIONS_NS.slice(1);
		public static const POLICY_ACTIONS_TAG:Array		= ACTIONS_TAG.slice(1);
		public static const POLICY_ACTIONS_VALUE:Array	= ACTIONS_VALUE.slice(1);
		

		// Policy Values
		public static const OPEN:String			= "open";
		public static const CLOSED:String		= "closed";
		

		// Policy Lists
		public static const POLICIES:Array	= [OPEN, CLOSED];
		
	}
}