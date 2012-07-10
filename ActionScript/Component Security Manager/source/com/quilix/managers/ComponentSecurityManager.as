/**
 * Copyright (c) 2009-2012 Rick Winscot www.quilix.com
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
package com.quilix.managers
{
 
        
        import com.quilix.ro.ManagedComponentRO;
        
        import flash.events.Event;
        import flash.events.EventDispatcher;
        import flash.utils.*;
        
        import mx.collections.ArrayCollection;
        import mx.core.Application;
        import mx.core.UIComponent;
        import mx.utils.DescribeTypeCache;
         
         
        [Event(name="permissionsUpdated", type="flash.events.Event")]
         
        /**
         * Uses the principle of least privilege to restrict access to or visibility of 
         * UIComponents. The ComponentSecurityManager should be addedToStage as early as
         * possible in the application init cycle - to prevent components from side
         * stepping security restrictions.
         * 
         * <pre>
         * 
         * private var csm:ComponentSecurityManager = ComponentSecurityManager.getInstance();
         * </pre>
         * 
         * <p>
         * Be aware that although this class in implemented as a singleton... conflicts
         * may arise when using modules or extended security contexts. After initialization, 
         * the ComponentSecurityManager via the root SystemManager will process security 
         * restrictions for UIComponents as they are added to the stage. 
         * </p>
         * 
         * <p>
         * The components field contains a comma separated list of your component ids, the permissions
         * field contains a comma separated list of your required permissions, and the restrictions field 
         * contains a comma separated list of your components restricted properties. The enabled, visible, 
         * and includeInLayout are supported along with any other Boolean UIComponent property. Don't get 
         * too fancy... or you'll a-splode yourself.
         * </p>
         * 
         * <p>
         * Managed MXML components should be annotated as:
         * </p>
         * 
         * <pre>
         * 
         *      &lt;mx:Metadata&gt;
         *        [ManageComponents( components="this", permissions="foo", restrictions="visible,includeInLayout" )]
         *  &lt;/mx:Metadata&gt;
         * </pre>
         * 
         * Managed ActionScript classes that extend UIComponent should be annotated as:
         * 
         * <pre>
         * 
         * [ManageComponents( components="this", permissions="foo", restrictions="visible,includeInLayout" )]
         * public class foo
         * {
         * ...
         * </pre>
         * 
         * You can also use a loose binding method to manage a UIComponent or non-UIComponent.
         * 
         * <pre>
         * 
         * // Within your class...
         * private var csm:ComponentSecurityManager = ComponentSecurityManager.getInstance();
         * 
         * // Binding source
         * [Bindable]
         * private var _enabled:Boolean = false;
         * 
         * // Standard creation complete handler to add event listener.
         * private function ccomp():void
         * {
         *     csm.addEventListener("permissionsUpdated", handlePermissionUpdatedEvent);
         * }
         * 
         * // Permissions changed handler - will toggle button enabled as 'foo' permission
         * // is added or removed.
         * private function handlePermissionUpdatedEvent( event:Event ):void
         * {
         *     _enabled = csm.hasPermission( "foo" );
         * }
         * 
         * &lt;mx:Button label="click me!" click="Alert.show('you clicked me!');" enabled="{_enabled}"/&gt;
         * </pre>
         */
        public class ComponentSecurityManager extends EventDispatcher
        {
         

                include "../../../../includes/Version.as";


                /**
                 * @private
                 * Collection of managed components.
                 */
                private var _managedComponents:ArrayCollection = new ArrayCollection();

                /**
                 * @private
                 * Permissions collection for the current user.
                 */
                private var _permissions:ArrayCollection = new ArrayCollection();

         
                /**
                 * @private
                 * The Singleton 'self-reference' served up by getInstance().
                 */
                private static var _componentSecurityManager:ComponentSecurityManager = null;
                 
                /**
                 * Uses a scope constrained Constructor and ensures that the only 
                 * class eligible to call the ComponentSecurityManager is itself.
                 */
                public function ComponentSecurityManager( enforcer:ComponentSecurityManagerEnforcer )
                {
                        if ( getQualifiedClassName( super ) != "com.quilix.managers::ComponentSecurityManager" )
                                throw new Error( "Invalid Singleton access. Please use ComponentSecurityManager.getInstance() instead." );
                }
                 
                /**
                 * The 'single' access point for your ComponentSecurityManager.
                 * 
                 * @example
                 * <listing>
                 * 
                 * 
                 * private var csm:ComponentSecurityManager = ComponentSecurityManager.getInstance();
                 * 
                 * </listing>
                 */
                public static function getInstance():ComponentSecurityManager
                {
                        if ( _componentSecurityManager == null )
                        {
                                _componentSecurityManager= new ComponentSecurityManager( new ComponentSecurityManagerEnforcer );
                                _componentSecurityManager.init();
                        }
                         
                        return _componentSecurityManager;
                }
                
                
                /**
                 * Called internally as ComponentSecurityManager is instantiated. Adds an event listener to 
                 * the Application.application.systemManager to keep track of all UIComponents that are added.
                 */
                public function init():void
                {
                        if ( Application.application.systemManager.getTopLevelRoot().hasEventListener( Event.ADDED_TO_STAGE ) == false )
                                Application.application.systemManager.getTopLevelRoot().addEventListener( Event.ADDED_TO_STAGE, handleComponentAddedToStageEvent, true );
                }

                
                /**
                 * @private
                 * Handles SystemManager stage addition announcements. Fluffy bunnies RULE!
                 */
                private function handleComponentAddedToStageEvent( event:Event ):void
                {
                        if ( event.target is UIComponent )
                                processComponent( event.target as UIComponent );
                }

                
                /**
                 * @private
                 * Break the announcement down to see if the component should be managed 
                 * or not. The identifier for a component is it's id (needs to be unique).
                 */
                private function processComponent( target:UIComponent ):void
                {
                        var nfo:XML = DescribeTypeCache.describeType( target ).typeDescription;
                        var md:XMLList = nfo.metadata.(@name == "ManageComponents");
                        var mc:ManagedComponentRO;

                        // Component / container with metadata
                        if ( md.length() > 0 )
                        {
                                for each ( var metadata:XML in md )
                                {
                                        var names:Array = String( metadata..arg.(@key == "components").@value ).split(",");
                                        // TODO: name already exists? throw error unless it's 'this'
                                        
                                        for ( var i:int = 0; i < names.length; i++ )
                                        {
                                                // Populate ManageComponent req'd properties
                                                mc = new ManagedComponentRO( names[i],
                                                                                                   String( metadata..arg.(@key == "permissions").@value ).split(","),
                                                                                                   String( metadata..arg.(@key == "restrictions").@value ).split(",") );

                                                // Include 'this' in permission context... 
                                                if ( mc.id == "this" )
                                                {
                                                        mc.component = target;
                                                        mc.addedToStage = true;
                                                }
                                                else
                                                {
                                                        // Child on stage yet?
                                                        var child:Object = target.getChildByName(names[i]);
                                                        
                                                        if ( child != null )
                                                        {
                                                                mc.id = child.id;
                                                                mc.component = child as UIComponent;
                                                                mc.addedToStage = true;
                                                        }
                                                }
                                                
                                                // Add new component to managed collection and update - remember that the id
                                                // is only used to track the component until it is added to the stage. After,
                                                // you should be using the component itself.
                                                if ( componentIdExists(mc.id) == false )
                                                {
                                                        _managedComponents.addItem( mc );
                                                        processRestrictions( mc );                                                      
                                                }
                                                else
                                                {
                                                        throw new Error("A component with the id '" + mc.id + "' is already being managed. The component id must be globally unique and cannot be dynamically reconfigured.");
                                                }
                                        }
                                }
                        }
                        else
                        {
                                // Children potentially within a parent component / container with metadata
                                for ( var j:int = 0; j < this._managedComponents.length; j++ )
                                {
                                        mc = _managedComponents[j] as ManagedComponentRO;
                                        
                                        // Id match for previously noted components?
                                        if ( target.id == mc.id )
                                        {
                                                mc.component = target;
                                                mc.addedToStage = true;
                                                
                                                processRestrictions( mc );
                                        }
                                }
                        }
                }


                /**
                 * Checks to see if a component with the specified id is already being managed. 
                 * Best used to track N child components.
                 * 
                 * @param id The components id as a <code>String</code>.
                 * @return Returns <code>true</code> if a component with the specified id is
                 * found or <code>false</code> if not.
                 */
                private function componentIdExists( id:String ):Boolean
                {
                        for ( var i:int = 0; i < this._managedComponents.length; i++ )
                        {
                                var target:ManagedComponentRO = this._managedComponents[i] as ManagedComponentRO;
                                
                                if ( target.id == id && id != "this" )
                                        return true;
                        }
                        
                        return false;
                }


                /**
                 * Checks to see if a specified component is already being managed. Best
                 * used to track components identified as 'this.'
                 * 
                 * @param comp The <code>UIComponent</code> to check for.
                 * @return Returns <code>true</code> if the component is found or 
                 * <code>false</code> if not.
                 */
                public function componentExists( comp:UIComponent ):Boolean
                {
                        for ( var i:int = 0; i < this._managedComponents.length; i++ )
                        {
                                var target:ManagedComponentRO = this._managedComponents[i] as ManagedComponentRO;
                                
                                if ( target.component == comp )
                                        return true;
                        }
                        
                        return false;                   
                }


                /**
                 * @private
                 * Comb through managed components and update restricted properties as needed.
                 */
                private function processRestrictions( mc:ManagedComponentRO ):void
                {
                        for ( var i:int = 0; i < mc.restrictions.length; i++ )
                        {
                                if ( mc.component == null && mc.addedToStage == true )
                                {
                                        _managedComponents.removeItemAt( _managedComponents.getItemIndex( mc ) );
                                }
                                else if ( mc.component != null )
                                {
                                        // Restrictions may be enforced via direct binding...
                                        if ( mc.restrictions.length > 0 )
                                                mc.component[mc.restrictions[i]] = hasPermissions( mc.permissions );
                                }
                        }
                }
                

                /**
                 * Adds security / restrictions to the specified component.
                 * 
                 * @param component The <code>UIComponent</code> to secure.
                 * @param permissions An <code>Array</code> of permissions to apply to the component.
                 * @param restrictions An <code>Array</code> of restrictions to apply to the component.
                 * @return Returns a <code>ManagedComponentRO</code> (reference object) if successful.
                 * 
                 * @internal At this point we don't have to check for an id - since the component
                 * *should* already be non-null.
                 */
                public function addComponent( component:UIComponent, permissions:Array, restrictions:Array ):ManagedComponentRO
                {
                        var mc:ManagedComponentRO = new ManagedComponentRO( component.id, permissions, restrictions, component, true );
                        
                        _managedComponents.addItem( mc );
                        updateComponents();
                        
                        return mc;
                }
                
                
                /**
                 * Removes security / restrictions and restores component.
                 * 
                 * @param component The <code>UIComponent</code> to remove. 
                 */
                public function removeComponent( component:UIComponent ):void
                {
                        for ( var i:int = 0; i < _managedComponents.length; i++ )
                        {
                                var mc:ManagedComponentRO = _managedComponents[i] as ManagedComponentRO;
                                
                                if ( mc.component == component )
                                {
                                        for ( var j:int = 0; j < mc.restrictions.length; j++ )
                                                mc.component[ mc.restrictions[j] ] = true;
                                        
                                        _managedComponents.removeItemAt( i );
                                        return;
                                }
                        }
                }
                
                
                /**
                 * @private
                 * Send all components through the wash to see if the baby falls out.
                 */
                private function updateComponents():void
                {
                        for ( var i:int = 0; i < _managedComponents.length ; i++ )
                                processRestrictions( _managedComponents[i] as ManagedComponentRO );
                }


                /**
                 * Set the collective permissions for the current user.
                 * 
                 * @param permissions An <code>ArrayCollection</code> of permissions.
                 */             
                public function setPermissions( permissions:ArrayCollection ):void
                {
                        _permissions = permissions;
                        updateComponents();
                        
                        dispatchEvent( new Event("permissionsUpdated") );
                }
                
                
                /**
                 * Grants additional access to managed components with the specified
                 * permission.
                 * 
                 * @param permission <code>String</code> token granting access to 
                 * specified / managed components.
                 */
                public function addPermission( permission:String ):void
                {
                        if ( _permissions.contains( permission ) == false )
                        {
                                _permissions.addItem( permission );
                                updateComponents();
                                
                                dispatchEvent( new Event("permissionsUpdated") );
                        }
                }

        
                /**
                 * Reduces access to or removes managed components with the specified
                 * permission.
                 * 
                 * @param permission <code>String</code> token that removes
                 * previously granted access to specified / managed components.
                 */
                public function removePermission( permission:String ):void
                {
                        if ( _permissions.contains( permission ) == true ) 
                        {
                                _permissions.removeItemAt( _permissions.getItemIndex( permission ) );
                                updateComponents();
                                
                                dispatchEvent( new Event("permissionsUpdated") );
                        }
                }
                
                
                /**
                 * Removes all permissions for the current user.
                 */
                public function removeAllPermissions():void
                {
                        _permissions.removeAll();
                        updateComponents();
                        
                        dispatchEvent( new Event("permissionsUpdated") );
                }
                
                
                /**
                 * Determines if the current user has the specified permissions.
                 * 
                 * @param permissions <code>Array</code>
                 * @return Returns <code>true</code> if the user has all the specified 
                 * permissions else it will return <code>false</code>.
                 */
                [Bindable(event="permissionsUpdated")]
                public function hasPermissions( permissions:Array ):Boolean
                {
                        var result:Boolean = false;
                        
                        for ( var i:int = 0; i < permissions.length; i++ )
                        {
                                result = result || hasPermission( permissions[i] );
                        }
                        
                        return result;
                }
                
                
                /**
                 * Determines if the current user has the specified permission.
                 * 
                 * @param permission <code>String</code>
                 * @return Returns <code>true</code> if the user has the specified
                 * permission else it will return <code>false</code>.
                 */
                [Bindable(event="permissionsUpdated")]
                public function hasPermission( permission:String ):Boolean
                {
                        for ( var i:int = 0; i < _permissions.length; i++ )
                        {
                                if ( _permissions[i] == permission )
                                        return true;
                        }
                                
                        return false;
                }
         
         
        }// end ComponentSecurityManager
         
}// end package com.quilix.managers
 
/**
 * Used to enforce restricted instantiation of the ComponentSecurityManager.
 */
class ComponentSecurityManagerEnforcer{}