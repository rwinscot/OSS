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
package com.quilix.ro
{
        
        
        import mx.core.UIComponent;
        
        
        /**
         * A Reference Object (RO) used by the ComponentSecurityManager to
         * track managed components of UIComponent kind.  
         */
        public class ManagedComponentRO
        {


                /**
                 * Used to track components from first mention through being added to the
                 * stage. The id must be globally unique except when referring to 'this.'
                 * 
                 * @default empty
                 */
                public var id:String = "";

                /**
                 * UIComponent reference or our 'managed component.'
                 * 
                 * @default null
                 */
                public var component:UIComponent = null;

                /**
                 * Permissions as they apply to the managed component.
                 * 
                 * @default null
                 */
                public var permissions:Array = null;

                /**
                 * @private
                 */
                private var _restrictions:Array = [];
                
                /**
                 * Restrictions to be enforced on the managed component. Restrictions can 
                 * be optional - when direct binding is used.  
                 * 
                 * @param ary <code>Array</code> of boolean capable restrictions.
                 * @return Returns an <code>Array</code> of permission strings.
                 * @default empty
                 * 
                 * @example
                 * <listing>
                 * 
                 * 
                 * // In your MXML or class... [Bindable] is used to suppress the compiler
                 * // and IDE warning - it will work with or without.
                 * [Bindable]
                 * private var csm:ComponentSecurityManager;
                 * 
                 * 
                 * // Security hook-up
                 * private function ccomp():void
                 * {
                 *     csm = ComponentSecurityManager.getInstance();
                 * }
                 * 
                 * // A function that will trigger restriction updates 
                 * private function togglePermission():void
                 * {
                 *    if ( csm.hasPermission(CAN_CLICK_A) == true )
                 *    {
                 *       csm.removePermission(CAN_CLICK_A);
                 *    }
                 *    else
                 *    {
                 *       csm.addPermission(CAN_CLICK_A);
                 *    }
                 * }
                 * 
                 * &lt;-- MXML component where restrictions are being applied through binding --&gt;
                 * &lt;mx:Button id="buttonA" x="543" y="386" label="Button" enabled="{csm.hasPermission(CAN_CLICK_A)}"/&gt;
                 * 
                 * &lt;-- some mechanism that will trigger restriction updates --&gt;
                 * &lt;mx:CheckBox label="Can click A." change="togglePermission();"/&gt;
                 * 
                 * </listing>
                 */
                public function get restrictions():Array
                {
                        return _restrictions;
                }
                
                public function set restrictions( ary:Array ):void
                {
                        // Split operations can give you an array with a single empty element
                        // so... we need to make sure that doesn't happen.
                        if ( ary.join("") == "" )
                                ary = [];
                                
                        _restrictions = ary;
                }

                /**
                 * Used to determine if the managed component has been added to the 
                 * stage yet.
                 * 
                 * @default false
                 */
                public var addedToStage:Boolean = false;


                /**
                 * Constructor.
                 */
                public function ManagedComponentRO( id:String, permissions:Array, restrictions:Array = null, component:UIComponent = null, addedToStage:Boolean = false )
                { 
                        this.id = id;
                        this.component = component;
                        this.permissions = permissions;
                        this.restrictions = restrictions;
                        this.addedToStage = addedToStage;
                }


        }// end ManagedComponentRO
        
}// end package com.quilix.ro