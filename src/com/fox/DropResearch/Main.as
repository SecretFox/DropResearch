/**
import com.Utils.archieve:
 * ...
 * @author fox
 */
import com.Utils.Archive;
import com.fox.DropResearch.Mod

class com.fox.DropResearch.Main {
	private static var s_app:Mod;
	public static function main(swfRoot:MovieClip):Void {
		var s_app:Mod = new Mod(swfRoot);
		swfRoot.onLoad = function() { s_app.Load(); };
		swfRoot.OnUnload =  function() { s_app.Unload(); };
		swfRoot.OnModuleActivated = function(config:Archive) { s_app.Activate(config); };
		swfRoot.OnModuleDeactivated = function() { return s_app.Deactivate(); };
	}

	public function Main() { }
}