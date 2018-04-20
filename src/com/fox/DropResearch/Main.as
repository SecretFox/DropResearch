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
		s_app = new Mod(swfRoot);
		swfRoot.onLoad = Load;
		swfRoot.onUnload = Unload;
		swfRoot.OnModuleActivated = OnActivated;
		swfRoot.OnModuleDeactivated = OnDeactivated;
	}

	public function Main() { }

	public static function Load():Void {
		s_app.Load();
	}
	public static function Unload():Void {
		s_app.Unload();
	}
	public static function OnActivated(config: Archive):Void {
		s_app.Activate(config);
	}

	public static function OnDeactivated():Archive {
		return s_app.Deactivate();
	}
}