package classes.Perks 
{
	import classes.PerkClass;
	import classes.PerkType;
	import classes.GlobalFlags.*;

	public class Regeneration4Perk extends PerkType
	{
		
		override public function desc(params:PerkClass = null):String
		{
			if (kGAMECLASS.flags[kFLAGS.HUNGER_ENABLED] > 0 && kGAMECLASS.player.hunger < 25) return "<b>DISABLED</b> - You are too hungry!";
			else return super.desc(params);
		}
		
		public function Regeneration4Perk() 
		{
			super("Regeneration 4", "Regeneration 4",
				"Regenerates further 2% of max HP/hour and 1% of max HP/round.",
				"You choose the 'Regeneration 4' perk, giving you an additional 1% of max HP per turn in combat and 2% of max HP per hour.");
		}
		
	}

}