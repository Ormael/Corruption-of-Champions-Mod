package classes.Perks 
{
	import classes.PerkClass;
	import classes.PerkType;
	import classes.GlobalFlags.kGAMECLASS;
	
	public class AscensionDesiresPerk extends PerkType
	{
		
		override public function desc(params:PerkClass = null):String
		{
			return "(Rank: " + params.value1 + "/" + kGAMECLASS.charCreation.MAX_HARDINESS_LEVEL + ") Increases maximum hp by " + params.value1 * 20 + ".";
		}
		
		public function AscensionHardinessPerk() 
		{
			super("Ascension: Hardiness", "Ascension: Hardiness", "", "Increases maximum hp by 20 per level.");
		}
		
		override public function keepOnAscension(respec:Boolean = false):Boolean 
		{
			return true;
		}
	}

}
