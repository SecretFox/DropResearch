import com.GameInterface.DistributedValue;
import com.GameInterface.DistributedValueBase;
import com.GameInterface.UtilsBase;
import com.Utils.Archive;
/**
 * ...
 * @author fox
 */
class com.fox.DropResearch.DossierHandler{
	static var DossierData = DistributedValue.Create("DossierData_DR");
	
	static function Save(data){
		DossierData.SetValue(data);
	}
	
	static function GetConfig(){
		return DossierData.GetValue();
	}
	
	static function ClearConfig(){
		var conf:Archive = new Archive();
		Save(conf);
	}
	
	static function LoadConfig(config:Archive){
		/*
		 * Using ReplaceEntry on ValueChanged function, which doesn't require pre-initializing the keys
		 * var conf:Archive = new Archive();
		 * conf.AddEntry("MissionsDone", Number(config.FindEntry("MissionsDone", 0)));
		 * conf.AddEntry("MissionDossiers",Number(config.FindEntry("MissionDossiers",0)));
		 * conf.AddEntry("ScenariosDone",Number(config.FindEntry("ScenariosDone",0)));
		 * conf.AddEntry("ScenarioDossiers",Number(config.FindEntry("ScenarioDossiers",0)));
		 * conf.AddEntry("DungeonsDone",Number(config.FindEntry("DungeonsDone",0)));
		 * conf.AddEntry("DungeonDossiers",Number(config.FindEntry("DungeonDossiers",0)));
		 * conf.AddEntry("LairsDone",Number(config.FindEntry("LairsDone",0)));
		 * conf.AddEntry("LairDossiers",Number(config.FindEntry("LairDossiers",0)));
		 * conf.AddEntry("NYRStoryDone",Number(config.FindEntry("NYRStoryDone",0)));
		 * conf.AddEntry("NYRStoryDossiers",Number(config.FindEntry("NYRStoryDossiers",0)));
		 * conf.AddEntry("NYRE1Done",Number(config.FindEntry("NYRE1Done",0)));
		 * conf.AddEntry("NYRE1Dossiers",Number(config.FindEntry("NYRE1Dossiers",0)));
		 * conf.AddEntry("NYRE5Done",Number(config.FindEntry("NYRE5Done",0)));
		 * conf.AddEntry("NYRE5Dossiers",Number(config.FindEntry("NYRE5Dossiers",0)));
		 * conf.AddEntry("NYRE10Done",Number(config.FindEntry("NYRE10Done",0)));
		 * conf.AddEntry("NYRE10Dossiers", Number(config.FindEntry("NYRE10Dossiers", 0)));
		 */
		Save(config);
	}
	
	static function ValueChanged(key, value){
		var config:Archive = DossierData.GetValue();
		var oldVal = Number(config.FindEntry(key, 0));
		var newval = oldVal + value;
		if (DistributedValueBase.GetDValue("DropResearch_Debug")){
			UtilsBase.PrintChatText(
				"Set value " + key +
				" from " + oldVal +
				" to " + newval
			);
		}
		config.ReplaceEntry(key, newval);
		Save(config);
	}
	
	static function getKeyValue(key){
		var config:Archive = DossierData.GetValue();
		return Number(config.FindEntry(key, 0));
	}
}