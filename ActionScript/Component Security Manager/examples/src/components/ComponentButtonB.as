package components
{
	import mx.controls.Button;

	[ManageComponents( components="this", permissions="canClickComponentButtonB", restrictions="enabled" )]
	public class ComponentButtonB extends Button
	{
		public function ComponentButtonB()
		{
			super();
			
			// Anything that you intend to secure should be secure from the 
			// start - note that the enabled property below is set as such.
			this.enabled = false;
		}
		
	}// end ComponentButtonB
	
}// end namespace components