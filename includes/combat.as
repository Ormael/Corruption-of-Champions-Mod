﻿import classes.Monster;
import classes.Scenes.Areas.HighMountains.Izumi;
import classes.Scenes.Areas.GlacialRift.FrostGiant;
import classes.Scenes.Areas.Mountain.Minotaur;
import classes.Scenes.Dungeons.D3.Doppleganger;
import classes.Scenes.Dungeons.D3.JeanClaude;
import classes.Scenes.Dungeons.D3.LivingStatue;
import classes.Scenes.Dungeons.D3.LivingStatueScenes;
import classes.Scenes.Dungeons.D3.SuccubusGardener;

import coc.view.MainView;
import classes.Saves;
import classes.internals.Utils;

import flash.net.SharedObject;

public function endHpVictory():void
{
	monster.defeated_(true);
}

public function endLustVictory():void
{
	monster.defeated_(false);
}

public function endHpLoss():void
{
	monster.won_(true,false);
}

public function endLustLoss():void
{
	if (player.findStatusAffect(StatusAffects.Infested) >= 0 && flags[kFLAGS.CAME_WORMS_AFTER_COMBAT] == 0) {
		flags[kFLAGS.CAME_WORMS_AFTER_COMBAT] = 1;
		mountain.wormsScene.infestOrgasm();
		monster.won_(false,true);
	} else {
		monster.won_(false,false);
	}
}

//combat is over. Clear shit out and go to main
public function cleanupAfterCombat(nextFunc:Function = null):void {
	fireMagicLastTurn = -100;
	if (nextFunc == null) nextFunc = camp.returnToCampUseOneHour;
	if (prison.inPrison && prison.prisonCombatWinEvent != null) nextFunc = prison.prisonCombatWinEvent;
	if (inCombat) {
		//clear status
		clearStatuses(false);
		//Clear itemswapping in case it hung somehow
//No longer used:		itemSwapping = false;
		//Player won
		if(monster.HP < 1 || monster.lust > (eMaxLust - 1)) {
			awardPlayer(nextFunc);
		}
		//Player lost
		else {
			if(monster.statusAffectv1(StatusAffects.Sparring) == 2) {
				outputText("The cow-girl has defeated you in a practice fight!", true);
				outputText("\n\nYou have to lean on Isabella's shoulder while the two of your hike back to camp.  She clearly won.", false);
				inCombat = false;
				player.HP = 1;
				statScreenRefresh();
				doNext(nextFunc);
				return;
			}
			//Next button is handled within the minerva loss function
			if(monster.findStatusAffect(StatusAffects.PeachLootLoss) >= 0) {
				inCombat = false;
				player.HP = 1;
				statScreenRefresh();
				return;
			}
			if(monster.short == "Ember") {
				inCombat = false;
				player.HP = 1;
				statScreenRefresh();
				doNext(nextFunc);
				return;
			}
			temp = rand(10) + 1 + Math.round(monster.level / 2);
			if (inDungeon) temp += 20 + monster.level * 2;
			//Increases gems lost in NG+.
			temp *= 1 + (player.newGamePlusMod() * 0.5);
			//Round gems.
			temp = Math.round(temp);
			//Keep gems from going below zero.
			if (temp > player.gems) temp = player.gems;
			var timePasses:int = monster.handleCombatLossText(inDungeon, temp); //Allows monsters to customize the loss text and the amount of time lost
			player.gems -= temp;
			inCombat = false;
			if (prison.inPrison == false && flags[kFLAGS.PRISON_CAPTURE_CHANCE] > 0 && rand(100) < flags[kFLAGS.PRISON_CAPTURE_CHANCE] && (prison.trainingFeed.prisonCaptorFeedingQuestTrainingIsTimeUp() || !prison.trainingFeed.prisonCaptorFeedingQuestTrainingExists()) && (monster.short == "goblin" || monster.short == "goblin assassin" || monster.short == "imp" || monster.short == "imp lord" || monster.short == "imp warlord" || monster.short == "hellhound" || monster.short == "minotaur" || monster.short == "satyr" || monster.short == "gnoll" || monster.short == "gnoll spear-thrower" || monster.short == "basilisk")) {
				outputText("  You feel yourself being dragged and carried just before you black out.");
				doNext(prison.prisonIntro);
				return;
			}
			//BUNUS XPZ
			if(flags[kFLAGS.COMBAT_BONUS_XP_VALUE] > 0) {
				player.XP += flags[kFLAGS.COMBAT_BONUS_XP_VALUE];
				outputText("  Somehow you managed to gain " + flags[kFLAGS.COMBAT_BONUS_XP_VALUE] + " XP from the situation.");
				flags[kFLAGS.COMBAT_BONUS_XP_VALUE] = 0;
			}
			//Bonus lewts
			if (flags[kFLAGS.BONUS_ITEM_AFTER_COMBAT_ID] != "") {
				outputText("  Somehow you came away from the encounter with " + ItemType.lookupItem(flags[kFLAGS.BONUS_ITEM_AFTER_COMBAT_ID]).longName + ".\n\n");
				inventory.takeItem(ItemType.lookupItem(flags[kFLAGS.BONUS_ITEM_AFTER_COMBAT_ID]), createCallBackFunction(camp.returnToCamp, timePasses));
			}
			else doNext(createCallBackFunction(camp.returnToCamp, timePasses));
		}
	}
	//Not actually in combat
	else doNext(nextFunc);
}

public function checkAchievementDamage(damage:Number):void
{
	flags[kFLAGS.ACHIEVEMENT_PROGRESS_TOTAL_DAMAGE] += damage;
	if (flags[kFLAGS.ACHIEVEMENT_PROGRESS_TOTAL_DAMAGE] >= 50000) kGAMECLASS.awardAchievement("Bloodletter", kACHIEVEMENTS.COMBAT_BLOOD_LETTER);
	if (damage >= 50) kGAMECLASS.awardAchievement("Pain", kACHIEVEMENTS.COMBAT_PAIN);
	if (damage >= 100) kGAMECLASS.awardAchievement("Fractured Limbs", kACHIEVEMENTS.COMBAT_FRACTURED_LIMBS);
	if (damage >= 250) kGAMECLASS.awardAchievement("Broken Bones", kACHIEVEMENTS.COMBAT_BROKEN_BONES);
	if (damage >= 500) kGAMECLASS.awardAchievement("Overkill", kACHIEVEMENTS.COMBAT_OVERKILL);
}
public function approachAfterKnockback():void
{
	clearOutput();
	outputText("You close the distance between you and " + monster.a + monster.short + " as quickly as possible.\n\n");
	player.removeStatusAffect(StatusAffects.KnockedBack);
	if (player.weaponName == "flintlock pistol") {
		if (flags[kFLAGS.FLINTLOCK_PISTOL_AMMO] <= 0) {
			flags[kFLAGS.FLINTLOCK_PISTOL_AMMO] = 4;
			outputText("At the same time, you open the magazine of your pistol to reload the ammunition.  This takes up a turn.\n\n");
			enemyAI();
			return;
		}
		else {
			outputText("At the same time, you fire a round at " + monster.short + ". ");
			attack();
			return;
		}
	}
	if (player.weaponName == "crossbow") {
		outputText("At the same time, you fire a bolt at " + monster.short + ". ");
		attack();
		return;
	}
	enemyAI();
	return;
}

private function isPlayerSilenced():Boolean
{
	var temp:Boolean = false;
	if (player.findStatusAffect(StatusAffects.ThroatPunch) >= 0) temp = true;
	if (player.findStatusAffect(StatusAffects.WebSilence) >= 0) temp = true;
	if (player.findStatusAffect(StatusAffects.GooArmorSilence) >= 0) temp = true;
	return temp;
}

private function isPlayerBound():Boolean 
{
	var temp:Boolean = false;
	if (player.findStatusAffect(StatusAffects.HarpyBind) >= 0 || player.findStatusAffect(StatusAffects.GooBind) >= 0 || player.findStatusAffect(StatusAffects.TentacleBind) >= 0 || player.findStatusAffect(StatusAffects.NagaBind) >= 0 || monster.findStatusAffect(StatusAffects.QueenBind) >= 0 || monster.findStatusAffect(StatusAffects.PCTailTangle) >= 0) temp = true;
	if (player.findStatusAffect(StatusAffects.HolliConstrict) >= 0) temp = true;
	if (player.findStatusAffect(StatusAffects.GooArmorBind) >= 0) temp = true;
	if (monster.findStatusAffect(StatusAffects.MinotaurEntangled) >= 0) {
		outputText("\n<b>You're bound up in the minotaur lord's chains!  All you can do is try to struggle free!</b>");
		temp = true;
	}
	if (player.findStatusAffect(StatusAffects.UBERWEB) >= 0) temp = true;
	if (player.findStatusAffect(StatusAffects.Bound) >= 0) temp = true;
	if (player.findStatusAffect(StatusAffects.Chokeslam) >= 0) temp = true;
	if (player.findStatusAffect(StatusAffects.Titsmother) >= 0) temp = true;
	if (player.findStatusAffect(StatusAffects.GiantGrabbed) >= 0) {
		outputText("\n<b>You're trapped in the giant's hand!  All you can do is try to struggle free!</b>");
		temp = true;
	}
	if (player.findStatusAffect(StatusAffects.Tentagrappled) >= 0) {
		outputText("\n<b>The demonesses tentacles are constricting your limbs!</b>");
		temp = true;
	}
	return temp;
}

private function isPlayerStunned():Boolean 
{
	var temp:Boolean = false;
	if (player.findStatusAffect(StatusAffects.IsabellaStunned) >= 0 || player.findStatusAffect(StatusAffects.Stunned) >= 0) {
		outputText("\n<b>You're too stunned to attack!</b>  All you can do is wait and try to recover!");
		temp = true;
	}
	if (player.findStatusAffect(StatusAffects.Whispered) >= 0) {
		outputText("\n<b>Your mind is too addled to focus on combat!</b>  All you can do is try and recover!");
		temp = true;
	}
	if (player.findStatusAffect(StatusAffects.Confusion) >= 0) {
		outputText("\n<b>You're too confused</b> about who you are to try to attack!");
		temp = true;
	}
	return temp;
}

private function canUseMagic():Boolean {
	if (player.findStatusAffect(StatusAffects.ThroatPunch) >= 0) return false;
	if (player.findStatusAffect(StatusAffects.WebSilence) >= 0) return false;
	if (player.findStatusAffect(StatusAffects.GooArmorSilence) >= 0) return false;
	return true;
}

public function combatMenu(newRound:Boolean = true):void { //If returning from a sub menu set newRound to false
	clearOutput();
	flags[kFLAGS.IN_COMBAT_USE_PLAYER_WAITED_FLAG] = 0;
	mainView.hideMenuButton(MainView.MENU_DATA);
	mainView.hideMenuButton(MainView.MENU_APPEARANCE);
	mainView.hideMenuButton(MainView.MENU_PERKS);
	hideUpDown();
	if (newRound) combatStatusesUpdate(); //Update Combat Statuses
	display();
	statScreenRefresh();
//This is now automatic - newRound arg defaults to true:	menuLoc = 0;
	if (combatRoundOver()) return;
	menu();
	var attacks:Function = normalAttack;
	//Standard menu before modifications.
	if(!isWieldingRangedWeapon())
		addButton(0, "Attack", attacks, null, null, null, "Attempt to attack the enemy with your " + player.weaponName + ".  Damage done is determined by your strength and weapon.");
	else if (player.weaponName.indexOf("staff") != -1)
		addButton(0, "M.Bolt", attacks, null, null, null, "Attempt to attack the enemy with magic bolt from your " + player.weaponName + ".  Damage done is determined by your intellegence, speed and weapon.", "Magic Bolt");
	else if (flags[kFLAGS.FLINTLOCK_PISTOL_AMMO] <= 0 && player.weaponName == "flintlock pistol")
		addButton(0, "Reload", attacks, null, null, null, "Your " + player.weaponName + " is out of ammo.  You'll have to reload it before attack.");
	else
		addButton(0, "Shoot", attacks, null, null, null, "Fire a round at your opponent with your " + player.weaponName + "!  Damage done is determined by your strength, speed and weapon.");
		
	addButton(1, "Tease", teaseAttack, null, null, null, "Attempt to make an enemy more aroused by striking a seductive pose and exposing parts of your body.");
	if (canUseMagic()) addButton(2, "Spells", magicMenu, null, null, null, "Opens your spells menu, where you can cast any spells you have learned.  Beware, casting spells increases your fatigue, and if you become exhausted you will be easier to defeat.");
	addButton(3, "Items", inventory.inventoryMenu, null, null, null, "The inventory allows you to use an item.  Be careful as this leaves you open to a counterattack when in combat.");
	addButton(4, "Run", runAway, null, null, null, "Choosing to run will let you try to escape from your enemy. However, it will be hard to escape enemies that are faster than you and if you fail, your enemy will get a free attack.");
	addButton(5, "P. Specials", physicalSpecials, null, null, null, "Physical special attack menu.", "Physical Specials");
	addButton(6, "M. Specials", magicalSpecials, null, null, null, "Mental and supernatural special attack menu.", "Magical Specials");
	addButton(7, "Wait", wait, null, null, null, "Take no action for this round.  Why would you do this?  This is a terrible idea.");
	if (monster.findStatusAffect(StatusAffects.Level) >= 0) addButton(7, "Climb", wait, null, null, null, "Climb the sand to move away from the sand trap.");
	addButton(8, "Fantasize", fantasize, null, null, null, "Fantasize about your opponent in a sexual way.  Its probably a pretty bad idea to do this unless you want to end up getting raped.");
	if (CoC_Settings.debugBuild && !debug) addButton(9, "Inspect", debugInspect, null, null, null, "Use your debug powers to inspect your enemy.");
	//Modify menus.
	if (monster.findStatusAffect(StatusAffects.AttackDisabled) >= 0) {
		outputText("\n<b>Chained up as you are, you can't manage any real physical attacks!</b>");
		attacks = null;
	}
	//Knocked back
	if (player.findStatusAffect(StatusAffects.KnockedBack) >= 0)
	{
		outputText("\n<b>You'll need to close some distance before you can use any physical attacks!</b>");
		if (isWieldingRangedWeapon()) {
			if (flags[kFLAGS.FLINTLOCK_PISTOL_AMMO] <= 0 && player.weaponName == "flintlock pistol") addButton(0, "Reload&Approach", approachAfterKnockback, null, null, null, "Reload your flintlock pistol while approaching.", "Reload and Approach");
			else addButton(0, "Shoot&Approach", approachAfterKnockback, null, null, null, "Fire a round at your opponent and approach.", "Reload and Approach");
		}
		else addButton(0, "Approach", approachAfterKnockback, null, null, null, "Close some distance between you and your opponent.");
		if (player.hasKeyItem("Bow") >= 0 || player.hasKeyItem("Kelt's Bow") >= 0) addButton(5, "Bow", fireBow);
	}
	//Disabled physical attacks
	if (monster.findStatusAffect(StatusAffects.PhysicalDisabled) >= 0) {
		outputText("<b>  Even physical special attacks are out of the question.</b>");
		removeButton(5); //Removes physical special attack.
	}
	//Bound: Struggle or wait
	if (isPlayerBound()) {
		menu();
		addButton(0, "Struggle", struggle);
		addButton(1, "Wait", wait);
		if (player.findStatusAffect(StatusAffects.UBERWEB) >= 0) {
			addButton(6, "M. Special", magicalSpecials);
		}
		if (player.findStatusAffect(StatusAffects.Bound) >= 0) {
			addButton(0, "Struggle", (monster as Ceraph).ceraphBindingStruggle);
			addButton(1, "Wait", (monster as Ceraph).ceraphBoundWait);
		}
		if (player.findStatusAffect(StatusAffects.Chokeslam) >= 0) {
			addButton(0, "Struggle", (monster as Izumi).chokeSlamStruggle);
			addButton(1, "Wait", (monster as Izumi).chokeSlamWait);
		}
		if (player.findStatusAffect(StatusAffects.Titsmother) >= 0) {
			addButton(0, "Struggle", (monster as Izumi).titSmotherStruggle);
			addButton(1, "Wait", (monster as Izumi).titSmotherWait);
		}
		if (player.findStatusAffect(StatusAffects.Tentagrappled) >= 0) {
			addButton(0, "Struggle", (monster as SuccubusGardener).grappleStruggle);
			addButton(1, "Wait", (monster as SuccubusGardener).grappleWait);
		}
	}
	//Silence: Disables magic menu.
	if (isPlayerSilenced()) {
		removeButton(2);
	}
	//Stunned: Recover, lose 1 turn.
	if (isPlayerStunned()) {
		menu();
		addButton(0, "Recover", wait);
	}
	else if (monster.findStatusAffect(StatusAffects.Constricted) >= 0) {
		menu();
		addButton(0, "Squeeze", desert.nagaScene.naggaSqueeze, null, null, null, "Squeeze some HP out of your opponent! \n\nFatigue Cost: " + physicalCost(20) + "");
		addButton(1, "Tease", desert.nagaScene.naggaTease);
		addButton(4, "Release", desert.nagaScene.nagaLeggoMyEggo);
	}
}

private function teaseAttack():void {
	if (monster.lustVuln == 0) {
		clearOutput();
		outputText("You try to tease " + monster.a + monster.short + " with your body, but it doesn't have any effect on " + monster.pronoun2 + ".\n\n");
		enemyAI();
	}
	//Worms are immune!
	else if (monster.short == "worms") {
		clearOutput();
		outputText("Thinking to take advantage of its humanoid form, you wave your cock and slap your ass in a rather lewd manner. However, the creature fails to react to your suggestive actions.\n\n");
		enemyAI();
	}
	else {
		tease();
		if (!combatRoundOver()) enemyAI();
	}
}

private function normalAttack():void {
	clearOutput();
	attack();
}

public function packAttack():void {
	//Determine if dodged!
	if (player.spe - monster.spe > 0 && int(Math.random() * (((player.spe - monster.spe) / 4) + 80)) > 80) {
		outputText("You duck, weave, and dodge.  Despite their best efforts, the throng of demons only hit the air and each other.");
	}
	//Determine if evaded
	else if (player.findPerk(PerkLib.Evade) >= 0 && rand(100) < 10) {
		outputText("Using your skills at evading attacks, you anticipate and sidestep " + monster.a + monster.short + "' attacks.");
	}
	//("Misdirection"
	else if (player.findPerk(PerkLib.Misdirection) >= 0 && rand(100) < 15 && player.armorName == "red, high-society bodysuit") {
		outputText("Using Raphael's teachings, you anticipate and sidestep " + monster.a + monster.short + "' attacks.");
	}
	//Determine if cat'ed
	else if (player.findPerk(PerkLib.Flexibility) >= 0 && rand(100) < 6) {
		outputText("With your incredible flexibility, you squeeze out of the way of " + monster.a + monster.short + "' attacks.");
	}
	else {
		temp = int((monster.str + monster.weaponAttack) * (player.damagePercent() / 100)); //Determine damage - str modified by enemy toughness!
		if (temp <= 0) {
			temp = 0;
			if (!monster.plural)
				outputText("You deflect and block every " + monster.weaponVerb + " " + monster.a + monster.short + " throw at you.");
			else outputText("You deflect " + monster.a + monster.short + " " + monster.weaponVerb + ".");
		}
		else {
			if (temp <= 5)
				outputText("You are struck a glancing blow by " + monster.a + monster.short + "! ");
			else if (temp <= 10)
				outputText(monster.capitalA + monster.short + " wound you! ");
			else if (temp <= 20)
				outputText(monster.capitalA + monster.short + " stagger you with the force of " + monster.pronoun3 + " " + monster.weaponVerb + "s! ");
			else outputText(monster.capitalA + monster.short + " <b>mutilates</b> you with powerful fists and " + monster.weaponVerb + "s! ");
			takeDamage(temp, true);
		}
		statScreenRefresh();
		outputText("\n");
	}
	combatRoundOver();
}

public function lustAttack():void {
	if (player.lust < 35) {
		outputText("The " + monster.short + " press in close against you and although they fail to hit you with an attack, the sensation of their skin rubbing against yours feels highly erotic.");
	}
	else if (player.lust < 65) {
		outputText("The push of the " + monster.short + "' sweaty, seductive bodies sliding over yours is deliciously arousing and you feel your ");
		if (player.cocks.length > 0)
			outputText(player.multiCockDescriptLight() + " hardening ");
		else if (player.vaginas.length > 0) outputText(vaginaDescript(0) + " get wetter ");
		outputText("in response to all the friction.");
	}
	else {
		outputText("As the " + monster.short + " mill around you, their bodies rub constantly over yours, and it becomes harder and harder to keep your thoughts on the fight or resist reaching out to touch a well lubricated cock or pussy as it slips past.  You keep subconsciously moving your ");
		if (player.gender == 1) outputText(player.multiCockDescriptLight() + " towards the nearest inviting hole.");
		if (player.gender == 2) outputText(vaginaDescript(0) + " towards the nearest swinging cock.");
		if (player.gender == 3) outputText("aching cock and thirsty pussy towards the nearest thing willing to fuck it.");
		if (player.gender == 0) outputText("groin, before remember there is nothing there to caress.");
	}
	dynStats("lus", 10 + player.sens / 10);
	combatRoundOver();
}

private function wait():void {
	//Gain fatigue if not fighting sand tarps
	if (monster.findStatusAffect(StatusAffects.Level) < 0) fatigue(-5);
	flags[kFLAGS.IN_COMBAT_USE_PLAYER_WAITED_FLAG] = 1;
	if (monster.findStatusAffect(StatusAffects.PCTailTangle) >= 0) {
		(monster as Kitsune).kitsuneWait();
	}
	else if (monster.findStatusAffect(StatusAffects.Level) >= 0) {
		(monster as SandTrap).sandTrapWait();
	}
	else if (monster.findStatusAffect(StatusAffects.MinotaurEntangled) >= 0) {
		clearOutput();
		outputText("You sigh and relax in the chains, eying the well-endowed minotaur as you await whatever rough treatment he desires to give.  His musky, utterly male scent wafts your way on the wind, and you feel droplets of your lust dripping down your thighs.  You lick your lips as you watch the pre-cum drip from his balls, eager to get down there and worship them.  Why did you ever try to struggle against this fate?\n\n");
		dynStats("lus", 30 + rand(5), "resisted", false);
		enemyAI();
	}
	else if (player.findStatusAffect(StatusAffects.Whispered) >= 0) {
		clearOutput();
		outputText("You shake off the mental compulsions and ready yourself to fight!\n\n");
		player.removeStatusAffect(StatusAffects.Whispered);
		enemyAI();
	}
	else if (player.findStatusAffect(StatusAffects.HarpyBind) >= 0) {
		clearOutput();
		outputText("The brood continues to hammer away at your defenseless self. ");
		temp = 80 + rand(40);
		temp = takeDamage(temp, true);
		combatRoundOver();
	}
	else if (monster.findStatusAffect(StatusAffects.QueenBind) >= 0) {
		(monster as HarpyQueen).ropeStruggles(true);
	}
	else if (player.findStatusAffect(StatusAffects.GooBind) >= 0) {
		clearOutput();
		outputText("You writhe uselessly, trapped inside the goo girl's warm, seething body. Darkness creeps at the edge of your vision as you are lulled into surrendering by the rippling vibrations of the girl's pulsing body around yours.");
		temp = takeDamage(.35 * maxHP(), true);
		combatRoundOver();
	}
	else if (player.findStatusAffect(StatusAffects.GooArmorBind) >= 0) {
		clearOutput();
		outputText("Suddenly, the goo-girl leaks half-way out of her heavy armor and lunges at you. You attempt to dodge her attack, but she doesn't try and hit you - instead, she wraps around you, pinning your arms to your chest. More and more goo latches onto you - you'll have to fight to get out of this.");
		player.addStatusValue(StatusAffects.GooArmorBind, 1, 1);
		if (player.statusAffectv1(StatusAffects.GooArmorBind) >= 5) {
			if (monster.findStatusAffect(StatusAffects.Spar) >= 0)
				valeria.pcWinsValeriaSparDefeat();
			else dungeons.heltower.gooArmorBeatsUpPC();
			return;
		}
		combatRoundOver();
	}
	else if (player.findStatusAffect(StatusAffects.NagaBind) >= 0) {
		clearOutput();
		outputText("The naga's grip on you tightens as you relax into the stimulating pressure.");
		dynStats("lus", player.sens / 5 + 5);
		takeDamage(5 + rand(5));
		combatRoundOver();
	}
	else if (player.findStatusAffect(StatusAffects.HolliConstrict) >= 0) {
		(monster as Holli).waitForHolliConstrict(true);
	}
	else if (player.findStatusAffect(StatusAffects.TentacleBind) >= 0) {
		clearOutput();
		if (player.cocks.length > 0)
			outputText("The creature continues spiraling around your cock, sending shivers up and down your body. You must escape or this creature will overwhelm you!");
		else if (player.hasVagina())
			outputText("The creature continues sucking your clit and now has latched two more suckers on your nipples, amplifying your growing lust. You must escape or you will become a mere toy to this thing!");
		else outputText("The creature continues probing at your asshole and has now latched " + num2Text(player.totalNipples()) + " more suckers onto your nipples, amplifying your growing lust.  You must escape or you will become a mere toy to this thing!");
		dynStats("lus", (8 + player.sens / 10));
		combatRoundOver();
	}
	else if (player.findStatusAffect(StatusAffects.GiantGrabbed) >= 0) {
		clearOutput();
		(monster as FrostGiant).giantGrabFail(false);
	}
	else if (player.findStatusAffect(StatusAffects.GiantBoulder) >= 0) {
		clearOutput();
		(monster as FrostGiant).giantBoulderMiss();
	}
	else if (player.findStatusAffect(StatusAffects.IsabellaStunned) >= 0) {
		clearOutput();
		outputText("You wobble about for some time but manage to recover. Isabella capitalizes on your wasted time to act again.\n\n");
		player.removeStatusAffect(StatusAffects.IsabellaStunned);
		enemyAI();
	}
	else if (player.findStatusAffect(StatusAffects.Stunned) >= 0) {
		clearOutput();
		outputText("You wobble about, stunned for a moment.  After shaking your head, you clear the stars from your vision, but by then you've squandered your chance to act.\n\n");
		player.removeStatusAffect(StatusAffects.Stunned);
		enemyAI();
	}
	else if (player.findStatusAffect(StatusAffects.Confusion) >= 0) {
		clearOutput();
		outputText("You shake your head and file your memories in the past, where they belong.  It's time to fight!\n\n");
		player.removeStatusAffect(StatusAffects.Confusion);
		enemyAI();
	}
	else if (monster is Doppleganger) {
		clearOutput();
		outputText("You decide not to take any action this round.\n\n");
		(monster as Doppleganger).handlePlayerWait();
		enemyAI();
	}
	else {
		clearOutput();
		outputText("You decide not to take any action this round.\n\n");
		enemyAI();
	}
}

private function struggle():void {
	if (monster.findStatusAffect(StatusAffects.MinotaurEntangled) >= 0) {
		clearOutput();
		if (player.str / 9 + rand(20) + 1 >= 15) {
			outputText("Utilizing every ounce of your strength and cunning, you squirm wildly, shrugging through weak spots in the chain's grip to free yourself!  Success!\n\n");
			monster.removeStatusAffect(StatusAffects.MinotaurEntangled);
			if (flags[kFLAGS.URTA_QUEST_STATUS] == 0.75) outputText("\"<i>No!  You fool!  You let her get away!  Hurry up and finish her up!  I need my serving!</i>\"  The succubus spits out angrily.\n\n");
			combatRoundOver();
		}
		//Struggle Free Fail*
		else {
			outputText("You wiggle and struggle with all your might, but the chains remain stubbornly tight, binding you in place.  Damnit!  You can't lose like this!\n\n");
			enemyAI();
		}
	}
	else if (monster.findStatusAffect(StatusAffects.PCTailTangle) >= 0) {
		(monster as Kitsune).kitsuneStruggle();
	}
	else if (player.findStatusAffect(StatusAffects.HolliConstrict) >= 0) {
		(monster as Holli).struggleOutOfHolli();
	}
	else if (monster.findStatusAffect(StatusAffects.QueenBind) >= 0) {
		(monster as HarpyQueen).ropeStruggles();
	}
	else if (player.findStatusAffect(StatusAffects.GooBind) >= 0) {
		clearOutput();
		//[Struggle](successful) :
		if (rand(3) == 0 || rand(80) < player.str) {
			outputText("You claw your fingers wildly within the slime and manage to brush against her heart-shaped nucleus. The girl silently gasps and loses cohesion, allowing you to pull yourself free while she attempts to solidify.");
			player.removeStatusAffect(StatusAffects.GooBind);
		}
		//Failed struggle
		else {
			outputText("You writhe uselessly, trapped inside the goo girl's warm, seething body. Darkness creeps at the edge of your vision as you are lulled into surrendering by the rippling vibrations of the girl's pulsing body around yours. ");
			temp = takeDamage(.15 * maxHP(), true);
		}
		combatRoundOver();
	}
	else if (player.findStatusAffect(StatusAffects.HarpyBind) >= 0) {
		(monster as HarpyMob).harpyHordeGangBangStruggle();
	}
	else if (player.findStatusAffect(StatusAffects.GooArmorBind) >= 0) {
		(monster as GooArmor).struggleAtGooBind();
	}
	else if (player.findStatusAffect(StatusAffects.UBERWEB) >= 0) {
		clearOutput();
		outputText("You claw your way out of the webbing while Kiha does her best to handle the spiders single-handedly!\n\n");
		player.removeStatusAffect(StatusAffects.UBERWEB);
		enemyAI();
	}
	else if (player.findStatusAffect(StatusAffects.NagaBind) >= 0) {
		clearOutput();
		if (rand(3) == 0 || rand(80) < player.str / 1.5) {
			outputText("You wriggle and squirm violently, tearing yourself out from within the naga's coils.");
			player.removeStatusAffect(StatusAffects.NagaBind);
		}
		else {
			outputText("The naga's grip on you tightens as you struggle to break free from the stimulating pressure.");
			dynStats("lus", player.sens / 10 + 2);
			takeDamage(7 + rand(5));
		}
		combatRoundOver();
	}
	else if (player.findStatusAffect(StatusAffects.GiantGrabbed) >= 0) {
		(monster as FrostGiant).giantGrabStruggle();
	}
	else {
		clearOutput();
		outputText("You struggle with all of your might to free yourself from the tentacles before the creature can fulfill whatever unholy desire it has for you.\n");
		//33% chance to break free + up to 50% chance for strength
		if (rand(3) == 0 || rand(80) < player.str / 2) {
			outputText("As the creature attempts to adjust your position in its grip, you free one of your " + player.legs() + " and hit the beast in its beak, causing it to let out an inhuman cry and drop you to the ground smartly.\n\n");
			player.removeStatusAffect(StatusAffects.TentacleBind);
			monster.createStatusAffect(StatusAffects.TentacleCoolDown, 3, 0, 0, 0);
			enemyAI();
		}
		//Fail to break free
		else {
			outputText("Despite trying to escape, the creature only tightens its grip, making it difficult to breathe.\n\n");
			takeDamage(5);
			if (player.cocks.length > 0)
				outputText("The creature continues spiraling around your cock, sending shivers up and down your body. You must escape or this creature will overwhelm you!");
			else if (player.hasVagina())
				outputText("The creature continues sucking your clit and now has latched two more suckers on your nipples, amplifying your growing lust. You must escape or you will become a mere toy to this thing!");
			else outputText("The creature continues probing at your asshole and has now latched " + num2Text(player.totalNipples()) + " more suckers onto your nipples, amplifying your growing lust.  You must escape or you will become a mere toy to this thing!");
			dynStats("lus", (3 + player.sens / 10 + player.lib / 20));
			combatRoundOver();
		}
	}
}

private function fireBow():void {
	clearOutput();
	if (player.fatigue + physicalCost(25) > player.maxFatigue()) {
		outputText("You're too fatigued to fire the bow!");
		menu();
		addButton(0, "Next", combatMenu, false);
		return;
	}
	if (monster.findStatusAffect(StatusAffects.BowDisabled) >= 0) {
		outputText("You can't use your bow right now!");
		menu();
		addButton(0, "Next", combatMenu, false);
		return;
	}
	fatigue(25, 2);
	//Keep logic sane if this attack brings victory
//This is now automatic - newRound arg defaults to true:	menuLoc = 0;
	//Amily!
	if (monster.findStatusAffect(StatusAffects.Concentration) >= 0) {
		outputText("Amily easily glides around your attack thanks to her complete concentration on your movements.\n\n");
		enemyAI();
		return;
	}
	//Prep messages vary by skill.
	if (player.statusAffectv1(StatusAffects.Kelt) < 30) {
		outputText("Fumbling a bit, you nock an arrow and fire!\n");
	}
	else if (player.statusAffectv1(StatusAffects.Kelt) < 50) {
		outputText("You pull an arrow and fire it at " + monster.a + monster.short + "!\n");
	}
	else if (player.statusAffectv1(StatusAffects.Kelt) < 80) {
		outputText("With one smooth motion you draw, nock, and fire your deadly arrow at your opponent!\n");
	}
	else if (player.statusAffectv1(StatusAffects.Kelt) <= 99) {
		outputText("In the blink of an eye you draw and fire your bow directly at " + monster.a + monster.short + ".\n");
	}
	else {
		outputText("You casually fire an arrow at " + monster.a + monster.short + " with supreme skill.\n");
		//Keep it from going over 100
		player.changeStatusValue(StatusAffects.Kelt, 1, 100);
	}
	if (monster.findStatusAffect(StatusAffects.Sandstorm) >= 0 && rand(10) > 1) {
		outputText("Your shot is blown off target by the tornado of sand and wind.  Damn!\n\n");
		enemyAI();
		return;
	}
	//[Bow Response]
	if (monster.short == "Isabella") {
		if (monster.findStatusAffect(StatusAffects.Blind) >= 0)
			outputText("Isabella hears the shot and turns her shield towards it, completely blocking it with her wall of steel.\n\n");
		else outputText("You arrow thunks into Isabella's shield, completely blocked by the wall of steel.\n\n");
		if (isabellaFollowerScene.isabellaAccent())
			outputText("\"<i>You remind me of ze horse-people.  They cannot deal vith mein shield either!</i>\" cheers Isabella.\n\n");
		else outputText("\"<i>You remind me of the horse-people.  They cannot deal with my shield either!</i>\" cheers Isabella.\n\n");
		enemyAI();
		return;
	}
	//worms are immune
	if (monster.short == "worms") {
		outputText("The arrow slips between the worms, sticking into the ground.\n\n");
		enemyAI();
		return;
	}
	//Vala miss chance!
	if (monster.short == "Vala" && rand(10) < 7 && monster.findStatusAffect(StatusAffects.Stunned) < 0) {
		outputText("Vala flaps her wings and twists her body. Between the sudden gust of wind and her shifting of position, the arrow goes wide.\n\n");
		enemyAI();
		return;
	}
	//Blind miss chance
	if (player.findStatusAffect(StatusAffects.Blind) >= 0) {
		outputText("The arrow hits something, but blind as you are, you don't have a chance in hell of hitting anything with a bow.\n\n");
		enemyAI();
		return;
	}
	//Miss chance 10% based on speed + 10% based on int + 20% based on skill
	if (monster.short != "pod" && player.spe / 10 + player.inte / 10 + player.statusAffectv1(StatusAffects.Kelt) / 5 + 60 < rand(101)) {
		outputText("The arrow goes wide, disappearing behind your foe.\n\n");
		enemyAI();
		return;
	}
	//Hit!  Damage calc! 20 +
	var damage:Number = 0;
	damage = int(((20 + player.str / 3 + player.statusAffectv1(StatusAffects.Kelt) / 1.2) + player.spe / 3) * (monster.damagePercent() / 100));
	if (damage < 0) damage = 0;
	if (damage == 0) {
		if (monster.inte > 0)
			outputText(monster.capitalA + monster.short + " shrugs as the arrow bounces off them harmlessly.\n\n");
		else outputText("The arrow bounces harmlessly off " + monster.a + monster.short + ".\n\n");
		enemyAI();
		return;
	}
	if (monster.short == "pod")
		outputText("The arrow lodges deep into the pod's fleshy wall");
	else if (monster.plural)
		outputText(monster.capitalA + monster.short + " look down at the arrow that now protrudes from one of " + monster.pronoun3 + " bodies");
	else outputText(monster.capitalA + monster.short + " looks down at the arrow that now protrudes from " + monster.pronoun3 + " body");
	if (player.findPerk(PerkLib.HistoryFighter) >= 0) damage *= 1.1;
	if (player.findPerk(PerkLib.JobArcher) >= 0) damage *= 1.2;
	if (player.hasKeyItem("Kelt's Bow") >= 0) damage *= 1.3;
	damage = doDamage(damage);
	monster.lust -= 20;
	if (monster.lust < 0) monster.lust = 0;
	if (monster.HP <= 0) {
		if (monster.short == "pod")
			outputText(". ");
		else if (monster.plural)
			outputText(" and stagger, collapsing onto each other from the wounds you've inflicted on " + monster.pronoun2 + ". ");
		else outputText(" and staggers, collapsing from the wounds you've inflicted on " + monster.pronoun2 + ". ");
		outputText("<b>(<font color=\"#800000\">" + String(damage) + "</font>)</b>");
		outputText("\n\n");
		checkAchievementDamage(damage);
		doNext(endHpVictory);
		return;
	}
	else outputText(".  It's clearly very painful. <b>(<font color=\"#800000\">" + String(damage) + "</font>)</b>\n\n");
	checkAchievementDamage(damage);
	enemyAI();
}

private function fireBreathMenu():void {
	clearOutput();
	outputText("Which of your special fire-breath attacks would you like to use?");
	simpleChoices("Akbal's", fireballuuuuu, "Hellfire", hellFire, "Dragonfire", dragonBreath, "", null, "Back", playerMenu);
}

private function debugInspect():void {
	outputText(monster.generateDebugDescription());
	doNext(playerMenu);
}

//Fantasize
public function fantasize():void {
	var temp2:Number = 0;
	doNext(combatMenu);
	clearOutput();
	if (monster.short == "frost giant" && (player.findStatusAffect(StatusAffects.GiantBoulder) >= 0)) {
		temp2 = 10 + rand(player.lib / 5 + player.cor / 8);
		dynStats("lus", temp2, "resisted", false);
		(monster as FrostGiant).giantBoulderFantasize();
		enemyAI();
		return;
	}
	if(player.armorName == "goo armor") {
		outputText("As you fantasize, you feel Valeria rubbing her gooey body all across your sensitive skin");
		if(player.gender > 0) outputText(" and genitals");
		outputText(", arousing you even further.\n");
		temp2 = 25 + rand(player.lib/8+player.cor/8)
	}	
	else if(player.balls > 0 && player.ballSize >= 10 && rand(2) == 0) {
		outputText("You daydream about fucking " + monster.a + monster.short + ", feeling your balls swell with seed as you prepare to fuck " + monster.pronoun2 + " full of cum.\n", false);
		temp2 = 5 + rand(player.lib/8+player.cor/8);
		outputText("You aren't sure if it's just the fantasy, but your " + ballsDescriptLight() + " do feel fuller than before...\n", false);
		player.hoursSinceCum += 50;
	}
	else if(player.biggestTitSize() >= 6 && rand(2) == 0) {
		outputText("You fantasize about grabbing " + monster.a + monster.short + " and shoving " + monster.pronoun2 + " in between your jiggling mammaries, nearly suffocating " + monster.pronoun2 + " as you have your way.\n", false);
		temp2 = 5 + rand(player.lib/8+player.cor/8)
	}
	else if(player.biggestLactation() >= 6 && rand(2) == 0) {
		outputText("You fantasize about grabbing " + monster.a + monster.short + " and forcing " + monster.pronoun2 + " against a " + nippleDescript(0) + ", and feeling your milk let down.  The desire to forcefeed SOMETHING makes your nipples hard and moist with milk.\n", false);
		temp2 = 5 + rand(player.lib/8+player.cor/8)
	}
	else {
		outputText("You fill your mind with perverted thoughts about " + monster.a + monster.short + ", picturing " + monster.pronoun2 + " in all kinds of perverse situations with you.\n", true);	
		temp2 = 10+rand(player.lib/5+player.cor/8);		
	}
	if(temp2 >= 20) outputText("The fantasy is so vivid and pleasurable you wish it was happening now.  You wonder if " + monster.a + monster.short + " can tell what you were thinking.\n\n", false);
	else outputText("\n", false);
	dynStats("lus", temp2, "resisted", false);
	if(player.lust >= player.maxLust()) {
		if(monster.short == "pod") {
			outputText("<b>You nearly orgasm, but the terror of the situation reasserts itself, muting your body's need for release.  If you don't escape soon, you have no doubt you'll be too fucked up to ever try again!</b>\n\n", false);
			player.lust = 99;
			dynStats("lus", -25);
		}
		else {
			doNext(endLustLoss);
			return;
		}
	}
	enemyAI();	
}
//Mouf Attack
// (Similar to the bow attack, high damage but it raises your fatigue).
public function bite():void {
	if(player.fatigue + physicalCost(25) > player.maxFatigue()) {
		outputText("You're too fatigued to use your shark-like jaws!", true);
		menu();
		addButton(0, "Next", combatMenu, false);
		return;
	}
	//Worms are special
	if(monster.short == "worms") {
		outputText("There is no way those are going anywhere near your mouth!\n\n", true);
		menu();
		addButton(0, "Next", combatMenu, false);
		return;
	}
	fatigue(25,2);
	//Amily!
	if(monster.findStatusAffect(StatusAffects.Concentration) >= 0) {
		outputText("Amily easily glides around your attack thanks to her complete concentration on your movements.\n\n", true);
		enemyAI();
		return;
	}
	outputText("You open your mouth wide, your shark teeth extending out. Snarling with hunger, you lunge at your opponent, set to bite right into them!  ", true);
	if(player.findStatusAffect(StatusAffects.Blind) >= 0) outputText("In hindsight, trying to bite someone while blind was probably a bad idea... ", false);
	var damage:Number = 0;
	//Determine if dodged!
	if((player.findStatusAffect(StatusAffects.Blind) >= 0 && rand(3) != 0) || (monster.spe - player.spe > 0 && int(Math.random()*(((monster.spe-player.spe)/4)+80)) > 80)) {
		if(monster.spe - player.spe < 8) outputText(monster.capitalA + monster.short + " narrowly avoids your attack!", false);
		if(monster.spe - player.spe >= 8 && monster.spe-player.spe < 20) outputText(monster.capitalA + monster.short + " dodges your attack with superior quickness!", false);
		if(monster.spe - player.spe >= 20) outputText(monster.capitalA + monster.short + " deftly avoids your slow attack.", false);
		outputText("\n\n", false);
		enemyAI();
		return;
	}
	//Determine damage - str modified by enemy toughness!
	damage = int((player.str + 45) * (monster.damagePercent() / 100));
	
	//Deal damage and update based on perks
	if(damage > 0) {
		if (player.findPerk(PerkLib.HistoryFighter) >= 0) damage *= 1.1;
		if (player.findPerk(PerkLib.JobWarrior) >= 0) damage *= 1.05;
		if (player.jewelryEffectId == JewelryLib.MODIFIER_ATTACK_POWER) damage *= 1 + (player.jewelryEffectMagnitude / 100);
		if (player.countCockSocks("red") > 0) damage *= (1 + player.countCockSocks("red") * 0.02);
		damage = doDamage(damage);
	}
	
	if(damage <= 0) {
		damage = 0;
		outputText("Your bite is deflected or blocked by " + monster.a + monster.short + ". ", false);
	}
	if(damage > 0 && damage < 10) {
		outputText("You bite doesn't do much damage to " + monster.a + monster.short + "! ", false);
	}
	if(damage >= 10 && damage < 20) {
		outputText("You seriously wound " + monster.a + monster.short + " with your bite! ", false);
	}
	if(damage >= 20 && damage < 30) {
		outputText("Your bite staggers " + monster.a + monster.short + " with its force. ", false);
	}
	if(damage >= 30) {
		outputText("Your powerful bite <b>mutilates</b> " + monster.a + monster.short + "! ", false);
	}
	if (damage > 0) outputText("<b>(<font color=\"#800000\">" + damage + "</font>)</b>", false)
	else outputText("<b>(<font color=\"#000080\">" + damage + "</font>)</b>", false)
	outputText("\n\n", false);
	checkAchievementDamage(damage);
	//Kick back to main if no damage occured!
	if(monster.HP > 0 && monster.lust < eMaxLust) {
		enemyAI();
	}
	else {
		if(monster.HP <= 0) doNext(endHpVictory);
		else doNext(endLustVictory);
	}
}

public function fatigueRecovery():void {
	fatigue(-1);
	if(player.findPerk(PerkLib.EnlightenedNinetails) >= 0 || player.findPerk(PerkLib.CorruptedNinetails) >= 0) fatigue(-(1+rand(3)));
}

//ATTACK
public function attack():void {
	if(player.findStatusAffect(StatusAffects.FirstAttack) < 0) {
		clearOutput();
		fatigueRecovery();
	}
	if(player.findStatusAffect(StatusAffects.Sealed) >= 0 && player.statusAffectv2(StatusAffects.Sealed) == 0 && !isWieldingRangedWeapon()) {
		outputText("You attempt to attack, but at the last moment your body wrenches away, preventing you from even coming close to landing a blow!  The kitsune's seals have made normal attack impossible!  Maybe you could try something else?\n\n", false);
		enemyAI();
		return;
	}
	if(flags[kFLAGS.PC_FETISH] >= 3 && !urtaQuest.isUrta() && !isWieldingRangedWeapon()) {
		outputText("You attempt to attack, but at the last moment your body wrenches away, preventing you from even coming close to landing a blow!  Ceraph's piercings have made normal attack impossible!  Maybe you could try something else?\n\n", false);
		enemyAI();
		return;
	}
	//Reload
	if (player.weaponName == "flintlock pistol") {
		if (flags[kFLAGS.FLINTLOCK_PISTOL_AMMO] <= 0) {
			flags[kFLAGS.FLINTLOCK_PISTOL_AMMO] = 4;
			outputText("You open the magazine of your pistol to reload the ammunition.  This takes up a turn.\n\n");
			enemyAI();
			return;
		}
		else flags[kFLAGS.FLINTLOCK_PISTOL_AMMO]--;
	}
	//Amily!
	if(monster.findStatusAffect(StatusAffects.Concentration) >= 0 && !isWieldingRangedWeapon()) {
		outputText("Amily easily glides around your attack thanks to her complete concentration on your movements.\n\n", true);
		enemyAI();
		return;
	}
	if(monster.findStatusAffect(StatusAffects.Level) >= 0 && player.findStatusAffect(StatusAffects.FirstAttack) < 0 && !isWieldingRangedWeapon()) {
		outputText("It's all or nothing!  With a bellowing cry you charge down the treacherous slope and smite the sandtrap as hard as you can!  ");
		(monster as SandTrap).trapLevel(-4);
	}
	if(player.findPerk(PerkLib.DoubleAttack) >= 0 && player.spe >= 50 && flags[kFLAGS.DOUBLE_ATTACK_STYLE] < 2) {
		if(player.findStatusAffect(StatusAffects.FirstAttack) >= 0) player.removeStatusAffect(StatusAffects.FirstAttack);
		else {
			//Always!
			if(flags[kFLAGS.DOUBLE_ATTACK_STYLE] == 0) player.createStatusAffect(StatusAffects.FirstAttack,0,0,0,0);
			//Alternate!
			else if(player.str < 61 && flags[kFLAGS.DOUBLE_ATTACK_STYLE] == 1) player.createStatusAffect(StatusAffects.FirstAttack,0,0,0,0);
		}
	}
	//"Brawler perk". Urta only. Thanks to Fenoxo for pointing this out... Even though that should have been obvious :<
	//Urta has fists and the Brawler perk. Don't check for that because Urta can't drop her fists or lose the perk!
	else if(urtaQuest.isUrta()) {
		if(player.findStatusAffect(StatusAffects.FirstAttack) >= 0) {
			player.removeStatusAffect(StatusAffects.FirstAttack);
		}
		else {
			player.createStatusAffect(StatusAffects.FirstAttack,0,0,0,0);
			outputText("Utilizing your skills as a bareknuckle brawler, you make two attacks!\n");
		}
	}
	//Blind
	if(player.findStatusAffect(StatusAffects.Blind) >= 0) {
		outputText("You attempt to attack, but as blinded as you are right now, you doubt you'll have much luck!  ", false);
	}
	if (monster is Basilisk && player.findPerk(PerkLib.BasiliskResistance) < 0 && !isWieldingRangedWeapon()) {
		if (monster.findStatusAffect(StatusAffects.Blind) >= 0)
			outputText("Blind basilisk can't use his eyes, so you can actually aim your strikes!  ", false);
		//basilisk counter attack (block attack, significant speed loss): 
		else if(player.inte/5 + rand(20) < 25) {
			outputText("Holding the basilisk in your peripheral vision, you charge forward to strike it.  Before the moment of impact, the reptile shifts its posture, dodging and flowing backward skillfully with your movements, trying to make eye contact with you. You find yourself staring directly into the basilisk's face!  Quickly you snap your eyes shut and recoil backwards, swinging madly at the lizard to force it back, but the damage has been done; you can see the terrible grey eyes behind your closed lids, and you feel a great weight settle on your bones as it becomes harder to move.", false);
			Basilisk.basiliskSpeed(player,20);
			player.removeStatusAffect(StatusAffects.FirstAttack);
			combatRoundOver();
			flags[kFLAGS.BASILISK_RESISTANCE_TRACKER] += 2;
			return;
		}
		//Counter attack fails: (random chance if PC int > 50 spd > 60; PC takes small physical damage but no block or spd penalty)
		else {
			outputText("Holding the basilisk in your peripheral vision, you charge forward to strike it.  Before the moment of impact, the reptile shifts its posture, dodging and flowing backward skillfully with your movements, trying to make eye contact with you. You twist unexpectedly, bringing your " + player.weaponName + " up at an oblique angle; the basilisk doesn't anticipate this attack!  ", false);
		}
	}
	if (monster is FrostGiant && player.findStatusAffect(StatusAffects.GiantBoulder) >= 0) {
		(monster as FrostGiant).giantBoulderHit(0);
		enemyAI();
		return;
	}
	//Worms are special
	if(monster.short == "worms") {
		//50% chance of hit (int boost)
		if(rand(100) + player.inte/3 >= 50) {
			temp = int(player.str/5 - rand(5));
			if(temp == 0) temp = 1;
			outputText("You strike at the amalgamation, crushing countless worms into goo, dealing <b><font color=\"#800000\">" + temp + "</font></b> damage.\n\n", false);
			monster.HP -= temp;
			if(monster.HP <= 0) {
				doNext(endHpVictory);
				return;
			}
		}
		//Fail
		else {
			outputText("You attempt to crush the worms with your reprisal, only to have the collective move its individual members, creating a void at the point of impact, leaving you to attack only empty air.\n\n", false);
		}
		if(player.findStatusAffect(StatusAffects.FirstAttack) >= 0) {
			attack();
			return;
		}
		enemyAI();
		return;
	}
	
	var damage:Number = 0;
	//Determine if dodged!
	if ((player.findStatusAffect(StatusAffects.Blind) >= 0 && rand(2) == 0) || (monster.spe - player.spe > 0 && int(Math.random() * (((monster.spe-player.spe) / 4) + 80)) > 80)) {
		//Akbal dodges special education
		if(monster.short == "Akbal") outputText("Akbal moves like lightning, weaving in and out of your furious strikes with the speed and grace befitting his jaguar body.\n", false);
		else if(monster.short == "plain girl") outputText("You wait patiently for your opponent to drop her guard. She ducks in and throws a right cross, which you roll away from before smacking your " + player.weaponName + " against her side. Astonishingly, the attack appears to phase right through her, not affecting her in the slightest. You glance down to your " + player.weaponName + " as if betrayed.\n", false);
		else if(monster.short == "kitsune") {
			//Player Miss:
			outputText("You swing your [weapon] ferociously, confident that you can strike a crushing blow.  To your surprise, you stumble awkwardly as the attack passes straight through her - a mirage!  You curse as you hear a giggle behind you, turning to face her once again.\n\n");
		}
		else {
			if (player.weapon == weapons.HNTCANE && rand(2) == 0) {
				if (rand(2) == 0) outputText("You slice through the air with your cane, completely missing your enemy.");
				else outputText("You lunge at your enemy with the cane.  It glows with a golden light but fails to actually hit anything.");
			}
			if(monster.spe - player.spe < 8) outputText(monster.capitalA + monster.short + " narrowly avoids your attack!", false);
			if(monster.spe - player.spe >= 8 && monster.spe-player.spe < 20) outputText(monster.capitalA + monster.short + " dodges your attack with superior quickness!", false);
			if(monster.spe - player.spe >= 20) outputText(monster.capitalA + monster.short + " deftly avoids your slow attack.", false);
			outputText("\n", false);
			if(player.findStatusAffect(StatusAffects.FirstAttack) >= 0) {
				attack();
				return;
			}
			else outputText("\n", false);
		}
		enemyAI();
		return;
	}
	//BLOCKED ATTACK:
	if(monster.findStatusAffect(StatusAffects.Earthshield) >= 0 && rand(4) == 0) {
		outputText("Your strike is deflected by the wall of sand, dirt, and rock!  Damn!\n");
		if(player.findStatusAffect(StatusAffects.FirstAttack) >= 0) {
			attack();
			return;
		}
		else outputText("\n", false);
		enemyAI();
		return;
	}
	//------------
	// DAMAGE
	//------------
	//Determine damage
	//BASIC DAMAGE STUFF
	
	//Double Attack Hybrid Reductions
	var getBase:Function = function(init:Number):Number {
		if(player.findPerk(PerkLib.DoubleAttack) >= 0 && player.spe >= 50 && init > 61 + (player.newGamePlusMod() * 15) && flags[kFLAGS.DOUBLE_ATTACK_STYLE] == 0) {
			return 60.5 + (player.newGamePlusMod() * 15);
		} else return init;
	};
	
	// init value depending on weapon type
	if (isWieldingRangedWeapon()) {
		if (player.weaponName.indexOf("staff") != -1) damage = getBase.call(null, player.inte) + player.spe * 0.1;
		else damage = getBase.call(null, player.str) + player.spe * 0.2; // woudn't be better to use speed as base and int as extra?
	}
	else
		damage = getBase.call(null, player.str);
		
	if (player.findPerk(PerkLib.HoldWithBothHands) >= 0 && player.weapon != WeaponLib.FISTS && player.shield == ShieldLib.NOTHING && !isWieldingRangedWeapon()) damage += (player.str * 0.2);
	//Weapon addition!
	damage += player.weaponAttack;
	if (damage < 10) damage = 10;
	//Bonus sand trap damage!
	if(monster.findStatusAffect(StatusAffects.Level) >= 0) damage = Math.round(damage * 1.75);
	//Determine if critical hit!
	var crit:Boolean = false;
	var critChance:int = 5;
	if (player.findPerk(PerkLib.Tactician) >= 0 && player.inte >= 50) critChance += (player.inte - 50) / 5;
	if (rand(100) < critChance) {
		crit = true;
		damage *= 1.75;
	}
	//Apply AND DONE!
	damage *= (monster.damagePercent(false, true) / 100);
	//Damage post processing!
	//Thunderous Strikes
	if(player.findPerk(PerkLib.ThunderousStrikes) >= 0 && player.str >= 80)
		damage *= 1.2;
		
	if (player.findPerk(PerkLib.ChiReflowMagic) >= 0) damage *= UmasShop.NEEDLEWORK_MAGIC_REGULAR_MULTI;
	if (player.findPerk(PerkLib.ChiReflowAttack) >= 0) damage *= UmasShop.NEEDLEWORK_ATTACK_REGULAR_MULTI;
	if (player.jewelryEffectId == JewelryLib.MODIFIER_ATTACK_POWER) damage *= 1 + (player.jewelryEffectMagnitude / 100);
	if (player.countCockSocks("red") > 0) damage *= (1 + player.countCockSocks("red") * 0.02);
	//One final round
	damage = Math.round(damage);
	
	//ANEMONE SHIT
	if(monster.short == "anemone" && !isWieldingRangedWeapon()) {
		//hit successful:
		//special event, block (no more than 10-20% of turns, also fails if PC has >75 corruption):
		if(rand(10) <= 1) {
			outputText("Seeing your " + player.weaponName + " raised, the anemone looks down at the water, angles her eyes up at you, and puts out a trembling lip.  ", false);
			if(player.cor < 75) {
				outputText("You stare into her hangdog expression and lose most of the killing intensity you had summoned up for your attack, stopping a few feet short of hitting her.\n", false);
				damage = 0;
				//Kick back to main if no damage occured!
				if(monster.HP > 0 && monster.lust < eMaxLust) {
					if(player.findStatusAffect(StatusAffects.FirstAttack) >= 0) {
						attack();
						return;
					}
					enemyAI();
				}
				else {
					if(monster.HP <= 0) doNext(endHpVictory);
					else doNext(endLustVictory);
				}
				return;
			}
			else outputText("Though you lose a bit of steam to the display, the drive for dominance still motivates you to follow through on your swing.", false);
		}
	}

	// Have to put it before doDamage, because doDamage applies the change, as well as status effects and shit.
	if (monster is Doppleganger)
	{
		if (monster.findStatusAffect(StatusAffects.Stunned) < 0)
		{
			if (damage > 0 && player.findPerk(PerkLib.HistoryFighter) >= 0) damage *= 1.1;
			if (player.countCockSocks("red") > 0) damage *= (1 + player.countCockSocks("red") * 0.02);
			if (damage > 0) damage = doDamage(damage, false);
		
			(monster as Doppleganger).mirrorAttack(damage);
			return;
		}
		
		// Stunning the doppleganger should now "buy" you another round.
	}
	if (player.weapon == weapons.HNTCANE) {
		switch(rand(2)) {
			case 0:
				outputText("You swing your cane through the air. The light wood lands with a loud CRACK that is probably more noisy than painful. ");
				damage *= 0.5;
				break;
			case 1:
				outputText("You brandish your cane like a sword, slicing it through the air. It thumps against your adversary, but doesn’t really seem to harm them much. ");
				damage *= 0.5;
				break;
			default:
		}
	}
	if(damage > 0) {
		if (player.findPerk(PerkLib.HistoryFighter) >= 0) damage *= 1.1;
		if (player.findPerk(PerkLib.JobWarrior) >= 0) damage *= 1.05;
		damage = doDamage(damage);
	}
	if(damage <= 0) {
		damage = 0;
		outputText("Your attacks are deflected or blocked by " + monster.a + monster.short + ".", false);
	}
	else {
		outputText("You hit " + monster.a + monster.short + "! ", false);
		if(crit) outputText("<b>Critical hit! </b>");
		outputText("<b>(<font color=\"#800000\">" + damage + "</font>)</b>", false)
	}
	if(player.findPerk(PerkLib.BrutalBlows) >= 0 && player.str > 75) {
		if(monster.armorDef > 0) outputText("\nYour hits are so brutal that you damage " + monster.a + monster.short + "'s defenses!");
		if(monster.armorDef - 10 > 0) monster.armorDef -= 10;
		else monster.armorDef = 0;
	}
	//Damage cane.
	if (player.weapon == weapons.HNTCANE) {
		flags[kFLAGS.ERLKING_CANE_ATTACK_COUNTER]++;
		//Break cane
		if (flags[kFLAGS.ERLKING_CANE_ATTACK_COUNTER] >= 10 && rand(20) == 0) {
			outputText("\n<b>The cane you're wielding finally snaps! It looks like you won't be able to use it anymore.</b>");
			player.setWeapon(WeaponLib.FISTS);
		}
	}
	if(damage > 0) {
		//Lust raised by anemone contact!
		if(monster.short == "anemone" && !isWieldingRangedWeapon()) {
			outputText("\nThough you managed to hit the anemone, several of the tentacles surrounding her body sent home jolts of venom when your swing brushed past them.", false);
			//(gain lust, temp lose str/spd)
			(monster as Anemone).applyVenom((1+rand(2)));
		}
		
		//Lust raising weapon bonuses
		if(monster.lustVuln > 0) {
			if(player.weaponPerk == "Aphrodisiac Weapon") {
				outputText("\n" + monster.capitalA + monster.short + " shivers as your weapon's 'poison' goes to work.", false);
				monster.teased(monster.lustVuln * (5 + player.cor / 10));
			}
			if(player.weaponName == "coiled whip" && rand(2) == 0) {		
				if(!monster.plural) outputText("\n" + monster.capitalA + monster.short + " shivers and gets turned on from the whipping.", false);
				else outputText("\n" + monster.capitalA + monster.short + " shiver and get turned on from the whipping.", false);
				monster.teased(monster.lustVuln * (5 + player.cor / 12));
			}
			if(player.weaponName == "succubi whip") {
				if(player.cor < 90) dynStats("cor", .3);
				if(!monster.plural) outputText("\n" + monster.capitalA + monster.short + " shivers and moans involuntarily from the whip's touches.", false);
				else outputText("\n" + monster.capitalA + monster.short + " shiver and moan involuntarily from the whip's touches.", false);
				monster.teased(monster.lustVuln * (20 + player.cor / 15));
				if(rand(2) == 0) {
					outputText(" You get a sexual thrill from it. ", false);
					dynStats("lus", 1);
				}
				
			}
		}
		//Weapon Procs!
		if(player.weaponName == "huge warhammer" || player.weaponName == "spiked gauntlet" || player.weaponName == "hooked gauntlets") {
			//10% chance
			if(rand(10) == 0 && monster.findPerk(PerkLib.Resolute) < 0) {
				outputText("\n" + monster.capitalA + monster.short + " reels from the brutal blow, stunned.", false);
				if (monster.findStatusAffect(StatusAffects.Stunned) < 0) monster.createStatusAffect(StatusAffects.Stunned,rand(2),0,0,0);
			}
			//50% Bleed chance
			if (player.weaponName == "hooked gauntlets" && rand(2) == 0 && monster.armorDef < 10 && monster.findStatusAffect(StatusAffects.IzmaBleed) < 0) 
			{
				if (monster is LivingStatue)
				{
					outputText("Despite the rents you've torn in its stony exterior, the statue does not bleed.");
				}
				else
				{
					monster.createStatusAffect(StatusAffects.IzmaBleed,3,0,0,0);
					if(monster.plural) outputText("\n" + monster.capitalA + monster.short + " bleed profusely from the many bloody gashes your hooked gauntlets leave behind.", false);
					else outputText("\n" + monster.capitalA + monster.short + " bleeds profusely from the many bloody gashes your hooked gauntlets leave behind.", false);
				}
			}
		}
		
	}
	
	if (monster is JeanClaude && player.findStatusAffect(StatusAffects.FirstAttack) < 0)
	{
		if (monster.HP < 1 || monster.lust > (eMaxLust - 1))
		{
			// noop
		}
		if (player.lust <= 30)
		{
			outputText("\n\nJean-Claude doesn’t even budge when you wade into him with your [weapon].");

			outputText("\n\n“<i>Why are you attacking me, slave?</i>” he says. The basilisk rex sounds genuinely confused. His eyes pulse with hot, yellow light, reaching into you as he opens his arms, staring around as if begging the crowd for an explanation. “<i>You seem lost, unable to understand, lashing out at those who take care of you. Don’t you know who you are? Where you are?</i>” That compulsion in his eyes, that never-ending heat, it’s... it’s changing things. You need to finish this as fast as you can.");
		}
		else if (player.lust <= 50)
		{
			outputText("\n\nAgain your [weapon] thumps into Jean-Claude. Again it feels wrong. Again it sends an aching chime through you, that you are doing something that revolts your nature.");

			outputText("\n\n“<i>Why are you fighting your master, slave?</i>” he says. He is bigger than he was before. Or maybe you are smaller. “<i>You are confused. Put your weapon down- you are no warrior, you only hurt yourself when you flail around with it. You have forgotten what you were trained to be. Put it down, and let me help you.</i>” He’s right. It does hurt. Your body murmurs that it would feel so much better to open up and bask in the golden eyes fully, let it move you and penetrate you as it may. You grit your teeth and grip your [weapon] harder, but you can’t stop the warmth the hypnotic compulsion is building within you.");
		}
		else if (player.lust <= 80)
		{
			outputText("\n\n“<i>Do you think I will be angry at you?</i>” growls Jean-Claude lowly. Your senses feel intensified, his wild, musky scent rich in your nose. It’s hard to concentrate... or rather it’s hard not to concentrate on the sweat which runs down his hard, defined frame, the thickness of his bulging cocks, the assured movement of his powerful legs and tail, and the glow, that tantalizing, golden glow, which pulls you in and pushes so much delicious thought and sensation into your head…  “<i>I am not angry. You will have to be punished, yes, but you know that is only right, that in the end you will accept and enjoy being corrected. Come now, slave. You only increase the size of the punishment with this silliness.</i>”");
		}
		else
		{
			outputText("\n\nYou can’t... there is a reason why you keep raising your weapon against your master, but what was it? It can’t be that you think you can defeat such a powerful, godly alpha male as him. And it would feel so much better to supplicate yourself before the glow, lose yourself in it forever, serve it with your horny slut body, the only thing someone as low and helpless as you could possibly offer him. Master’s mouth is moving but you can no longer tell where his voice ends and the one in your head begins... only there is a reason you cling to like you cling onto your [weapon], whatever it is, however stupid and distant it now seems, a reason to keep fighting...");
		}
		
		dynStats("lus", 25);
	}
	
	outputText("\n", false);
	checkAchievementDamage(damage);
	//Kick back to main if no damage occured!
	if(monster.HP >= 1 && monster.lust <= (eMaxLust - 1)) {
		if(player.findStatusAffect(StatusAffects.FirstAttack) >= 0) {
			attack();
			return;
		}
		outputText("\n", false);
		enemyAI();
	}
	else {
		if(monster.HP <= 0) doNext(endHpVictory);
		else doNext(endLustVictory);
	}
}
//Gore Attack - uses 15 fatigue!
public function goreAttack():void {
	clearOutput();
//This is now automatic - newRound arg defaults to true:	menuLoc = 0;
	if (monster.short == "worms") {
		outputText("Taking advantage of your new natural weapons, you quickly charge at the freak of nature. Sensing impending danger, the creature willingly drops its cohesion, causing the mass of worms to fall to the ground with a sick, wet 'thud', leaving your horns to stab only at air.\n\n");
		enemyAI();
		return;
	}
	if(player.fatigue + physicalCost(15) > player.maxFatigue()) {
		outputText("You're too fatigued to use a charge attack!");
		menu();
		addButton(0, "Next", combatMenu, false);
		return;
	}
	fatigue(15,2);
	var damage:Number = 0;
	//Amily!
	if(monster.findStatusAffect(StatusAffects.Concentration) >= 0) {
		outputText("Amily easily glides around your attack thanks to her complete concentration on your movements.\n\n");
		enemyAI();
		return;
	}
	//Bigger horns = better success chance.
	//Small horns - 60% hit
	if(player.horns >= 6 && player.horns < 12) {
		temp = 60;
	}
	//bigger horns - 75% hit
	if(player.horns >= 12 && player.horns < 20) {
		temp = 75;
	}
	//huge horns - 90% hit
	if(player.horns >= 20) {
		temp = 80;
	}
	//Vala dodgy bitch!
	if(monster.short == "Vala") {
		temp = 20;
	}
	//Account for monster speed - up to -50%.
	temp -= monster.spe/2;
	//Account for player speed - up to +50%
	temp += player.spe/2;
	//Hit & calculation
	if(temp >= rand(100)) {
		var horns:Number = player.horns;
		if (player.horns > 40) player.horns = 40;
		damage = int(player.str + horns * 2 * (monster.damagePercent() / 100)); //As normal attack + horn length bonus
		//normal
		if(rand(4) > 0) {
			outputText("You lower your head and charge, skewering " + monster.a + monster.short + " on one of your bullhorns!  ");
		}
		//CRIT
		else {
			//doubles horn bonus damage
			damage *= 2;
			outputText("You lower your head and charge, slamming into " + monster.a + monster.short + " and burying both your horns into " + monster.pronoun2 + "! <b>Critical hit!</b>  ");
		}
		//Bonus damage for rut!
		if(player.inRut && monster.cockTotal() > 0) {
			outputText("The fury of your rut lent you strength, increasing the damage!  ");
			damage += 5;
		}
		//Bonus per level damage
		damage += player.level * 2;
		//Reduced by armor
		damage *= monster.damagePercent() / 100;
		if(damage < 0) damage = 5;
		//CAP 'DAT SHIT
		if(damage > player.level * 10 + 100) damage = player.level * 10 + 100;
		if(damage > 0) {
			if (player.findPerk(PerkLib.HistoryFighter) >= 0) damage *= 1.1;
			if (player.findPerk(PerkLib.JobWarrior) >= 0) damage *= 1.05;
			if (player.jewelryEffectId == JewelryLib.MODIFIER_ATTACK_POWER) damage *= 1 + (player.jewelryEffectMagnitude / 100);
			if (player.countCockSocks("red") > 0) damage *= (1 + player.countCockSocks("red") * 0.02);
			damage = doDamage(damage);
		}
		//Different horn damage messages
		if(damage < 20) outputText("You pull yourself free, dealing <b><font color=\"#080000\">" + damage + "</font></b> damage.");
		if(damage >= 20 && damage < 40) outputText("You struggle to pull your horns free, dealing <b><font color=\"#080000\">" + damage + "</font></b> damage.");
		if(damage >= 40) outputText("With great difficulty you rip your horns free, dealing <b><font color=\"#080000\">" + damage + "</font></b> damage.");
	}
	//Miss
	else {
		//Special vala changes
		if(monster.short == "Vala") {
			outputText("You lower your head and charge Vala, but she just flutters up higher, grabs hold of your horns as you close the distance, and smears her juicy, fragrant cunt against your nose.  The sensual smell and her excited moans stun you for a second, allowing her to continue to use you as a masturbation aid, but she quickly tires of such foreplay and flutters back with a wink.\n\n");
			dynStats("lus", 5);
		}
		else outputText("You lower your head and charge " + monster.a + monster.short + ", only to be sidestepped at the last moment!");
	}
	//New line before monster attack
	outputText("\n\n");
	checkAchievementDamage(damage);
	//Victory ORRRRR enemy turn.
	if(monster.HP > 0 && monster.lust < eMaxLust) enemyAI();
	else {
		if(monster.HP <= 0) doNext(endHpVictory);
		if(monster.lust >= eMaxLust) doNext(endLustVictory);
	}
}
//Upheaval Attack
public function upheavalAttack():void {
	clearOutput();
//This is now automatic - newRound arg defaults to true:	menuLoc = 0;
	if (monster.short == "worms") {
		outputText("Taking advantage of your new natural weapon, you quickly charge at the freak of nature. Sensing impending danger, the creature willingly drops its cohesion, causing the mass of worms to fall to the ground with a sick, wet 'thud', leaving your horns to stab only at air.\n\n");
		enemyAI();
		return;
	}
	if(player.fatigue + physicalCost(15) > player.maxFatigue()) {
		outputText("You're too fatigued to use a charge attack!");
		doNext(combatMenu);
		return;
	}
	fatigue(15,2);
	var damage:Number = 0;
	//Amily!
	if(monster.findStatusAffect(StatusAffects.Concentration) >= 0) {
		outputText("Amily easily glides around your attack thanks to her complete concentration on your movements.\n\n");
		enemyAI();
		return;
	}
	//Bigger horns = better success chance.
	//Small horns - 60% hit
	if(player.horns >= 6 && player.horns < 12) {
		temp = 60;
	}
	//bigger horns - 75% hit
	if(player.horns >= 12 && player.horns < 20) {
		temp = 75;
	}
	//huge horns - 90% hit
	if(player.horns >= 20) {
		temp = 80;
	}
	//Vala dodgy bitch!
	if(monster.short == "Vala") {
		temp = 20;
	}
	//Account for monster speed - up to -50%.
	temp -= monster.spe/2;
	//Account for player speed - up to +50%
	temp += player.spe/2;
	//Hit & calculation
	if(temp >= rand(100)) {
		var horns:Number = player.horns;
		if (player.horns > 40) player.horns = 40;
		damage = int(player.str + (player.tou / 2) + (player.spe / 2) + (player.level * 2) * 1.2 * (monster.damagePercent() / 100)); //As normal attack + horn length bonus
		if(damage < 0) damage = 5;
		//Normal
		outputText("You hurl yourself towards [enemy] with your head low and jerk your head upward, every muscle flexing as you send [enemy] flying. ");
		//Critical
		if (combatCritical()) {
			outputText("<b>Critical hit! </b>");
			damage *= 1.75;
		}
		//CAP 'DAT SHIT
		if(damage > player.level * 10 + 100) damage = player.level * 10 + 100;
		if(damage > 0) {
			if (player.findPerk(PerkLib.HistoryFighter) >= 0) damage *= 1.1;
			if (player.findPerk(PerkLib.JobWarrior) >= 0) damage *= 1.05;
			if (player.jewelryEffectId == JewelryLib.MODIFIER_ATTACK_POWER) damage *= 1 + (player.jewelryEffectMagnitude / 100);
			if (player.countCockSocks("red") > 0) damage *= (1 + player.countCockSocks("red") * 0.02);
			//Round it off
			damage = int(damage);
			damage = doDamage(damage, true);
		}
		outputText("\n\n");
	}
	//Miss
	else {
		//Special vala changes
		if(monster.short == "Vala") {
			outputText("You lower your head and charge Vala, but she just flutters up higher, grabs hold of your horns as you close the distance, and smears her juicy, fragrant cunt against your nose.  The sensual smell and her excited moans stun you for a second, allowing her to continue to use you as a masturbation aid, but she quickly tires of such foreplay and flutters back with a wink.\n\n");
			dynStats("lus", 5);
		}
		else outputText("You hurl yourself towards [enemy] with your head low and snatch it upwards, hitting nothing but air.");
	}
	//New line before monster attack
	outputText("\n\n");
	checkAchievementDamage(damage);
	//Victory ORRRRR enemy turn.
	if(monster.HP > 0 && monster.lust < eMaxLust) enemyAI();
	else {
		if(monster.HP <= 0) doNext(endHpVictory);
		if(monster.lust >= eMaxLust) doNext(endLustVictory);
	}
}
//Player sting attack
public function playerStinger():void {
	clearOutput();
	//Keep logic sane if this attack brings victory
//This is now automatic - newRound arg defaults to true:	menuLoc = 0;
	if (player.tailVenom < 33) {
		outputText("You do not have enough venom to sting right now!");
		doNext(physicalSpecials);
		return;
	}
	//Worms are immune!
	if (monster.short == "worms") {
		outputText("Taking advantage of your new natural weapons, you quickly thrust your stinger at the freak of nature. Sensing impending danger, the creature willingly drops its cohesion, causing the mass of worms to fall to the ground with a sick, wet 'thud', leaving you to stab only at air.\n\n");
		enemyAI();
		return;
	}
	//Determine if dodged!
	//Amily!
	if(monster.findStatusAffect(StatusAffects.Concentration) >= 0) {
		outputText("Amily easily glides around your attack thanks to her complete concentration on your movements.\n\n");
		enemyAI();
		return;
	}
	if(monster.spe - player.spe > 0 && int(Math.random()*(((monster.spe-player.spe)/4)+80)) > 80) {
		if(monster.spe - player.spe < 8) outputText(monster.capitalA + monster.short + " narrowly avoids your stinger!\n\n");
		if(monster.spe - player.spe >= 8 && monster.spe-player.spe < 20) outputText(monster.capitalA + monster.short + " dodges your stinger with superior quickness!\n\n");
		if(monster.spe - player.spe >= 20) outputText(monster.capitalA + monster.short + " deftly avoids your slow attempts to sting " + monster.pronoun2 + ".\n\n");
		enemyAI();
		return;
	}
	//determine if avoided with armor.
	if(monster.armorDef - player.level >= 10 && rand(4) > 0) {
		outputText("Despite your best efforts, your sting attack can't penetrate " +  monster.a + monster.short + "'s defenses.\n\n");
		enemyAI();
		return;
	}
	//Sting successful!
	outputText("Searing pain lances through " + monster.a + monster.short + " as you manage to sting " + monster.pronoun2 + "!  ");
	if(monster.plural) outputText("You watch as " + monster.pronoun1 + " stagger back a step and nearly trip, flushing hotly.");
	else outputText("You watch as " + monster.pronoun1 + " staggers back a step and nearly trips, flushing hotly.");
	//Tabulate damage!
	var damage:Number = 35 + rand(player.lib/10);
	//Level adds more damage up to a point (level 30)
	if (player.level < 10) damage += player.level * 3;
	else if (player.level < 20) damage += 30 + (player.level - 10) * 2;
	else if (player.level < 30) damage += 50 + (player.level - 20) * 1;
	else damage += 60;
	monster.teased(monster.lustVuln * damage);
	if(monster.findStatusAffect(StatusAffects.lustvenom) < 0) monster.createStatusAffect(StatusAffects.lustvenom, 0, 0, 0, 0);
	/* IT used to paralyze 50% of the time, this is no longer the case!
	Paralise the other 50%!
	else {
		outputText("Searing pain lances through " + monster.a + monster.short + " as you manage to sting " + monster.pronoun2 + "!  ", false);
		if(monster.short == "demons") outputText("You watch as " + monster.pronoun1 + " stagger back a step and nearly trip, finding it hard to move as " + monster.pronoun1 + " are afflicted with your paralytic venom.  ", false);
		else outputText("You watch as " + monster.pronoun1 + " staggers back a step and nearly trips, finding it hard to move as " + monster.pronoun1 + " is afflicted with your paralytic venom.  ", false);
		if(monster.short == "demons") outputText("It appears that " + monster.a + monster.short + " are weaker and slower.", false);
		else outputText("It appears that " + monster.a + monster.short + " is weaker and slower.", false);
		monster.str -= (5+rand(player.lib/5))
		monster.spe -= (5+rand(player.lib/5))
		if(monster.str < 1) monster.str = 1;
		if(monster.spe < 1) monster.spe = 1;
	}*/
	//New line before monster attack
	outputText("\n\n");
	//Use tail mp
	player.tailVenom -= 25;
	//Kick back to main if no damage occured!
	if(monster.HP > 0 && monster.lust < eMaxLust) enemyAI();
	else doNext(endLustVictory);
}

public function combatMiss():Boolean {
	return player.spe - monster.spe > 0 && int(Math.random() * (((player.spe - monster.spe) / 4) + 80)) > 80;
}
public function combatParry():Boolean {
	return player.findPerk(PerkLib.Parry) >= 0 && player.spe >= 50 && player.str >= 50 && rand(100) < ((player.spe - 50) / 5) && player.weapon != WeaponLib.FISTS;
	trace("Parried!");
}
public function combatCritical():Boolean {
	var critChance:int = 4;
	if (player.findPerk(PerkLib.Tactician) >= 0 && player.inte >= 50) critChance += (player.inte - 50) / 50;
	if (player.findPerk(PerkLib.Blademaster) >= 0 && (player.weaponVerb == "slash" || player.weaponVerb == "cleave" || player.weaponVerb == "keen cut")) critChance += 5;
	return rand(100) <= critChance;
}

public function combatBlock(doFatigue:Boolean = false):Boolean {
	//Set chance
	var blockChance:int = 20 + player.shieldBlock + Math.floor((player.str - monster.str) / 5);
	if (player.findPerk(PerkLib.ShieldMastery) >= 0 && player.tou >= 50) blockChance += (player.tou - 50) / 5;
	if (blockChance < 10) blockChance = 10;
	//Fatigue limit
	var fatigueLimit:int = player.maxFatigue() - physicalCost(10);;
	if (blockChance >= (rand(100) + 1) && player.fatigue <= fatigueLimit && player.shieldName != "nothing") {
		if (doFatigue) fatigue(10, 2);
		return true;
	}
	else return false;
}
public function isWieldingRangedWeapon():Boolean {
	if (player.weaponName == "flintlock pistol" || player.weaponName == "crossbow" || player.weaponName == "blunderbuss rifle" || player.weaponName.indexOf("staff") != -1 && player.findPerk(PerkLib.StaffChanneling) >= 0) return true;
	else return false;
}

//DEAL DAMAGE
public function doDamage(damage:Number, apply:Boolean = true, display:Boolean = false):Number {
	if(player.findPerk(PerkLib.Sadist) >= 0) {
		damage *= 1.2;
		dynStats("lus", 3);
	}
	if (monster.HP - damage <= 0) {
		/* No monsters use this perk, so it's been removed for now
		if(monster.findPerk(PerkLib.LastStrike) >= 0) doNext(monster.perk(monster.findPerk(PerkLib.LastStrike)).value1);
		else doNext(endHpVictory);
		*/
		doNext(endHpVictory);
	}
	
	// Uma's Massage Bonuses
	var statIndex:int = player.findStatusAffect(StatusAffects.UmasMassage);
	if (statIndex >= 0)
	{
		if (player.statusAffect(statIndex).value1 == UmasShop.MASSAGE_POWER)
		{
			damage *= player.statusAffect(statIndex).value2;
		}
	}
	
	damage = Math.round(damage);
	
	if(damage < 0) damage = 1;
	if (apply) monster.HP -= damage;
	if (display) {
		if (damage > 0) outputText("<b>(<font color=\"#800000\">" + temp + "</font>)</b>"); //Damage
		else if (damage == 0) outputText("<b>(<font color=\"#000080\">" + temp + "</font>)</b>"); //Miss/block
		else if (damage < 0) outputText("<b>(<font color=\"#008000\">" + temp + "</font>)</b>"); //Heal
	}
	//Isabella gets mad
	if(monster.short == "Isabella") {
		flags[kFLAGS.ISABELLA_AFFECTION]--;
		//Keep in bounds
		if(flags[kFLAGS.ISABELLA_AFFECTION] < 0) flags[kFLAGS.ISABELLA_AFFECTION] = 0;
	}
	//Interrupt gigaflare if necessary.
	if (monster.findStatusAffect(StatusAffects.Gigafire) >= 0) monster.addStatusValue(StatusAffects.Gigafire, 1, damage);
	//Keep shit in bounds.
	if(monster.HP < 0) monster.HP = 0;
	return damage;
}

public function takeDamage(damage:Number, display:Boolean = false):Number {
	return player.takeDamage(damage, display);
}
//ENEMYAI!
public function enemyAI():void {
	monster.doAI();
}
public function finishCombat():void
{
	var hpVictory:Boolean = monster.HP < 1;
	if (hpVictory) {
		outputText("You defeat " + monster.a + monster.short + ".\n", true);
	} else {
		outputText("You smile as " + monster.a + monster.short + " collapses and begins masturbating feverishly.", true);
	}
	cleanupAfterCombat();
}
public function dropItem(monster:Monster, nextFunc:Function = null):void {
	if (nextFunc == null) nextFunc = camp.returnToCampUseOneHour;
	if(monster.findStatusAffect(StatusAffects.NoLoot) >= 0) {
		return;
	}
	var itype:ItemType = monster.dropLoot();
	if(monster.short == "tit-fucked Minotaur") {
		itype = consumables.MINOCUM;
	}
	if(monster is Minotaur) {
		if(monster.weaponName == "axe") {
			if(rand(2) == 0) {
				//50% breakage!
				if(rand(2) == 0) {
					itype = weapons.L__AXE;
					if(player.tallness < 78 && player.str < 90) {
						outputText("\nYou find a large axe on the minotaur, but it is too big for a person of your stature to comfortably carry.  ", false);
						if(rand(2) == 0) itype = null;
						else itype = consumables.SDELITE;
					}
					//Not too tall, dont rob of axe!
					else plotFight = true;
				}
				else outputText("\nThe minotaur's axe appears to have been broken during the fight, rendering it useless.  ", false);
			}
			else itype = consumables.MINOBLO;
		}
	}
	if(monster is BeeGirl) {
		//force honey drop if milked
		if(flags[kFLAGS.FORCE_BEE_TO_PRODUCE_HONEY] == 1) {
			if(rand(2) == 0) itype = consumables.BEEHONY;
			else itype = consumables.PURHONY;
			flags[kFLAGS.FORCE_BEE_TO_PRODUCE_HONEY] = 0;
		}
	}
	if(monster is Jojo && monk > 4) {
		if(rand(2) == 0) itype = consumables.INCUBID;
		else {
			if(rand(2) == 0) itype = consumables.B__BOOK;
			else itype = consumables.SUCMILK;
		}
	}
	if(monster is Harpy || monster is Sophie) {
		if(rand(10) == 0) itype = armors.W_ROBES;
		else if(rand(3) == 0 && player.findPerk(PerkLib.LuststickAdapted) >= 0) itype = consumables.LUSTSTK;
		else itype = consumables.GLDSEED;
	}
	//Chance of armor if at level 1 pierce fetish
	if(!plotFight && !(monster is Ember) && !(monster is Kiha) && !(monster is Hel) && !(monster is Isabella)
			&& flags[kFLAGS.PC_FETISH] == 1 && rand(10) == 0 && !player.hasItem(armors.SEDUCTA, 1) && !ceraphFollowerScene.ceraphIsFollower()) {
		itype = armors.SEDUCTA;
	}

	if(!plotFight && rand(200) == 0 && player.level >= 7) itype = consumables.BROBREW;
	if(!plotFight && rand(200) == 0 && player.level >= 7) itype = consumables.BIMBOLQ;
	if(!plotFight && rand(1000) == 0 && player.level >= 7) itype = consumables.RAINDYE;
	//Chance of eggs if Easter!
	if(!plotFight && rand(6) == 0 && isEaster()) {
		temp = rand(13);
		if(temp == 0) itype =consumables.BROWNEG;
		if(temp == 1) itype =consumables.L_BRNEG;
		if(temp == 2) itype =consumables.PURPLEG;
		if(temp == 3) itype =consumables.L_PRPEG;
		if(temp == 4) itype =consumables.BLUEEGG;
		if(temp == 5) itype =consumables.L_BLUEG;
		if(temp == 6) itype =consumables.PINKEGG;
		if(temp == 7) itype =consumables.NPNKEGG;
		if(temp == 8) itype =consumables.L_PNKEG;
		if(temp == 9) itype =consumables.L_WHTEG;
		if(temp == 10) itype =consumables.WHITEEG;
		if(temp == 11) itype =consumables.BLACKEG;
		if(temp == 12) itype =consumables.L_BLKEG;
	}
	//Bonus loot overrides others
	if (flags[kFLAGS.BONUS_ITEM_AFTER_COMBAT_ID] != "") {
		itype = ItemType.lookupItem(flags[kFLAGS.BONUS_ITEM_AFTER_COMBAT_ID]);
	}
	monster.handleAwardItemText(itype); //Each monster can now override the default award text
	if (itype != null) {
		if (inDungeon)
			inventory.takeItem(itype, playerMenu);
		else inventory.takeItem(itype, nextFunc);
	}
}
public function awardPlayer(nextFunc:Function = null):void
{
	if (nextFunc == null) nextFunc = camp.returnToCampUseOneHour; //Default to returning to camp.
	if (player.countCockSocks("gilded") > 0) {
		//trace( "awardPlayer found MidasCock. Gems bumped from: " + monster.gems );
		
		var bonusGems:int = monster.gems * 0.15 + 5 * player.countCockSocks("gilded"); // int so AS rounds to whole numbers
		monster.gems += bonusGems;
		//trace( "to: " + monster.gems )
	}
	if (player.findPerk(PerkLib.HistoryFortune) >= 0) {
		var bonusGems2:int = monster.gems * 0.15;
		monster.gems += bonusGems2;
	}
	if (player.findPerk(PerkLib.HistoryWhore) >= 0) {
		var bonusGems3:int = (monster.gems * 0.04) * player.teaseLevel;
		if (monster.lust >= eMaxLust) monster.gems += bonusGems3;
	}
	if (player.findPerk(PerkLib.AscensionFortune) >= 0) {
		monster.gems *= 1 + (player.perkv1(PerkLib.AscensionFortune) * 0.1);
		monster.gems = Math.round(monster.gems);
	}
	monster.handleAwardText(); //Each monster can now override the default award text
	if (!inDungeon && !inRoomedDungeon && !prison.inPrison) { //Not in dungeons
		if (nextFunc != null) doNext(nextFunc);
		else doNext(playerMenu);
	}
	else {
		if (nextFunc != null) doNext(nextFunc);
		else doNext(playerMenu);
	}
	dropItem(monster, nextFunc);
	inCombat = false;
	player.gems += monster.gems;
	player.XP += monster.XP;
	mainView.statsView.showStatUp('xp');
	dynStats("lust", 0, "resisted", false); //Forces up arrow.
}

//Clear statuses
public function clearStatuses(visibility:Boolean):void {
	player.clearStatuses(visibility);
}
//Update combat status effects
private function combatStatusesUpdate():void {
	//old outfit used for fetish cultists
	var oldOutfit:String = "";
	var changed:Boolean = false;
	//Reset menuloc
//This is now automatic - newRound arg defaults to true:	menuLoc = 0;
	hideUpDown();
	if(player.findStatusAffect(StatusAffects.Sealed) >= 0) {
		//Countdown and remove as necessary
		if(player.statusAffectv1(StatusAffects.Sealed) > 0) {
			player.addStatusValue(StatusAffects.Sealed,1,-1);
			if(player.statusAffectv1(StatusAffects.Sealed) <= 0) player.removeStatusAffect(StatusAffects.Sealed);
			else outputText("<b>One of your combat abilities is currently sealed by magic!</b>\n\n");
		}
	}
	monster.combatRoundUpdate();
	//[Silence warning]
	if(player.findStatusAffect(StatusAffects.ThroatPunch) >= 0) {
		player.addStatusValue(StatusAffects.ThroatPunch,1,-1);
		if(player.statusAffectv1(StatusAffects.ThroatPunch) >= 0) outputText("Thanks to Isabella's wind-pipe crushing hit, you're having trouble breathing and are <b>unable to cast spells as a consequence.</b>\n\n", false);
		else {
			outputText("Your wind-pipe recovers from Isabella's brutal hit.  You'll be able to focus to cast spells again!\n\n", false);
			player.removeStatusAffect(StatusAffects.ThroatPunch);
		}
	}
	if(player.findStatusAffect(StatusAffects.GooArmorSilence) >= 0) {
		if(player.statusAffectv1(StatusAffects.GooArmorSilence) >= 2 || rand(20) + 1 + player.str/10 >= 15) {
			//if passing str check, output at beginning of turn
			outputText("<b>The sticky slop covering your mouth pulls away reluctantly, taking more force than you would expect, but you've managed to free your mouth enough to speak!</b>\n\n");
			player.removeStatusAffect(StatusAffects.GooArmorSilence);
		}
		else {
			outputText("<b>Your mouth is obstructed by sticky goo!  You are silenced!</b>\n\n", false);
			player.addStatusValue(StatusAffects.GooArmorSilence,1,1);
		}
	}
	if(player.findStatusAffect(StatusAffects.LustStones) >= 0) {
		//[When witches activate the stones for goo bodies]
		if(player.isGoo()) {
			outputText("<b>The stones start vibrating again, making your liquid body ripple with pleasure.  The witches snicker at the odd sight you are right now.\n\n</b>");
		}
		//[When witches activate the stones for solid bodies]
		else {
			outputText("<b>The smooth stones start vibrating again, sending another wave of teasing bliss throughout your body.  The witches snicker at you as you try to withstand their attack.\n\n</b>");
		}
		dynStats("lus", player.statusAffectv1(StatusAffects.LustStones) + 4);
	}
	if(player.findStatusAffect(StatusAffects.WebSilence) >= 0) {
		if(player.statusAffectv1(StatusAffects.WebSilence) >= 2 || rand(20) + 1 + player.str/10 >= 15) {
			outputText("You rip off the webbing that covers your mouth with a cry of pain, finally able to breathe normally again!  Now you can cast spells!\n\n", false);
			player.removeStatusAffect(StatusAffects.WebSilence);
		}
		else {
			outputText("<b>Your mouth and nose are obstructed by sticky webbing, making it difficult to breathe and impossible to focus on casting spells.  You try to pull it off, but it just won't work!</b>\n\n", false);
			player.addStatusValue(StatusAffects.WebSilence,1,1);
		}
	}		
	if(player.findStatusAffect(StatusAffects.HolliConstrict) >= 0) {
		outputText("<b>You're tangled up in Holli's verdant limbs!  All you can do is try to struggle free...</b>\n\n");
	}
	if(player.findStatusAffect(StatusAffects.UBERWEB) >= 0)
		outputText("<b>You're pinned under a pile of webbing!  You should probably struggle out of it and get back in the fight!</b>\n\n", false);
	if (player.findStatusAffect(StatusAffects.Blind) >= 0 && monster.findStatusAffect(StatusAffects.Sandstorm) < 0) 
	{
		if (player.findStatusAffect(StatusAffects.SheilaOil) >= 0) 
		{
			if(player.statusAffectv1(StatusAffects.Blind) <= 0) {
				outputText("<b>You finish wiping the demon's tainted oils away from your eyes; though the smell lingers, you can at least see.  Sheila actually seems happy to once again be under your gaze.</b>\n\n", false);
				player.removeStatusAffect(StatusAffects.Blind);
			}
			else {
				outputText("<b>You scrub at the oily secretion with the back of your hand and wipe some of it away, but only smear the remainder out more thinly.  You can hear the demon giggling at your discomfort.</b>\n\n", false);
				player.addStatusValue(StatusAffects.Blind,1,-1);
			}
		}
		else 
		{
			//Remove blind if countdown to 0
			if (player.statusAffectv1(StatusAffects.Blind) == 0) 
			{
				player.removeStatusAffect(StatusAffects.Blind);
				//Alert PC that blind is gone if no more stacks are there.
				if (player.findStatusAffect(StatusAffects.Blind) < 0) 
				{
					outputText("<b>Your eyes have cleared and you are no longer blind!</b>\n\n", false);
				}
				else outputText("<b>You are blind, and many physical attacks will miss much more often.</b>\n\n", false);
			}
			else 
			{
				player.addStatusValue(StatusAffects.Blind,1,-1);
				outputText("<b>You are blind, and many physical attacks will miss much more often.</b>\n\n", false);
			}
		}
	}
	//Basilisk compulsion
	if(player.findStatusAffect(StatusAffects.BasiliskCompulsion) >= 0) {
		Basilisk.basiliskSpeed(player,15);
		//Continuing effect text: 
		outputText("<b>You still feel the spell of those grey eyes, making your movements slow and difficult, the remembered words tempting you to look into its eyes again. You need to finish this fight as fast as your heavy limbs will allow.</b>\n\n", false);
		flags[kFLAGS.BASILISK_RESISTANCE_TRACKER]++;
	}
	if(player.findStatusAffect(StatusAffects.IzmaBleed) >= 0) {
		if(player.statusAffectv1(StatusAffects.IzmaBleed) <= 0) {
			player.removeStatusAffect(StatusAffects.IzmaBleed);
			outputText("<b>You sigh with relief; your bleeding has slowed considerably.</b>\n\n", false);
		}
		//Bleed effect:
		else {
			var bleed:Number = (2 + rand(4))/100;
			bleed *= player.HP;
			bleed = takeDamage(bleed);
			outputText("<b>You gasp and wince in pain, feeling fresh blood pump from your wounds. (<font color=\"#800000\">" + temp + "</font>)</b>\n\n", false);
		}
	}
	if(player.findStatusAffect(StatusAffects.AcidSlap) >= 0) {
		var slap:Number = 3 + (maxHP() * 0.02);
		outputText("<b>Your muscles twitch in agony as the acid keeps burning you. <b>(<font color=\"#800000\">" + slap + "</font>)</b></b>\n\n", false);
	}
	if(player.findPerk(PerkLib.ArousingAura) >= 0 && monster.lustVuln > 0 && player.cor >= 70) {
		if(monster.lust < (eMaxLust * 0.5)) outputText("Your aura seeps into " + monster.a + monster.short + " but does not have any visible effects just yet.\n\n", false);
		else if(monster.lust < (eMaxLust * 0.6)) {
			if(!monster.plural) outputText(monster.capitalA + monster.short + " starts to squirm a little from your unholy presence.\n\n", false);
			else outputText(monster.capitalA + monster.short + " start to squirm a little from your unholy presence.\n\n", false);
		}
		else if(monster.lust < (eMaxLust * 0.75)) outputText("Your arousing aura seems to be visibly affecting " + monster.a + monster.short + ", making " + monster.pronoun2 + " squirm uncomfortably.\n\n", false);
		else if(monster.lust < (eMaxLust * 0.85)) {
			if(!monster.plural) outputText(monster.capitalA + monster.short + "'s skin colors red as " + monster.pronoun1 + " inadvertantly basks in your presence.\n\n", false);
			else outputText(monster.capitalA + monster.short + "' skin colors red as " + monster.pronoun1 + " inadvertantly bask in your presence.\n\n", false);
		}
		else {
			if(!monster.plural) outputText("The effects of your aura are quite pronounced on " + monster.a + monster.short + " as " + monster.pronoun1 + " begins to shake and steal glances at your body.\n\n", false);
			else outputText("The effects of your aura are quite pronounced on " + monster.a + monster.short + " as " + monster.pronoun1 + " begin to shake and steal glances at your body.\n\n", false);
		}
		monster.lust += monster.lustVuln * (2 + rand(4));
	}
	if(player.findStatusAffect(StatusAffects.Bound) >= 0 && flags[kFLAGS.PC_FETISH] >= 2) {
		outputText("The feel of tight leather completely immobilizing you turns you on more and more.  Would it be so bad to just wait and let her play with you like this?\n\n", false);
		dynStats("lus", 3);
	}
	if(player.findStatusAffect(StatusAffects.GooArmorBind) >= 0) {
		if(flags[kFLAGS.PC_FETISH] >= 2) {
			outputText("The feel of the all-encapsulating goo immobilizing your helpless body turns you on more and more.  Maybe you should just wait for it to completely immobilize you and have you at its mercy.\n\n");
			dynStats("lus", 3);
		}
		else outputText("You're utterly immobilized by the goo flowing around you.  You'll have to struggle free!\n\n");
	}
	if(player.findStatusAffect(StatusAffects.HarpyBind) >= 0) {
		if(flags[kFLAGS.PC_FETISH] >= 2) {
			outputText("The harpies are holding you down and restraining you, making the struggle all the sweeter!\n\n");
			dynStats("lus", 3);
		}
		else outputText("You're restrained by the harpies so that they can beat on you with impunity.  You'll need to struggle to break free!\n\n");
	}
	if(player.findStatusAffect(StatusAffects.NagaBind) >= 0 && flags[kFLAGS.PC_FETISH] >= 2) {
		outputText("Coiled tightly by the naga and utterly immobilized, you can't help but become aroused thanks to your bondage fetish.\n\n", false);
		dynStats("lus", 5);
	}
	if(player.findStatusAffect(StatusAffects.TentacleBind) >= 0) {
		outputText("You are firmly trapped in the tentacle's coils.  <b>The only thing you can try to do is struggle free!</b>\n\n", false);
		if(flags[kFLAGS.PC_FETISH] >= 2) {
			outputText("Wrapped tightly in the tentacles, you find it hard to resist becoming more and more aroused...\n\n", false);
			dynStats("lus", 3);
		}
	}
	if(player.findStatusAffect(StatusAffects.DriderKiss) >= 0) {
		//(VENOM OVER TIME: WEAK)
		if(player.statusAffectv1(StatusAffects.DriderKiss) == 0) {
			outputText("Your heart hammers a little faster as a vision of the drider's nude, exotic body on top of you assails you.  It'll only get worse if she kisses you again...\n\n", false);
			dynStats("lus", 8);
		}
		//(VENOM OVER TIME: MEDIUM)
		else if(player.statusAffectv1(StatusAffects.DriderKiss) == 1) {
			outputText("You shudder and moan, nearly touching yourself as your ", false);
			if(player.gender > 0) outputText("loins tingle and leak, hungry for the drider's every touch.", false);
			else outputText("asshole tingles and twitches, aching to be penetrated.", false);
			outputText("  Gods, her venom is getting you so hot.  You've got to end this quickly!\n\n", false);
			dynStats("lus", 15);
		}
		//(VENOM OVER TIME: MAX)
		else {
			outputText("You have to keep pulling your hands away from your crotch - it's too tempting to masturbate here on the spot and beg the drider for more of her sloppy kisses.  Every second that passes, your arousal grows higher.  If you don't end this fast, you don't think you'll be able to resist much longer.  You're too turned on... too horny... too weak-willed to resist much longer...\n\n", false);
			dynStats("lus", 25);
		}
	}
	//Harpy lip gloss
	if(player.hasCock() && player.findStatusAffect(StatusAffects.Luststick) >= 0 && (monster.short == "harpy" || monster.short == "Sophie")) {
		//Chance to cleanse!
		if(player.findPerk(PerkLib.Medicine) >= 0 && rand(100) <= 14) {
			outputText("You manage to cleanse the harpy lip-gloss from your system with your knowledge of medicine!\n\n", false);
			player.removeStatusAffect(StatusAffects.Luststick);
		}		
		else if(rand(5) == 0) {
			if(rand(2) == 0) outputText("A fantasy springs up from nowhere, dominating your thoughts for a few moments.  In it, you're lying down in a soft nest.  Gold-rimmed lips are noisily slurping around your " + player.cockDescript(0) + ", smearing it with her messy aphrodisiac until you're completely coated in it.  She looks up at you knowingly as the two of you get ready to breed the night away...\n\n", false);		
			else outputText("An idle daydream flutters into your mind.  In it, you're fucking a harpy's asshole, clutching tightly to her wide, feathery flanks as the tight ring of her pucker massages your " + player.cockDescript(0) + ".  She moans and turns around to kiss you on the lips, ensuring your hardness.  Before long her feverish grunts of pleasure intensify, and you feel the egg she's birthing squeezing against you through her internal walls...\n\n", false);
			dynStats("lus", 20);
		}
	}
	if(player.findStatusAffect(StatusAffects.StoneLust) >= 0) {
		if(player.vaginas.length > 0) {
			if(player.lust < 40) outputText("You squirm as the smooth stone orb vibrates within you.\n\n", false);
			if(player.lust >= 40 && player.lust < 70) outputText("You involuntarily clench around the magical stone in your twat, in response to the constant erotic vibrations.\n\n", false);
			if(player.lust >= 70 && player.lust < 85) outputText("You stagger in surprise as a particularly pleasant burst of vibrations erupt from the smooth stone sphere in your " + vaginaDescript(0) + ".\n\n", false);
			if(player.lust >= 85) outputText("The magical orb inside of you is making it VERY difficult to keep your focus on combat, white-hot lust suffusing your body with each new motion.\n\n", false);
		}
		else {
			outputText("The orb continues vibrating in your ass, doing its best to arouse you.\n\n", false);
		}
		dynStats("lus", 7 + int(player.sens)/10);
	}
	if(player.findStatusAffect(StatusAffects.KissOfDeath) >= 0) {
		//Effect 
		outputText("Your lips burn with an unexpected flash of heat.  They sting and burn with unholy energies as a puff of ectoplasmic gas escapes your lips.  That puff must be a part of your soul!  It darts through the air to the succubus, who slurps it down like a delicious snack.  You feel feverishly hot and exhausted...\n\n", false);
		dynStats("lus", 5);
		takeDamage(15);		
	}
	if(player.findStatusAffect(StatusAffects.DemonSeed) >= 0) {
		outputText("You feel something shift inside you, making you feel warm.  Finding the desire to fight this... hunk gets harder and harder.\n\n", false);
		dynStats("lus", (player.statusAffectv1(StatusAffects.DemonSeed) + int(player.sens/30) + int(player.lib/30) + int(player.cor/30)));
	}
	if(player.inHeat && player.vaginas.length > 0 && monster.totalCocks() > 0) {
		dynStats("lus", (rand(player.lib/5) + 3 + rand(5)));
		outputText("Your " + vaginaDescript(0) + " clenches with an instinctual desire to be touched and filled.  ", false);
		outputText("If you don't end this quickly you'll give in to your heat.\n\n", false);
	}
	if(player.inRut && player.totalCocks() > 0 && monster.hasVagina()) {
		dynStats("lus", (rand(player.lib/5) + 3 + rand(5)));
		if(player.totalCocks() > 1) outputText("Each of y", false);
		else outputText("Y", false);
		if(monster.plural) outputText("our " + player.multiCockDescriptLight() + " dribbles pre-cum as you think about plowing " + monster.a + monster.short + " right here and now, fucking " + monster.pronoun3 + " " + monster.vaginaDescript() + "s until they're totally fertilized and pregnant.\n\n", false);
		else outputText("our " + player.multiCockDescriptLight() + " dribbles pre-cum as you think about plowing " + monster.a + monster.short + " right here and now, fucking " + monster.pronoun3 + " " + monster.vaginaDescript() + " until it's totally fertilized and pregnant.\n\n", false);
	}
	if(player.findStatusAffect(StatusAffects.NagaVenom) >= 0) {
		//Chance to cleanse!
		if(player.findPerk(PerkLib.Medicine) >= 0 && rand(100) <= 14) {
			outputText("You manage to cleanse the naga venom from your system with your knowledge of medicine!\n\n", false);
			player.spe += player.statusAffectv1(StatusAffects.NagaVenom);
			mainView.statsView.showStatUp( 'spe' );
			// speUp.visible = true;
			// speDown.visible = false;
			player.removeStatusAffect(StatusAffects.NagaVenom);
		}
		else if(player.spe > 3) {
			player.addStatusValue(StatusAffects.NagaVenom,1,2);
			//stats(0,0,-2,0,0,0,0,0);
			player.spe -= 2;
		}
		else takeDamage(5);
		outputText("You wince in pain and try to collect yourself, the naga's venom still plaguing you.\n\n", false);
		takeDamage(2);
	}
	else if(player.findStatusAffect(StatusAffects.TemporaryHeat) >= 0) {
		//Chance to cleanse!
		if(player.findPerk(PerkLib.Medicine) >= 0 && rand(100) <= 14) {
			outputText("You manage to cleanse the heat and rut drug from your system with your knowledge of medicine!\n\n", false);
			player.removeStatusAffect(StatusAffects.TemporaryHeat);
		}
		else {
			dynStats("lus", (player.lib/12 + 5 + rand(5)) * player.statusAffectv2(StatusAffects.TemporaryHeat));
			if(player.hasVagina()) {
				outputText("Your " + vaginaDescript(0) + " clenches with an instinctual desire to be touched and filled.  ", false);
			}
			else if(player.totalCocks() > 0) {
				outputText("Your " + player.cockDescript(0) + " pulses and twitches, overwhelmed with the desire to breed.  ", false);			
			}
			if(player.gender == 0) {
				outputText("You feel a tingle in your " + assholeDescript() + ", and the need to touch and fill it nearly overwhelms you.  ", false);
			}
			outputText("If you don't finish this soon you'll give in to this potent drug!\n\n", false);
		}
	}
	//Poison
	if(player.findStatusAffect(StatusAffects.Poison) >= 0) {
		//Chance to cleanse!
		if(player.findPerk(PerkLib.Medicine) >= 0 && rand(100) <= 14) {
			outputText("You manage to cleanse the poison from your system with your knowledge of medicine!\n\n", false);
			player.removeStatusAffect(StatusAffects.Poison);
		}
		else {
			outputText("The poison continues to work on your body, wracking you with pain!\n\n", false);
			takeDamage(8+rand(maxHP()/20) * player.statusAffectv2(StatusAffects.Poison));
		}
	}
	//Bondage straps + bondage fetish
	if(flags[kFLAGS.PC_FETISH] >= 2 && player.armorName == "barely-decent bondage straps") {
		outputText("The feeling of the tight, leather straps holding tightly to your body while exposing so much of it turns you on a little bit more.\n\n", false);
		dynStats("lus", 2);
	}
	//Giant boulder
	if (player.findStatusAffect(StatusAffects.GiantBoulder) >= 0) {
		outputText("<b>There is a large boulder coming your way. If you don't avoid it in time, you might take some serious damage.</b>\n\n");
	}
	regeneration(true);
	if(player.lust >= player.maxLust()) doNext(endLustLoss);
	if(player.HP <= 0) doNext(endHpLoss);
}

public function regeneration(combat:Boolean = true):void {
	var healingPercent:Number = 0;
	if(combat) {
		//Regeneration
		healingPercent = 0;
		if (player.hunger >= 25 || flags[kFLAGS.HUNGER_ENABLED] <= 0)
		{
			if(player.findPerk(PerkLib.Regeneration) >= 0) healingPercent += 1;
			if(player.findPerk(PerkLib.Regeneration2) >= 0) healingPercent += 1;
		}
		if(player.armor.name == "skimpy nurse's outfit") healingPercent += 1;
		if(player.armor == armors.GOOARMR) healingPercent += (valeria.valeriaFluidsEnabled() ? (flags[kFLAGS.VALERIA_FLUIDS] < 50 ? flags[kFLAGS.VALERIA_FLUIDS] / 25 : 2) : 2);
		if(player.findPerk(PerkLib.LustyRegeneration) >= 0) healingPercent += 1;
		if(healingPercent > 5) healingPercent = 5;
		HPChange(Math.round(maxHP() * healingPercent / 100), false);
	}
	else {
		//Regeneration
		healingPercent = 0;
		if (player.hunger >= 25 || flags[kFLAGS.HUNGER_ENABLED] <= 0)
		{
			if(player.findPerk(PerkLib.Regeneration) >= 0) healingPercent += 2;
			if(player.findPerk(PerkLib.Regeneration2) >= 0) healingPercent += 2;
		}
		if(player.armorName == "skimpy nurse's outfit") healingPercent += 2;
		if(player.armorName == "goo armor") healingPercent += (valeria.valeriaFluidsEnabled() ? (flags[kFLAGS.VALERIA_FLUIDS] < 50 ? flags[kFLAGS.VALERIA_FLUIDS] / 16 : 3) : 3);
		if(player.findPerk(PerkLib.LustyRegeneration) >= 0) healingPercent += 2;
		if(healingPercent > 10) healingPercent = 10;
		HPChange(Math.round(maxHP() * healingPercent / 100), false);
	}
}

private var combatRound:int = 0;
public function startCombat(monster_:Monster, plotFight_:Boolean = false):void {
	combatRound = 0;
	plotFight = plotFight_;
	mainView.hideMenuButton( MainView.MENU_DATA );
	mainView.hideMenuButton( MainView.MENU_APPEARANCE );
	mainView.hideMenuButton( MainView.MENU_LEVEL );
	mainView.hideMenuButton( MainView.MENU_PERKS );
	mainView.hideMenuButton( MainView.MENU_STATS );
	showStats();
	//Flag the game as being "in combat"
	inCombat = true;
	monster = monster_;
	if(monster.short == "Ember") {
		monster.pronoun1 = emberScene.emberMF("he","she");
		monster.pronoun2 = emberScene.emberMF("him","her");
		monster.pronoun3 = emberScene.emberMF("his","her");
	}
	//Reduce enemy def if player has precision!
	if(player.findPerk(PerkLib.Precision) >= 0 && player.inte >= 25) {
		if(monster.armorDef <= 10) monster.armorDef = 0;
		else monster.armorDef -= 10;
	}
	if (player.findPerk(PerkLib.Battlemage) >= 0 && player.lust >= 50) {
		spellMight(true); // XXX: message?
	}
	if (player.findPerk(PerkLib.Spellsword) >= 0 && player.lust < getWhiteMagicLustCap()) {
		spellChargeWeapon(true); // XXX: message?
	}
	monster.str += 25 * player.newGamePlusMod();
	monster.tou += 25 * player.newGamePlusMod();
	monster.spe += 25 * player.newGamePlusMod();
	monster.inte += 25 * player.newGamePlusMod();
	monster.level += 30 * player.newGamePlusMod();
	//Adjust lust vulnerability in New Game+.
	if (player.newGamePlusMod() == 1) monster.lustVuln *= 0.8;
	else if (player.newGamePlusMod() == 2) monster.lustVuln *= 0.65;
	else if (player.newGamePlusMod() == 3) monster.lustVuln *= 0.5;
	else if (player.newGamePlusMod() >= 4) monster.lustVuln *= 0.4;
	monster.HP = monster.eMaxHP();
	monster.XP = monster.totalXP();
	if (player.weaponName == "flintlock pistol") flags[kFLAGS.FLINTLOCK_PISTOL_AMMO] = 4;
	if (player.weaponName == "blunderbuss") flags[kFLAGS.FLINTLOCK_PISTOL_AMMO] = 12;
	if (prison.inPrison && prison.prisonCombatAutoLose) {
		dynStats("lus", player.maxLust(), "resisted", false);
		doNext(endLustLoss);
		return;
	}
	doNext(playerMenu);
}
public function startCombatImmediate(monster:Monster, _plotFight:Boolean):void
{
	startCombat(monster, _plotFight);
}
public function display():void {
	if (!monster.checkCalled){
		outputText("<B>/!\\BUG! Monster.checkMonster() is not called! Calling it now...</B>\n");
		monster.checkMonster();
	}
	if (monster.checkError != ""){
		outputText("<B>/!\\BUG! Monster is not correctly initialized! </B>"+
				monster.checkError+"</u></b>\n");
	}
	var hpDisplay:String = "";
	var lustDisplay:String = "";
	var math:Number = monster.HPRatio();
	//hpDisplay = "(<b>" + String(int(math * 1000) / 10) + "% HP</b>)";
	hpDisplay = monster.HP + " / " + monster.eMaxHP() + " (" + (int(math * 1000) / 10) + "%)";
	lustDisplay = Math.floor(monster.lust) + " / " + eMaxLust;

	//trace("trying to show monster image!");
	if (monster.imageName != "")
	{
		var monsterName:String = "monster-" + monster.imageName;
		//trace("Monster name = ", monsterName);
		outputText(images.showImage(monsterName), false,false);
	}
	outputText("<b>You are fighting ", false);
	outputText(monster.a + monster.short + ":</b> \n");
	if (player.findStatusAffect(StatusAffects.Blind) >= 0) {
		outputText("It's impossible to see anything!\n");
	}
	else {
		outputText(monster.long + "\n\n", false);
		//Bonus sand trap stuff
		if(monster.findStatusAffect(StatusAffects.Level) >= 0) {
			temp = monster.statusAffectv1(StatusAffects.Level);
			//[(new PG for PC height levels)PC level 4: 
			if(temp == 4) outputText("You are right at the edge of its pit.  If you can just manage to keep your footing here, you'll be safe.");
			else if(temp == 3) outputText("The sand sinking beneath your feet has carried you almost halfway into the creature's pit.");
			else outputText("The dunes tower above you and the hissing of sand fills your ears.  <b>The leering sandtrap is almost on top of you!</b>");
			//no new PG)
			outputText("  You could try attacking it with your " + player.weaponName + ", but that will carry you straight to the bottom.  Alternately, you could try to tease it or hit it at range, or wait and maintain your footing until you can clamber up higher.");
			outputText("\n\n");
		}
		if(monster.plural) {
			if(math >= 1) outputText("You see " + monster.pronoun1 + " are in perfect health.  ", false);
			else if(math > .75) outputText("You see " + monster.pronoun1 + " aren't very hurt.  ", false);
			else if(math > .5) outputText("You see " + monster.pronoun1 + " are slightly wounded.  ", false);
			else if(math > .25) outputText("You see " + monster.pronoun1 + " are seriously hurt.  ", false);
			else outputText("You see " + monster.pronoun1 + " are unsteady and close to death.  ", false);
		}
		else {
			if(math >= 1) outputText("You see " + monster.pronoun1 + " is in perfect health.  ", false);
			else if(math > .75) outputText("You see " + monster.pronoun1 + " isn't very hurt.  ", false);
			else if(math > .5) outputText("You see " + monster.pronoun1 + " is slightly wounded.  ", false);
			else if(math > .25) outputText("You see " + monster.pronoun1 + " is seriously hurt.  ", false);
			else outputText("You see " + monster.pronoun1 + " is unsteady and close to death.  ", false);
		}
		showMonsterLust();
		outputText("\n\n<b><u>" + capitalizeFirstLetter(monster.short) + "'s Stats</u></b>\n")
		outputText("Level: " + monster.level + "\n", false);
		outputText("HP: " + hpDisplay + "\n", false);
		outputText("Lust: " + lustDisplay + "\n", false);
	}
	if (debug){
		outputText("\n----------------------------\n");
		outputText(monster.generateDebugDescription(),false);
	}
}
public function showMonsterLust():void {
	//Entrapped
	if(monster.findStatusAffect(StatusAffects.Constricted) >= 0) {
		outputText(monster.capitalA + monster.short + " is currently wrapped up in your tail-coils!  ", false);
	}
	//Venom stuff!
	if(monster.findStatusAffect(StatusAffects.NagaVenom) >= 0) {
		if(monster.plural) {
			if(monster.statusAffectv1(StatusAffects.NagaVenom) <= 1) {
				outputText("You notice " + monster.pronoun1 + " are beginning to show signs of weakening, but there still appears to be plenty of fight left in " + monster.pronoun2 + ".  ", false);
			}
    	    else {
				outputText("You notice " + monster.pronoun1 + " are obviously affected by your venom, " + monster.pronoun3 + " movements become unsure, and " + monster.pronoun3 + " balance begins to fade. Sweat begins to roll on " + monster.pronoun3 + " skin. You wager " + monster.pronoun1 + " are probably beginning to regret provoking you.  ", false);
			}
		}
		//Not plural
		else {
			if(monster.statusAffectv1(StatusAffects.NagaVenom) <= 1) {
				outputText("You notice " + monster.pronoun1 + " is beginning to show signs of weakening, but there still appears to be plenty of fight left in " + monster.pronoun2 + ".  ", false);
			}
    	    else {
				outputText("You notice " + monster.pronoun1 + " is obviously affected by your venom, " + monster.pronoun3 + " movements become unsure, and " + monster.pronoun3 + " balance begins to fade. Sweat is beginning to roll on " + monster.pronoun3 + " skin. You wager " + monster.pronoun1 + " is probably beginning to regret provoking you.  ", false);
			}
		}
		
		monster.spe -= monster.statusAffectv1(StatusAffects.NagaVenom);
		monster.str -= monster.statusAffectv1(StatusAffects.NagaVenom);
		if(monster.spe < 1) monster.spe = 1;
		if(monster.str < 1) monster.str = 1;
	}
	if(monster.short == "harpy") {
		//(Enemy slightly aroused) 
		if(monster.lust >= (eMaxLust * 0.45) && monster.lust < (eMaxLust * 0.7) outputText("The harpy's actions are becoming more and more erratic as she runs her mad-looking eyes over your body, her chest jiggling, clearly aroused.  ", false);
		//(Enemy moderately aroused) 
		if(monster.lust >= (eMaxLust * 0.7) && monster.lust < (eMaxLust * 0.9)) outputText("She stops flapping quite so frantically and instead gently sways from side to side, showing her soft, feathery body to you, even twirling and raising her tail feathers, giving you a glimpse of her plush pussy, glistening with fluids.", false);
		//(Enemy dangerously aroused) 
		if(monster.lust >= (eMaxLust * 0.9)) outputText("You can see her thighs coated with clear fluids, the feathers matted and sticky as she struggles to contain her lust.", false);
	}
	else if(monster is Clara)
	{
		//Clara is becoming aroused
		if(monster.lust <= (eMaxLust * 0.4))	 {}
		else if(monster.lust <= (eMaxLust * 0.65)) outputText("The anger in her motions is weakening.");
		//Clara is somewhat aroused
		else if(monster.lust <= (eMaxLust * 0.75)) outputText("Clara seems to be becoming more aroused than angry now.");
		//Clara is very aroused
		else if(monster.lust <= (eMaxLust * 0.85)) outputText("Clara is breathing heavily now, the signs of her arousal becoming quite visible now.");
		//Clara is about to give in
		else outputText("It looks like Clara is on the verge of having her anger overwhelmed by her lusts.");
	}
	//{Bonus Lust Descripts}
	else if(monster.short == "Minerva") {
		if(monster.lust < (eMaxLust * 0.4)) {}
		//(40)
		else if(monster.lust < (eMaxLust * 0.6)) outputText("Letting out a groan Minerva shakes her head, focusing on the fight at hand.  The bulge in her short is getting larger, but the siren ignores her growing hard-on and continues fighting.  ");
		//(60) 
		else if(monster.lust < (eMaxLust * 0.8)) outputText("Tentacles are squirming out from the crotch of her shorts as the throbbing bulge grows bigger and bigger, becoming harder and harder... for Minerva to ignore.  A damp spot has formed just below the bulge.  ");
		//(80)
		else outputText("She's holding onto her weapon for support as her face is flushed and pain-stricken.  Her tiny, short shorts are painfully holding back her quaking bulge, making the back of the fabric act like a thong as they ride up her ass and struggle against her cock.  Her cock-tentacles are lashing out in every direction.  The dampness has grown and is leaking down her leg.");
	}
	else if(monster.short == "Cum Witch") {
		//{Bonus Lust Desc (40+)}
		if(monster.lust < (eMaxLust * 0.4)) {}
		else if(monster.lust < (eMaxLust * 0.5)) outputText("Her nipples are hard, and poke two visible tents into the robe draped across her mountainous melons.  ");
		//{Bonus Lust Desc (50-75)}
		else if(monster.lust < (eMaxLust * 0.75)) outputText("Wobbling dangerously, you can see her semi-hard shaft rustling the fabric as she moves, evidence of her growing needs.  ");
		//{75+}
		if(monster.lust >= (eMaxLust * 0.75)) outputText("Swelling obscenely, the Cum Witch's thick cock stands out hard and proud, its bulbous tip rustling through the folds of her fabric as she moves and leaving dark smears in its wake.  ");
		//(85+}
		if(monster.lust >= (eMaxLust * 0.85)) outputText("Every time she takes a step, those dark patches seem to double in size.  ");
		//{93+}
		if(monster.lust >= (eMaxLust * 0.93)) outputText("There's no doubt about it, the Cum Witch is dripping with pre-cum and so close to caving in.  Hell, the lower half of her robes are slowly becoming a seed-stained mess.  ");
		//{Bonus Lust Desc (60+)}
		if(monster.lust >= (eMaxLust * 0.7)) outputText("She keeps licking her lips whenever she has a moment, and she seems to be breathing awfully hard.  ");
	}
	else if(monster.short == "Kelt") {
		//Kelt Lust Levels
		//(sub 50)
		if(monster.lust < (eMaxLust * 0.5)) outputText("Kelt actually seems to be turned off for once in his miserable life.  His maleness is fairly flaccid and droopy.  ");
		//(sub 60)
		else if(monster.lust < (eMaxLust * 0.6)) outputText("Kelt's gotten a little stiff down below, but he still seems focused on taking you down.  ");
		//(sub 70)
		else if(monster.lust < (eMaxLust * 0.7)) outputText("Kelt's member has grown to its full size and even flared a little at the tip.  It bobs and sways with every movement he makes, reminding him how aroused you get him.  ");
		//(sub 80)
		else if(monster.lust < (eMaxLust * 0.8)) outputText("Kelt is unabashedly aroused at this point.  His skin is flushed, his manhood is erect, and a thin bead of pre has begun to bead underneath.  ");
		//(sub 90)
		else if(monster.lust < (eMaxLust * 0.9)) outputText("Kelt seems to be having trouble focusing.  He keeps pausing and flexing his muscles, slapping his cock against his belly and moaning when it smears his pre-cum over his equine underside.  ");
		//(sub 100) 
		else outputText("There can be no doubt that you're having quite the effect on Kelt.  He keeps fidgeting, dripping pre-cum everywhere as he tries to keep up the facade of fighting you.  His maleness is continually twitching and bobbing, dripping messily.  He's so close to giving in...");
	}
	else if(monster.short == "green slime") {
		if(monster.lust >= (eMaxLust * 0.45) && monster.lust < (eMaxLust * 0.65)) outputText("A lump begins to form at the base of the figure's torso, where its crotch would be.  ", false); 
		if(monster.lust >= (eMaxLust * 0.65) && monster.lust < (eMaxLust * 0.85)) outputText("A distinct lump pulses at the base of the slime's torso, as if something inside the creature were trying to escape.  ", false);
		if(monster.lust >= (eMaxLust * 0.85) && monster.lust < (eMaxLust * 0.93)) outputText("A long, thick pillar like a small arm protrudes from the base of the slime's torso.  ", false);
		if(monster.lust >= (eMaxLust * 0.93)) outputText("A long, thick pillar like a small arm protrudes from the base of the slime's torso.  Its entire body pulses, and it is clearly beginning to lose its cohesion.  ", false);
	}
	else if(monster.short == "Sirius, a naga hypnotist") {
		if(monster.lust < (eMaxLust * 0.4)) {}
		else if(monster.lust >= (eMaxLust * 0.4)) outputText("You can see the tip of his reptilian member poking out of its protective slit. ");
		else if(monster.lust >= (eMaxLust * 0.6)) outputText("His cock is now completely exposed and half-erect, yet somehow he still stays focused on your eyes and his face is inexpressive.  ");
		else outputText("His cock is throbbing hard, you don't think it will take much longer for him to pop.   Yet his face still looks inexpressive... despite the beads of sweat forming on his brow.  ");

	}
	else if(monster.short == "kitsune") {
		//Kitsune Lust states:
		//Low
		if(monster.lust > (eMaxLust * 0.3) && monster.lust < (eMaxLust * 0.5)) outputText("The kitsune's face is slightly flushed.  She fans herself with her hand, watching you closely.");
		//Med
		else if(monster.lust > (eMaxLust * 0.3) && monster.lust < (eMaxLust * 0.75)) outputText("The kitsune's cheeks are bright pink, and you can see her rubbing her thighs together and squirming with lust.");
		//High
		else if(monster.lust > (eMaxLust * 0.3)) {
			//High (redhead only)
			if(monster.hairColor == "red") outputText("The kitsune is openly aroused, unable to hide the obvious bulge in her robes as she seems to be struggling not to stroke it right here and now.");
			else outputText("The kitsune is openly aroused, licking her lips frequently and desperately trying to hide the trail of fluids dripping down her leg.");
		}
	}
	else if(monster.short == "demons") {
		if(monster.lust > (eMaxLust * 0.3) && monster.lust < (eMaxLust * 0.6)) outputText("The demons lessen somewhat in the intensity of their attack, and some even eye up your assets as they strike at you.", false);
		if(monster.lust >= (eMaxLust * 0.6) && monster.lust < (eMaxLust * 0.8)) outputText("The demons are obviously steering clear from damaging anything you might use to fuck and they're starting to leave their hands on you just a little longer after each blow. Some are starting to cop quick feels with their other hands and you can smell the demonic lust of a dozen bodies on the air.", false);
		if(monster.lust >= (eMaxLust * 0.8)) outputText(" The demons are less and less willing to hit you and more and more willing to just stroke their hands sensuously over you. The smell of demonic lust is thick on the air and part of the group just stands there stroking themselves openly.", false);
	}
	else {
		if(monster.plural) {
			if(monster.lust > (eMaxLust * 0.5) && monster.lust < (eMaxLust * 0.6)) outputText(monster.capitalA + monster.short + "' skin remains flushed with the beginnings of arousal.  ", false);
			if(monster.lust >= (eMaxLust * 0.6) && monster.lust < (eMaxLust * 0.7)) outputText(monster.capitalA + monster.short + "' eyes constantly dart over your most sexual parts, betraying " + monster.pronoun3 + " lust.  ", false);
			if(monster.cocks.length > 0) {
				if(monster.lust >= (eMaxLust * 0.7) && monster.lust < (eMaxLust * 0.85)) outputText(monster.capitalA + monster.short + " are having trouble moving due to the rigid protrusion in " + monster.pronoun3 + " groins.  ", false);
				if(monster.lust >= (eMaxLust * 0.85)) outputText(monster.capitalA + monster.short + " are panting and softly whining, each movement seeming to make " + monster.pronoun3 + " bulges more pronounced.  You don't think " + monster.pronoun1 + " can hold out much longer.  ", false);
			}
			if(monster.vaginas.length > 0) {
				if(monster.lust >= (eMaxLust * 0.7) && monster.lust < (eMaxLust * 0.85)) outputText(monster.capitalA + monster.short + " are obviously turned on, you can smell " + monster.pronoun3 + " arousal in the air.  ", false);
				if(monster.lust >= (eMaxLust * 0.85)) outputText(monster.capitalA + monster.short + "' " + monster.vaginaDescript() + "s are practically soaked with their lustful secretions.  ", false);
			}
		}
		else {
			if(monster.lust > (eMaxLust * 0.5) && monster.lust < (eMaxLust * 0.6)) outputText(monster.capitalA + monster.short + "'s skin remains flushed with the beginnings of arousal.  ", false);
			if(monster.lust >= (eMaxLust * 0.6) && monster.lust < (eMaxLust * 0.7)) outputText(monster.capitalA + monster.short + "'s eyes constantly dart over your most sexual parts, betraying " + monster.pronoun3 + " lust.  ", false);
			if(monster.cocks.length > 0) {
				if(monster.lust >= (eMaxLust * 0.7) && monster.lust < (eMaxLust * 0.85)) outputText(monster.capitalA + monster.short + " is having trouble moving due to the rigid protrusion in " + monster.pronoun3 + " groin.  ", false);
				if(monster.lust >= (eMaxLust * 0.85)) outputText(monster.capitalA + monster.short + " is panting and softly whining, each movement seeming to make " + monster.pronoun3 + " bulge more pronounced.  You don't think " + monster.pronoun1 + " can hold out much longer.  ", false);
			}
			if(monster.vaginas.length > 0) {
				if(monster.lust >= (eMaxLust * 0.7) && monster.lust < (eMaxLust * 0.85)) outputText(monster.capitalA + monster.short + " is obviously turned on, you can smell " + monster.pronoun3 + " arousal in the air.  ", false);
				if(monster.lust >= (eMaxLust * 0.85)) outputText(monster.capitalA + monster.short + "'s " + monster.vaginaDescript() + " is practically soaked with her lustful secretions.  ", false);
			}
		}
	}
}

// This is a bullshit work around to get the parser to do what I want without having to fuck around in it's code.
public function teaseText():String
{
	tease(true);
	return "";
}

// Just text should force the function to purely emit the test text to the output display, and not have any other side effects
public function tease(justText:Boolean = false):void {
	if (!justText) clearOutput();
	//You cant tease a blind guy!
	if(monster.findStatusAffect(StatusAffects.Blind) >= 0) {
		outputText("You do your best to tease " + monster.a + monster.short + " with your body.  It doesn't work - you blinded " + monster.pronoun2 + ", remember?\n\n", true);
		return;
	}
	if(player.findStatusAffect(StatusAffects.Sealed) >= 0 && player.statusAffectv2(StatusAffects.Sealed) == 1) {
		outputText("You do your best to tease " + monster.a + monster.short + " with your body.  Your artless twirls have no effect, as <b>your ability to tease is sealed.</b>\n\n", true);
		return;
	}	
	if(monster.short == "Sirius, a naga hypnotist") {
		outputText("He is too focused on your eyes to pay any attention to your teasing moves, <b>looks like you'll have to beat him up.</b>\n\n");
		return;
	}
	fatigueRecovery();
	var damage:Number;
	var chance:Number;
	var bimbo:Boolean = false;
	var bro:Boolean = false;
	var futa:Boolean = false;
	var choices:Array = [];
	var select:Number;
	//Tags used for bonus damage and chance later on
	var breasts:Boolean = false;
	var penis:Boolean = false;
	var balls:Boolean = false;
	var vagina:Boolean = false;
	var anus:Boolean = false;
	var ass:Boolean = false;
	//If auto = true, set up bonuses using above flags
	var auto:Boolean = true;
	//==============================
	//Determine basic success chance.
	//==============================
	chance = 60;
	//5% chance for each tease level.
	chance += player.teaseLevel * 5;
	//Extra chance for sexy undergarments.
	chance += player.upperGarment.sexiness;
	chance += player.lowerGarment.sexiness;
	//10% for seduction perk
	if(player.findPerk(PerkLib.Seduction) >= 0) chance += 10;
	//10% for sexy armor types
	if(player.findPerk(PerkLib.SluttySeduction) >= 0) chance += 10;
	//10% for bimbo shits
	if(player.findPerk(PerkLib.BimboBody) >= 0) {
		chance += 10;
		bimbo = true;
	}
	if(player.findPerk(PerkLib.BroBody) >= 0) {
		chance += 10;
		bro = true;
	}
	if(player.findPerk(PerkLib.FutaForm) >= 0) {
		chance += 10;
		futa = true;
	}
	//2 & 2 for seductive valentines!
	if(player.findPerk(PerkLib.SensualLover) >= 0) {
		chance += 2;
	}
	if (player.findPerk(PerkLib.ChiReflowLust) >= 0) chance += UmasShop.NEEDLEWORK_LUST_TEASE_MULTI;
	//==============================
	//Determine basic damage.
	//==============================
	damage = 6 + rand(3);
	if(player.findPerk(PerkLib.SensualLover) >= 0) {
		damage += 2;
	}
	if(player.findPerk(PerkLib.Seduction) >= 0) damage += 5;
	//+ slutty armor bonus
	if(player.findPerk(PerkLib.SluttySeduction) >= 0) damage += player.perkv1(PerkLib.SluttySeduction);
	//10% for bimbo shits
	if(bimbo || bro || futa) {
		damage += 5;
		bimbo = true;
	}
	if (player.level < 30) damage += player.level;
	else if (player.level < 60) damage += 30 + ((player.level - 30) / 2);
	else damage += 45 + ((player.level - 60) / 5);
	if (player.findPerk(PerkLib.JobSeducer) >= 0) damage += player.teaseLevel*3;
	else damage += player.teaseLevel*2;
	//==============================
	//TEASE SELECT CHOICES
	//==BASICS========
	//0 butt shake
	//1 breast jiggle
	//2 pussy flash
	//3 cock flash
	//==BIMBO STUFF===
	//4 butt shake
	//5 breast jiggle
	//6 pussy flash
	//7 special Adjatha-crafted bend over bimbo times
	//==BRO STUFF=====
	//8 Pec Dance
	//9 Heroic Pose
	//10 Bulgy groin thrust
	//11 Show off dick
	//==EXTRAS========
	//12 Cat flexibility.
	//13 Pregnant
	//14 Brood Mother
	//15 Nipplecunts
	//16 Anal gape
	//17 Bee abdomen tease
	//18 DOG TEASE
	//19 Maximum Femininity:
	//20 Maximum MAN:
	//21 Perfect Androgyny:
	//22 SPOIDAH SILK
	//23 RUT
	//24 Poledance - req's staff! - Req's gender!  Req's TITS!
	//25 Tall Tease! - Reqs 2+ feet & PC Cunt!
	//26 SMART PEEPS! 70+ int, arouse spell!
	//27 - FEEDER
	//28 FEMALE TEACHER COSTUME TEASE
	//29 Male Teacher Outfit Tease
	//30 Naga Fetish Clothes
	//31 Centaur harness clothes
	//32 Genderless servant clothes
	//33 Crotch Revealing Clothes (herm only?)
	//34 Maid Costume (female only):
	//35 Servant Boy Clothes (male only)
	//36 Bondage Patient Clothes 
	//37 Kitsune Tease
	//38 Kitsune Tease
	//39 Kitsune Tease
	//40 Kitsune Tease
	//41 Kitsune Gendered Tease
	//42 Urta teases
	//43 Cowgirl teases
	//44 Bikini Mail Tease
	//45 Lethicite Armor Tease
	//==============================
	//BUILD UP LIST OF TEASE CHOICES!
	//==============================
	//Futas!
	if((futa || bimbo) && player.gender == 3) {
		//Once chance of butt.
		choices[choices.length] = 4;
		//Big butts get more butt
		if(player.buttRating >= 7) choices[choices.length] = 4;
		if(player.buttRating >= 10) choices[choices.length] = 4;
		if(player.buttRating >= 14) choices[choices.length] = 4;
		if(player.buttRating >= 20) choices[choices.length] = 4;
		if(player.buttRating >= 25) choices[choices.length] = 4;
		//Breast jiggle!
		if(player.biggestTitSize() >= 2) choices[choices.length] = 5;
		if(player.biggestTitSize() >= 4) choices[choices.length] = 5;
		if(player.biggestTitSize() >= 8) choices[choices.length] = 5;
		if(player.biggestTitSize() >= 15) choices[choices.length] = 5;
		if(player.biggestTitSize() >= 30) choices[choices.length] = 5;
		if(player.biggestTitSize() >= 50) choices[choices.length] = 5;
		if(player.biggestTitSize() >= 75) choices[choices.length] = 5;
		if(player.biggestTitSize() >= 100) choices[choices.length] = 5;
		//Pussy Flash!
		if(player.hasVagina()) {
			choices[choices.length] = 2;
			if(player.wetness() >= 3) choices[choices.length] = 6;
			if(player.wetness() >= 5) choices[choices.length] = 6;
			if(player.vaginalCapacity() >= 30) choices[choices.length] = 6;
			if(player.vaginalCapacity() >= 60) choices[choices.length] = 6;
			if(player.vaginalCapacity() >= 75) choices[choices.length] = 6;
		}
		//Adj special!
		if(player.hasVagina() && player.buttRating >= 8 && player.hipRating >= 6 && player.biggestTitSize() >= 4) {
			choices[choices.length] = 7;
			choices[choices.length] = 7;
			choices[choices.length] = 7;
			choices[choices.length] = 7;
		}
		//Cock flash!
		if(futa && player.hasCock()) {
			choices[choices.length] = 10;
			choices[choices.length] = 11;
			if(player.cockTotal() > 1) choices[choices.length] = 10;
			if(player.cockTotal() >= 2) choices[choices.length] = 11;
			if(player.biggestCockArea() >= 10) choices[choices.length] = 10;
			if(player.biggestCockArea() >= 25) choices[choices.length] = 11;
			if(player.biggestCockArea() >= 50) choices[choices.length] = 11;
			if(player.biggestCockArea() >= 75) choices[choices.length] = 10;
			if(player.biggestCockArea() >= 100) choices[choices.length] = 11;
			if(player.biggestCockArea() >= 300) choices[choices.length] = 10;
		}
	}
	else if(bro) {
		//8 Pec Dance
		if(player.biggestTitSize() < 1 && player.tone >= 60) {
			choices[choices.length] = 8;
			if(player.tone >= 70) choices[choices.length] = 8;
			if(player.tone >= 80) choices[choices.length] = 8;
			if(player.tone >= 90) choices[choices.length] = 8;
			if(player.tone == 100) choices[choices.length] = 8;
		}
		//9 Heroic Pose
		if(player.tone >= 60 && player.str >= 50) {
			choices[choices.length] = 9;
			if(player.tone >= 80) choices[choices.length] = 9;
			if(player.str >= 70) choices[choices.length] = 9;
			if(player.tone >= 90) choices[choices.length] = 9;
			if(player.str >= 80) choices[choices.length] = 9;
		}	
		//Cock flash!
		if(player.hasCock()) {
			choices[choices.length] = 10;
			choices[choices.length] = 11;
			if(player.cockTotal() > 1) choices[choices.length] = 10;
			if(player.cockTotal() >= 2) choices[choices.length] = 11;
			if(player.biggestCockArea() >= 10) choices[choices.length] = 10;
			if(player.biggestCockArea() >= 25) choices[choices.length] = 11;
			if(player.biggestCockArea() >= 50) choices[choices.length] = 11;
			if(player.biggestCockArea() >= 75) choices[choices.length] = 10;
			if(player.biggestCockArea() >= 100) choices[choices.length] = 11;
			if(player.biggestCockArea() >= 300) choices[choices.length] = 10;
		}
	}
	//VANILLA FOLKS
	else {
		//Once chance of butt.
		choices[choices.length] = 0;
		//Big butts get more butt
		if(player.buttRating >= 7) choices[choices.length] = 0;
		if(player.buttRating >= 10) choices[choices.length] = 0;
		if(player.buttRating >= 14) choices[choices.length] = 0;
		if(player.buttRating >= 20) choices[choices.length] = 0;
		if(player.buttRating >= 25) choices[choices.length] = 0;
		//Breast jiggle!
		if(player.biggestTitSize() >= 2) choices[choices.length] = 1;
		if(player.biggestTitSize() >= 4) choices[choices.length] = 1;
		if(player.biggestTitSize() >= 8) choices[choices.length] = 1;
		if(player.biggestTitSize() >= 15) choices[choices.length] = 1;
		if(player.biggestTitSize() >= 30) choices[choices.length] = 1;
		if(player.biggestTitSize() >= 50) choices[choices.length] = 1;
		if(player.biggestTitSize() >= 75) choices[choices.length] = 1;
		if(player.biggestTitSize() >= 100) choices[choices.length] = 1;
		//Pussy Flash!
		if(player.hasVagina()) {
			choices[choices.length] = 2;
			if(player.wetness() >= 3) choices[choices.length] = 2;
			if(player.wetness() >= 5) choices[choices.length] = 2;
			if(player.vaginalCapacity() >= 30) choices[choices.length] = 2;
			if(player.vaginalCapacity() >= 60) choices[choices.length] = 2;
			if(player.vaginalCapacity() >= 75) choices[choices.length] = 2;
		}
		//Cock flash!
		if(player.hasCock()) {
			choices[choices.length] = 3;
			if(player.cockTotal() > 1) choices[choices.length] = 3;
			if(player.cockTotal() >= 2) choices[choices.length] = 3;
			if(player.biggestCockArea() >= 10) choices[choices.length] = 3;
			if(player.biggestCockArea() >= 25) choices[choices.length] = 3;
			if(player.biggestCockArea() >= 50) choices[choices.length] = 3;
			if(player.biggestCockArea() >= 75) choices[choices.length] = 3;
			if(player.biggestCockArea() >= 100) choices[choices.length] = 3;
			if(player.biggestCockArea() >= 300) choices[choices.length] = 3;
		}
	}
	//==EXTRAS========
	//12 Cat flexibility.
	if(player.findPerk(PerkLib.Flexibility) >= 0 && player.isBiped() && player.hasVagina()) {
		choices[choices.length] = 12;
		choices[choices.length] = 12;
		if(player.wetness() >= 3) choices[choices.length] = 12;
		if(player.wetness() >= 5) choices[choices.length] = 12;
		if(player.vaginalCapacity() >= 30) choices[choices.length] = 12;
	}
	//13 Pregnant
	if(player.pregnancyIncubation <= 216 && player.pregnancyIncubation > 0) {
		choices[choices.length] = 13;
		if(player.biggestLactation() >= 1) choices[choices.length] = 13;
		if(player.pregnancyIncubation <= 180) choices[choices.length] = 13;
		if(player.pregnancyIncubation <= 120) choices[choices.length] = 13;
		if(player.pregnancyIncubation <= 100) choices[choices.length] = 13;
		if(player.pregnancyIncubation <= 50) choices[choices.length] = 13;
		if(player.pregnancyIncubation <= 24) choices[choices.length] = 13;
		if(player.pregnancyIncubation <= 24) choices[choices.length] = 13;
		if(player.pregnancyIncubation <= 24) choices[choices.length] = 13;
		if(player.pregnancyIncubation <= 24) choices[choices.length] = 13;
	}
	//14 Brood Mother
	if(monster.hasCock() && player.hasVagina() && player.findPerk(PerkLib.BroodMother) >= 0 && (player.pregnancyIncubation <= 0 || player.pregnancyIncubation > 216)) {
		choices[choices.length] = 14;
		choices[choices.length] = 14;
		choices[choices.length] = 14;
		if(player.inHeat) choices[choices.length] = 14;
		if(player.inHeat) choices[choices.length] = 14;
		if(player.inHeat) choices[choices.length] = 14;
		if(player.inHeat) choices[choices.length] = 14;
		if(player.inHeat) choices[choices.length] = 14;
		if(player.inHeat) choices[choices.length] = 14;
		if(player.inHeat) choices[choices.length] = 14;
	}
	//15 Nipplecunts
	if(player.hasFuckableNipples()) {
		choices[choices.length] = 15;
		choices[choices.length] = 15;
		if(player.hasVagina()) choices[choices.length] = 15;
		if(player.hasVagina()) choices[choices.length] = 15;
		if(player.hasVagina()) choices[choices.length] = 15;
		if(player.wetness() >= 3) choices[choices.length] = 15;
		if(player.wetness() >= 5) choices[choices.length] = 15;
		if(player.biggestTitSize() >= 3) choices[choices.length] = 15;
		if(player.nippleLength >= 3) choices[choices.length] = 15;
	}
	//16 Anal gape
	if(player.ass.analLooseness >= 4) {
		choices[choices.length] = 16;
		if(player.ass.analLooseness >= 5) choices[choices.length] = 16;
	}		
	//17 Bee abdomen tease
	if(player.tailType == TAIL_TYPE_BEE_ABDOMEN) {
		choices[choices.length] = 17;
		choices[choices.length] = 17;
	}
	//18 DOG TEASE
	if(player.dogScore() >= 4 && player.hasVagina() && player.isBiped()) {
		choices[choices.length] = 18;
		choices[choices.length] = 18;
	}
	//19 Maximum Femininity:
	if(player.femininity >= 100) {
		choices[choices.length] = 19;
		choices[choices.length] = 19;
		choices[choices.length] = 19;
	}
	//20 Maximum MAN:
	if(player.femininity <= 0) {
		choices[choices.length] = 20;
		choices[choices.length] = 20;
		choices[choices.length] = 20;
	}
	//21 Perfect Androgyny:
	if(player.femininity == 50) {
		choices[choices.length] = 21;
		choices[choices.length] = 21;
		choices[choices.length] = 21;
	}
	//22 SPOIDAH SILK
	if(player.tailType == TAIL_TYPE_SPIDER_ADBOMEN) {
		choices[choices.length] = 22;
		choices[choices.length] = 22;
		choices[choices.length] = 22;
		if(player.spiderScore() >= 4) {
			choices[choices.length] = 22;
			choices[choices.length] = 22;
			choices[choices.length] = 22;
		}
	}
	//23 RUT
	if(player.inRut && monster.hasVagina() && player.hasCock()) {
		choices[choices.length] = 23;
		choices[choices.length] = 23;
		choices[choices.length] = 23;
		choices[choices.length] = 23;
		choices[choices.length] = 23;
	}
	//24 Poledance - req's staff! - Req's gender!  Req's TITS!
	if(player.weaponName == "wizard's staff" && player.biggestTitSize() >= 1 && player.gender > 0) {
		choices[choices.length] = 24;
		choices[choices.length] = 24;
		choices[choices.length] = 24;
		choices[choices.length] = 24;
		choices[choices.length] = 24;
	}
	//25 Tall Tease! - Reqs 2+ feet & PC Cunt!
	if(player.tallness - monster.tallness >= 24 && player.biggestTitSize() >= 4) {
		choices[choices.length] = 25;
		choices[choices.length] = 25;
		choices[choices.length] = 25;
		choices[choices.length] = 25;
		choices[choices.length] = 25;
	}
	//26 SMART PEEPS! 70+ int, arouse spell!
	if(player.inte >= 70 && player.findStatusAffect(StatusAffects.KnowsArouse) >= 0) {
		choices[choices.length] = 26;
		choices[choices.length] = 26;
		choices[choices.length] = 26;
	}
	//27 FEEDER
	if(player.findPerk(PerkLib.Feeder) >= 0 && player.biggestTitSize() >= 4) {
		choices[choices.length] = 27;
		choices[choices.length] = 27;
		choices[choices.length] = 27;
		if(player.biggestTitSize() >= 10) choices[choices.length] = 27;
		if(player.biggestTitSize() >= 15) choices[choices.length] = 27;
		if(player.biggestTitSize() >= 25) choices[choices.length] = 27;
		if(player.biggestTitSize() >= 40) choices[choices.length] = 27;
		if(player.biggestTitSize() >= 60) choices[choices.length] = 27;
		if(player.biggestTitSize() >= 80) choices[choices.length] = 27;
	}
	//28 FEMALE TEACHER COSTUME TEASE
	if(player.armorName == "backless female teacher's clothes" && player.gender == 2) {
		choices[choices.length] = 28;
		choices[choices.length] = 28;
		choices[choices.length] = 28;
		choices[choices.length] = 28;
	}
	//29 Male Teacher Outfit Tease
	if(player.armorName == "formal vest, tie, and crotchless pants" && player.gender == 1) {
		choices[choices.length] = 29;
		choices[choices.length] = 29;
		choices[choices.length] = 29;
		choices[choices.length] = 29;
	}
	//30 Naga Fetish Clothes
	if(player.armorName == "headdress, necklaces, and many body-chains") {
		choices[choices.length] = 30;
		choices[choices.length] = 30;
		choices[choices.length] = 30;
		choices[choices.length] = 30;
	}
	//31 Centaur harness clothes
	if(player.armorName == "bridle bit and saddle set") {
		choices[choices.length] = 31;
		choices[choices.length] = 31;
		choices[choices.length] = 31;
		choices[choices.length] = 31;
	}
	//32 Genderless servant clothes
	if(player.armorName == "servant's clothes" && player.gender == 0) {
		choices[choices.length] = 32;
		choices[choices.length] = 32;
		choices[choices.length] = 32;
		choices[choices.length] = 32;
	}
	//33 Crotch Revealing Clothes (herm only?)
	if(player.armorName == "crotch-revealing clothes" && player.gender == 3) {
		choices[choices.length] = 33;
		choices[choices.length] = 33;
		choices[choices.length] = 33;
		choices[choices.length] = 33;
	}
	//34 Maid Costume (female only):
	if(player.armorName == "maid's clothes" && player.hasVagina()) {
		choices[choices.length] = 34;
		choices[choices.length] = 34;
		choices[choices.length] = 34;
		choices[choices.length] = 34;
	}
	//35 Servant Boy Clothes (male only)
	if(player.armorName == "cute servant's clothes" && player.hasCock()) {
		choices[choices.length] = 35;
		choices[choices.length] = 35;
		choices[choices.length] = 35;
		choices[choices.length] = 35;
	}
	//36 Bondage Patient Clothes 
	if(player.armorName == "bondage patient clothes") {
		choices[choices.length] = 36;
		choices[choices.length] = 36;
		choices[choices.length] = 36;
		choices[choices.length] = 36;
	}	
	//37 Kitsune Tease
	//38 Kitsune Tease
	//39 Kitsune Tease
	//40 Kitsune Tease
	if(player.kitsuneScore() >= 2 && player.tailType == TAIL_TYPE_FOX) {
		choices[choices.length] = 37;
		choices[choices.length] = 37;
		choices[choices.length] = 37;
		choices[choices.length] = 37;
		choices[choices.length] = 38;
		choices[choices.length] = 38;
		choices[choices.length] = 38;
		choices[choices.length] = 38;
		choices[choices.length] = 39;
		choices[choices.length] = 39;
		choices[choices.length] = 39;
		choices[choices.length] = 39;
		choices[choices.length] = 40;
		choices[choices.length] = 40;
		choices[choices.length] = 40;
		choices[choices.length] = 40;
	}
	//41 Kitsune Gendered Tease
	if(player.kitsuneScore() >= 2 && player.tailType == TAIL_TYPE_FOX) {
		choices[choices.length] = 41;
		choices[choices.length] = 41;
		choices[choices.length] = 41;
		choices[choices.length] = 41;
	}
	//42 Urta teases!
	if(urtaQuest.isUrta()) {
		choices[choices.length] = 42;
		choices[choices.length] = 42;
		choices[choices.length] = 42;
		choices[choices.length] = 42;
		choices[choices.length] = 42;
		choices[choices.length] = 42;
		choices[choices.length] = 42;
		choices[choices.length] = 42;
		choices[choices.length] = 42;
	}
	//43 - special mino + cowgirls
	if(player.hasVagina() && player.lactationQ() >= 500 && player.biggestTitSize() >= 6 && player.cowScore() >= 3 && player.tailType == TAIL_TYPE_COW) {
		choices[choices.length] = 43;
		choices[choices.length] = 43;
		choices[choices.length] = 43;
		choices[choices.length] = 43;
		choices[choices.length] = 43;
		choices[choices.length] = 43;
		choices[choices.length] = 43;
		choices[choices.length] = 43;
		choices[choices.length] = 43;
	}
	//44 - Bikini Mail Teases!
	if(player.hasVagina() && player.biggestTitSize() >= 4 && player.armorName == "lusty maiden's armor") {
		choices[choices.length] = 44;
		choices[choices.length] = 44;
		choices[choices.length] = 44;
		choices[choices.length] = 44;
		choices[choices.length] = 44;
		choices[choices.length] = 44;
		choices[choices.length] = 44;
		choices[choices.length] = 44;
		choices[choices.length] = 44;
		choices[choices.length] = 44;
		choices[choices.length] = 44;
		choices[choices.length] = 44;
		choices[choices.length] = 44;
		choices[choices.length] = 44;
		choices[choices.length] = 44;
	}
	//45 - Lethicite armor
	if (player.armor == armors.LTHCARM && player.upperGarment == UndergarmentLib.NOTHING && player.lowerGarment == UndergarmentLib.NOTHING) {
		choices[choices.length] = 45;
		choices[choices.length] = 45;
		choices[choices.length] = 45;
		choices[choices.length] = 45;
		choices[choices.length] = 45;
		choices[choices.length] = 45;
	}
	//=======================================================
	//    CHOOSE YOUR TEASE AND DISPLAY IT!
	//=======================================================
	select = choices[rand(choices.length)];
	if(monster.short.indexOf("minotaur") != -1) 
	{
		if(player.hasVagina() && player.lactationQ() >= 500 && player.biggestTitSize() >= 6 && player.cowScore() >= 3 && player.tailType == TAIL_TYPE_COW)
			select = 43;
	}
	//Lets do zis!
	switch(select) {
		//0 butt shake
		case 0:
			//Display
			outputText("You slap your " + buttDescript(), false);
			if(player.buttRating >= 10 && player.tone < 60) outputText(", making it jiggle delightfully.", false);
			else outputText(".", false);
			//Mod success
			ass = true;
			break;
		//1 BREAST JIGGLIN'
		case 1:
			//Single breast row
			if(player.breastRows.length == 1) {
				//50+ breastsize% success rate
				outputText("Your lift your top, exposing your " + breastDescript(0) + " to " + monster.a + monster.short + ".  You shake them from side to side enticingly.", false);
				if(player.lust >= 50) outputText("  Your " + nippleDescript(0) + "s seem to demand " + monster.pronoun3 + " attention.", false);
			}
			//Multirow
			if(player.breastRows.length > 1) {
				//50 + 10% per breastRow + breastSize%
				outputText("You lift your top, freeing your rows of " + breastDescript(0) + " to jiggle freely.  You shake them from side to side enticingly", false);
				if(player.lust >= 50) outputText(", your " + nippleDescript(0) + "s painfully visible.", false);
				else outputText(".", false);
				chance++;
			}
			breasts = true;
			break;
		//2 PUSSAH FLASHIN'
		case 2:
			if(player.isTaur()) {
				outputText("You gallop toward your unsuspecting enemy, dodging their defenses and knocking them to the ground.  Before they can recover, you slam your massive centaur ass down upon them, stopping just short of using crushing force to pin them underneath you.  In this position, your opponent's face is buried right in your girthy horsecunt.  You grind your cunt into " + monster.pronoun3 + " face for a moment before standing.  When you do, you're gratified to see your enemy covered in your lubricant and smelling powerfully of horsecunt.", false);
				chance += 2;
				damage += 4;
			}
			else {	
				outputText("You open your " + player.armorName + ", revealing your ", false);
				if(player.cocks.length > 0) {
					chance++;
					damage++;
					if(player.cocks.length == 1) outputText(player.cockDescript(0), false);
					if(player.cocks.length > 1) outputText(player.multiCockDescriptLight(), false);
					outputText(" and ", false);
					if(player.findPerk(PerkLib.BulgeArmor) >= 0) {
						damage += 5;
					}
					penis = true;
				}
				outputText(vaginaDescript(0), false);
				outputText(".", false);
			}
			vagina = true;
			break;
		//3 cock flash
		case 3:
			if(player.isTaur() && player.horseCocks() > 0) {
				outputText("You let out a bestial whinny and stomp your hooves at your enemy.  They prepare for an attack, but instead you kick your front hooves off the ground, revealing the hefty horsecock hanging beneath your belly.  You let it flop around, quickly getting rigid and to its full erect length.  You buck your hips as if you were fucking a mare in heat, letting your opponent know just what's in store for them if they surrender to pleasure...", false);
				if(player.findPerk(PerkLib.BulgeArmor) >= 0) damage += 5;
			}
			else {
				outputText("You open your " + player.armorName + ", revealing your ", false);
				if(player.cocks.length == 1) outputText(player.cockDescript(0), false);
				if(player.cocks.length > 1) outputText(player.multiCockDescriptLight(), false);
				if(player.hasVagina()) outputText(" and ", false);
				//Bulgy bonus!
				if(player.findPerk(PerkLib.BulgeArmor) >= 0) {
					damage += 5;
					chance++;
				}
				if(player.vaginas.length > 0) {
					outputText(vaginaDescript(0), false);
					vagina = true;
				}
				outputText(".", false);
			}
			penis = true;
			break;
		//BIMBO
		//4 butt shake
		case 4:
			outputText("You turn away and bounce your " + buttDescript() + " up and down hypnotically", false);
			//Big butts = extra text + higher success
			if(player.buttRating >= 10) {
				outputText(", making it jiggle delightfully.  " + monster.capitalA + monster.short + " even gets a few glimpses of the " + assholeDescript() + " between your cheeks.", false);
				chance += 3;
			}
			//Small butts = less damage, still high success
			else {
				outputText(", letting " + monster.a + monster.short + " get a good look at your " + assholeDescript() + " and " + vaginaDescript(0) + ".", false);
				chance += 1;
				vagina = true;
			}
			ass = true;
			anus = true;
			break;
		//5 breast jiggle
		case 5:
			outputText("You lean forward, letting the well-rounded curves of your " + allBreastsDescript() + " show to " + monster.a + monster.short + ".", false);
			outputText("  You cup them in your palms and lewdly bounce them, putting on a show and giggling the entire time.  An inch at a time, your " + player.armorName + " starts to come down, dropping tantalizingly slowly until your " + nippleDescript(0) + "s pop free.", false);
			if(player.lust >= 50) {
				if(player.hasFuckableNipples()) {
					chance++;
					outputText("  Clear slime leaks from them, making it quite clear that they're more than just nipples.", false);
				}
				else outputText("  Your hard nipples seem to demand " + monster.pronoun3 + " attention.", false);
				chance += 1;
				damage += 2;
			}
			//Damage boosts!
			breasts = true;
			break;
		//6 pussy flash
		case 6:
			if (player.findPerk(PerkLib.BimboBrains) >= 0 || player.findPerk(PerkLib.FutaFaculties) >= 0) {
				outputText("You coyly open your " + player.armorName + " and giggle, \"<i>Is this, like, what you wanted to see?</i>\"  ", false);
			}
			else {
				outputText("You coyly open your " + player.armorName + " and purr, \"<i>Does the thought of a hot, ", false);
				if(futa) outputText("futanari ", false);
				else if(player.findPerk(PerkLib.BimboBody) >= 0) outputText("bimbo ", false);
				else outputText("sexy ");
				outputText("body turn you on?</i>\"  ", false);
			}
			if(monster.plural) outputText(monster.capitalA + monster.short + "' gazes are riveted on your groin as you run your fingers up and down your folds seductively.", false);
			else outputText(monster.capitalA + monster.short + "'s gaze is riveted on your groin as you run your fingers up and down your folds seductively.", false);
			if(player.clitLength > 3) outputText("  You smile as your " + clitDescript() + " swells out from the folds and stands proudly, begging to be touched.", false);
			else outputText("  You smile and pull apart your lower-lips to expose your " + clitDescript() + ", giving the perfect view.", false);
			if(player.cockTotal() > 0) outputText("  Meanwhile, " + player.sMultiCockDesc() + " bobs back and forth with your gyrating hips, adding to the display.", false);
			//BONUSES!
			if(player.hasCock()) {
				if(player.findPerk(PerkLib.BulgeArmor) >= 0) damage += 5;
				penis = true;
			}
			vagina = true;
			break;
		//7 special Adjatha-crafted bend over bimbo times
		case 7:
			outputText("The glinting of light catches your eye and you whip around to inspect the glittering object, turning your back on " + monster.a + monster.short + ".  Locking your knees, you bend waaaaay over, " + chestDesc() + " swinging in the open air while your " + buttDescript() + " juts out at the " + monster.a + monster.short + ".  Your plump cheeks and " + hipDescript() + " form a jiggling heart-shape as you eagerly rub your thighs together.\n\n", false);
			outputText("The clear, warm fluid of your happy excitement trickles down from your loins, polishing your " + player.skin() + " to a glossy, inviting shine.  Retrieving the useless, though shiny, bauble, you hold your pose for just a moment longer, a sly little smile playing across your lips as you wiggle your cheeks one more time before straightening up and turning back around.", false);
			vagina = true;
			chance++;
			damage += 2;
			break;
		//==BRO STUFF=====
		//8 Pec Dance
		case 8:
			outputText("You place your hands on your hips and flex repeatedly, skillfully making your pecs alternatively bounce in a muscular dance.  ", false);
			if(player.findPerk(PerkLib.BroBrains) >= 0) outputText("Damn, " + monster.a + monster.short + " has got to love this!", false);
			else outputText(monster.capitalA + monster.short + " will probably enjoy the show, but you feel a bit silly doing this.", false);
			chance += (player.tone - 75)/5;
			damage += (player.tone - 70)/5;
			auto = false;
			break;
		//9 Heroic Pose
		case 9:
			outputText("You lift your arms and flex your incredibly muscular arms while flashing your most disarming smile.  ", false);
			if(player.findPerk(PerkLib.BroBrains) >= 0) outputText(monster.capitalA + monster.short + " can't resist such a heroic pose!", false);
			else outputText("At least the physical changes to your body are proving useful!", false);
			chance += (player.tone - 75)/5;
			damage += (player.tone - 70)/5;
			auto = false;
			break;
		//10 Bulgy groin thrust
		case 10:
			outputText("You lean back and pump your hips at " + monster.a + monster.short + " in an incredibly vulgar display.  The bulging, barely-contained outline of your " + player.cockDescript(0) + " presses hard into your gear.  ", false);
			if(player.findPerk(PerkLib.BroBrains) >= 0) outputText("No way could " + monster.pronoun1 + " resist your huge cock!", false);
			else outputText("This is so crude, but at the same time, you know it'll likely be effective.", false);
			outputText("  You go on like that, humping the air for your foe", false);
			outputText("'s", false);
			outputText(" benefit, trying to entice them with your man-meat.", false);
			if(player.findPerk(PerkLib.BulgeArmor) >= 0) damage += 5;
			penis = true;
			break;
		//11 Show off dick
		case 11:
			if(silly() && rand(2) == 0) outputText("You strike a herculean pose and flex, whispering, \"<i>Do you even lift?</i>\" to " + monster.a + monster.short + ".", false);
			else {
				outputText("You open your " + player.armorName + " just enough to let your " + player.cockDescript(0) + " and " + ballsDescriptLight() + " dangle free.  A shiny rope of pre-cum dangles from your cock, showing that your reproductive system is every bit as fit as the rest of you.  ", false);
				if(player.findPerk(PerkLib.BroBrains) >= 0) outputText("Bitches love a cum-leaking cock.", false);
				else outputText("You've got to admit, you look pretty good down there.", false);
			}
			if(player.findPerk(PerkLib.BulgeArmor) >= 0) damage += 5;
			penis = true;
			break;
		//==EXTRAS========
		//12 Cat flexibility.
		case 12:
			//CAT TEASE MOTHERFUCK (requires flexibility and legs [maybe can't do it with armor?])
			outputText("Reaching down, you grab an ankle and pull it backwards, looping it up and over to touch the foot to your " + hairDescript() + ".  You bring the leg out to the side, showing off your " + vaginaDescript(0) + " through your " + player.armorName + ".  The combination of the lack of discomfort on your face and the ease of which you're able to pose shows " + monster.a + monster.short + " how good of a time they're in for with you.", false);
			vagina = true;
			if(player.thickness < 33) chance++;
			else if(player.thickness >= 66) chance--;
			damage += (player.thickness - 50)/10;
			break;
		//13 Pregnant
		case 13:
			//PREG
			outputText("You lean back, feigning a swoon while pressing a hand on the small of your back.  The pose juts your huge, pregnant belly forward and makes the shiny spherical stomach look even bigger.  With a teasing groan, you rub the protruding tummy gently, biting your lip gently as you stare at " + monster.a + monster.short + " through heavily lidded eyes.  \"<i>All of this estrogen is making me frisky,</i>\" you moan, stroking hand gradually shifting to the southern hemisphere of your big baby-bump.", false);
			//if lactating] 
			if(player.biggestLactation() >= 1) {
				outputText("  Your other hand moves to expose your " + chestDesc() + ", cupping and squeezing a stream of milk to leak down the front of your " + player.armorName + ".  \"<i>Help a mommy out.</i>\"\n\n", false);
				chance += 2;
				damage += 4;
			}
			if(player.pregnancyIncubation < 100) {
				chance++;
				damage += 2;
			}
			if(player.pregnancyIncubation < 50) {
				chance++;
				damage += 2;
			}
			break;
		//14 Brood Mother
		case 14:
			if(rand(2) == 0) outputText("You tear open your " + player.armorName + " and slip a few fingers into your well-used birth canal, giving your opponent a good look at what they're missing.  \"<i>C'mon stud,</i>\" you say, voice dripping with lust and desire, \"<i>Come to mama " + player.short + " and fuck my pussy 'til your baby batter just POURS out.  I want your children inside of me, I want your spawn crawling out of this cunt and begging for my milk.  Come on, FUCK ME PREGNANT!</i>\"", false);
			else outputText("You wiggle your " + hipDescript() + " at your enemy, giving them a long, tantalizing look at the hips that have passed so very many offspring.  \"<i>Oh, like what you see, bad boy?  Well why don't you just come on over and stuff that cock inside me?  Give me your seed, and I'll give you suuuuch beautiful offspring.  Oh?  Does that turn you on?  It does!  Come on, just let loose and fuck me full of your babies!</i>\"", false);
			chance += 2;
			damage += 4;
			if(player.inHeat) {
				chance += 2;
				damage += 4;
			}
			vagina = true;
			break;
		//15 Nipplecunts
		case 15:
			//Req's tits & Pussy
			if(player.biggestTitSize() > 1 && player.hasVagina() && rand(2) == 0) {
				outputText("Closing your eyes, you lean forward and slip a hand under your " + player.armorName + ".  You let out the slightest of gasps as your fingers find your drooling honeypot, warm tips poking, one after another between your engorged lips.  When you withdraw your hand, your fingers have been soaked in the dripping passion of your cunny, translucent beads rolling down to wet your palm.  With your other hand, you pull down the top of your " + player.armorName + " and bare your " + chestDesc() + " to " + monster.a + monster.short + ".\n\n", false);
				outputText("Drawing your lust-slick hand to your " + nippleDescript(0) + "s, the yielding flesh of your cunt-like nipples parts before the teasing digits.  Using your own girl cum as added lubrication, you pump your fingers in and out of your nipples, moaning as you add progressively more digits until only your thumb remains to stroke the inflamed flesh of your over-stimulated chest.  Your throat releases the faintest squeak of your near-orgasmic delight and you pant, withdrawing your hands and readjusting your armor.\n\n", false);
				outputText("Despite how quiet you were, it's clear that every lewd, desperate noise you made was heard by " + monster.a + monster.short + ".", false);
				chance += 2;
				damage += 4;
			}
			else if(player.biggestTitSize() > 1 && rand(2) == 0) {
				outputText("You yank off the top of your " + player.armorName + ", revealing your " + chestDesc() + " and the gaping nipplecunts on each.  With a lusty smirk, you slip a pair of fingers into the nipples of your " + chestDesc() + ", pulling the nipplecunt lips wide, revealing the lengthy, tight passage within.  You fingerfuck your nipplecunts, giving your enemy a good show before pulling your armor back on, leaving the tantalizing image of your gaping titpussies to linger in your foe's mind.", false);
				chance += 1;
				damage += 2;
			}
			else outputText("You remove the front of your " + player.armorName + " exposing your " + chestDesc() + ".  Using both of your hands, you thrust two fingers into your nipple cunts, milky girl cum soaking your hands and fingers.  \"<i>Wouldn't you like to try out these holes too?</i>\"", false);
			breasts = true;
			break;
		//16 Anal gape
		case 16:
			outputText("You quickly strip out of your " + player.armorName + " and turn around, giving your " + buttDescript() + " a hard slap and showing your enemy the real prize: your " + assholeDescript() + ".  With a smirk, you easily plunge your hand inside, burying yourself up to the wrist inside your anus.  You give yourself a quick fisting, watching the enemy over your shoulder while you moan lustily, sure to give them a good show.  You withdraw your hand and give your ass another sexy spank before readying for combat again.", false);
			anus = true;
			ass = true;
			break;
		//17 Bee abdomen tease
		case 17:
			outputText("You swing around, shedding the " + player.armorName + " around your waist to expose your " + buttDescript() + " to " + monster.a + monster.short + ".  Taking up your oversized bee abdomen in both hands, you heft the thing and wave it about teasingly.  Drops of venom drip to and fro, a few coming dangerously close to " + monster.pronoun2 + ".  \"<i>Maybe if you behave well enough, I'll even drop a few eggs into your belly,</i>\" you say softly, dropping the abdomen back to dangle above your butt and redressing.", false);
			ass = true;
			chance += .5;
			damage += .5;
			break;			
		//18 DOG TEASE
		case 18:
			outputText("You sit down like a dog, your [legs] are spread apart, showing your ", false);
			if(player.hasVagina()) outputText("parted cunt-lips", false);
			else outputText("puckered asshole, hanging, erect maleness,", false);
			outputText(" and your hands on the ground in front of you.  You pant heavily with your tongue out and promise, \"<i>I'll be a good little bitch for you</i>.\"", false);
			vagina = true;
			chance += 1;
			damage += 2;
			break;
		//19 MAX FEM TEASE - SYMPHONIE
		case 19:
			outputText("You make sure to capture your foe's attention, then slowly and methodically allow your tongue to slide along your lush, full lips.  The glistening moisture that remains on their plump beauty speaks of deep lust and deeper throats.  Batting your long lashes a few times, you pucker them into a playful blown kiss, punctuating the act with a small moan. Your gorgeous feminine features hint at exciting, passionate moments together, able to excite others with just your face alone.", false);
			chance += 2;
			damage += 4;
			break;
		//20 MAX MASC TEASE
		case 20:
			outputText("As your foe regards you, you recognize their attention is fixated on your upper body.  Thrusting your strong jaw forward you show off your chiseled chin, handsome features marking you as a flawless specimen.  Rolling your broad shoulders, you nod your head at your enemy.  The strong, commanding presence you give off could melt the heart of an icy nun.  Your perfect masculinity speaks to your confidence, allowing you to excite others with just your face alone.", false);
			chance += 2;
			damage += 4;
			break;
		//21 MAX ADROGYN
		case 21:
			outputText("You reach up and run your hands down your delicate, androgynous features.  With the power of a man but the delicacy of a woman, looking into your eyes invites an air of enticing mystery.  You blow a brief kiss to your enemy while at the same time radiating a sexually exciting confidence.  No one could identify your gender by looking at your features, and the burning curiosity they encourage could excite others with just your face alone.", false);
			damage -= 3;
			break;
		//22 SPOIDAH SILK
		case 22:
			outputText("Reaching back, you milk some wet silk from your spider-y abdomen and present it to " + monster.a + monster.short + ", molding the sticky substance as " + monster.pronoun1 + " looks on curiously.  Within moments, you hold up a silken heart scuplture, and with a wink, you toss it at " + monster.pronoun2 + ". It sticks to " + monster.pronoun3 + " body, the sensation causing " + monster.pronoun2 + " to hastily slap the heart off.  " + monster.mf("He","She") + " returns " + monster.pronoun3 + " gaze to you to find you turned around, " + buttDescript() + " bared and abdomen bouncing lazily.  \"<i>I wonder what would happen if I webbed up your hole after I dropped some eggs inside?</i>\" you hiss mischievously.  " + monster.mf("He","She") + " gulps.", false);
			ass = true;
			break;
		//23 RUT TEASE
		case 23:
			if(player.horseCocks() > 0 && player.longestHorseCockLength() >= 12) {
				outputText("You whip out your massive horsecock, and are immediately surrounded by a massive, heady musk.  Your enemy swoons, nearly falling to her knees under your oderous assault.  Grinning, you grab her shoulders and force her to her knees.  Before she can defend herself, you slam your horsecock onto her head, running it up and down on her face, her nose acting like a sexy bump in an onahole.  You fuck her face -- literally -- for a moment before throwing her back and sheathing your cock.", false);
			}
			else {
				outputText("Panting with your unstoppable lust for the delicious, impregnable cunt before you, you yank off your " + player.armorName + " with strength born of your inhuman rut, and quickly wave your fully erect cock at your enemy.  She flashes with lust, quickly feeling the heady effect of your man-musk.  You rush up, taking advantage of her aroused state and grab her shoulders.  ", false);
				outputText("Before she can react, you push her down until she's level with your cock, and start to spin it in a circle, slapping her right in the face with your musky man-meat.  Her eyes swim, trying to follow your meatspin as you swat her in the face with your cock!  Satisfied, you release her and prepare to fight!", false);
			}
			penis = true;
			break;
		//24 STAFF POLEDANCE
		case 24:
			outputText("You run your tongue across your lips as you plant your staff into the ground.  Before your enemy can react, you spin onto the long, wooden shaft, using it like an impromptu pole.  You lean back against the planted staff, giving your enemy a good look at your body.  You stretch backwards like a cat, nearly touching your fingertips to the ground beneath you, now holding onto the staff with only one leg.  You pull yourself upright and give your " + buttDescript() + " a little slap and your " + chestDesc() + " a wiggle before pulling open your " + player.armorName + " and sliding the pole between your tits.  You drop down to a low crouch, only just covering your genitals with your hand as you shake your " + buttDescript() + " playfully.  You give the enemy a little smirk as you slip your " + player.armorName + " back on and pick up your staff.", false);
			ass = true;
			breasts = true;
			break;
		//TALL WOMAN TEASE
		case 25:
			outputText("You move close to your enemy, handily stepping over " + monster.pronoun3 + " defensive strike before leaning right down in " + monster.pronoun3 + " face, giving " + monster.pronoun2 + " a good long view at your cleavage.  \"<i>Hey, there, little " + monster.mf("guy","girl") + ",</i>\" you smile.  Before " + monster.pronoun1 + " can react, you grab " + monster.pronoun2 + " and smoosh " + monster.pronoun3 + " face into your " + player.allChestDesc() + ", nearly choking " + monster.pronoun2 + " in the canyon of your cleavage.  " + monster.mf("He","She") + " struggles for a moment.  You give " + monster.pronoun2 + " a little kiss on the head and step back, ready for combat.", false);
			breasts = true;
			chance += 2;
			damage += 4;
			break;
		//Magic Tease
		case 26:
			outputText("Seeing a lull in the battle, you plant your " + player.weaponName + " on the ground and let your magic flow through you.  You summon a trickle of magic into a thick, slowly growing black ball of lust.  You wave the ball in front of you, making a little dance and striptease out of the affair as you slowly saturate the area with latent sexual magics.", false);
			chance++;
			damage += 2;
			break;
		//Feeder
		case 27:
			outputText("You present your swollen breasts full of milk to " + monster.a + monster.short + " and say \"<i>Wouldn't you just love to lie back in my arms and enjoy what I have to offer you?</i>\"", false);
			breasts = true;
			chance ++;
			damage++;
			break;
		//28 FEMALE TEACHER COSTUME TEASE
		case 28:
			outputText("You turn to the side and give " + monster.a + monster.short + " a full view of your body.  You ask them if they're in need of a private lesson in lovemaking after class.", false);
			ass = true;
			break;
		//29 Male Teacher Outfit Tease
		case 29:
			outputText("You play with the strings on your outfit a bit and ask " + monster.a + monster.short + " just how much do they want to see their teacher pull them off?", false);
			chance++;
			damage += 3;
			break;
		//30 Naga Fetish Clothes
		case 30:
			outputText("You sway your body back and forth, and do an erotic dance for " + monster.a + monster.short + ".", false);
			chance += 2;
			damage += 4;
			break;
		//31 Centaur harness clothes
		case 31:
			outputText("You rear back, and declare that, \"<i>This horse is ready to ride, all night long!</i>\"", false);
			chance += 2;
			damage += 4;
			break;
		//32 Genderless servant clothes
		case 32:
			outputText("You turn your back to your foe, and flip up your butt flap for a moment.   Your " + buttDescript() + " really is all you have to offer downstairs.", false);
			ass = true;
			chance++;
			damage += 2;
			break;
		//33 Crotch Revealing Clothes (herm only?)
		case 33:
			outputText("You do a series of poses to accentuate what you've got on display with your crotch revealing clothes, while asking if your " + player.mf("master","mistress") + " is looking to sample what is on display.", false);
			chance += 2;
			damage += 4;
			break;
		//34 Maid Costume (female only)
		case 34:
			outputText("You give a rather explicit curtsey towards " + monster.a + monster.short + " and ask them if your " + player.mf("master","mistress") + " is interested in other services today.", false);
			chance ++;
			damage += 2;
			breasts = true;
			break;
		//35 Servant Boy Clothes (male only)
		case 35:
			outputText("You brush aside your crotch flap for a moment, then ask " + monster.a + monster.short + " if, " + player.mf("Master","Mistress") + " would like you to use your " + player.multiCockDescriptLight() + " on them?", false);
			penis = true;
			chance++;
			damage += 2;
			break;
		//36 Bondage Patient Clothes (done):
		case 36:
			outputText("You pull back one of the straps on your bondage cloths and let it snap back.  \"<i>I need some medical care, feeling up for it?</i>\" you tease.", false);
			damage+= 2;
			chance++;
			break;
		default:
			outputText("You shimmy and shake sensually. (An error occurred.)", false);
			break;
		case 37:
			outputText("You purse your lips coyly, narrowing your eyes mischievously and beckoning to " + monster.a + monster.short + " with a burning come-hither glare.  Sauntering forward, you pop your hip to the side and strike a coquettish pose, running " + ((player.tailVenom > 1) ? "one of your tails" : "your tail") + " up and down " + monster.pronoun3 + " body sensually.");
			chance+= 6;
			damage+= 3;
			break;
		case 38:
			outputText( "You wet your lips, narrowing your eyes into a smoldering, hungry gaze.  Licking the tip of your index finger, you trail it slowly and sensually down the front of your " + player.armorName + ", following the line of your " + chestDesc() + " teasingly.  You hook your thumbs into your top and shimmy it downward at an agonizingly slow pace.  The very instant that your [nipples] pop free, your tail crosses in front, obscuring " + monster.a + monster.short + "'s view.");
			breasts = true;
			chance++;
			damage++;
			break;
		case 39:
			outputText( "Leaning forward, you bow down low, raising a hand up to your lips and blowing " + monster.a + monster.short + " a kiss.  You stand straight, wiggling your " + hipDescript() + " back and forth seductively while trailing your fingers down your front slowly, pouting demurely.  The tip of ");
			if(player.tailVenom == 1) outputText("your");
			else outputText("a");
			outputText(" bushy tail curls up around your " + player.leg() + ", uncoiling with a whipping motion that makes an audible crack in the air.");
			ass = true;
			chance++;
			damage += 1;
			break;
		case 40:
			outputText("Turning around, you stare demurely over your shoulder at " + monster.a + monster.short + ", batting your eyelashes amorously.");
			if(player.tailVenom == 1) outputText("  Your tail twists and whips about, sliding around your " + hipDescript() + " in a slow arc and framing your rear nicely as you slowly lift your " + player.armorName + ".");
			else outputText("  Your tails fan out, twisting and whipping sensually, sliding up and down your " + player.legs() + " and framing your rear nicely as you slowly lift your " + player.armorName + ".");
			outputText("  As your [butt] comes into view, you brush your tail" + ((player.tailVenom > 1) ? "s" : "" ) + " across it, partially obscuring the view in a tantalizingly teasing display.");
			ass = true;
			anus = true;
			chance++;
			damage += 2;
			break;
		case 41:
			outputText( "Smirking coyly, you sway from side to side, running your tongue along your upper teeth seductively.  You hook your thumbs into your " + player.armorName + " and pull them away to partially reveal ");
			if(player.cockTotal() > 0) outputText(player.sMultiCockDesc());
			if(player.gender == 3) outputText(" and ");
			if(player.gender >= 2) outputText("your " + vaginaDescript(0));
			outputText(".  Your bushy tail" + ((player.tailVenom > 1) ? "s" : "" ) + " cross" + ((player.tailVenom > 1) ? "": "es") + " in front, wrapping around your genitals and obscuring the view teasingly.");
			vagina = true;
			penis = true;
			damage += 2;
			chance++;
			break;
		case 42:
			//Tease #1:
			if(rand(2) == 0) {
				outputText("You lift your skirt and flash your king-sized stallionhood, already unsheathing itself and drooling pre, at your opponent.  \"<i>Come on, then; I got plenty of girlcock for you if that's what you want!</i>\" you cry.");
				penis = true;
				damage += 3;
				chance--;
			}
			//Tease #2:
			else {
				outputText("You turn partially around and then bend over, swaying your tail from side to side in your most flirtatious manner and wiggling your hips seductively, your skirt fluttering with the motions.  \"<i>Come on then, what are you waiting for?  This is a fine piece of ass here,</i>\" you grin, spanking yourself with an audible slap.");
				ass = true;
				chance+= 2;
				damage += 3;
			}
			break;
		case 43:
			var cows:int = rand(7);
			if(cows == 0) {
				outputText("You tuck your hands under your chin and use your arms to squeeze your massive, heavy breasts together.  Milk squirts from your erect nipples, filling the air with a rich, sweet scent.");
				breasts = true;
				chance += 2;
				damage++;
			}
			else if(cows == 1) {
				outputText("Moaning, you bend forward, your full breasts nearly touching the ground as you sway your [hips] from side to side.  Looking up from under heavily-lidded eyes, you part your lips and lick them, letting out a low, lustful \"<i>Mooooo...</i>\"");
				breasts = true;
				chance += 2;
				damage += 2;
			}
			else if(cows == 2) {
				outputText("You tuck a finger to your lips, blinking innocently, then flick your tail, wafting the scent of your ");
				if(player.wetness() >= 3) outputText("dripping ");
				outputText("sex through the air.");
				vagina = true;
				chance++;
				damage++;
			}
			else if(cows == 3) {
				outputText("You heft your breasts, fingers splayed across your [nipples] as you SQUEEZE.  Milk runs in rivulets over your hands and down the massive curves of your breasts, soaking your front with sweet, sticky milk.");
				breasts = true;
				chance += 3;
				damage++;
			}
			else if(cows == 4) {
				outputText("You lift a massive breast to your mouth, suckling loudly at yourself, finally letting go of your nipple with a POP and a loud, satisfied gasp, milk running down your chin.");
				breasts = true;
				chance++;
				damage += 3;
			}
			else if(cows == 5) {
				outputText("You crouch low, letting your breasts dangle in front of you.  Each hand caresses one in turn as you slowly milk yourself onto your thighs, splashing white, creamy milk over your hips and sex.");
				vagina = true;
				breasts = true;
				chance++;
			}
			else {
				outputText("You lift a breast to your mouth, taking a deep draught of your own milk, then tilt your head back.  With a low moan, you let it run down your front, winding a path between your breasts until it drips sweetly from your crotch.");
				vagina = true;
				breasts = true;
				damage += 2;
			}
			if(monster.short.indexOf("minotaur") != -1) {
				damage += 6;
				chance += 3;
			}
			break;
		//lusty maiden's armor teases
		case 44:
			var maiden:int = rand(5);
			damage += 5;
			chance += 3;
			if(maiden == 0) {
				outputText("Confidently sauntering forward, you thrust your chest out with your back arched in order to enhance your [chest].  You slowly begin to shake your torso back and forth, slapping your chain-clad breasts against each other again and again.  One of your hands finds its way to one of the pillowy expanses and grabs hold, fingers sinking into the soft tit through the fine, mail covering.  You stop your shaking to trace a finger down through the exposed center of your cleavage, asking, \"<i>Don't you just want to snuggle inside?</i>\"");
				breasts = true;
			}
			else if(maiden == 1) {
				outputText("You skip up to " + monster.a + monster.short + " and spin around to rub your barely-covered butt up against " + monster.pronoun2 + ".  Before " + monster.pronoun1 + " can react, you're slowly bouncing your [butt] up and down against " + monster.pronoun3 + " groin.  When " + monster.pronoun1 + " reaches down, you grab " + monster.pronoun3 + " hand and press it up, under your skirt, right against the steamy seal on your sex.  The simmering heat of your overwhelming lust burns hot enough for " + monster.pronoun2 + " to feel even through the contoured leather, and you let " + monster.pronoun2 + " trace the inside of your [leg] for a moment before moving away, laughing playfully.");
				ass = true;
				vagina = true;
			}
			else if(maiden == 2) {
				outputText("You flip up the barely-modest chain you call a skirt and expose your g-string to " +  monster.a + monster.short + ".  Slowly swaying your [hips], you press a finger down on the creased crotch plate and exaggerate a lascivious moan into a throaty purr of enticing, sexual bliss.  Your eyes meet " + monster.pronoun3 + ", and you throatily whisper, \"<i>");
				if(player.hasVirginVagina()) outputText("Think you can handle a virgin's infinite lust?");
				else outputText("Think you have what it takes to satisfy this perfect pussy?");
				outputText("</i>\"");
				vagina = true;
				damage += 3;
			}
			else if(maiden == 3) {
				outputText("You seductively wiggle your way up to " + monster.a + monster.short + ", and before " + monster.pronoun1 + " can react to your salacious advance, you snap a [leg] up in what would be a vicious kick, if you weren't simply raising it to rest your [foot] on " + monster.pronoun3 + " shoulder.  With your thighs so perfectly spready, your skirt is lifted, and " + monster.a + monster.short + " is given a perfect view of your thong-enhanced cameltoe and the moisture that beads at the edges of your not-so-modest covering.");
				vagina = true;
			}
			else {
				outputText("Bending over, you lift your [butt] high in the air.  Most of your barely-covered tush is exposed, but the hem of your chainmail skirt still protects some of your anal modesty.  That doesn't last long.  You start shaking your [butt] up, down, back, and forth to an unheard rhythm, flipping the pointless covering out of the way so that " + monster.a + monster.short + " can gaze upon your curvy behind in it all its splendid detail.  A part of you hopes that " + monster.pronoun1 + " takes in the intricate filigree on the back of your thong, though to " + monster.pronoun2 + " it looks like a bunch of glittering arrows on an alabaster background, all pointing squarely at your [asshole].");
				ass = true;
				chance += 2;
			}
			break;
		//lethicite armor teases
		case 45:
			var partChooser:Array = []; //Array for choosing.
			//Choose part. Must not be a centaur for cock and vagina teases!
			partChooser[partChooser.length] = 0;
			if (player.gender == 1 && !player.isTaur()) partChooser[partChooser.length] = 1;
			if (player.gender == 2 && !player.isTaur()) partChooser[partChooser.length] = 2;
			if (player.gender == 3 && player.hasVagina() && !player.isTaur()) partChooser[partChooser.length] = 3;
			//Let's do this!
			switch(partChooser[rand(partChooser.length)]) {
				case 0:
					outputText("You place your hand on your lethicite-covered belly, move your hand up across your belly and towards your [chest]. Taking advantage of the small openings in your breastplate, you pinch and tweak your exposed [nipples].");
					breasts = true;
					chance += 3;
					damage += 1;
					break;
				case 1:
					outputText("You move your hand towards your [cocks], unobstructed by the lethicite. You give your [cock] a good stroke and sway your hips back and forth, emphasizing your manhood.");
					penis = true;
					chance += 1;
					damage += 2;
					break;
				case 2:
					outputText("You move your hand towards your [pussy], unobstructed by the lethicite. You give your [clit] a good tease, finger your [pussy], and sway your hips back and forth, emphasizing your womanhood.");
					vagina = true;
					chance += 1;
					damage += 2;
					break;
				case 3:
					outputText("You move your hand towards your [cocks] and [pussy], unobstructed by the lethicite. You give your [cock] a good stroke, tease your [clit], and sway your hips back and forth, emphasizing your hermaphroditic gender.");
					penis = true;
					vagina = true;
					chance += 1;
					damage += 3;
					break;
				default:
					outputText("Whoops, something derped! Please let Kitteh6660 know! Anyways, you put on a tease show.");
			}
			
			break;
	}
	//===========================
	//BUILD BONUSES IF APPLICABLE
	//===========================	
	var bonusChance:Number = 0;
	var bonusDamage:Number = 0;
	if(auto) {
		//TIT BONUSES
		if(breasts) {
			if(player.bRows() > 1) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.bRows() > 2) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.bRows() > 4) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.biggestLactation() >= 2) {
				bonusChance++;
				bonusDamage += 2;
			}
			if(player.biggestLactation() >= 3) {
				bonusChance++;
				bonusDamage += 2;
			}
			if(player.biggestTitSize() >= 4) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.biggestTitSize() >= 7) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.biggestTitSize() >= 12) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.biggestTitSize() >= 25) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.biggestTitSize() >= 50) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.hasFuckableNipples()) {
				bonusChance++;
				bonusDamage += 2;
			}
			if(player.averageNipplesPerBreast() > 1) {
				bonusChance++;
				bonusDamage += 2;
			}
		}
		//PUSSY BONUSES
		if(vagina) {
			if(player.hasVagina() && player.wetness() >= 2) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.hasVagina() && player.wetness() >= 3) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.hasVagina() && player.wetness() >= 4) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.hasVagina() && player.wetness() >= 5) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.clitLength > 1.5) {
				bonusChance += .5;
				bonusDamage++;
			}
			if(player.clitLength > 3.5) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.clitLength > 7) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.clitLength > 12) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.vaginalCapacity() >= 30) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.vaginalCapacity() >= 70) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.vaginalCapacity() >= 120) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.vaginalCapacity() >= 200) {
				bonusChance += .5;
				bonusDamage += 1;
			}
		}
		//Penis bonuses!
		if(penis) {
			if(player.cockTotal() > 1) {
				bonusChance += 1;
				bonusDamage += 2;
			}
			if(player.biggestCockArea() >= 15) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.biggestCockArea() >= 30) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.biggestCockArea() >= 60) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.biggestCockArea() >= 120) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.cumQ() >= 50) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.cumQ() >= 150) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.cumQ() >= 300) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.cumQ() >= 1000) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(balls > 0) {
				if(player.balls > 2) {
					bonusChance += 1;
					bonusDamage += 2;
				}
				if(player.ballSize > 3) {
					bonusChance += .5;
					bonusDamage += 1;
				}
				if(player.ballSize > 7) {
					bonusChance += .5;
					bonusDamage += 1;
				}
				if(player.ballSize > 12) {
					bonusChance += .5;
					bonusDamage += 1;
				}
			}
			if(player.biggestCockArea() < 8) {
				bonusChance--;
				bonusDamage-=2;
				if(player.biggestCockArea() < 5) {
					bonusChance--;
					bonusDamage-=2;
				}
			}
		}
		if(ass) {
			if(player.buttRating >= 6) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.buttRating >= 10) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.buttRating >= 13) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.buttRating >= 16) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.buttRating >= 20) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.hipRating >= 6) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.hipRating >= 10) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.hipRating >= 13) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.hipRating >= 16) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.hipRating >= 20) {
				bonusChance += .5;
				bonusDamage += 1;
			}
		}
		if(anus) {
			if(player.ass.analLooseness == 0) {
				bonusChance += 1.5;
				bonusDamage += 3;
			}
			if(player.ass.analWetness > 0) {
				bonusChance += 1;
				bonusDamage += 2;
			}
			if(player.analCapacity() >= 30) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.analCapacity() >= 70) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.analCapacity() >= 120) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.analCapacity() >= 200) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.ass.analLooseness == 4) {
				bonusChance += .5;
				bonusDamage += 1;
			}
			if(player.ass.analLooseness == 5) {
				bonusChance += 1.5;
				bonusDamage += 3;
			}
		}
		//Trim it down!
		if(bonusChance > 5) bonusChance = 5;
		if(bonusDamage > 10) bonusDamage = 10;
	}
	//Land the hit!
	if(rand(100) <= chance + rand(bonusChance)) {
		//NERF TEASE DAMAGE
		damage *= .7;
		bonusDamage *= .7;
		if(player.findPerk(PerkLib.HistoryWhore) >= 0) {
			damage *= 1.15;
			bonusDamage *= 1.15;
		}
		if (player.findPerk(PerkLib.ChiReflowLust) >= 0) damage *= UmasShop.NEEDLEWORK_LUST_TEASE_DAMAGE_MULTI;
		if(monster.plural) damage *= 1.3;
		damage = (damage + rand(bonusDamage)) * monster.lustVuln;
		
		if (monster is JeanClaude) (monster as JeanClaude).handleTease(damage, true);
		else if (monster is Doppleganger && monster.findStatusAffect(StatusAffects.Stunned) < 0) (monster as Doppleganger).mirrorTease(damage, true);
		else if (!justText) monster.teased(damage);
		
		if (flags[kFLAGS.PC_FETISH] >= 1 && !urtaQuest.isUrta()) 
		{
			if(player.lust < 75) outputText("\nFlaunting your body in such a way gets you a little hot and bothered.", false);
			else outputText("\nIf you keep exposing yourself you're going to get too horny to fight back.  This exhibitionism fetish makes it hard to resist just stripping naked and giving up.", false);
			if (!justText) dynStats("lus", 2 + rand(3));
		}
		
		// Similar to fetish check, only add XP if the player IS the player...
		if (!justText && !urtaQuest.isUrta()) teaseXP(1);
	}
	//Nuttin honey
	else {
		if (!justText && !urtaQuest.isUrta()) teaseXP(5);
		
		if (monster is JeanClaude) (monster as JeanClaude).handleTease(0, false);
		else if (monster is Doppleganger) (monster as Doppleganger).mirrorTease(0, false);
		else if (!justText) outputText("\n" + monster.capitalA + monster.short + " seems unimpressed.", false);
	}
	outputText("\n\n", false);
}

public function teaseXP(XP:Number = 0):void {
	while(XP > 0) {
		XP--;
		player.teaseXP++;
		//Level dat shit up!
		if(player.teaseLevel < 5 && player.teaseXP >= 10 + (player.teaseLevel + 1) * 5 * (player.teaseLevel + 1)) {
			outputText("\n<b>Tease skill leveled up to " + (player.teaseLevel + 1) + "!</b>", false);
			player.teaseLevel++;
			player.teaseXP = 0;
		}
	}
}

//VICTORY OR DEATH?
public function combatRoundOver():Boolean { //Called after the monster's action
	combatRound++;
	statScreenRefresh();
	flags[kFLAGS.ENEMY_CRITICAL] = 0;
	if (!inCombat) return false;
	if(monster.HP < 1) {
		doNext(endHpVictory);
		return true;
	}
	if(monster.lust > (eMaxLust - 1)) {
		doNext(endLustVictory);
		return true;
	}
	if(monster.findStatusAffect(StatusAffects.Level) >= 0) {
		if((monster as SandTrap).trapLevel() <= 1) {
			desert.sandTrapScene.sandtrapmentLoss();
			return true;
		}
	}
	if(monster.short == "basilisk" && player.spe <= 1) {
		doNext(endHpLoss);
		return true;
	}
	if(player.HP < 1) {
		doNext(endHpLoss);
		return true;
	}
	if(player.lust >= player.maxLust()) {
		doNext(endLustLoss);
		return true;
	}
	doNext(playerMenu); //This takes us back to the combatMenu and a new combat round
	return false;
}

public function hasSpells():Boolean {
	return player.hasSpells();
}
public function spellCount():Number {
	return player.spellCount();
}
public function getWhiteMagicLustCap():Number {
	var whiteLustCap:int = player.maxLust() * 0.75;
	if (player.findPerk(PerkLib.Enlightened) >= 0 && player.cor < (10 + player.corruptionTolerance())) whiteLustCap += (player.maxLust() * 0.1);
	if (player.findPerk(PerkLib.FocusedMind) >= 0) whiteLustCap += (player.maxLust() * 0.1);
	return whiteLustCap;
}

public function magicMenu():void {
//Pass false to combatMenu instead:	menuLoc = 3;
	if (inCombat && player.findStatusAffect(StatusAffects.Sealed) >= 0 && player.statusAffectv2(StatusAffects.Sealed) == 2) {
		clearOutput();
		outputText("You reach for your magic, but you just can't manage the focus necessary.  <b>Your ability to use magic was sealed, and now you've wasted a chance to attack!</b>\n\n");
		enemyAI();
		return;
	}
	menu();
	clearOutput();
	outputText("What spell will you use?\n\n");
	//WHITE SHITZ
	var whiteLustCap:int = getWhiteMagicLustCap();
	
	if (player.lust >= whiteLustCap)
		outputText("You are far too aroused to focus on white magic.\n\n");
	else {
		if (player.findStatusAffect(StatusAffects.KnowsCharge) >= 0) {
			if (player.findStatusAffect(StatusAffects.ChargeWeapon) < 0)
				addButton(0, "Charge W.", spellChargeWeapon, null, null, null, "The Charge Weapon spell will surround your weapon in electrical energy, causing it to do even more damage.  The effect lasts for the entire combat.  \n\nFatigue Cost: " + spellCost(15) + "", "Charge Weapon");
			else outputText("<b>Charge weapon is already active and cannot be cast again.</b>\n\n");
		}
		if (player.findStatusAffect(StatusAffects.KnowsBlind) >= 0) {
			if (monster.findStatusAffect(StatusAffects.Blind) < 0)
				addButton(1, "Blind", spellBlind, null, null, null, "Blind is a fairly self-explanatory spell.  It will create a bright flash just in front of the victim's eyes, blinding them for a time.  However if they blink it will be wasted.  \n\nFatigue Cost: " + spellCost(20) + "");
			else outputText("<b>" + monster.capitalA + monster.short + " is already affected by blind.</b>\n\n");
		}
		if (player.findStatusAffect(StatusAffects.KnowsWhitefire) >= 0) addButton(2, "Whitefire", spellWhitefire, null, null, null, "Whitefire is a potent fire based attack that will burn your foe with flickering white flames, ignoring their physical toughness and most armors.  \n\nFatigue Cost: " + spellCost(30) + "");
	}
	//BLACK MAGICSKS
	if (player.lust < 50)
		outputText("You aren't turned on enough to use any black magics.\n\n");
	else {
		if (player.findStatusAffect(StatusAffects.KnowsArouse) >= 0) addButton(5, "Arouse", spellArouse, null, null, null, "The arouse spell draws on your own inner lust in order to enflame the enemy's passions.  \n\nFatigue Cost: " + spellCost(15) + "");
		if (player.findStatusAffect(StatusAffects.KnowsHeal) >= 0) addButton(6, "Heal", spellHeal, null, null, null, "Heal will attempt to use black magic to close your wounds and restore your body, however like all black magic used on yourself, it has a chance of backfiring and greatly arousing you.  \n\nFatigue Cost: " + spellCost(20) + "");
		if (player.findStatusAffect(StatusAffects.KnowsMight) >= 0) {
			if (player.findStatusAffect(StatusAffects.Might) < 0)
				addButton(7, "Might", spellMight, null, null, null, "The Might spell draws upon your lust and uses it to fuel a temporary increase in muscle size and power.  It does carry the risk of backfiring and raising lust, like all black magic used on oneself.  \n\nFatigue Cost: " + spellCost(25) + "");
			else outputText("<b>You are already under the effects of Might and cannot cast it again.</b>\n\n");
		}
	}
	// JOJO ABILITIES -- kind makes sense to stuff it in here along side the white magic shit (also because it can't fit into M. Specials :|
	if (player.findPerk(PerkLib.CleansingPalm) >= 0 && player.cor < (10 + player.corruptionTolerance())) {
		addButton(3, "C.Palm", spellCleansingPalm, null, null, null, "Unleash the power of your cleansing aura! More effective against corrupted opponents. Doesn't work on the pure.  \n\nFatigue Cost: " + spellCost(30) + "", "Cleansing Palm");
	}
	addButton(14, "Back", combatMenu, false);
}

public function spellMod():Number {
	var mod:Number = 1;
	if(player.findPerk(PerkLib.JobSorcerer) >= 0 && player.inte >= 25) mod += .1;
	if(player.findPerk(PerkLib.Archmage) >= 0 && player.inte >= 75) mod += .5;
	if(player.findPerk(PerkLib.Channeling) >= 0 && player.inte >= 60) mod += .5;
	if(player.findPerk(PerkLib.Mage) >= 0 && player.inte >= 50) mod += .5;
	if(player.findPerk(PerkLib.Spellpower) >= 0 && player.inte >= 50) mod += .5;
	if(player.findPerk(PerkLib.WizardsFocus) >= 0) {
		mod += player.perkv1(PerkLib.WizardsFocus);
	}
	if (player.findPerk(PerkLib.ChiReflowMagic) >= 0) mod += UmasShop.NEEDLEWORK_MAGIC_SPELL_MULTI;
	if (player.jewelryEffectId == JewelryLib.MODIFIER_SPELL_POWER) mod += (player.jewelryEffectMagnitude / 100);
	if (player.countCockSocks("blue") > 0) mod += (player.countCockSocks("blue") * .05);
	if (player.findPerk(PerkLib.AscensionMysticality) >= 0) mod *= 1 + (player.perkv1(PerkLib.AscensionMysticality) * 0.05);
	return mod;
}
public function spellArouse():void {
	if(player.findPerk(PerkLib.BloodMage) < 0 && player.fatigue + spellCost(15) > player.maxFatigue()) {
		outputText("You are too tired to cast this spell.", true);
		doNext(magicMenu);
		return;
	}
	doNext(combatMenu);
//This is now automatic - newRound arg defaults to true:	menuLoc = 0;
	fatigue(15,1);
	statScreenRefresh();
	if (monster is FrostGiant && player.findStatusAffect(StatusAffects.GiantBoulder) >= 0) {
		(monster as FrostGiant).giantBoulderHit(2);
		enemyAI();
		return;
	}
	if(monster.findStatusAffect(StatusAffects.Shell) >= 0) {
		outputText("As soon as your magic touches the multicolored shell around " + monster.a + monster.short + ", it sizzles and fades to nothing.  Whatever that thing is, it completely blocks your magic!\n\n");
		flags[kFLAGS.SPELLS_CAST]++;
		spellPerkUnlock();
		enemyAI();
		return;
	}
	outputText("You make a series of arcane gestures, drawing on your own lust to inflict it upon your foe!\n", true);
	//Worms be immune
	if(monster.short == "worms") {
		outputText("The worms appear to be unaffected by your magic!", false);
		outputText("\n\n", false);
		flags[kFLAGS.SPELLS_CAST]++;
		spellPerkUnlock();
		doNext(playerMenu);
		if(monster.lust >= eMaxLust) doNext(endLustVictory);
		else enemyAI();
		return;
	}
	if(monster.lustVuln == 0) {
		outputText("It has no effect!  Your foe clearly does not experience lust in the same way as you.\n\n", false);
		flags[kFLAGS.SPELLS_CAST]++;
		spellPerkUnlock();
		enemyAI();
		return;
	}
	var lustDmg:Number = monster.lustVuln * (player.inte/5*spellMod() + rand(monster.lib - monster.inte*2 + monster.cor)/5);
	if(monster.lust < (eMaxLust * 0.3)) outputText(monster.capitalA + monster.short + " squirms as the magic affects " + monster.pronoun2 + ".  ", false);
	if(monster.lust >= (eMaxLust * 0.3) && monster.lust < (eMaxLust * 0.6)) {
		if(monster.plural) outputText(monster.capitalA + monster.short + " stagger, suddenly weak and having trouble focusing on staying upright.  ", false);
		else outputText(monster.capitalA + monster.short + " staggers, suddenly weak and having trouble focusing on staying upright.  ", false);
	}
	if(monster.lust >= (eMaxLust * 0.6)) {
		outputText(monster.capitalA + monster.short + "'");
		if(!monster.plural) outputText("s");
		outputText(" eyes glaze over with desire for a moment.  ", false);
	}
	if(monster.cocks.length > 0) {
		if(monster.lust >= (eMaxLust * 0.6) && monster.cocks.length > 0) outputText("You see " + monster.pronoun3 + " " + monster.multiCockDescriptLight() + " dribble pre-cum.  ", false);
		if(monster.lust >= (eMaxLust * 0.3) && monster.lust < (eMaxLust * 0.6) && monster.cocks.length == 1) outputText(monster.capitalA + monster.short + "'s " + monster.cockDescriptShort(0) + " hardens, distracting " + monster.pronoun2 + " further.  ", false);
		if(monster.lust >= (eMaxLust * 0.3) && monster.lust < (eMaxLust * 0.6) && monster.cocks.length > 1) outputText("You see " + monster.pronoun3 + " " + monster.multiCockDescriptLight() + " harden uncomfortably.  ", false);
	}
	if(monster.vaginas.length > 0) {
		if(monster.plural) {
			if(monster.lust >= (eMaxLust * 0.6) && monster.vaginas[0].vaginalWetness == VAGINA_WETNESS_NORMAL) outputText(monster.capitalA + monster.short + "'s " + monster.vaginaDescript() + "s dampen perceptibly.  ", false);
			if(monster.lust >= (eMaxLust * 0.6) && monster.vaginas[0].vaginalWetness == VAGINA_WETNESS_WET) outputText(monster.capitalA + monster.short + "'s crotches become sticky with girl-lust.  ", false);
			if(monster.lust >= (eMaxLust * 0.6) && monster.vaginas[0].vaginalWetness == VAGINA_WETNESS_SLICK) outputText(monster.capitalA + monster.short + "'s " + monster.vaginaDescript() + "s become sloppy and wet.  ", false);
			if(monster.lust >= (eMaxLust * 0.6) && monster.vaginas[0].vaginalWetness == VAGINA_WETNESS_DROOLING) outputText("Thick runners of girl-lube stream down the insides of " + monster.a + monster.short + "'s thighs.  ", false);
			if(monster.lust >= (eMaxLust * 0.6) && monster.vaginas[0].vaginalWetness == VAGINA_WETNESS_SLAVERING) outputText(monster.capitalA + monster.short + "'s " + monster.vaginaDescript() + "s instantly soak " + monster.pronoun2 + " groin.  ", false);
		}
		else {
			if(monster.lust >= (eMaxLust * 0.6) && monster.vaginas[0].vaginalWetness == VAGINA_WETNESS_NORMAL) outputText(monster.capitalA + monster.short + "'s " + monster.vaginaDescript() + " dampens perceptibly.  ", false);
			if(monster.lust >= (eMaxLust * 0.6) && monster.vaginas[0].vaginalWetness == VAGINA_WETNESS_WET) outputText(monster.capitalA + monster.short + "'s crotch becomes sticky with girl-lust.  ", false);
			if(monster.lust >= (eMaxLust * 0.6) && monster.vaginas[0].vaginalWetness == VAGINA_WETNESS_SLICK) outputText(monster.capitalA + monster.short + "'s " + monster.vaginaDescript() + " becomes sloppy and wet.  ", false);
			if(monster.lust >= (eMaxLust * 0.6) && monster.vaginas[0].vaginalWetness == VAGINA_WETNESS_DROOLING) outputText("Thick runners of girl-lube stream down the insides of " + monster.a + monster.short + "'s thighs.  ", false);
			if(monster.lust >= (eMaxLust * 0.6) && monster.vaginas[0].vaginalWetness == VAGINA_WETNESS_SLAVERING) outputText(monster.capitalA + monster.short + "'s " + monster.vaginaDescript() + " instantly soaks her groin.  ", false);
		}
	}
	monster.teased(lustDmg);
	outputText("\n\n", false);
	doNext(playerMenu);
	flags[kFLAGS.SPELLS_CAST]++;
	spellPerkUnlock();
	if(monster.lust >= eMaxLust) doNext(endLustVictory);
	else enemyAI();
	return;	
}
public function spellHeal():void {
	if(/*player.findPerk(PerkLib.BloodMage) < 0 && */player.fatigue + spellCost(20) > player.maxFatigue()) {
		outputText("You are too tired to cast this spell.", true);
		doNext(magicMenu);
		return;
	}
	doNext(combatMenu);
//This is now automatic - newRound arg defaults to true:	menuLoc = 0;
	fatigue(20, 3);
	if (monster is FrostGiant && player.findStatusAffect(StatusAffects.GiantBoulder) >= 0) {
		(monster as FrostGiant).giantBoulderHit(2);
		enemyAI();
		return;
	}
	outputText("You focus on your body and its desire to end pain, trying to draw on your arousal without enhancing it.\n", true);
	//25% backfire!
	var backfire:int = 25;
	if (player.findPerk(PerkLib.FocusedMind) >= 0) backfire = 15;
	if(rand(100) < backfire) {
		outputText("An errant sexual thought crosses your mind, and you lose control of the spell!  Your ", false);
		if(player.gender == 0) outputText(assholeDescript() + " tingles with a desire to be filled as your libido spins out of control.", false);
		if(player.gender == 1) {
			if(player.cockTotal() == 1) outputText(player.cockDescript(0) + " twitches obscenely and drips with pre-cum as your libido spins out of control.", false);
			else outputText(player.multiCockDescriptLight() + " twitch obscenely and drip with pre-cum as your libido spins out of control.", false);
		}
		if(player.gender == 2) outputText(vaginaDescript(0) + " becomes puffy, hot, and ready to be touched as the magic diverts into it.", false);
		if(player.gender == 3) outputText(vaginaDescript(0) + " and " + player.multiCockDescriptLight() + " overfill with blood, becoming puffy and incredibly sensitive as the magic focuses on them.", false);
		dynStats("lib", .25, "lus", 15);
	}
	else {
		temp = int((player.level + (player.inte/1.5) + rand(player.inte)) * spellMod())
		//temp = int((player.inte/(2 + rand(3)) * spellMod()) * (maxHP()/150));
		if(player.armorName == "skimpy nurse's outfit") temp *= 1.2;
		outputText("You flush with success as your wounds begin to knit <b>(<font color=\"#008000\">+" + temp + "</font>)</b>.", false);
		HPChange(temp,false);
	}
	
	outputText("\n\n", false);
	statScreenRefresh();
	flags[kFLAGS.SPELLS_CAST]++;
	spellPerkUnlock();
	if(player.lust >= player.maxLust()) doNext(endLustLoss);
	else enemyAI();
	return;
}

//(25) Might – increases strength/toughness by 5 * spellMod, up to a 
//maximum of 15, allows it to exceed the maximum.  Chance of backfiring 
//and increasing lust by 15.
public function spellMight(silent:Boolean = false):void {
	
	var doEffect:Function = function():* {
		player.createStatusAffect(StatusAffects.Might,0,0,0,0);
		temp = 10 * spellMod();
		tempStr = temp;
		tempTou = temp;
		//if(player.str + temp > 100) tempStr = 100 - player.str;
		//if(player.tou + temp > 100) tempTou = 100 - player.tou;
		player.changeStatusValue(StatusAffects.Might,1,tempStr);
		player.changeStatusValue(StatusAffects.Might,2,tempTou);
		if(player.str < 100) {
			mainView.statsView.showStatUp('str');
			// strUp.visible = true;
			// strDown.visible = false;
			mainView.statsView.showStatUp('tou');
			// touUp.visible = true;
			// touDown.visible = false;
		}
		player.str += player.statusAffectv1(StatusAffects.Might);
		player.tou += player.statusAffectv2(StatusAffects.Might);
		statScreenRefresh();
	}
	
	if (silent)	{ // for Battlemage
		doEffect.call();
		return;
	}
	
	if(player.findPerk(PerkLib.BloodMage) < 0 && player.fatigue + spellCost(25) > player.maxFatigue()) {
		outputText("You are too tired to cast this spell.", true);
		doNext(magicMenu);
		return;
	}
	doNext(combatMenu);
//This is now automatic - newRound arg defaults to true:	menuLoc = 0;
	fatigue(25,1);
	var tempStr:Number = 0;
	var tempTou:Number = 0;
	if (monster is FrostGiant && player.findStatusAffect(StatusAffects.GiantBoulder) >= 0) {
		(monster as FrostGiant).giantBoulderHit(2);
		enemyAI();
		return;
	}
	outputText("You flush, drawing on your body's desires to empower your muscles and toughen you up.\n\n", true);
	//25% backfire!
	var backfire:int = 25;
	if (player.findPerk(PerkLib.FocusedMind) >= 0) backfire = 15;
	if(rand(100) < backfire) {
		outputText("An errant sexual thought crosses your mind, and you lose control of the spell!  Your ", false);
		if(player.gender == 0) outputText(assholeDescript() + " tingles with a desire to be filled as your libido spins out of control.", false);
		if(player.gender == 1) {
			if(player.cockTotal() == 1) outputText(player.cockDescript(0) + " twitches obscenely and drips with pre-cum as your libido spins out of control.", false);
			else outputText(player.multiCockDescriptLight() + " twitch obscenely and drip with pre-cum as your libido spins out of control.", false);
		}
		if(player.gender == 2) outputText(vaginaDescript(0) + " becomes puffy, hot, and ready to be touched as the magic diverts into it.", false);
		if(player.gender == 3) outputText(vaginaDescript(0) + " and " + player.multiCockDescriptLight() + " overfill with blood, becoming puffy and incredibly sensitive as the magic focuses on them.", false);
		dynStats("lib", .25, "lus", 15);
	}
	else {
		outputText("The rush of success and power flows through your body.  You feel like you can do anything!", false);
		doEffect.call();
	}
	outputText("\n\n", false);
	flags[kFLAGS.SPELLS_CAST]++;
	spellPerkUnlock();
	if(player.lust >= player.maxLust()) doNext(endLustLoss);
	else enemyAI();
	return;
}

//(15) Charge Weapon – boosts your weapon attack value by 10 * SpellMod till the end of combat.
public function spellChargeWeapon(silent:Boolean = false):void {
	if (silent) {
		player.createStatusAffect(StatusAffects.ChargeWeapon,10*spellMod(),0,0,0);
		statScreenRefresh();
		return;
	}
	
	if(player.findPerk(PerkLib.BloodMage) < 0 && player.fatigue + spellCost(15) > player.maxFatigue()) {
		outputText("You are too tired to cast this spell.", true);
		doNext(magicMenu);
		return;
	}
	doNext(combatMenu);
//This is now automatic - newRound arg defaults to true:	menuLoc = 0;
	fatigue(15, 1);
	if (monster is FrostGiant && player.findStatusAffect(StatusAffects.GiantBoulder) >= 0) {
		(monster as FrostGiant).giantBoulderHit(2);
		enemyAI();
		return;
	}
	outputText("You utter words of power, summoning an electrical charge around your " + player.weaponName + ".  It crackles loudly, ensuring you'll do more damage with it for the rest of the fight.\n\n", true);
	player.createStatusAffect(StatusAffects.ChargeWeapon,10*spellMod(),0,0,0);
	statScreenRefresh();
	flags[kFLAGS.SPELLS_CAST]++;
	spellPerkUnlock();
	enemyAI();
}
//(20) Blind – reduces your opponent's accuracy, giving an additional 50% miss chance to physical attacks.
public function spellBlind():void {
	clearOutput();
	if(player.findPerk(PerkLib.BloodMage) < 0 && player.fatigue + spellCost(20) > player.maxFatigue()) {
		outputText("You are too tired to cast this spell.", true);
		doNext(magicMenu);
		return;
	}
	doNext(combatMenu);
//This is now automatic - newRound arg defaults to true:	menuLoc = 0;
	fatigue(20,1);
	if(monster.findStatusAffect(StatusAffects.Shell) >= 0) {
		outputText("As soon as your magic touches the multicolored shell around " + monster.a + monster.short + ", it sizzles and fades to nothing.  Whatever that thing is, it completely blocks your magic!\n\n");
		flags[kFLAGS.SPELLS_CAST]++;
		spellPerkUnlock();
		enemyAI();
		return;
	}
	if (monster is JeanClaude)
	{
		outputText("Jean-Claude howls, reeling backwards before turning back to you, rage clenching his dragon-like face and enflaming his eyes. Your spell seemed to cause him physical pain, but did nothing to blind his lidless sight.");

		outputText("\n\n“<i>You think your hedge magic will work on me, intrus?</i>” he snarls. “<i>Here- let me show you how it’s really done.</i>” The light of anger in his eyes intensifies, burning a retina-frying white as it demands you stare into it...");
		
		if (rand(player.spe) >= 50 || rand(player.inte) >= 50)
		{
			outputText("\n\nThe light sears into your eyes, but with the discipline of conscious effort you escape the hypnotic pull before it can mesmerize you, before Jean-Claude can blind you.");

			outputText("\n\n“<i>You fight dirty,</i>” the monster snaps. He sounds genuinely outraged. “<i>I was told the interloper was a dangerous warrior, not a little [boy] who accepts duels of honour and then throws sand into his opponent’s eyes. Look into my eyes, little [boy]. Fair is fair.</i>”");
			
			monster.HP -= int(10+(player.inte/3 + rand(player.inte/2)) * spellMod());
		}
		else
		{
			outputText("\n\nThe light sears into your eyes and mind as you stare into it. It’s so powerful, so infinite, so exquisitely painful that you wonder why you’d ever want to look at anything else, at anything at- with a mighty effort, you tear yourself away from it, gasping. All you can see is the afterimages, blaring white and yellow across your vision. You swipe around you blindly as you hear Jean-Claude bark with laughter, trying to keep the monster at arm’s length.");

			outputText("\n\n“<i>The taste of your own medicine, it is not so nice, eh? I will show you much nicer things in there in time intrus, don’t worry. Once you have learnt your place.</i>”");
			
			player.createStatusAffect(StatusAffects.Blind, rand(4) + 1, 0, 0, 0);
		}
		if (monster is FrostGiant && player.findStatusAffect(StatusAffects.GiantBoulder) >= 0) {
			(monster as FrostGiant).giantBoulderHit(2);
			enemyAI();
			return;
		}
		flags[kFLAGS.SPELLS_CAST]++;
		spellPerkUnlock();
		if(monster.HP < 1) doNext(endHpVictory);
		else enemyAI();
		return;
	}
	outputText("You glare at " + monster.a + monster.short + " and point at " + monster.pronoun2 + ".  A bright flash erupts before " + monster.pronoun2 + "!\n", true);
	if (monster is LivingStatue)
	{
		// noop
	}
	else if(rand(3) != 0) {
		outputText(" <b>" + monster.capitalA + monster.short + " ", false);
		if(monster.plural && monster.short != "imp horde") outputText("are blinded!</b>", false);
		else outputText("is blinded!</b>", false);
		monster.createStatusAffect(StatusAffects.Blind,5*spellMod(),0,0,0);
		if(monster.short == "Isabella")
			if (isabellaFollowerScene.isabellaAccent()) outputText("\n\n\"<i>Nein! I cannot see!</i>\" cries Isabella.", false);
			else outputText("\n\n\"<i>No! I cannot see!</i>\" cries Isabella.", false);
		if(monster.short == "Kiha") outputText("\n\n\"<i>You think blindness will slow me down?  Attacks like that are only effective on those who don't know how to see with their other senses!</i>\" Kiha cries defiantly.", false);
		if(monster.short == "plain girl") {
			outputText("  Remarkably, it seems as if your spell has had no effect on her, and you nearly get clipped by a roundhouse as you stand, confused. The girl flashes a radiant smile at you, and the battle continues.", false);
			monster.removeStatusAffect(StatusAffects.Blind);
		}
	}
	else outputText(monster.capitalA + monster.short + " blinked!", false);	
	outputText("\n\n", false);
	flags[kFLAGS.SPELLS_CAST]++;
	spellPerkUnlock();
	statScreenRefresh();
	enemyAI();
}
//(30) Whitefire – burns the enemy for 10 + int/3 + rand(int/2) * spellMod.
private var fireMagicLastTurn:int = -100;
private var fireMagicCumulated:int = 0;
private function calcInfernoMod(damage:Number):int {
	if (player.findPerk(PerkLib.RagingInferno) >= 0) {
		var multiplier:Number = 1;
		if (combatRound - fireMagicLastTurn == 2) {
			outputText("Traces of your previously used fire magic are still here, and you use them to empower another spell!\n\n");
			switch(fireMagicCumulated) {
				case 0:
				case 1:
					multiplier = 1;
					break;
				case 2:
					multiplier = 1.2;
					break;
				case 3:
					multiplier = 1.35;
					break;
				case 4:
					multiplier = 1.45;
					break;
				default:
					multiplier = 1.5 + ((fireMagicCumulated - 5) * 0.05); //Diminishing returns at max, add 0.05 to multiplier.
			}
			damage = Math.round(damage * multiplier);
			fireMagicCumulated++;
			// XXX: Message?
		} else {
			if (combatRound - fireMagicLastTurn > 2 && fireMagicLastTurn > 0)
				outputText("Unfortunately, traces of your previously used fire magic are too weak to be used.\n\n");
			fireMagicCumulated = 1;
		}
		fireMagicLastTurn = combatRound;
	}
	return damage;
}

public function spellWhitefire():void {
	clearOutput();
	if(player.findPerk(PerkLib.BloodMage) < 0 && player.fatigue + spellCost(30) > player.maxFatigue()) {
		outputText("You are too tired to cast this spell.", true);
		doNext(magicMenu);
		return;
	}
	doNext(combatMenu);
//This is now automatic - newRound arg defaults to true:	menuLoc = 0;
	fatigue(30,1);
	if(monster.findStatusAffect(StatusAffects.Shell) >= 0) {
		outputText("As soon as your magic touches the multicolored shell around " + monster.a + monster.short + ", it sizzles and fades to nothing.  Whatever that thing is, it completely blocks your magic!\n\n");
		flags[kFLAGS.SPELLS_CAST]++;
		spellPerkUnlock();
		enemyAI();
		return;
	}
	if (monster is Doppleganger)
	{
		(monster as Doppleganger).handleSpellResistance("whitefire");
		flags[kFLAGS.SPELLS_CAST]++;
		spellPerkUnlock();
		return;
	}
	if (monster is FrostGiant && player.findStatusAffect(StatusAffects.GiantBoulder) >= 0) {
		(monster as FrostGiant).giantBoulderHit(2);
		enemyAI();
		return;
	}
	outputText("You narrow your eyes, focusing your mind with deadly intent.  You snap your fingers and " + monster.a + monster.short + " is enveloped in a flash of white flames!\n", true);
	temp = int(10+(player.inte/3 + rand(player.inte/2)) * spellMod());
	//High damage to goes.
	temp = calcInfernoMod(temp);
	if (monster.short == "goo-girl") temp = Math.round(temp * 1.5);
	if (monster.short == "tentacle beast") temp = Math.round(temp * 1.2);
	outputText(monster.capitalA + monster.short + " takes <b><font color=\"#800000\">" + temp + "</font></b> damage.", false);
	//Using fire attacks on the goo]
	if(monster.short == "goo-girl") {
		outputText("  Your flames lick the girl's body and she opens her mouth in pained protest as you evaporate much of her moisture. When the fire passes, she seems a bit smaller and her slimy " + monster.skinTone + " skin has lost some of its shimmer.", false);
		if(monster.findPerk(PerkLib.Acid) < 0) monster.createPerk(PerkLib.Acid,0,0,0,0);
	}
	if(monster.short == "Holli" && monster.findStatusAffect(StatusAffects.HolliBurning) < 0) (monster as Holli).lightHolliOnFireMagically();
	outputText("\n\n", false);
	checkAchievementDamage(temp);
	flags[kFLAGS.SPELLS_CAST]++;
	spellPerkUnlock();
	monster.HP -= temp;
	statScreenRefresh();
	if(monster.HP < 1) doNext(endHpVictory);
	else enemyAI();
}

public function spellCleansingPalm():void
{
	clearOutput();
	if (player.findPerk(PerkLib.BloodMage) < 0 && player.fatigue + spellCost(30) > player.maxFatigue()) {
		outputText("You are too tired to cast this spell.", true);
		doNext(magicMenu);
		return;
	}
	doNext(combatMenu);
//This is now automatic - newRound arg defaults to true:	menuLoc = 0;
	fatigue(30,1);
	if(monster.findStatusAffect(StatusAffects.Shell) >= 0) {
		outputText("As soon as your magic touches the multicolored shell around " + monster.a + monster.short + ", it sizzles and fades to nothing.  Whatever that thing is, it completely blocks your magic!\n\n");
		flags[kFLAGS.SPELLS_CAST]++;
		spellPerkUnlock();
		enemyAI();
		return;
	}
	
	if (monster.short == "Jojo")
	{
		// Not a completely corrupted monkmouse
		if (kGAMECLASS.monk < 2)
		{
			outputText("You thrust your palm forward, sending a blast of pure energy towards Jojo. At the last second he sends a blast of his own against yours canceling it out\n\n");
			flags[kFLAGS.SPELLS_CAST]++;
			spellPerkUnlock();
			enemyAI();
			return;
		}
	}
	
	if (monster is LivingStatue)
	{
		outputText("You thrust your palm forward, causing a blast of pure energy to slam against the giant stone statue- to no effect!");
		flags[kFLAGS.SPELLS_CAST]++;
		spellPerkUnlock();
		enemyAI();
		return;
	}
		
	var corruptionMulti:Number = (monster.cor - 20) / 25;
	if (corruptionMulti > 1.5) {
		corruptionMulti = 1.5;
		corruptionMulti += ((monster.cor - 57.5) / 100); //The increase to multiplier is diminished.
	}
	
	temp = int((player.inte / 4 + rand(player.inte / 3)) * (spellMod() * corruptionMulti));
	
	if (temp > 0)
	{
		outputText("You thrust your palm forward, causing a blast of pure energy to slam against " + monster.a + monster.short + ", tossing");
		if ((monster as Monster).plural == true) outputText(" them");
		else outputText((monster as Monster).mfn(" him", " her", " it"));
		outputText(" back a few feet.\n\n");
		if (silly() && corruptionMulti >= 1.75) outputText("It's super effective!  ");
		outputText(monster.capitalA + monster.short + " takes <b><font color=\"#800000\">" + temp + "</font></b> damage.\n\n");
	}
	else
	{
		temp = 0;
		outputText("You thrust your palm forward, causing a blast of pure energy to slam against " + monster.a + monster.short + ", which they ignore. It is probably best you don’t use this technique against the pure.\n\n");
	}
	
	flags[kFLAGS.SPELLS_CAST]++;
	spellPerkUnlock();
	monster.HP -= temp;
	statScreenRefresh();
	if(monster.HP < 1) doNext(endHpVictory);
	else enemyAI();
}

public function spellPerkUnlock():void {
	if(flags[kFLAGS.SPELLS_CAST] >= 5 && player.findPerk(PerkLib.SpellcastingAffinity) < 0) {
		outputText("<b>You've become more comfortable with your spells, unlocking the Spellcasting Affinity perk and reducing fatigue cost of spells by 20%!</b>\n\n");
		player.createPerk(PerkLib.SpellcastingAffinity,20,0,0,0);
	}
	if(flags[kFLAGS.SPELLS_CAST] >= 15 && player.perkv1(PerkLib.SpellcastingAffinity) < 35) {
		outputText("<b>You've become more comfortable with your spells, further reducing your spell costs by an additional 15%!</b>\n\n");
		player.setPerkValue(PerkLib.SpellcastingAffinity,1,35);
	}
	if(flags[kFLAGS.SPELLS_CAST] >= 45 && player.perkv1(PerkLib.SpellcastingAffinity) < 50) {
		outputText("<b>You've become more comfortable with your spells, further reducing your spell costs by an additional 15%!</b>\n\n");
		player.setPerkValue(PerkLib.SpellcastingAffinity,1,50);
	}
}

//player gains hellfire perk.  
//Hellfire deals physical damage to completely pure foes, 
//lust damage to completely corrupt foes, and a mix for those in between.  Its power is based on the PC's corruption and level.  Appearance is slightly changed to mention that the PC's eyes and mouth occasionally show flicks of fire from within them, text could possibly vary based on corruption.
public function hellFire():void {
	clearOutput();
	if (player.findPerk(PerkLib.BloodMage) < 0 && player.fatigue + spellCost(20) > player.maxFatigue()) {
		outputText("You are too tired to breathe fire.\n", true);
		doNext(combatMenu);
		return;
	}
//This is now automatic - newRound arg defaults to true:	menuLoc = 0;
	fatigue(20, 1);
	var damage:Number = (player.level * 8 + rand(10) + player.inte / 2 + player.cor / 5);
	damage = calcInfernoMod(damage);
	//Amily!
	if(monster.findStatusAffect(StatusAffects.Concentration) >= 0) {
		outputText("Amily easily glides around your attack thanks to her complete concentration on your movements.\n\n", true);
		enemyAI();
		return;
	}
	if (monster is LivingStatue)
	{
		outputText("The fire courses over the stone behemoths skin harmlessly. It does leave the surface of the statue glossier in its wake.");
		enemyAI();
		return;
	}
	
	if(player.findStatusAffect(StatusAffects.GooArmorSilence) < 0) outputText("You take in a deep breath and unleash a wave of corrupt red flames from deep within.", false);
	
	if(player.findStatusAffect(StatusAffects.WebSilence) >= 0) {
		outputText("  <b>The fire burns through the webs blocking your mouth!</b>", false);
		player.removeStatusAffect(StatusAffects.WebSilence);
	}
	if(player.findStatusAffect(StatusAffects.GooArmorSilence) >= 0) {
		outputText("  <b>A growl rumbles from deep within as you charge the terrestrial fire, and you force it from your chest and into the slime.  The goop bubbles and steams as it evaporates, drawing a curious look from your foe, who pauses in her onslaught to lean in and watch.  While the tension around your mouth lessens and your opponent forgets herself more and more, you bide your time.  When you can finally work your jaw enough to open your mouth, you expel the lion's - or jaguar's? share of the flame, inflating an enormous bubble of fire and evaporated slime that thins and finally pops to release a superheated cloud.  The armored girl screams and recoils as she's enveloped, flailing her arms.</b>", false);
		player.removeStatusAffect(StatusAffects.GooArmorSilence);
		damage += 25;
	}
	if(monster.short == "Isabella" && monster.findStatusAffect(StatusAffects.Stunned) < 0) {
		outputText("  Isabella shoulders her shield into the path of the crimson flames.  They burst over the wall of steel, splitting around the impenetrable obstruction and washing out harmlessly to the sides.\n\n", false);
		if (isabellaFollowerScene.isabellaAccent()) outputText("\"<i>Is zat all you've got?  It'll take more than a flashy magic trick to beat Izabella!</i>\" taunts the cow-girl.\n\n", false);
		else outputText("\"<i>Is that all you've got?  It'll take more than a flashy magic trick to beat Isabella!</i>\" taunts the cow-girl.\n\n", false);
		enemyAI();
		return;
	}
	else if(monster.short == "Vala" && monster.findStatusAffect(StatusAffects.Stunned) < 0) {
		outputText("  Vala beats her wings with surprising strength, blowing the fireball back at you!  ", false);		
		if(player.findPerk(PerkLib.Evade) >= 0 && rand(2) == 0) {
			outputText("You dive out of the way and evade it!", false);
		}
		else if(player.findPerk(PerkLib.Flexibility) >= 0 && rand(4) == 0) {
			outputText("You use your flexibility to barely fold your body out of the way!", false);
		}
		else {
			damage = int(damage / 6);
			outputText("Your own fire smacks into your face, arousing you!", false);
			dynStats("lus", damage);
		}
		outputText("\n", false);
	}
	else {
		if(monster.inte < 10) {
			outputText("  Your foe lets out a shriek as their form is engulfed in the blistering flames.", false);
			damage = int(damage);
			outputText("<b>(<font color=\"#800000\">+" + damage + "</font>)</b>\n", false);
			monster.HP -= damage;
		}
		else {
			if(monster.lustVuln > 0) {
				outputText("  Your foe cries out in surprise and then gives a sensual moan as the flames of your passion surround them and fill their body with unnatural lust.", false);
				monster.teased(monster.lustVuln * damage / 6);
				outputText("\n");
			}
			else {
				outputText("  The corrupted fire doesn't seem to have effect on " + monster.a + monster.short + "!\n", false);
			}
		}
	}
	outputText("\n", false);
	if(monster.short == "Holli" && monster.findStatusAffect(StatusAffects.HolliBurning) < 0) (monster as Holli).lightHolliOnFireMagically();
	if(monster.HP < 1) {
		doNext(endHpVictory);
	}
	else if(monster.lust >= (eMaxLust - 1)) {
		doNext(endLustVictory);
	}
	else enemyAI();
}

public function kick():void {
	clearOutput();
	if(player.fatigue + physicalCost(15) > player.maxFatigue()) {
		outputText("You're too fatigued to use a charge attack!", true);
		menu();
		addButton(0, "Next", combatMenu, false);
		return;
	}
	fatigue(15,2);
	//Variant start messages!
	if(player.lowerBody == LOWER_BODY_TYPE_KANGAROO) {
		//(tail)
		if(player.tailType == TAIL_TYPE_KANGAROO) outputText("You balance on your flexible kangaroo-tail, pulling both legs up before slamming them forward simultaneously in a brutal kick.  ", false);
		//(no tail) 
		else outputText("You balance on one leg and cock your powerful, kangaroo-like leg before you slam it forward in a kick.  ", false);
	}
	//(bunbun kick) 
	else if(player.lowerBody == LOWER_BODY_TYPE_BUNNY) outputText("You leap straight into the air and lash out with both your furred feet simultaneously, slamming forward in a strong kick.  ", false);
	//(centaur kick)
	else if(player.lowerBody == LOWER_BODY_TYPE_HOOFED || player.lowerBody == LOWER_BODY_TYPE_PONY || player.lowerBody == LOWER_BODY_TYPE_CLOVEN_HOOFED)
		if(player.isTaur()) outputText("You lurch up onto your backlegs, lifting your forelegs from the ground a split-second before you lash them out in a vicious kick.  ", false);
		//(bipedal hoof-kick) 
		else outputText("You twist and lurch as you raise a leg and slam your hoof forward in a kick.  ", false);

	if(flags[kFLAGS.PC_FETISH] >= 3) {
		outputText("You attempt to attack, but at the last moment your body wrenches away, preventing you from even coming close to landing a blow!  Ceraph's piercings have made normal attack impossible!  Maybe you could try something else?\n\n", false);
		enemyAI();
		return;
	}
	//Amily!
	if(monster.findStatusAffect(StatusAffects.Concentration) >= 0) {
		outputText("Amily easily glides around your attack thanks to her complete concentration on your movements.\n\n", true);
		enemyAI();
		return;
	}
	//Blind
	if(player.findStatusAffect(StatusAffects.Blind) >= 0) {
		outputText("You attempt to attack, but as blinded as you are right now, you doubt you'll have much luck!  ", false);
	}
	//Worms are special
	if(monster.short == "worms") {
		//50% chance of hit (int boost)
		if(rand(100) + player.inte/3 >= 50) {
			temp = int(player.str/5 - rand(5));
			if(temp == 0) temp = 1;
			outputText("You strike at the amalgamation, crushing countless worms into goo, dealing " + temp + " damage.\n\n", false);
			monster.HP -= temp;
			if(monster.HP <= 0) {
				doNext(endHpVictory);
				return;
			}
		}
		//Fail
		else {
			outputText("You attempt to crush the worms with your reprisal, only to have the collective move its individual members, creating a void at the point of impact, leaving you to attack only empty air.\n\n", false);
		}
		enemyAI();
		return;
	}
	var damage:Number;
	//Determine if dodged!
	if((player.findStatusAffect(StatusAffects.Blind) >= 0 && rand(2) == 0) || (monster.spe - player.spe > 0 && int(Math.random()*(((monster.spe-player.spe)/4)+80)) > 80)) {
		//Akbal dodges special education
		if(monster.short == "Akbal") outputText("Akbal moves like lightning, weaving in and out of your furious attack with the speed and grace befitting his jaguar body.\n", false);
		else {		
			outputText(monster.capitalA + monster.short + " manage", false);
			if(!monster.plural) outputText("s", false);
			outputText(" to dodge your kick!", false);
			outputText("\n\n", false);
		}
		enemyAI();
		return;
	}
	//Determine damage
	//Base:
	damage = player.str;
	//Leg bonus
	//Bunny - 20, Kangaroo - 35, 1 hoof = 30, 2 hooves = 40
	if(player.lowerBody == LOWER_BODY_TYPE_HOOFED || player.lowerBody == LOWER_BODY_TYPE_PONY || player.lowerBody == LOWER_BODY_TYPE_CLOVEN_HOOFED)
		damage += 30;
	else if(player.lowerBody == LOWER_BODY_TYPE_BUNNY) damage += 20;
	else if (player.lowerBody == LOWER_BODY_TYPE_KANGAROO) damage += 35;
	if(player.isTaur()) damage += 10;
	//Damage post processing!
	if (player.findPerk(PerkLib.HistoryFighter) >= 0) damage *= 1.1;
	if (player.findPerk(PerkLib.JobWarrior) >= 0) damage *= 1.05;
	if (player.jewelryEffectId == JewelryLib.MODIFIER_ATTACK_POWER) damage *= 1 + (player.jewelryEffectMagnitude / 100);
	if (player.countCockSocks("red") > 0) damage *= (1 + player.countCockSocks("red") * 0.02);
	//Reduce damage
	damage *= monster.damagePercent() / 100;
	//(None yet!)
	if(damage > 0) damage = doDamage(damage);
	
	//BLOCKED
	if(damage <= 0) {
		damage = 0;
		outputText(monster.capitalA + monster.short, false);
		if(monster.plural) outputText("'", false);
		else outputText("s", false);
		outputText(" defenses are too tough for your kick to penetrate!", false);
	}
	//LAND A HIT!
	else {
		outputText(monster.capitalA + monster.short, false);
		if(!monster.plural) outputText(" reels from the damaging impact! <b>(<font color=\"#800000\">" + damage + "</font>)</b>", false);
		else outputText(" reel from the damaging impact! <b>(<font color=\"#800000\">" + damage + "</font>)</b>", false);
	}
	if(damage > 0) {
		//Lust raised by anemone contact!
		if(monster.short == "anemone") {
			outputText("\nThough you managed to hit the anemone, several of the tentacles surrounding her body sent home jolts of venom when your swing brushed past them.", false);
			//(gain lust, temp lose str/spd)
			(monster as Anemone).applyVenom((1+rand(2)));
		}
	}
	outputText("\n\n", false);
	checkAchievementDamage(damage);
	if(monster.HP < 1 || monster.lust > (eMaxLust - 1)) combatRoundOver();
	else enemyAI();
}

public function PCWebAttack():void {
	clearOutput();
	//Keep logic sane if this attack brings victory
	if(player.tailVenom < 33) {
		outputText("You do not have enough webbing to shoot right now!", true);
		doNext(physicalSpecials);
		return;
	}
	player.tailVenom-= 33;
	//Amily!
	if(monster.findStatusAffect(StatusAffects.Concentration) >= 0) {
		outputText("Amily easily glides around your attack thanks to her complete concentration on your movements.\n\n", true);
		enemyAI();
		return;
	}
	if (monster.short == "lizan rogue") {
		outputText("As your webbing flies at him the lizan flips back, slashing at the adhesive strands with the claws on his hands and feet with practiced ease.  It appears he's used to countering this tactic.");
		enemyAI();
		return;
	}
	//Blind
	if(player.findStatusAffect(StatusAffects.Blind) >= 0) {
		outputText("You attempt to attack, but as blinded as you are right now, you doubt you'll have much luck!  ", false);
	}
	else outputText("Turning and clenching muscles that no human should have, you expel a spray of sticky webs at " + monster.a + monster.short + "!  ", false);
	//Determine if dodged!
	if((player.findStatusAffect(StatusAffects.Blind) >= 0 && rand(2) == 0) || (monster.spe - player.spe > 0 && int(Math.random()*(((monster.spe-player.spe)/4)+80)) > 80)) {
		outputText("You miss " + monster.a + monster.short + " completely - ", false);
		if(monster.plural) outputText("they", false);
		else outputText(monster.mf("he","she") + " moved out of the way!\n\n", false);
		enemyAI();
		return;
	}
	//Over-webbed
	if(monster.spe < 1) {
		if(!monster.plural) outputText(monster.capitalA + monster.short + " is completely covered in webbing, but you hose " + monster.mf("him","her") + " down again anyway.", false);
		else outputText(monster.capitalA + monster.short + " are completely covered in webbing, but you hose them down again anyway.", false);
	}
	//LAND A HIT!
	else {
		if(!monster.plural) outputText("The adhesive strands cover " + monster.a + monster.short + " with restrictive webbing, greatly slowing " + monster.mf("him","her") + ". ", false);
		else outputText("The adhesive strands cover " + monster.a + monster.short + " with restrictive webbing, greatly slowing " + monster.mf("him","her") + ". ", false);
		monster.spe -= 45;
		if(monster.spe < 0) monster.spe = 0;
	}
	awardAchievement("How Do I Shot Web?", kACHIEVEMENTS.COMBAT_SHOT_WEB);
	outputText("\n\n", false);
	if(monster.HP < 1 || monster.lust > (eMaxLust - 1)) combatRoundOver();
	else enemyAI();
}
public function nagaBiteAttack():void {
	clearOutput();
	//FATIIIIGUE
	if(player.fatigue + physicalCost(10) > player.maxFatigue()) {
		outputText("You just don't have the energy to bite something right now...", true);
//Pass false to combatMenu instead:		menuLoc = 1;
//		doNext(combatMenu);
		menu();
		addButton(0, "Next", combatMenu, false);
		return;
	}
	fatigue(10,2);
	//Amily!
	if(monster.findStatusAffect(StatusAffects.Concentration) >= 0) {
		outputText("Amily easily glides around your attack thanks to her complete concentration on your movements.", true);
		enemyAI();
		return;
	}
	if (monster is LivingStatue)
	{
		outputText("Your fangs can't even penetrate the giant's flesh.");
		enemyAI();
		return;
	}
	//Works similar to bee stinger, must be regenerated over time. Shares the same poison-meter
    if(rand(player.spe/2 + 40) + 20 > monster.spe/1.5 || monster.findStatusAffect(StatusAffects.Constricted) >= 0) {
		//(if monster = demons)
		if(monster.short == "demons") outputText("You look at the crowd for a moment, wondering which of their number you should bite. Your glance lands upon the leader of the group, easily spotted due to his snakeskin cloak. You quickly dart through the demon crowd as it closes in around you and lunge towards the broad form of the leader. You catch the demon off guard and sink your needle-like fangs deep into his flesh. You quickly release your venom and retreat before he, or the rest of the group manage to react.", false);
		//(Otherwise) 
		else outputText("You lunge at the foe headfirst, fangs bared. You manage to catch " + monster.a + monster.short + " off guard, your needle-like fangs penetrating deep into " + monster.pronoun3 + " body. You quickly release your venom, and retreat before " + monster.pronoun1 + " manages to react.", false);
        //The following is how the enemy reacts over time to poison. It is displayed after the description paragraph,instead of lust
        monster.str -= 5 + rand(5);
		monster.spe -= 5 + rand(5);
		if(monster.str < 1) monster.str = 1;
		if(monster.spe < 1) monster.spe = 1;
		if(monster.findStatusAffect(StatusAffects.NagaVenom) >= 0)
		{
			monster.addStatusValue(StatusAffects.NagaVenom,1,1);
		}
		else monster.createStatusAffect(StatusAffects.NagaVenom,1,0,0,0);
	}
	else {
       outputText("You lunge headfirst, fangs bared. Your attempt fails horrendously, as " + monster.a + monster.short + " manages to counter your lunge, knocking your head away with enough force to make your ears ring.", false);
	}
	outputText("\n\n", false);
	if(monster.HP < 1 || monster.lust > (eMaxLust - 1)) combatRoundOver();
	else enemyAI();
}
public function spiderBiteAttack():void {
	clearOutput();
	//FATIIIIGUE
	if(player.fatigue + physicalCost(10) > player.maxFatigue()) {
		outputText("You just don't have the energy to bite something right now...", true);
//Pass false to combatMenu instead:		menuLoc = 1;
//		doNext(combatMenu);
		menu();
		addButton(0, "Next", combatMenu, false);
		return;
	}
	fatigue(10,2);
	//Amily!
	if(monster.findStatusAffect(StatusAffects.Concentration) >= 0) {
		outputText("Amily easily glides around your attack thanks to her complete concentration on your movements.", true);
		enemyAI();
		return;
	}
	if (monster is LivingStatue)
	{
		outputText("Your fangs can't even penetrate the giant's flesh.");
		enemyAI();
		return;
	}
	//Works similar to bee stinger, must be regenerated over time. Shares the same poison-meter
    if(rand(player.spe/2 + 40) + 20 > monster.spe/1.5) {
		//(if monster = demons)
		if(monster.short == "demons") outputText("You look at the crowd for a moment, wondering which of their number you should bite. Your glance lands upon the leader of the group, easily spotted due to his snakeskin cloak. You quickly dart through the demon crowd as it closes in around you and lunge towards the broad form of the leader. You catch the demon off guard and sink your needle-like fangs deep into his flesh. You quickly release your venom and retreat before he, or the rest of the group manage to react.", false);
		//(Otherwise) 
		else {
			if(!monster.plural) outputText("You lunge at the foe headfirst, fangs bared. You manage to catch " + monster.a + monster.short + " off guard, your needle-like fangs penetrating deep into " + monster.pronoun3 + " body. You quickly release your venom, and retreat before " + monster.a + monster.pronoun1 + " manages to react.", false);
			else outputText("You lunge at the foes headfirst, fangs bared. You manage to catch one of " + monster.a + monster.short + " off guard, your needle-like fangs penetrating deep into " + monster.pronoun3 + " body. You quickly release your venom, and retreat before " + monster.a + monster.pronoun1 + " manage to react.", false);
		}
		//React
		if(monster.lustVuln == 0) outputText("  Your aphrodisiac toxin has no effect!", false);
		else {
			if(monster.plural) outputText("  The one you bit flushes hotly, though the entire group seems to become more aroused in sympathy to their now-lusty compatriot.", false);
			else outputText("  " + monster.mf("He","She") + " flushes hotly and " + monster.mf("touches his suddenly-stiff member, moaning lewdly for a moment.","touches a suddenly stiff nipple, moaning lewdly.  You can smell her arousal in the air."), false);
			var lustDmg:int = 25 * monster.lustVuln;
			if (rand(5) == 0) lustDmg *= 2;
			monster.teased(lustDmg);
		}
	}
	else {
       outputText("You lunge headfirst, fangs bared. Your attempt fails horrendously, as " + monster.a + monster.short + " manages to counter your lunge, pushing you back out of range.", false);
	}
	outputText("\n\n", false);
	if(monster.HP < 1 || monster.lust > (eMaxLust - 1)) combatRoundOver();
	else enemyAI();
}

//New Abilities and Items
//[Abilities]
//Whisper 
public function superWhisperAttack():void {
	clearOutput();
	if (player.findPerk(PerkLib.BloodMage) < 0 && player.fatigue + spellCost(10) > player.maxFatigue())
	{
		outputText("You are too tired to focus this ability.", true);
		doNext(combatMenu);
		return;
	}
	if(player.findStatusAffect(StatusAffects.ThroatPunch) >= 0 || player.findStatusAffect(StatusAffects.WebSilence) >= 0) {
		outputText("You cannot focus to reach the enemy's mind while you're having so much difficult breathing.", true);
		doNext(combatMenu);
		return;
	}
	if(monster.short == "pod" || monster.inte == 0) {
		outputText("You reach for the enemy's mind, but cannot find anything.  You frantically search around, but there is no consciousness as you know it in the room.\n\n", true);
		changeFatigue(1);
		enemyAI();
		return;
	}
	if (monster is LivingStatue)
	{
		outputText("There is nothing inside the golem to whisper to.");
		changeFatigue(1);
		enemyAI();
		return;
	}
//This is now automatic - newRound arg defaults to true:	menuLoc = 0;
	fatigue(10, 1);
	if(monster.findStatusAffect(StatusAffects.Shell) >= 0) {
		outputText("As soon as your magic touches the multicolored shell around " + monster.a + monster.short + ", it sizzles and fades to nothing.  Whatever that thing is, it completely blocks your magic!\n\n");
		enemyAI();
		return;
	}
	if(monster.findPerk(PerkLib.Focused) >= 0) {
		if(!monster.plural) outputText(monster.capitalA + monster.short + " is too focused for your whispers to influence!\n\n");
		enemyAI();
		return;
	}
	//Enemy too strong or multiplesI think you 
	if(player.inte < monster.inte || monster.plural) {
		outputText("You reach for your enemy's mind, but can't break through.\n", false);
		changeFatigue(10);
		enemyAI();
		return;
	}
	//[Failure] 
	if(rand(10) == 0) {
		outputText("As you reach for your enemy's mind, you are distracted and the chorus of voices screams out all at once within your mind. You're forced to hastily silence the voices to protect yourself.", false);
		changeFatigue(10);
		enemyAI();
		return;
	}
	outputText("You reach for your enemy's mind, watching as its sudden fear petrifies your foe.\n\n", false);
	monster.createStatusAffect(StatusAffects.Fear,1,0,0,0);
	enemyAI();
}

//Attack used:
//This attack has a cooldown and is more dramatic when used by the PC, it should be some sort of last ditch attack for emergencies. Don't count on using this whenever you want.
	//once a day or something
	//Effect of attack: Damages and stuns the enemy for the turn you used this attack on, plus 2 more turns. High chance of success.
public function dragonBreath():void {
	clearOutput();
	if (player.findPerk(PerkLib.BloodMage) < 0 && player.fatigue + spellCost(20) > player.maxFatigue())
	{
		outputText("You are too tired to breathe fire.", true);
		doNext(combatMenu);
		return;
	}
	//Not Ready Yet:
	if(player.findStatusAffect(StatusAffects.DragonBreathCooldown) >= 0) {
		outputText("You try to tap into the power within you, but your burning throat reminds you that you're not yet ready to unleash it again...");
		doNext(combatMenu);
		return;
	}
//This is now automatic - newRound arg defaults to true:	menuLoc = 0;
	fatigue(20, 1);
	player.createStatusAffect(StatusAffects.DragonBreathCooldown,0,0,0,0);
	var damage:Number = int(player.level * 8 + 25 + rand(10));
	
	damage = calcInfernoMod(damage);
	
	if(player.findStatusAffect(StatusAffects.DragonBreathBoost) >= 0) {
		player.removeStatusAffect(StatusAffects.DragonBreathBoost);
		damage *= 1.5;
	}
	//Shell
	if(monster.findStatusAffect(StatusAffects.Shell) >= 0) {
		outputText("As soon as your magic touches the multicolored shell around " + monster.a + monster.short + ", it sizzles and fades to nothing.  Whatever that thing is, it completely blocks your magic!\n\n");
		enemyAI();
		return;
	}
	//Amily!
	if(monster.findStatusAffect(StatusAffects.Concentration) >= 0) {
		outputText("Amily easily glides around your attack thanks to her complete concentration on your movements.", true);
		enemyAI();
		return;
	}
	if (monster is LivingStatue)
	{
		outputText("The fire courses by the stone skin harmlessly. It does leave the surface of the statue glossier in its wake.");
		enemyAI();
		return;
	}
	outputText("Tapping into the power deep within you, you let loose a bellowing roar at your enemy, so forceful that even the environs crumble around " + monster.pronoun2 + ".  " + monster.capitalA + monster.short + " does " + monster.pronoun3 + " best to avoid it, but the wave of force is too fast.");
	if(monster.findStatusAffect(StatusAffects.Sandstorm) >= 0) {
		outputText("  <b>Your breath is massively dissipated by the swirling vortex, causing it to hit with far less force!</b>");
		damage = Math.round(0.2 * damage);
	}
	//Miss: 
	if((player.findStatusAffect(StatusAffects.Blind) >= 0 && rand(2) == 0) || (monster.spe - player.spe > 0 && int(Math.random()*(((monster.spe-player.spe)/4)+80)) > 80)) {
		outputText("  Despite the heavy impact caused by your roar, " + monster.a + monster.short + " manages to take it at an angle and remain on " + monster.pronoun3 + " feet and focuses on you, ready to keep fighting.");
	}
	//Special enemy avoidances
	else if(monster.short == "Vala" && monster.findStatusAffect(StatusAffects.Stunned) < 0) {
		outputText("Vala beats her wings with surprising strength, blowing the fireball back at you! ", false);		
		if(player.findPerk(PerkLib.Evade) >= 0 && rand(2) == 0) {
			outputText("You dive out of the way and evade it!", false);
		}
		else if(player.findPerk(PerkLib.Flexibility) >= 0 && rand(4) == 0) {
			outputText("You use your flexibility to barely fold your body out of the way!", false);
		}
		//Determine if blocked!
		else if (combatBlock(true)) {
			outputText("You manage to block your own fire with your " + player.shieldName + "!");
		}
		else {
			damage = takeDamage(damage);
			outputText("Your own fire smacks into your face! <b>(<font color=\"#800000\">" + damage + "</font>)</b>", false);
		}
		outputText("\n\n", false);
	}
	//Goos burn
	else if(monster.short == "goo-girl") {
		outputText(" Your flames lick the girl's body and she opens her mouth in pained protest as you evaporate much of her moisture. When the fire passes, she seems a bit smaller and her slimy " + monster.skinTone + " skin has lost some of its shimmer. ", false);
		if(monster.findPerk(PerkLib.Acid) < 0) monster.createPerk(PerkLib.Acid,0,0,0,0);
		damage = Math.round(damage * 1.5);
		damage = doDamage(damage);
		monster.createStatusAffect(StatusAffects.Stunned,0,0,0,0);
		outputText("<b>(<font color=\"#800000\">" + damage + "</font>)</b>\n\n", false);
	}
	else {
		if(monster.findPerk(PerkLib.Resolute) < 0) {
			outputText("  " + monster.capitalA + monster.short + " reels as your wave of force slams into " + monster.pronoun2 + " like a ton of rock!  The impact sends " + monster.pronoun2 + " crashing to the ground, too dazed to strike back.");
			monster.createStatusAffect(StatusAffects.Stunned,1,0,0,0);
		}
		else {
			outputText("  " + monster.capitalA + monster.short + " reels as your wave of force slams into " + monster.pronoun2 + " like a ton of rock!  The impact sends " + monster.pronoun2 + " staggering back, but <b>" + monster.pronoun1 + " ");
			if(!monster.plural) outputText("is ");
			else outputText("are");
			outputText("too resolute to be stunned by your attack.</b>");
		}
		damage = doDamage(damage);
		outputText(" <b>(<font color=\"#800000\">" + damage + "</font>)</b>");
	}
	outputText("\n\n");
	checkAchievementDamage(damage);
	if(monster.short == "Holli" && monster.findStatusAffect(StatusAffects.HolliBurning) < 0) (monster as Holli).lightHolliOnFireMagically();
	combatRoundOver();
}

//* Terrestrial Fire
public function fireballuuuuu():void {
	clearOutput();
	if(player.fatigue + 20 > player.maxFatigue()) {
		outputText("You are too tired to breathe fire.", true);
		doNext(combatMenu);
		return;
	}
//This is now automatic - newRound arg defaults to true:	menuLoc = 0;
	changeFatigue(20);
	
	//[Failure]
	//(high damage to self, +10 fatigue on top of ability cost)
	if(rand(5) == 0 || player.findStatusAffect(StatusAffects.WebSilence) >= 0) {
		if(player.findStatusAffect(StatusAffects.WebSilence) >= 0) outputText("You reach for the terrestrial fire, but as you ready to release a torrent of flame, it backs up in your throat, blocked by the webbing across your mouth.  It causes you to cry out as the sudden, heated force explodes in your own throat. ", false);
		else if(player.findStatusAffect(StatusAffects.GooArmorSilence) >= 0) outputText("You reach for the terrestrial fire but as you ready the torrent, it erupts prematurely, causing you to cry out as the sudden heated force explodes in your own throat.  The slime covering your mouth bubbles and pops, boiling away where the escaping flame opens small rents in it.  That wasn't as effective as you'd hoped, but you can at least speak now. ");
		else outputText("You reach for the terrestrial fire, but as you ready to release a torrent of flame, the fire inside erupts prematurely, causing you to cry out as the sudden heated force explodes in your own throat. ", false);
		changeFatigue(10);
		takeDamage(10 + rand(20), true);
		outputText("\n\n");
		enemyAI();
		return;
	}
	
	var damage:Number;
	damage = int(player.level * 10 + 45 + rand(10));
	damage = calcInfernoMod(damage);
	
	if(monster.findStatusAffect(StatusAffects.Shell) >= 0) {
		outputText("As soon as your magic touches the multicolored shell around " + monster.a + monster.short + ", it sizzles and fades to nothing.  Whatever that thing is, it completely blocks your magic!\n\n");
		enemyAI();
		return;
	}
	//Amily!
	if(monster.findStatusAffect(StatusAffects.Concentration) >= 0) {
		outputText("Amily easily glides around your attack thanks to her complete concentration on your movements.", true);
		enemyAI();
		return;
	}
	if (monster is LivingStatue)
	{
		outputText("The fire courses by the stone skin harmlessly. It does leave the surface of the statue glossier in its wake.");
		enemyAI();
		return;
	}
	if (monster is Doppleganger)
	{
		(monster as Doppleganger).handleSpellResistance("fireball");
		flags[kFLAGS.SPELLS_CAST]++;
		spellPerkUnlock();
		return;
	}
	if(player.findStatusAffect(StatusAffects.GooArmorSilence) >= 0) {
		outputText("<b>A growl rumbles from deep within as you charge the terrestrial fire, and you force it from your chest and into the slime.  The goop bubbles and steams as it evaporates, drawing a curious look from your foe, who pauses in her onslaught to lean in and watch.  While the tension around your mouth lessens and your opponent forgets herself more and more, you bide your time.  When you can finally work your jaw enough to open your mouth, you expel the lion's - or jaguar's? share of the flame, inflating an enormous bubble of fire and evaporated slime that thins and finally pops to release a superheated cloud.  The armored girl screams and recoils as she's enveloped, flailing her arms.</b> ", false);
		player.removeStatusAffect(StatusAffects.GooArmorSilence);
		damage += 25;
	}
	else outputText("A growl rumbles deep with your chest as you charge the terrestrial fire.  When you can hold it no longer, you release an ear splitting roar and hurl a giant green conflagration at your enemy. ", false);

	if(monster.short == "Isabella" && monster.findStatusAffect(StatusAffects.Stunned) < 0) {
		outputText("Isabella shoulders her shield into the path of the emerald flames.  They burst over the wall of steel, splitting around the impenetrable obstruction and washing out harmlessly to the sides.\n\n", false);
		if (isabellaFollowerScene.isabellaAccent()) outputText("\"<i>Is zat all you've got?  It'll take more than a flashy magic trick to beat Izabella!</i>\" taunts the cow-girl.\n\n", false);
		else outputText("\"<i>Is that all you've got?  It'll take more than a flashy magic trick to beat Isabella!</i>\" taunts the cow-girl.\n\n", false);
		enemyAI();
		return;
	}
	else if(monster.short == "Vala" && monster.findStatusAffect(StatusAffects.Stunned) < 0) {
		outputText("Vala beats her wings with surprising strength, blowing the fireball back at you! ", false);		
		if(player.findPerk(PerkLib.Evade) >= 0 && rand(2) == 0) {
			outputText("You dive out of the way and evade it!", false);
		}
		else if(player.findPerk(PerkLib.Flexibility) >= 0 && rand(4) == 0) {
			outputText("You use your flexibility to barely fold your body out of the way!", false);
		}
		else {
			//Determine if blocked!
			if (combatBlock(true)) {
				outputText("You manage to block your own fire with your " + player.shieldName + "!");
				combatRoundOver();
				return;
			}
			outputText("Your own fire smacks into your face! <b>(<font color=\"#800000\">" + damage + "</font>)</b>", false);
			takeDamage(damage);
		}
		outputText("\n\n", false);
	}
	else {
		//Using fire attacks on the goo]
		if(monster.short == "goo-girl") {
			outputText(" Your flames lick the girl's body and she opens her mouth in pained protest as you evaporate much of her moisture. When the fire passes, she seems a bit smaller and her slimy " + monster.skinTone + " skin has lost some of its shimmer. ", false);
			if(monster.findPerk(PerkLib.Acid) < 0) monster.createPerk(PerkLib.Acid,0,0,0,0);
			damage = Math.round(damage * 1.5);
		}
		if(monster.findStatusAffect(StatusAffects.Sandstorm) >= 0) {
			outputText("<b>Your breath is massively dissipated by the swirling vortex, causing it to hit with far less force!</b>  ");
			damage = Math.round(0.2 * damage);
		}
		outputText("<b>(<font color=\"#800000\">" + damage + "</font>)</b>\n\n", false);
		monster.HP -= damage;
		if(monster.short == "Holli" && monster.findStatusAffect(StatusAffects.HolliBurning) < 0) (monster as Holli).lightHolliOnFireMagically();
	}
	checkAchievementDamage(damage);
	if(monster.HP < 1) {
		doNext(endHpVictory);
	}
	else enemyAI();
}

public function kissAttack():void {
	if(player.findStatusAffect(StatusAffects.Blind) >= 0) {
		outputText("There's no way you'd be able to find their lips while you're blind!", true);
//Pass false to combatMenu instead:		menuLoc = 3;
		doNext(physicalSpecials);
		return;
	}
	clearOutput();
	var attack:Number = rand(6);
	switch(attack) {
		case 1:
			//Attack text 1:
			outputText("You hop up to " + monster.a + monster.short + " and attempt to plant a kiss on " + monster.pronoun3 + ".", false);
			break;
		//Attack text 2:
		case 2:
			outputText("You saunter up and dart forward, puckering your golden lips into a perfect kiss.", false);
			break;
		//Attack text 3: 
		case 3:
			outputText("Swaying sensually, you wiggle up to " + monster.a + monster.short + " and attempt to plant a nice wet kiss on " + monster.pronoun2 + ".", false);
			break;
		//Attack text 4:
		case 4:
			outputText("Lunging forward, you fly through the air at " + monster.a + monster.short + " with your lips puckered and ready to smear drugs all over " + monster.pronoun2 + ".", false);
			break;
		//Attack text 5:
		case 5:
			outputText("You lean over, your lips swollen with lust, wet with your wanting slobber as you close in on " + monster.a + monster.short + ".", false);
			break;
		//Attack text 6:
		default:
			outputText("Pursing your drug-laced lips, you close on " + monster.a + monster.short + " and try to plant a nice, wet kiss on " + monster.pronoun2 + ".", false);
			break;
	}
	//Dodged!
	if(monster.spe - player.spe > 0 && rand(((monster.spe - player.spe)/4)+80) > 80) {
		attack = rand(3);
		switch(attack) {
			//Dodge 1:
			case 1:
				if(monster.plural) outputText("  " + monster.capitalA + monster.short + " sees it coming and moves out of the way in the nick of time!\n\n", false);
				break;
			//Dodge 2:
			case 2:
				if(monster.plural) outputText("  Unfortunately, you're too slow, and " + monster.a + monster.short + " slips out of the way before you can lay a wet one on one of them.\n\n", false);
				else outputText("  Unfortunately, you're too slow, and " + monster.a + monster.short + " slips out of the way before you can lay a wet one on " + monster.pronoun2 + ".\n\n", false);
				break;
			//Dodge 3:
			default:
				if(monster.plural) outputText("  Sadly, " + monster.a + monster.short + " moves aside, denying you the chance to give one of them a smooch.\n\n", false);
				else outputText("  Sadly, " + monster.a + monster.short + " moves aside, denying you the chance to give " + monster.pronoun2 + " a smooch.\n\n", false);
				break;
		}
		enemyAI();
		return;
	}
	//Success but no effect:
	if(monster.lustVuln <= 0 || !monster.hasCock()) {
		if(monster.plural) outputText("  Mouth presses against mouth, and you allow your tongue to stick out to taste the saliva of one of their number, making sure to give them a big dose.  Pulling back, you look at " + monster.a + monster.short + " and immediately regret wasting the time on the kiss.  It had no effect!\n\n", false);
		else outputText("  Mouth presses against mouth, and you allow your tongue to stick to taste " + monster.pronoun3 + "'s saliva as you make sure to give them a big dose.  Pulling back, you look at " + monster.a + monster.short + " and immediately regret wasting the time on the kiss.  It had no effect!\n\n", false);
		enemyAI();
		return;
	}
	attack = rand(4);
	var damage:Number = 0;
	switch(attack) {
		//Success 1:
		case 1:
			if(monster.plural) outputText("  Success!  A spit-soaked kiss lands right on one of their mouths.  The victim quickly melts into your embrace, allowing you to give them a nice, heavy dose of sloppy oral aphrodisiacs.", false);
			else outputText("  Success!  A spit-soaked kiss lands right on " + monster.a + monster.short + "'s mouth.  " + monster.mf("He","She") + " quickly melts into your embrace, allowing you to give them a nice, heavy dose of sloppy oral aphrodisiacs.", false);
			damage = 15;
			break;
		//Success 2:
		case 2:
			if(monster.plural) outputText("  Gold-gilt lips press into one of their mouths, the victim's lips melding with yours.  You take your time with your suddenly cooperative captive and make sure to cover every bit of their mouth with your lipstick before you let them go.", false);
			else outputText("  Gold-gilt lips press into " + monster.a + monster.short + ", " + monster.pronoun3 + " mouth melding with yours.  You take your time with your suddenly cooperative captive and make sure to cover every inch of " + monster.pronoun3 + " with your lipstick before you let " + monster.pronoun2 + " go.", false);
			damage = 20;
			break;
		//CRITICAL SUCCESS (3)
		case 3:
			if(monster.plural) outputText("  You slip past " + monster.a + monster.short + "'s guard and press your lips against one of them.  " + monster.mf("He","She") + " melts against you, " + monster.mf("his","her") + " tongue sliding into your mouth as " + monster.mf("he","she") + " quickly succumbs to the fiery, cock-swelling kiss.  It goes on for quite some time.  Once you're sure you've given a full dose to " + monster.mf("his","her") + " mouth, you break back and observe your handwork.  One of " + monster.a + monster.short + " is still standing there, licking " + monster.mf("his","her") + " his lips while " + monster.mf("his","her") + " dick is standing out, iron hard.  You feel a little daring and give the swollen meat another moist peck, glossing the tip in gold.  There's no way " + monster.mf("he","she") + " will go soft now.  Though you didn't drug the rest, they're probably a little 'heated up' from the show.", false);
			else outputText("  You slip past " + monster.a + monster.short + "'s guard and press your lips against " + monster.pronoun3 + ".  " + monster.mf("He","She") + " melts against you, " + monster.pronoun3 + " tongue sliding into your mouth as " + monster.pronoun1 + " quickly succumbs to the fiery, cock-swelling kiss.  It goes on for quite some time.  Once you're sure you've given a full dose to " + monster.pronoun3 + " mouth, you break back and observe your handwork.  " + monster.capitalA + monster.short + " is still standing there, licking " + monster.pronoun3 + " lips while " + monster.pronoun3 + " dick is standing out, iron hard.  You feel a little daring and give the swollen meat another moist peck, glossing the tip in gold.  There's no way " + monster.pronoun1 + " will go soft now.", false);
			damage = 30;
			break;
		//Success 4:
		default:
			outputText("  With great effort, you slip through an opening and compress their lips against your own, lust seeping through the oral embrace along with a heavy dose of drugs.", false);
			damage = 12;
			break;
	}
	//Add status if not already drugged
	if(monster.findStatusAffect(StatusAffects.LustStick) < 0) monster.createStatusAffect(StatusAffects.LustStick,0,0,0,0);
	//Else add bonus to round damage
	else monster.addStatusValue(StatusAffects.LustStick,2,Math.round(damage/10));
	//Deal damage
	monster.teased(monster.lustVuln * damage);
	outputText("\n\n");
	//Sets up for end of combat, and if not, goes to AI.
	if(!combatRoundOver()) enemyAI();
}
public function possess():void {
	clearOutput();
	if(monster.short == "plain girl" || monster.findPerk(PerkLib.Incorporeality) >= 0) {
		outputText("With a smile and a wink, your form becomes completely intangible, and you waste no time in throwing yourself toward the opponent's frame.  Sadly, it was doomed to fail, as you bounce right off your foe's ghostly form.", false);
	}
	else if (monster is LivingStatue)
	{
		outputText("There is nothing to possess inside the golem.");
	}
	//Sample possession text (>79 int, perhaps?):
	else if((!monster.hasCock() && !monster.hasVagina()) || monster.lustVuln == 0 || monster.inte == 0 || monster.inte > 100) {
		outputText("With a smile and a wink, your form becomes completely intangible, and you waste no time in throwing yourself into the opponent's frame.  Unfortunately, it seems ", false);
		if(monster.inte > 100) outputText("they were FAR more mentally prepared than anything you can handle, and you're summarily thrown out of their body before you're even able to have fun with them.  Darn, you muse.\n\n", false);
		else outputText("they have a body that's incompatible with any kind of possession.\n\n", false);
	}
	//Success!
	else if(player.inte >= (monster.inte - 10) + rand(21)) {
		outputText("With a smile and a wink, your form becomes completely intangible, and you waste no time in throwing yourself into your opponent's frame. Before they can regain the initiative, you take control of one of their arms, vigorously masturbating for several seconds before you're finally thrown out. Recorporealizing, you notice your enemy's blush, and know your efforts were somewhat successful.", false);
		var damage:Number = Math.round(player.inte/5) + rand(player.level) + player.level;
		monster.teased(monster.lustVuln * damage);
		outputText("\n\n");
	}
	//Fail
	else {
		outputText("With a smile and a wink, your form becomes completely intangible, and you waste no time in throwing yourself into the opponent's frame. Unfortunately, it seems they were more mentally prepared than you hoped, and you're summarily thrown out of their body before you're even able to have fun with them. Darn, you muse. Gotta get smarter.\n\n", false);
	}
	if(!combatRoundOver()) enemyAI();
}

public function runAway(callHook:Boolean = true):void {
	if (callHook && monster.onPcRunAttempt != null){
		monster.onPcRunAttempt();
		return;
	}
	clearOutput();
	if (inCombat && player.findStatusAffect(StatusAffects.Sealed) >= 0 && player.statusAffectv2(StatusAffects.Sealed) == 4) {
		clearOutput();
		outputText("You try to run, but you just can't seem to escape.  <b>Your ability to run was sealed, and now you've wasted a chance to attack!</b>\n\n");
		enemyAI();
		return;
	}
	//Rut doesnt let you run from dicks.
	if(player.inRut && monster.totalCocks() > 0) {
		outputText("The thought of another male in your area competing for all the pussy infuriates you!  No way will you run!", true);
//Pass false to combatMenu instead:		menuLoc = 3;
//		doNext(combatMenu);
		menu();
		addButton(0, "Next", combatMenu, false);
		return;
	}
	if(monster.findStatusAffect(StatusAffects.Level) >= 0 && player.canFly()) {
		clearOutput();
		outputText("You flex the muscles in your back and, shaking clear of the sand, burst into the air!  Wasting no time you fly free of the sandtrap and its treacherous pit.  \"One day your wings will fall off, little ant,\" the snarling voice of the thwarted androgyne carries up to you as you make your escape.  \"And I will be waiting for you when they do!\"");
		inCombat = false;
		clearStatuses(false);
		doNext(camp.returnToCampUseOneHour);
		return;
	}
	if(monster.findStatusAffect(StatusAffects.GenericRunDisabled) >= 0 || urtaQuest.isUrta()) {
		outputText("You can't escape from this fight!");
//Pass false to combatMenu instead:		menuLoc = 3;
//		doNext(combatMenu);
		menu();
		addButton(0, "Next", combatMenu, false);
		return;
	}
	if(monster.findStatusAffect(StatusAffects.Level) >= 0 && monster.statusAffectv1(StatusAffects.Level) < 4) {
		outputText("You're too deeply mired to escape!  You'll have to <b>climb</b> some first!");
//Pass false to combatMenu instead:		menuLoc = 3;
//		doNext(combatMenu);
		menu();
		addButton(0, "Next", combatMenu, false);
		return;
	}
	if(monster.findStatusAffect(StatusAffects.RunDisabled) >= 0) {
		outputText("You'd like to run, but you can't scale the walls of the pit with so many demonic hands pulling you down!");
//Pass false to combatMenu instead:		menuLoc = 3;
//		doNext(combatMenu);
		menu();
		addButton(0, "Next", combatMenu, false);
		return;
	}
	if(flags[kFLAGS.UNKNOWN_FLAG_NUMBER_00329] == 1 && (monster.short == "minotaur gang" || monster.short == "minotaur tribe")) {
		flags[kFLAGS.UNKNOWN_FLAG_NUMBER_00329] = 0;
		//(Free run away) 
		outputText("You slink away while the pack of brutes is arguing.  Once they finish that argument, they'll be sorely disappointed!", true);
		inCombat = false;
		clearStatuses(false);
		doNext(camp.returnToCampUseOneHour);
		return;
	}
	else if(monster.short == "minotaur tribe" && monster.HPRatio() >= 0.75) {
		outputText("There's too many of them surrounding you to run!", true);
//Pass false to combatMenu instead:		menuLoc = 3;
//		doNext(combatMenu);
		menu();
		addButton(0, "Next", combatMenu, false);
		return;
	}
	if(inDungeon || inRoomedDungeon) {
		outputText("You're trapped in your foe's home turf - there is nowhere to run!\n\n", true);
		enemyAI();
		return;
	}
	if (prison.inPrison && !prison.prisonCanEscapeRun()) {
		addButton(0, "Next", combatMenu, false);
		return;
	}
	//Attempt texts!
	if(monster.short == "Marae") {
		outputText("Your boat is blocked by tentacles! ");
		if(!player.canFly()) outputText("You may not be able to swim fast enough. ");
		else outputText("You grit your teeth with effort as you try to fly away but the tentacles suddenly grab your " + player.legs() + " and pull you down. ");
		outputText("It looks like you cannot escape. ");
		enemyAI();
		return;
	}
	if(monster.short == "Ember") {
		outputText("You take off");
		if(!player.canFly()) outputText(" running");
		else outputText(", flapping as hard as you can");
		outputText(", and Ember, caught up in the moment, gives chase.  ");
	}
	if (monster.short == "lizan rogue") {
		outputText("As you retreat the lizan doesn't even attempt to stop you. When you look back to see if he's still there you find nothing but the empty bog around you.");
		gameState = 0;
		clearStatuses(false);
		doNext(camp.returnToCampUseOneHour);
		return;
	}
	else if(player.canFly()) outputText("Gritting your teeth with effort, you beat your wings quickly and lift off!  ", false);	
	//Nonflying PCs
	else {
		//In prison!
		if (prison.inPrison) {
			outputText("You make a quick dash for the door and attempt to escape! ");
		}
		//Stuck!
		else if(player.findStatusAffect(StatusAffects.NoFlee) >= 0) {
			if(monster.short == "goblin") outputText("You try to flee but get stuck in the sticky white goop surrounding you.\n\n", true);
			else outputText("You put all your skills at running to work and make a supreme effort to escape, but are unable to get away!\n\n", true);
			enemyAI();
			return;
		}
		//Nonstuck!
		else outputText("You turn tail and attempt to flee!  ", false);
	}
		
	//Calculations
	var escapeMod:Number = 20 + monster.level * 3;
	if(debug) escapeMod -= 300;
	if(player.canFly()) escapeMod -= 20;
	if(player.tailType == TAIL_TYPE_RACCOON && player.earType == EARS_RACCOON && player.findPerk(PerkLib.Runner) >= 0) escapeMod -= 25;
	if(monster.findStatusAffect(StatusAffects.Stunned) >= 0) escapeMod -= 50;
	
	//Big tits doesn't matter as much if ya can fly!
	else {
		if(player.biggestTitSize() >= 35) escapeMod += 5;
		if(player.biggestTitSize() >= 66) escapeMod += 10;
		if(player.hipRating >= 20) escapeMod += 5;
		if(player.buttRating >= 20) escapeMod += 5;
		if(player.ballSize >= 24 && player.balls > 0) escapeMod += 5;
		if(player.ballSize >= 48 && player.balls > 0) escapeMod += 10;
		if(player.ballSize >= 120 && player.balls > 0) escapeMod += 10;
	}
	//ANEMONE OVERRULES NORMAL RUN
	if(monster.short == "anemone") {
		//Autosuccess - less than 60 lust
		if(player.lust < 60) {
			outputText("Marshalling your thoughts, you frown at the strange girl and turn to march up the beach.  After twenty paces inshore you turn back to look at her again.  The anemone is clearly crestfallen by your departure, pouting heavily as she sinks beneath the water's surface.", true);
			inCombat = false;
			clearStatuses(false);
			doNext(camp.returnToCampUseOneHour);
			return;
		}
		//Speed dependent
		else {
			//Success
			if(player.spe > rand(monster.spe+escapeMod)) {
				inCombat = false;
				clearStatuses(false);
				outputText("Marshalling your thoughts, you frown at the strange girl and turn to march up the beach.  After twenty paces inshore you turn back to look at her again.  The anemone is clearly crestfallen by your departure, pouting heavily as she sinks beneath the water's surface.", true);
				doNext(camp.returnToCampUseOneHour);
				return;
			}
			//Run failed:
			else {
				outputText("You try to shake off the fog and run but the anemone slinks over to you and her tentacles wrap around your waist.  <i>\"Stay?\"</i> she asks, pressing her small breasts into you as a tentacle slides inside your " + player.armorName + " and down to your nethers.  The combined stimulation of the rubbing and the tingling venom causes your knees to buckle, hampering your resolve and ending your escape attempt.", false);
				//(gain lust, temp lose spd/str)
				(monster as Anemone).applyVenom((4+player.sens/20));
				combatRoundOver();
				return;
			}
		}
	}
	//Ember is SPUCIAL
	if(monster.short == "Ember") {
		//GET AWAY
		if(player.spe > rand(monster.spe + escapeMod) || (player.findPerk(PerkLib.Runner) >= 0 && rand(100) < 50)) {
			if(player.findPerk(PerkLib.Runner) >= 0) outputText("Using your skill at running, y");
			else outputText("Y");
			outputText("ou easily outpace the dragon, who begins hurling imprecations at you.  \"What the hell, [name], you weenie; are you so scared that you can't even stick out your punishment?\"");
			outputText("\n\nNot to be outdone, you call back, \"Sucks to you!  If even the mighty Last Ember of Hope can't catch me, why do I need to train?  Later, little bird!\"");
			inCombat = false;
			clearStatuses(false);
			doNext(camp.returnToCampUseOneHour);
		}
		//Fail: 
		else {
			outputText("Despite some impressive jinking, " + emberScene.emberMF("he","she") + " catches you, tackling you to the ground.\n\n");
			enemyAI();
		}
		return;
	}
	//SUCCESSFUL FLEE
	if (player.spe > rand(monster.spe + escapeMod)) {
		//Escape prison
		if (prison.inPrison) {
			outputText("You quickly bolt out of the main entrance and after hiding for a good while, there's no sign of " + monster.a + " " + monster.short + ". You sneak back inside to retrieve whatever you had before you were captured. ");
			inCombat = false;
			clearStatuses(false);
			prison.prisonEscapeSuccessText();
			doNext(prison.prisonEscapeFinalePart1);
			return;
		}
		//Fliers flee!
		else if(player.canFly()) outputText(monster.capitalA + monster.short + " can't catch you.", false);
		//sekrit benefit: if you have coon ears, coon tail, and Runner perk, change normal Runner escape to flight-type escape
		else if(player.tailType == TAIL_TYPE_RACCOON && player.earType == EARS_RACCOON && player.findPerk(PerkLib.Runner) >= 0) {
			outputText("Using your running skill, you build up a head of steam and jump, then spread your arms and flail your tail wildly; your opponent dogs you as best " + monster.pronoun1 + " can, but stops and stares dumbly as your spastic tail slowly propels you several meters into the air!  You leave " + monster.pronoun2 + " behind with your clumsy, jerky, short-range flight.");
		}
		//Non-fliers flee
		else outputText(monster.capitalA + monster.short + " rapidly disappears into the shifting landscape behind you.", false);
		if(monster.short == "Izma") {
			outputText("\n\nAs you leave the tigershark behind, her taunting voice rings out after you.  \"<i>Oooh, look at that fine backside!  Are you running or trying to entice me?  Haha, looks like we know who's the superior specimen now!  Remember: next time we meet, you owe me that ass!</i>\"  Your cheek tingles in shame at her catcalls.", false);
		}
		inCombat = false;
		clearStatuses(false);
		doNext(camp.returnToCampUseOneHour);
		return;
	}
	//Runner perk chance
	else if(player.findPerk(PerkLib.Runner) >= 0 && rand(100) < 50) {
		inCombat = false;
		outputText("Thanks to your talent for running, you manage to escape.", false);
		if(monster.short == "Izma") {
			outputText("\n\nAs you leave the tigershark behind, her taunting voice rings out after you.  \"<i>Oooh, look at that fine backside!  Are you running or trying to entice me?  Haha, looks like we know who's the superior specimen now!  Remember: next time we meet, you owe me that ass!</i>\"  Your cheek tingles in shame at her catcalls.", false);
		}
		clearStatuses(false);
		doNext(camp.returnToCampUseOneHour);
		return;
	}
	//FAIL FLEE
	else {
		if(monster.short == "Holli") {
			(monster as Holli).escapeFailWithHolli();
			return;
		}
		//Flyers get special failure message.
		if(player.canFly()) {
			if(monster.plural) outputText(monster.capitalA + monster.short + " manage to grab your " + player.legs() + " and drag you back to the ground before you can fly away!", false);
			else outputText(monster.capitalA + monster.short + " manages to grab your " + player.legs() + " and drag you back to the ground before you can fly away!", false);
		}
		//fail
		else if(player.tailType == TAIL_TYPE_RACCOON && player.earType == EARS_RACCOON && player.findPerk(PerkLib.Runner) >= 0) outputText("Using your running skill, you build up a head of steam and jump, but before you can clear the ground more than a foot, your opponent latches onto you and drags you back down with a thud!");
		//Nonflyer messages
		else {
			//Huge balls messages
			if(player.balls > 0 && player.ballSize >= 24) {
				if(player.ballSize < 48) outputText("With your " + ballsDescriptLight() + " swinging ponderously beneath you, getting away is far harder than it should be.  ", false);
				else outputText("With your " + ballsDescriptLight() + " dragging along the ground, getting away is far harder than it should be.  ", false);
			}
			//FATASS BODY MESSAGES
			if(player.biggestTitSize() >= 35 || player.buttRating >= 20 || player.hipRating >= 20)
			{
				//FOR PLAYERS WITH GIANT BREASTS
				if(player.biggestTitSize() >= 35 && player.biggestTitSize() < 66)
				{
					if(player.hipRating >= 20)
					{
						outputText("Your " + hipDescript() + " forces your gait to lurch slightly side to side, which causes the fat of your " + player.skinTone + " ", false);
						if(player.buttRating >= 20) outputText(buttDescript() + " and ", false);
						outputText(chestDesc() + " to wobble immensely, throwing you off balance and preventing you from moving quick enough to escape.", false);
					}
					else if(player.buttRating >= 20) outputText("Your " + player.skinTone + buttDescript() + " and " + chestDesc() + " wobble and bounce heavily, throwing you off balance and preventing you from moving quick enough to escape.", false);
					else outputText("Your " + chestDesc() + " jiggle and wobble side to side like the " + player.skinTone + " sacks of milky fat they are, with such force as to constantly throw you off balance, preventing you from moving quick enough to escape.", false);
				}
				//FOR PLAYERS WITH MASSIVE BREASTS
				else if(player.biggestTitSize() >= 66) {
					if(player.hipRating >= 20) {
						outputText("Your " + chestDesc() + " nearly drag along the ground while your " + hipDescript() + " swing side to side ", false);
						if(player.buttRating >= 20) outputText("causing the fat of your " + player.skinTone + buttDescript() + " to wobble heavily, ", false);
						outputText("forcing your body off balance and preventing you from moving quick enough to get escape.", false);
					}
					else if(player.buttRating >= 20) outputText("Your " +chestDesc() + " nearly drag along the ground while the fat of your " + player.skinTone + buttDescript() + " wobbles heavily from side to side, forcing your body off balance and preventing you from moving quick enough to escape.", false);
					else outputText("Your " + chestDesc() + " nearly drag along the ground, preventing you from moving quick enough to get escape.", false);
				}
				//FOR PLAYERS WITH EITHER GIANT HIPS OR BUTT BUT NOT THE BREASTS
				else if(player.hipRating >= 20) {
					outputText("Your " + hipDescript() + " swing heavily from side to side ", false);
					if(player.buttRating >= 20) outputText("causing your " + player.skinTone + buttDescript() + " to wobble obscenely ", false);
					outputText("and forcing your body into an awkward gait that slows you down, preventing you from escaping.", false);
				}
				//JUST DA BOOTAH
				else if(player.buttRating >= 20) outputText("Your " + player.skinTone + buttDescript() + " wobbles so heavily that you're unable to move quick enough to escape.", false);
			}
			//NORMAL RUN FAIL MESSAGES
			else if(monster.plural) outputText(monster.capitalA + monster.short + " stay hot on your heels, denying you a chance at escape!", false);
			else outputText(monster.capitalA + monster.short + " stays hot on your heels, denying you a chance at escape!", false);
		}
	}
	outputText("\n\n", false);
	enemyAI();
}

public function anemoneSting():void {
	clearOutput();
	//-sting with hair (combines both bee-sting effects, but weaker than either one separately):
	//Fail!
	//25% base fail chance
	//Increased by 1% for every point over PC's speed
	//Decreased by 1% for every inch of hair the PC has
	var prob:Number = 70;
	if(monster.spe > player.spe) prob -= monster.spe - player.spe;
	prob += player.hairLength;
	if(prob <= rand(101)) {
		//-miss a sting
		if(monster.plural) outputText("You rush " + monster.a + monster.short + ", whipping your hair around to catch them with your tentacles, but " + monster.pronoun1 + " easily dodge.  Oy, you hope you didn't just give yourself whiplash.", false);
		else outputText("You rush " + monster.a + monster.short + ", whipping your hair around to catch it with your tentacles, but " + monster.pronoun1 + " easily dodges.  Oy, you hope you didn't just give yourself whiplash.", false);
	}	
	//Success!
	else {
		outputText("You rush " + monster.a + monster.short + ", whipping your hair around like a genie", false);
		outputText(", and manage to land a few swipes with your tentacles.  ", false);
		if(monster.plural) outputText("As the venom infiltrates " + monster.pronoun3 + " bodies, " + monster.pronoun1 + " twitch and begin to move more slowly, hampered half by paralysis and half by arousal.", false);
		else outputText("As the venom infiltrates " + monster.pronoun3 + " body, " + monster.pronoun1 + " twitches and begins to move more slowly, hampered half by paralysis and half by arousal.", false);
		//(decrease speed/str, increase lust)
		//-venom capacity determined by hair length, 2-3 stings per level of length
		//Each sting does 5-10 lust damage and 2.5-5 speed damage
		var damage:Number = 0;
		temp = 1 + rand(2);
		if(player.hairLength >= 12) temp += 1 + rand(2);
		if(player.hairLength >= 24) temp += 1 + rand(2);
		if(player.hairLength >= 36) temp += 1;
		while(temp > 0) {
			temp--;
			damage += 5 + rand(6);
		}
		damage += player.level * 1.5;
		monster.spe -= damage/2;
		damage = monster.lustVuln * damage;
		//Clean up down to 1 decimal point
		damage = Math.round(damage*10)/10;		
		monster.teased(damage);
	}
	//New lines and moving on!
	outputText("\n\n", false);
	doNext(combatMenu);
	if(!combatRoundOver()) enemyAI();
}

//------------
// M. SPECIALS
//------------
public function magicalSpecials():void {
	if (inCombat && player.findStatusAffect(StatusAffects.Sealed) >= 0 && player.statusAffectv2(StatusAffects.Sealed) == 6) {
		clearOutput();
		outputText("You try to ready a special ability, but wind up stumbling dizzily instead.  <b>Your ability to use magical special attacks was sealed, and now you've wasted a chance to attack!</b>\n\n");
		enemyAI();
		return;
	}
	menu();
	var button:int = 0;
	//Berserk
	if(player.findPerk(PerkLib.Berzerker) >= 0) {
		addButton(button++, "Berserk", berzerk, null, null, null, "Throw yourself into a rage!  Greatly increases the strength of your weapon and increases lust resistance, but your armor defense is reduced to zero!");
	}
	if(player.findPerk(PerkLib.Dragonfire) >= 0) {
		addButton(button++, "DragonFire", dragonBreath, null, null, null, "Unleash fire from your mouth. This can only be done once a day. \n\nFatigue Cost: " + spellCost(20), "Dragon Fire");
	}
	if(player.findPerk(PerkLib.FireLord) >= 0) {
		addButton(button++,"Fire Breath",fireballuuuuu, null, null, null, "Unleash fire from your mouth. \n\nFatigue Cost: 20", "Fire Breath");
	}
	if(player.findPerk(PerkLib.Hellfire) >= 0) {
		addButton(button++,"Hellfire",hellFire, null, null, null, "Unleash fire from your mouth. \n\nFatigue Cost: " + spellCost(20));
	}
	//Possess ability.
	if(player.findPerk(PerkLib.Incorporeality) >= 0) {
		addButton(button++, "Possess", possess, null, null, null, "Attempt to temporarily possess a foe and force them to raise their own lusts.");
	}
	if(player.findPerk(PerkLib.Whispered) >= 0) {
		addButton(button++, "Whisper", superWhisperAttack, null, null, null, "Whisper and induce fear in your opponent. \n\nFatigue Cost: " + spellCost(10) + "");
	}
	if(player.findPerk(PerkLib.CorruptedNinetails) >= 0) {
		addButton(button++, "C.FoxFire", corruptedFoxFire, null, null, null, "Unleash a corrupted purple flame at your opponent for high damage. Less effective against corrupted enemies. \n\nFatigue Cost: " + spellCost(35), "Corrupted FoxFire");
		addButton(button++, "Terror", kitsuneTerror, null, null, null, "Instill fear into your opponent with eldritch horrors. The more you cast this in a battle, the lesser effective it becomes. \n\nFatigue Cost: " + spellCost(20));
	}
	if(player.findPerk(PerkLib.EnlightenedNinetails) >= 0) {
		addButton(button++, "FoxFire", foxFire, null, null, null, "Unleash an ethereal blue flame at your opponent for high damage. More effective against corrupted enemies. \n\nFatigue Cost: " + spellCost(35));
		addButton(button++, "Illusion", kitsuneIllusion, null, null, null, "Warp the reality around your opponent, lowering their speed. The more you cast this in a battle, the lesser effective it becomes. \n\nFatigue Cost: " + spellCost(25));
	}
	if (player.findStatusAffect(StatusAffects.ShieldingSpell) >= 0) addButton(8, "Shielding", shieldingSpell);
	if (player.findStatusAffect(StatusAffects.ImmolationSpell) >= 0) addButton(8, "Immolation", immolationSpell);
	addButton(14, "Back", combatMenu, false);
}

//------------
// P. SPECIALS
//------------
public function physicalSpecials():void {
	if(urtaQuest.isUrta()) {
		urtaQuest.urtaSpecials();
		return;
	}
	if (inCombat && player.findStatusAffect(StatusAffects.Sealed) >= 0 && player.statusAffectv2(StatusAffects.Sealed) == 5) {
		clearOutput();
		outputText("You try to ready a special attack, but wind up stumbling dizzily instead.  <b>Your ability to use physical special attacks was sealed, and now you've wasted a chance to attack!</b>\n\n");
		enemyAI();
		return;
	}
	menu();
	var button:int = 0;
	if (player.hairType == 4) {
		addButton(button++, "AnemoneSting", anemoneSting, null, null, null, "Attempt to strike an opponent with the stinging tentacles growing from your scalp.  Reduces enemy speed and increases enemy lust.", "Anemone Sting");
	}
	//Bitez
	if (player.faceType == FACE_SHARK_TEETH) {
		addButton(button++, "Bite", bite, null, null, null, "Attempt to bite your opponent with your shark-teeth.");
	}
	else if (player.faceType == FACE_SNAKE_FANGS) {
		addButton(button++, "Bite", nagaBiteAttack, null, null, null, "Attempt to bite your opponent and inject venom.");
	}
	else if (player.faceType == FACE_SPIDER_FANGS) {
		addButton(button++, "Bite", spiderBiteAttack, null, null, null, "Attempt to bite your opponent and inject venom.");
	}
	//Bow attack
	if (player.hasKeyItem("Bow") >= 0 || player.hasKeyItem("Kelt's Bow") >= 0) {
		addButton(button++, "Bow", fireBow, null, null, null, "Use a bow to fire an arrow at your opponent.");
	}
	//Constrict
	if (player.lowerBody == LOWER_BODY_TYPE_NAGA) {
		addButton(button++, "Constrict", desert.nagaScene.nagaPlayerConstrict, null, null, null, "Attempt to bind an enemy in your long snake-tail.");
	}
	//Kick attackuuuu
	else if (player.isTaur() || player.lowerBody == LOWER_BODY_TYPE_HOOFED || player.lowerBody == LOWER_BODY_TYPE_BUNNY || player.lowerBody == LOWER_BODY_TYPE_KANGAROO) {
		addButton(button++, "Kick", kick, null, null, null, "Attempt to kick an enemy using your powerful lower body.");
	}
	//Gore if mino horns
	if (player.hornType == HORNS_COW_MINOTAUR && player.horns >= 6) {
		addButton(button++, "Gore", goreAttack, null, null, null, "Lower your head and charge your opponent, attempting to gore them on your horns.  This attack is stronger and easier to land with large horns.");
	}
	//Upheaval - requires rhino horn
	if (player.hornType == HORNS_RHINO && player.horns >= 2 && player.faceType == FACE_RHINO) {
		addButton(button++, "Upheaval", upheavalAttack, null, null, null, "Send your foe flying with your dual nose mounted horns. \n\nFatigue Cost: " + physicalCost(15) + "");
	}
	//Infest if infested
	if (player.findStatusAffect(StatusAffects.Infested) >= 0 && player.statusAffectv1(StatusAffects.Infested) == 5 && player.hasCock()) {
		addButton(button++, "Infest", mountain.wormsScene.playerInfest, null, null, null, "The infest attack allows you to cum at will, launching a stream of semen and worms at your opponent in order to infest them.  Unless your foe is very aroused they are likely to simply avoid it.  Only works on males or herms. \n\nAlso great for reducing your lust.");
	}
	//Kiss supercedes bite.
	if (player.findStatusAffect(StatusAffects.LustStickApplied) >= 0) {
		addButton(button++, "Kiss", kissAttack, null, null, null, "Attempt to kiss your foe on the lips with drugged lipstick.  It has no effect on those without a penis.");
	}
	switch (player.tailType) {
		case TAIL_TYPE_BEE_ABDOMEN:
			addButton(button++, "Sting", playerStinger, null, null, null, "Attempt to use your venomous bee stinger on an enemy.  Be aware it takes quite a while for your venom to build up, so depending on your abdomen's refractory period, you may have to wait quite a while between stings.  \n\nVenom: " + Math.floor(player.tailVenom) + "/100");
			break;
		case TAIL_TYPE_SPIDER_ADBOMEN:
			addButton(button++, "Web", PCWebAttack, null, null, null, "Attempt to use your abdomen to spray sticky webs at an enemy and greatly slow them down.  Be aware it takes a while for your webbing to build up.  \n\nWeb Amount: " + Math.floor(player.tailVenom) + "/100");
			break;
		case TAIL_TYPE_SHARK:
		case TAIL_TYPE_LIZARD:
		case TAIL_TYPE_KANGAROO:
		case TAIL_TYPE_DRACONIC:
		case TAIL_TYPE_RACCOON:
			addButton(button++, "Tail Whip", tailWhipAttack, null, null, null, "Whip your foe with your tail to enrage them and lower their defense!");
		default:
	}
	if (player.shield != ShieldLib.NOTHING) {
		addButton(button++, "Shield Bash", shieldBash, null, null, null, "Bash your opponent with a shield. Has a chance to stun. Bypasses stun immunity. \n\nThe more you stun your opponent, the harder it is to stun them again.");
	}
	addButton(14, "Back", combatMenu, false);
}

public function berzerk():void {
	clearOutput();
	if(player.findStatusAffect(StatusAffects.Berzerking) >= 0) {
		outputText("You're already pretty goddamn mad!", true);
		doNext(magicalSpecials);
		return;
	}
//This is now automatic - newRound arg defaults to true:	menuLoc = 0;
	outputText("You roar and unleash your savage fury, forgetting about defense in order to destroy your foe!\n\n", true);
	player.createStatusAffect(StatusAffects.Berzerking,0,0,0,0);
	enemyAI();
}

//Corrupted Fox Fire
public function corruptedFoxFire():void {
	clearOutput();
	if(player.findPerk(PerkLib.BloodMage) < 0 && player.fatigue + spellCost(35) > player.maxFatigue()) {
		outputText("You are too tired to use this ability.", true);
		doNext(magicalSpecials);
		return;
	}
	if(player.findStatusAffect(StatusAffects.ThroatPunch) >= 0 || player.findStatusAffect(StatusAffects.WebSilence) >= 0) {
		outputText("You cannot focus to use this ability while you're having so much difficult breathing.", true);
		doNext(magicalSpecials);
		return;
	}
//This is now automatic - newRound arg defaults to true:	menuLoc = 0;
	fatigue(35,1);
	//Deals direct damage and lust regardless of enemy defenses.  Especially effective against non-corrupted targets.
	outputText("Holding out your palm, you conjure corrupted purple flame that dances across your fingertips.  You launch it at " + monster.a + monster.short + " with a ferocious throw, and it bursts on impact, showering dazzling lavender sparks everywhere.");

	var dmg:int = int(10+(player.inte/3 + rand(player.inte/2)) * spellMod());
	dmg = calcInfernoMod(dmg);
	if (monster.cor >= 66) dmg = Math.round(dmg * .66);
	else if (monster.cor >= 50) dmg = Math.round(dmg * .8);
	else if (monster.cor >= 25) dmg = Math.round(dmg * 1.0);
	else if (monster.cor >= 10) dmg = Math.round(dmg * 1.2);
	else dmg = Math.round(dmg * 1.3);
	//High damage to goes.
	if(monster.short == "goo-girl") temp = Math.round(temp * 1.5);
	//Using fire attacks on the goo]
	if(monster.short == "goo-girl") {
		outputText("  Your flames lick the girl's body and she opens her mouth in pained protest as you evaporate much of her moisture. When the fire passes, she seems a bit smaller and her slimy " + monster.skinTone + " skin has lost some of its shimmer.", false);
		if(monster.findPerk(PerkLib.Acid) < 0) monster.createPerk(PerkLib.Acid,0,0,0,0);
	}
	dmg = doDamage(dmg);
	outputText("  <b>(<font color=\"#800000\">" + dmg + "</font>)</b>\n\n", false);
	statScreenRefresh();
	flags[kFLAGS.SPELLS_CAST]++;
	spellPerkUnlock();
	if(monster.HP < 1) doNext(endHpVictory);
	else enemyAI();
}
//Fox Fire
public function foxFire():void {
	clearOutput();
	if(player.findPerk(PerkLib.BloodMage) < 0 && player.fatigue + spellCost(35) > player.maxFatigue()) {
		outputText("You are too tired to use this ability.", true);
		doNext(magicalSpecials);
		return;
	}
	if(player.findStatusAffect(StatusAffects.ThroatPunch) >= 0 || player.findStatusAffect(StatusAffects.WebSilence) >= 0) {
		outputText("You cannot focus to use this ability while you're having so much difficult breathing.", true);
		doNext(magicalSpecials);
		return;
	}
//This is now automatic - newRound arg defaults to true:	menuLoc = 0;
	fatigue(35,1);
	if(monster.findStatusAffect(StatusAffects.Shell) >= 0) {
		outputText("As soon as your magic touches the multicolored shell around " + monster.a + monster.short + ", it sizzles and fades to nothing.  Whatever that thing is, it completely blocks your magic!\n\n");
		enemyAI();
		return;
	}
	//Deals direct damage and lust regardless of enemy defenses.  Especially effective against corrupted targets.
	outputText("Holding out your palm, you conjure an ethereal blue flame that dances across your fingertips.  You launch it at " + monster.a + monster.short + " with a ferocious throw, and it bursts on impact, showering dazzling azure sparks everywhere.");
	var dmg:int = int(10+(player.inte/3 + rand(player.inte/2)) * spellMod());
	dmg = calcInfernoMod(dmg);
	if (monster.cor < 33) dmg = Math.round(dmg * .66);
	else if (monster.cor < 50) dmg = Math.round(dmg * .8);
	else if (monster.cor < 75) dmg = Math.round(dmg * 1.0);
	else if (monster.cor < 90) dmg = Math.round(dmg * 1.2);
	else dmg = Math.round(dmg * 1.3); //30% more damage against very high corruption.
	//High damage to goes.
	if(monster.short == "goo-girl") temp = Math.round(temp * 1.5);
	//Using fire attacks on the goo]
	if(monster.short == "goo-girl") {
		outputText("  Your flames lick the girl's body and she opens her mouth in pained protest as you evaporate much of her moisture. When the fire passes, she seems a bit smaller and her slimy " + monster.skinTone + " skin has lost some of its shimmer.", false);
		if(monster.findPerk(PerkLib.Acid) < 0) monster.createPerk(PerkLib.Acid,0,0,0,0);
	}
	dmg = doDamage(dmg);
	outputText("  <b>(<font color=\"#800000\">" + dmg + "</font>)</b>\n\n", false);
	statScreenRefresh();
	flags[kFLAGS.SPELLS_CAST]++;
	spellPerkUnlock();
	if(monster.HP < 1) doNext(endHpVictory);
	else enemyAI();
}

//Terror
public function kitsuneTerror():void {
	clearOutput();
	//Fatigue Cost: 25
	if(player.findPerk(PerkLib.BloodMage) < 0 && player.fatigue + spellCost(20) > player.maxFatigue()) {
		outputText("You are too tired to use this ability.", true);
		doNext(magicalSpecials);
		return;
	}
	if(monster.findStatusAffect(StatusAffects.Shell) >= 0) {
		outputText("As soon as your magic touches the multicolored shell around " + monster.a + monster.short + ", it sizzles and fades to nothing.  Whatever that thing is, it completely blocks your magic!\n\n");
		enemyAI();
		return;
	}
	if(player.findStatusAffect(StatusAffects.ThroatPunch) >= 0 || player.findStatusAffect(StatusAffects.WebSilence) >= 0) {
		outputText("You cannot focus to reach the enemy's mind while you're having so much difficult breathing.", true);
		doNext(magicalSpecials);
		return;
	}
	if(monster.short == "pod" || monster.inte == 0) {
		outputText("You reach for the enemy's mind, but cannot find anything.  You frantically search around, but there is no consciousness as you know it in the room.\n\n", true);
		changeFatigue(1);
		enemyAI();
		return;
	}
//This is now automatic - newRound arg defaults to true:	menuLoc = 0;
	fatigue(20,1);
	//Inflicts fear and reduces enemy SPD.
	outputText("The world goes dark, an inky shadow blanketing everything in sight as you fill " + monster.a + monster.short + "'s mind with visions of otherworldly terror that defy description.");
	//(succeed)
	if (player.inte / 10 + rand(20) + 1 > monster.inte / 10 + 10 + (monster.statusAffectv1(StatusAffects.FearCounter) * 2)) {
		outputText("  They cower in horror as they succumb to your illusion, believing themselves beset by eldritch horrors beyond their wildest nightmares.\n\n");
		if (monster.statusAffectv1(StatusAffects.FearCounter) > 0) monster.addStatusValue(StatusAffects.FearCounter, 1, 1)
		else monster.createStatusAffect(StatusAffects.FearCounter, 1, 0, 0, 0);
		monster.createStatusAffect(StatusAffects.Fear, 1, 0, 0, 0);
		monster.spe -= 5;
		if (monster.spe < 1) monster.spe = 1;
	}
	else {
		outputText("  The dark fog recedes as quickly as it rolled in as they push back your illusions, resisting your hypnotic influence.");
		if (monster.statusAffectv1(StatusAffects.FearCounter) >= 4) outputText(" Your foe might be resistant by now.");
		outputText("\n\n");
	}
	enemyAI();
}

//Illusion
public function kitsuneIllusion():void {
	clearOutput();
	//Fatigue Cost: 25
	if(player.findPerk(PerkLib.BloodMage) < 0 && player.fatigue + spellCost(25) > player.maxFatigue()) {
		outputText("You are too tired to use this ability.", true);
		doNext(magicalSpecials);
		return;
	}
	if(player.findStatusAffect(StatusAffects.ThroatPunch) >= 0 || player.findStatusAffect(StatusAffects.WebSilence) >= 0) {
		outputText("You cannot focus to use this ability while you're having so much difficult breathing.", true);
		doNext(magicalSpecials);
		return;
	}
	if(monster.short == "pod" || monster.inte == 0) {
		outputText("In the tight confines of this pod, there's no use making such an attack!\n\n", true);
		changeFatigue(1);
		enemyAI();
		return;
	}
//This is now automatic - newRound arg defaults to true:	menuLoc = 0;
	fatigue(25,1);
	if(monster.findStatusAffect(StatusAffects.Shell) >= 0) {
		outputText("As soon as your magic touches the multicolored shell around " + monster.a + monster.short + ", it sizzles and fades to nothing.  Whatever that thing is, it completely blocks your magic!\n\n");
		enemyAI();
		return;
	}
	//Decrease enemy speed and increase their susceptibility to lust attacks if already 110% or more
	outputText("The world begins to twist and distort around you as reality bends to your will, " + monster.a + monster.short + "'s mind blanketed in the thick fog of your illusions.");
	//Check for success rate. Maximum 100% with over 90 Intelligence difference between PC and monster. There are diminishing returns. The more you cast, the harder it is to apply another layer of illusion.
	if(player.inte/10 + rand(20) > monster.inte/10 + 9 + monster.statusAffectv1(StatusAffects.Illusion) * 2) {
	//Reduce speed down to -20. Um, are there many monsters with 110% lust vulnerability?
		outputText("  They stumble humorously to and fro, unable to keep pace with the shifting illusions that cloud their perceptions.\n\n");
		if (monster.statusAffectv1(StatusAffects.Illusion) > 0) monster.addStatusValue(StatusAffects.Illusion, 1, 1);
		else monster.createStatusAffect(StatusAffects.Illusion, 1, 0, 0, 0);
		if (monster.spe >= 0) monster.spe -= (20 - (monster.statusAffectv1(StatusAffects.Illusion) * 5));
		if (monster.lustVuln >= 1.1) monster.lustVuln += .1;
		if (monster.spe < 1) monster.spe = 1;
	}
	else {
		outputText("  Like the snapping of a rubber band, reality falls back into its rightful place as they resist your illusory conjurations.\n\n");
	}
	enemyAI();
}

//special attack: tail whip? could unlock button for use by dagrons too
//tiny damage and lower monster armor by ~75% for one turn
//hit
public function tailWhipAttack():void {
	clearOutput();
	//miss
	if((player.findStatusAffect(StatusAffects.Blind) >= 0 && rand(2) == 0) || (monster.spe - player.spe > 0 && int(Math.random()*(((monster.spe-player.spe)/4)+80)) > 80)) {
		outputText("Twirling like a top, you swing your tail, but connect with only empty air.");
	}
	else {
		if(!monster.plural) outputText("Twirling like a top, you bat your opponent with your tail.  For a moment, " + monster.pronoun1 + " looks disbelieving, as if " + monster.pronoun3 + " world turned upside down, but " + monster.pronoun1 + " soon becomes irate and redoubles " + monster.pronoun3 + " offense, leaving large holes in " + monster.pronoun3 + " guard.  If you're going to take advantage, it had better be right away; " + monster.pronoun1 + "'ll probably cool off very quickly.");
		else outputText("Twirling like a top, you bat your opponent with your tail.  For a moment, " + monster.pronoun1 + " look disbelieving, as if " + monster.pronoun3 + " world turned upside down, but " + monster.pronoun1 + " soon become irate and redouble " + monster.pronoun3 + " offense, leaving large holes in " + monster.pronoun3 + " guard.  If you're going to take advantage, it had better be right away; " + monster.pronoun1 + "'ll probably cool off very quickly.");
		if(monster.findStatusAffect(StatusAffects.CoonWhip) < 0) monster.createStatusAffect(StatusAffects.CoonWhip,0,0,0,0);
		temp = Math.round(monster.armorDef * .75);
		while(temp > 0 && monster.armorDef >= 1) {
			monster.armorDef--;
			monster.addStatusValue(StatusAffects.CoonWhip,1,1);
			temp--;
		}
		monster.addStatusValue(StatusAffects.CoonWhip,2,2);
		if(player.tailType == TAIL_TYPE_RACCOON) monster.addStatusValue(StatusAffects.CoonWhip,2,2);
	}
	outputText("\n\n");
	enemyAI();
}

public function shieldBash():void {
	clearOutput();
	if (player.fatigue + physicalCost(20) > player.maxFatigue()) {
		outputText("You are too tired to perform a shield bash.");
		doNext(combatMenu);
		return;
	}
	outputText("You ready your [shield] and prepare to slam it towards " + monster.a + monster.short + ".  ");
	if ((player.findStatusAffect(StatusAffects.Blind) >= 0 && rand(2) == 0) || (monster.spe - player.spe > 0 && int(Math.random() * (((monster.spe-player.spe) / 4) + 80)) > 80)) {
		if (monster.spe - player.spe < 8) outputText(monster.capitalA + monster.short + " narrowly avoids your attack!", false);
		if (monster.spe - player.spe >= 8 && monster.spe-player.spe < 20) outputText(monster.capitalA + monster.short + " dodges your attack with superior quickness!", false);
		if (monster.spe - player.spe >= 20) outputText(monster.capitalA + monster.short + " deftly avoids your slow attack.", false);
		enemyAI();
		return;
	}
	var damage:int = 10 + (player.str / 1.5) + rand(player.str / 2) + (player.shieldBlock * 2);
	if (player.findPerk(PerkLib.ShieldSlam) >= 0) damage *= 1.2;
	damage *= (monster.damagePercent() / 100);
	var chance:int = Math.floor(monster.statusAffectv1(StatusAffects.TimesBashed) + 1);
	if (chance > 10) chance = 10;
	damage = doDamage(damage);
	outputText("Your [shield] slams against " + monster.a + monster.short + ", dealing <b><font color=\"#800000\">" + damage + "</font></b> damage! ");
	if (monster.findStatusAffect(StatusAffects.Stunned) < 0 && rand(chance) == 0) {
		outputText("<b>Your impact also manages to stun " + monster.a + monster.short + "!</b> ");
		monster.createStatusAffect(StatusAffects.Stunned, 1, 0, 0, 0);
		if (monster.findStatusAffect(StatusAffects.TimesBashed) < 0) monster.createStatusAffect(StatusAffects.TimesBashed, player.findPerk(PerkLib.ShieldSlam) >= 0 ? 0.5 : 1, 0, 0, 0);
		else monster.addStatusValue(StatusAffects.TimesBashed, 1, player.findPerk(PerkLib.ShieldSlam) >= 0 ? 0.5 : 1);
	}
	checkAchievementDamage(damage);
	fatigue(20,2);
	outputText("\n\n");
	enemyAI();
}

//Arian's stuff
//Using the Talisman in combat
public function immolationSpell():void {
	clearOutput();
	outputText("You gather energy in your Talisman and unleash the spell contained within.  A wave of burning flames gathers around " + monster.a + monster.short + ", slowly burning " + monster.pronoun2 + ".");
	var temp:int = int(75+(player.inte/3 + rand(player.inte/2)) * spellMod());
	temp = calcInfernoMod(temp);
	temp = doDamage(temp);
	outputText(" <b>(<font color=\"#800000\">" + temp + "</font>)</b>\n\n");
	player.removeStatusAffect(StatusAffects.ImmolationSpell);
	arianScene.clearTalisman();
	enemyAI();
}

public function shieldingSpell():void {
	clearOutput();
	outputText("You gather energy in your Talisman and unleash the spell contained within.  A barrier of light engulfs you, before turning completely transparent.  Your defense has been increased.\n\n");
	player.createStatusAffect(StatusAffects.Shielding,0,0,0,0);
	player.removeStatusAffect(StatusAffects.ShieldingSpell);
	arianScene.clearTalisman();
	enemyAI();
}
