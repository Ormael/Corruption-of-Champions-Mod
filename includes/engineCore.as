﻿import classes.*;
import flash.text.TextFormat;
// // import flash.events.MouseEvent;
// 
// //const DOUBLE_ATTACK_STYLE:int = 867;
// //const SPELLS_CAST:int = 868;
// 
// //Fenoxo loves his temps
// var temp:int = 0;
// 
// //Used to set what each action buttons displays and does.
// var args:Array = new Array();
// var funcs:Array = new Array();
// 
// //Used for stat tracking to keep up/down arrows correct.
// var oldStats = {};
// model.oldStats = oldStats;
// oldStats.oldStr  = 0;
// oldStats.oldTou  = 0;
// oldStats.oldSpe  = 0;
// oldStats.oldInte = 0;
// oldStats.oldSens = 0;
// oldStats.oldLib  = 0;
// oldStats.oldCor  = 0;
// oldStats.oldHP   = 0;
// oldStats.oldLust = 0;
// 
// model.maxHP = maxHP;

public function maxHP():Number {
	return player.maxHP();
}

public function silly():Boolean {
	return flags[kFLAGS.SILLY_MODE_ENABLE_FLAG] == 1;

}

/* Replaced by Utils.formatStringArray, which does almost the same thing in one function
public function clearList():void {
	list = [];
}
public var list:Array = [];
public function addToList(arg:*):void {
	list[list.length] = arg;
}
public function outputList():String {
	var stuff:String = "";
	for(var x:int = 0; x < list.length; x++) {
		stuff += list[x];
		if(list.length == 2 && x == 1) {
			stuff += " and ";
		}
		else if(x < list.length-2) {
			stuff += ", ";
		}
		else if(x < list.length-1) {
			stuff += ", and ";
		}
	}
	list = [];
	return stuff;        
}
*/
/**
 * Alters player's HP.
 * @param	changeNum The amount to damage (negative) or heal (positive).
 * @param	display Show the damage or heal taken.
 * @return  effective delta
 */
public function HPChange(changeNum:Number, display:Boolean):Number
{
	var before:Number = player.HP;
	if(changeNum == 0) return 0;
	if(changeNum > 0) {
		//Increase by 20%!
		if(player.findPerk(PerkLib.HistoryHealer) >= 0) changeNum *= 1.2;
		if(player.HP + int(changeNum) > maxHP()) {
			if(player.HP >= maxHP()) {
			if (display) HPChangeNotify(changeNum);
				return player.HP - before;
			}
			if (display) HPChangeNotify(changeNum);
			player.HP = maxHP();
		}
		else
		{
			if (display) HPChangeNotify(changeNum);
			player.HP += int(changeNum);
			mainView.statsView.showStatUp( 'hp' );
			// hpUp.visible = true;
		}
	}
	//Negative HP
	else
	{
		if(player.HP + changeNum <= 0) {
			if (display) HPChangeNotify(changeNum);
			player.HP = 0;
			mainView.statsView.showStatDown( 'hp' );
		}
		else {
			if (display) HPChangeNotify(changeNum);
			player.HP += changeNum;
			mainView.statsView.showStatDown( 'hp' );
		}
	}
	dynStats("lust", 0, "resisted", false) //Workaround to showing the arrow.
	statScreenRefresh();
	return player.HP - before;
}

public function HPChangeNotify(changeNum:Number):void {
	if (changeNum == 0) {
		if(player.HP >= maxHP())
			outputText("You're as healthy as you can be.\n", false);
	}
	else if (changeNum > 0) {
		if(player.HP >= maxHP())
			outputText("Your HP maxes out at " + maxHP() + ".\n", false);
		else
			outputText("You gain <b><font color=\"#008000\">" + int(changeNum) + "</font></b> HP.\n", false);
	}
	else {
		if(player.HP <= 0)
			outputText("You take <b><font color=\"#800000\">" + int(changeNum*-1) + "</font></b> damage, dropping your HP to 0.\n", false);
		else
			outputText("You take <b><font color=\"#800000\">" + int(changeNum*-1) + "</font></b> damage.\n", false);
	}
}
		
public function clone(source:Object):* {
	var copier:ByteArray = new ByteArray();
	copier.writeObject(source);
	copier.position = 0;
	return(copier.readObject());
}

/* Was only used in two places at the start of the game
public function speech(output:String, speaker:String):void {
	var speech:String = "";
	speech = speaker + " says, \"<i>" + output + "</i>\"\n";
	outputText(speech, false);
}
*/

/**
 * Clear the text on screen.
 */
public function clearOutput():void {
	forceUpdate();
	currentText = "";
	mainView.clearOutputText();
	if(gameState != 3) mainView.hideMenuButton( MainView.MENU_DATA );
	mainView.hideMenuButton( MainView.MENU_APPEARANCE );
	mainView.hideMenuButton( MainView.MENU_LEVEL );
	mainView.hideMenuButton( MainView.MENU_PERKS );
	mainView.hideMenuButton( MainView.MENU_STATS );
}

/**
 * Basically the same as outputText() but without the parser tags. Great for displaying square brackets on text.
 * @param	output The text to show. It can be formatted such as bold, italics, and underline tags.
 * @param	purgeText Clear the old text.
 */
public function rawOutputText(output:String, purgeText:Boolean = false):void
{
	
	//OUTPUT!
	if(purgeText) {
		//if(!debug) mainText.htmlText = output;
		//trace("Purging and writing Text", output);
		clearOutput();
		currentText = output;
		mainView.setOutputText( output );
		// mainText.htmlText = output;
	}
	else
	{
		//trace("Adding Text");
		currentText += output;
		mainView.appendOutputText( output );
		// mainText.htmlText += output;
	}
	// trace(getCurrentStackTrace())
	// scrollBar.update();

}

/**
 * Output the text on main text interface.
 * @param	output The text to show. It can be formatted such as bold, italics, and underline tags.
 * @param	purgeText Clear the old text.
 * @param	parseAsMarkdown Parses the text using Markdown.
 */
public function outputText(output:String, 
						purgeText:Boolean = false, 
						parseAsMarkdown:Boolean = false):void
{
	// we have to purge the output text BEFORE calling parseText, because if there are scene commands in 
	// the parsed text, parseText() will write directly to the output


	// This is cleaup in case someone hits the Data or new-game button when the event-test window is shown. 
	// It's needed since those buttons are available even when in the event-tester
	mainView.hideTestInputPanel();

	if (purgeText)
	{
		clearOutput();
	}

	output = this.parser.recursiveParser(output, parseAsMarkdown);

	//OUTPUT!
	if(purgeText) {
		//if(!debug) mainText.htmlText = output;
		currentText = output;
	}
	else {
		currentText += output;
		//if(!debug) mainText.htmlText = currentText;
	}
	if(debug) 
	{
		mainView.setOutputText( currentText );
	}

}

public function flushOutputTextToGUI():void
{
	var fmt:TextFormat = mainView.mainText.getTextFormat();
	
	if (flags[kFLAGS.CUSTOM_FONT_SIZE] != 0) fmt.size = flags[kFLAGS.CUSTOM_FONT_SIZE];
	
	mainView.setOutputText(currentText);
	
	if (flags[kFLAGS.CUSTOM_FONT_SIZE] != 0)
	{
		mainView.mainText.setTextFormat(fmt);
	}
	if (mainViewManager.mainColorArray[flags[kFLAGS.BACKGROUND_STYLE]] != null) mainView.mainText.textColor = mainViewManager.mainColorArray[flags[kFLAGS.BACKGROUND_STYLE]];
}

public function displayHeader(string:String):void {
	outputText("<font size=\"36\" face=\"Georgia\"><u>" + string + "</u></font>\n");
}

public function displayPerks(e:MouseEvent = null):void {
	var temp:int = 0;
	clearOutput();
	displayHeader("Perks");
	while(temp < player.perks.length) {
		outputText("<b>" + player.perk(temp).perkName + "</b> - " + player.perk(temp).perkDesc + "\n", false);
		temp++;
	}
	menu();
	var button:int = 0;
	addButton(button++, "Next", playerMenu);
	if(player.perkPoints > 0) {
		outputText("\n<b>You have " + num2Text(player.perkPoints) + " perk point", false);
		if(player.perkPoints > 1) outputText("s", false);
		outputText(" to spend.</b>", false);
		addButton(button++, "Perk Up", perkBuyMenu);
	}
	if(player.findPerk(PerkLib.DoubleAttack) >= 0) {
		outputText("\n<b>You can adjust your double attack settings.</b>");
		addButton(button++,"Dbl Options",doubleAttackOptions);
	}
}

public function doubleAttackOptions():void {
	clearOutput();
	menu();
	if(flags[kFLAGS.DOUBLE_ATTACK_STYLE] == 0) {
		outputText("You will currently always double attack in combat.  If your strength exceeds sixty, your double-attacks will be done at sixty strength in order to double-attack.");
		outputText("\n\nYou can change it to double attack until sixty strength and then dynamicly switch to single attacks.");
		outputText("\nYou can change it to always single attack.");
		addButton(1,"Dynamic",doubleAttackDynamic);
		addButton(2,"Single",doubleAttackOff);
	}
	else if(flags[kFLAGS.DOUBLE_ATTACK_STYLE] == 1) {
		outputText("You will currently double attack until your strength exceeds sixty, and then single attack.");
		outputText("\n\nYou can choose to force double attacks at reduced strength (when over sixty, it makes attacks at a strength of sixty.");
		outputText("\nYou can change it to always single attack.");
		addButton(0,"All Double",doubleAttackForce);
		addButton(2,"Single",doubleAttackOff);
	}
	else {
		outputText("You will always single attack your foes in combat.");
		outputText("\n\nYou can choose to force double attacks at reduced strength (when over sixty, it makes attacks at a strength of sixty.");
		outputText("\nYou can change it to double attack until sixty strength and then switch to single attacks.");
		addButton(0,"All Double",doubleAttackForce);
		addButton(1,"Dynamic",doubleAttackDynamic);
	}
	var e:MouseEvent;
	addButton(4, "Back", displayPerks);
}

public function doubleAttackForce():void {
	flags[kFLAGS.DOUBLE_ATTACK_STYLE] = 0;
	doubleAttackOptions();
}
public function doubleAttackDynamic():void {
	flags[kFLAGS.DOUBLE_ATTACK_STYLE] = 1;
	doubleAttackOptions();
}
public function doubleAttackOff():void {
	flags[kFLAGS.DOUBLE_ATTACK_STYLE] = 2;
	doubleAttackOptions();
}

public function levelUpGo(e:MouseEvent = null):void {
	clearOutput();
	hideMenus();
	mainView.hideMenuButton( MainView.MENU_NEW_MAIN );
	//Level up
	if (player.XP >= player.requiredXP() && player.level < levelCap) {
		player.XP -= player.requiredXP();
		player.level++;
		player.perkPoints++;
		player.statPoints += 5;
		if (player.level % 2 == 0) player.ascensionPerkPoints++;
		outputText("<b>You are now level " + num2Text(player.level) + "!</b>\n\nYou have gained five attribute points and one perk point!", true);
		doNext(attributeMenu);
	}
	//Spend attribute points
	else if(player.statPoints > 0) {
		attributeMenu();
	}
	//Spend perk points
	else if (player.perkPoints > 0) {
		perkBuyMenu();
	}
	else {
		outputText("<b>ERROR.  LEVEL UP PUSHED WHEN PC CANNOT LEVEL OR GAIN PERKS.  PLEASE REPORT THE STEPS TO REPRODUCE THIS BUG TO FENOXO@GMAIL.COM OR THE FENOXO.COM BUG REPORT FORUM.</b>");
		doNext(playerMenu);
	}
}

//Attribute menu
private function attributeMenu():void {
	clearOutput();
	outputText("You have <b>" + (player.statPoints) + "</b> left to spend.\n\n");
	
	outputText("Strength: ");
	if (player.str < player.getMaxStats("str")) outputText("" + Math.floor(player.str) + " + <b>" + player.tempStr + "</b> → " + Math.floor(player.str + player.tempStr) + "\n");
	else outputText("" + Math.floor(player.str) + " (Maximum)\n");
	
	outputText("Toughness: ");
	if (player.tou < player.getMaxStats("tou")) outputText("" + Math.floor(player.tou) + " + <b>" + player.tempTou + "</b> → " + Math.floor(player.tou + player.tempTou) + "\n");
	else outputText("" + Math.floor(player.tou) + " (Maximum)\n");
	
	outputText("Speed: ");
	if (player.spe < player.getMaxStats("spe")) outputText("" + Math.floor(player.spe) + " + <b>" + player.tempSpe + "</b> → " + Math.floor(player.spe + player.tempSpe) + "\n");
	else outputText("" + Math.floor(player.spe) + " (Maximum)\n");
	
	outputText("Intelligence: ");
	if (player.inte < player.getMaxStats("int")) outputText("" + Math.floor(player.inte) + " + <b>" + player.tempInt + "</b> → " + Math.floor(player.inte + player.tempInt) + "\n");
	else outputText("" + Math.floor(player.inte) + " (Maximum)\n");

	menu();
	//Add
	if (player.statPoints > 0) {
		if ((player.str + player.tempStr) < player.getMaxStats("str")) addButton(0, "Add STR", addAttribute, "str", null, null, "Add 1 point to Strength.", "Add Strength");
		if ((player.tou + player.tempTou) < player.getMaxStats("tou")) addButton(1, "Add TOU", addAttribute, "tou", null, null, "Add 1 point to Toughness.", "Add Toughness");
		if ((player.spe + player.tempSpe) < player.getMaxStats("spe")) addButton(2, "Add SPE", addAttribute, "spe", null, null, "Add 1 point to Speed.", "Add Speed");
		if ((player.inte + player.tempInt) < player.getMaxStats("int")) addButton(3, "Add INT", addAttribute, "int", null, null, "Add 1 point to Intelligence.", "Add Intelligence");
	}
	//Subtract
	if (player.tempStr > 0) addButton(5, "Sub STR", subtractAttribute, "str", null, null, "Subtract 1 point from Strength.", "Subtract Strength");
	if (player.tempTou > 0) addButton(6, "Sub TOU", subtractAttribute, "tou", null, null, "Subtract 1 point from Toughness.", "Subtract Toughness");
	if (player.tempSpe > 0) addButton(7, "Sub SPE", subtractAttribute, "spe", null, null, "Subtract 1 point from Speed.", "Subtract Speed");
	if (player.tempInt > 0) addButton(8, "Sub INT", subtractAttribute, "int", null, null, "Subtract 1 point from Intelligence.", "Subtract Intelligence");
	
	addButton(4, "Reset", resetAttributes);
	addButton(9, "Done", finishAttributes);
}

private function addAttribute(attribute:String):void {
	switch(attribute) {
		case "str":
			player.tempStr++;
			break;
		case "tou":
			player.tempTou++;
			break;
		case "spe":
			player.tempSpe++;
			break;
		case "int":
			player.tempInt++;
			break;
		default:
			player.statPoints++; //Failsafe
	}
	player.statPoints--;
	attributeMenu();
}
private function subtractAttribute(attribute:String):void {
	switch(attribute) {
		case "str":
			player.tempStr--;
			break;
		case "tou":
			player.tempTou--;
			break;
		case "spe":
			player.tempSpe--;
			break;
		case "int":
			player.tempInt--;
			break;
		default:
			player.statPoints--; //Failsafe
	}
	player.statPoints++;
	attributeMenu();
}
private function resetAttributes():void {
	//Increment unspent attribute points.
	player.statPoints += player.tempStr;
	player.statPoints += player.tempTou;
	player.statPoints += player.tempSpe;
	player.statPoints += player.tempInt;
	//Reset temporary attributes to 0.
	player.tempStr = 0;
	player.tempTou = 0;
	player.tempSpe = 0;
	player.tempInt = 0;
	//DONE!
	attributeMenu();
}
private function finishAttributes():void {
	clearOutput()
	if (player.tempStr > 0)
	{
		if (player.tempStr >= 3) outputText("Your muscles feel significantly stronger from your time adventuring.\n");
		else outputText("Your muscles feel slightly stronger from your time adventuring.\n");
	}
	if (player.tempTou > 0)
	{
		if (player.tempTou >= 3) outputText("You feel tougher from all the fights you have endured.\n");
		else outputText("You feel slightly tougher from all the fights you have endured.\n");
	}
	if (player.tempSpe > 0)
	{
		if (player.tempSpe >= 3) outputText("Your time in combat has driven you to move faster.\n");
		else outputText("Your time in combat has driven you to move slightly faster.\n");
	}
	if (player.tempInt > 0)
	{
		if (player.tempInt >= 3) outputText("Your time spent fighting the creatures of this realm has sharpened your wit.\n");
		else outputText("Your time spent fighting the creatures of this realm has sharpened your wit slightly.\n");
	}
	if (player.tempStr + player.tempTou + player.tempSpe + player.tempInt <= 0 || player.statPoints > 0)
	{
		outputText("\nYou may allocate your remaining stat points later.", false);
	}
	dynStats("str", player.tempStr, "tou", player.tempTou, "spe", player.tempSpe, "int", player.tempInt, "noBimbo", true); //Ignores bro/bimbo perks.
	player.tempStr = 0;
	player.tempTou = 0;
	player.tempSpe = 0;
	player.tempInt = 0;
	if (player.perkPoints > 0) doNext(perkBuyMenu);
	else doNext(playerMenu);
}

private function perkBuyMenu():void {
	clearOutput();
	var perkList:Array = buildPerkList();
	
	if (perkList.length == 0) {
		outputText("<b>You do not qualify for any perks at present.  </b>In case you qualify for any in the future, you will keep your " + num2Text(player.perkPoints) + " perk point");
		if(player.perkPoints > 1) outputText("s");
		outputText(".");
		doNext(playerMenu);
		return;
	}
	if (testingBlockExiting) {
		menu();
		addButton(0, "Next", perkSelect, perkList[rand(perkList.length)].perk);
	}
	else {
		outputText("Please select a perk from the drop-down list, then click 'Okay'.  You can press 'Skip' to save your perk point for later.\n\n");
		mainView.aCb.x = 210;
		mainView.aCb.y = 112;
		
		if (mainView.aCb.parent == null) {
			mainView.addChild(mainView.aCb);
			mainView.aCb.visible = true;
		}
		
		mainView.hideMenuButton( MainView.MENU_NEW_MAIN );
		menu();
		addButton(1, "Skip", perkSkip);
	}
}

private function perkSelect(selected:PerkClass):void {
	stage.focus = null;
	if (mainView.aCb.parent != null) {
		mainView.removeChild(mainView.aCb);
		applyPerk(selected);
	}
}

private function perkSkip():void {
	stage.focus = null;
	if (mainView.aCb.parent != null) {
		mainView.removeChild(mainView.aCb);
		playerMenu();
	}
}

private function changeHandler(event:Event):void {
 	//Store perk name for later addition
	clearOutput();
 	var selected:PerkClass = ComboBox(event.target).selectedItem.perk;
	mainView.aCb.move(210, 85);
	outputText("You have selected the following perk:\n\n");
	outputText("<b>" + selected.perkName + ":</b> " + selected.perkLongDesc + "\n\nIf you would like to select this perk, click <b>Okay</b>.  Otherwise, select a new perk, or press <b>Skip</b> to make a decision later.");
	menu();
	addButton(0, "Okay", perkSelect, selected);
	addButton(1, "Skip", perkSkip);
}

public function buildPerkList():Array {
	var perkList:Array = [];
	function _add(p:PerkClass):void{
		perkList.push({label: p.perkName,perk:p});
	}
	//------------
	// STRENGTH
	//------------
	if(player.str >= 25) {
		_add(new PerkClass(PerkLib.StrongBack));
	}
	if(player.findPerk(PerkLib.StrongBack) >= 0 && player.str >= 50) {
		_add(new PerkClass(PerkLib.StrongBack2));
	}
	if(player.str >= 20) {
		_add(new PerkClass(PerkLib.JobWarrior));
	}
	//Tier 1 Strength Perks
	if(player.level >= 6) {
		//Thunderous Strikes - +20% basic attack damage while str > 80.
		if(player.findPerk(PerkLib.JobWarrior) >= 0 && player.str >= 80) {
			_add(new PerkClass(PerkLib.ThunderousStrikes));
		}
		//Weapon Mastery - Doubles weapon damage bonus of 'large' type weapons. (Minotaur Axe, M. Hammer, etc)
		if(player.findPerk(PerkLib.JobWarrior) >= 0 && player.str > 60) {
			_add(new PerkClass(PerkLib.WeaponMastery));
		}
		if(player.findPerk(PerkLib.JobWarrior) >= 0 && player.str >= 75)
			_add(new PerkClass(PerkLib.BrutalBlows));
		if(player.str >= 50)
			_add(new PerkClass(PerkLib.IronFists));
		if(player.str >= 65 && player.findPerk(IronFists) >= 0 && player.newGamePlusMod >= 1)
			_add(new PerkClass(PerkLib.IronFists2));
		if(player.str >= 80 && player.findPerk(IronFists2) >= 0 && player.newGamePlusMod >= 2)
			_add(new PerkClass(PerkLib.IronFists3));			
		if(player.str >= 50 && player.spe >= 50)
			_add(new PerkClass(PerkLib.Parry));
	}
	//Tier 2 Strength Perks
	if(player.level >= 12) {
		if(player.str >= 75)
			_add(new PerkClass(PerkLib.Berzerker));
		if (player.findPerk(PerkLib.JobWarrior) >= 0 && player.str >= 80)
			_add(new PerkClass(PerkLib.HoldWithBothHands));
		if (player.str >= 80 && player.tou >= 60)
			_add(new PerkClass(PerkLib.ShieldSlam));
	}
	//Tier 3 Strength Perks
	if(player.level >= 18) {
		if(player.findPerk(Berzerker) >= 0 && player.findPerk(ImprovedSelfControl) >= 0 && player.str >= 75)
			_add(new PerkClass(PerkLib.ColdFury));
	}
	//------------
	// TOUGHNESS
	//------------
	//slot 2 - toughness perk 1
	if(player.findPerk(PerkLib.RefinedBody) < 0 && player.findPerk(PerkLib.JobGuardian) >= 0 && player.tou >= 25) {
		_add(new PerkClass(PerkLib.RefinedBody));
	}
	if(player.findPerk(PerkLib.RefinedBody) >= 0 && player.tou >= 25 && player.newGamePlusMod >= 1) {
		_add(new PerkClass(PerkLib.RefinedBody2));
	}
	if(player.findPerk(PerkLib.RefinedBody2) >= 0 && player.tou >= 40 && player.newGamePlusMod >= 2) {
		_add(new PerkClass(PerkLib.RefinedBody3));
	}
	if(player.findPerk(PerkLib.RefinedBody3) >= 0 && player.tou >= 55 && player.newGamePlusMod >= 3) {
		_add(new PerkClass(PerkLib.RefinedBody4));
	}
	if(player.findPerk(PerkLib.RefinedBody4) >= 0 && player.tou >= 70 && player.newGamePlusMod >= 4) {
		_add(new PerkClass(PerkLib.RefinedBody5));
	}
	//slot 2 - regeneration perk
	if(player.findPerk(PerkLib.RefinedBody) >= 0 && player.tou >= 50) {
		_add(new PerkClass(PerkLib.Regeneration));
	}
	if(player.findPerk(PerkLib.Regeneration) >= 0 && player.tou >= 70 && player.newGamePlusMod >= 1) {
		_add(new PerkClass(PerkLib.Regeneration2));
	}
	if(player.findPerk(PerkLib.Regeneration2) >= 0 && player.tou >= 90 && player.newGamePlusMod >= 2) {
		_add(new PerkClass(PerkLib.Regeneration3));
	}
	if(player.findPerk(PerkLib.Regeneration3) >= 0 && player.tou >= 110 && player.newGamePlusMod >= 3) {
		_add(new PerkClass(PerkLib.Regeneration4));
	}
	if(player.findPerk(PerkLib.Regeneration4) >= 0 && player.tou >= 130 && player.newGamePlusMod >= 4) {
		_add(new PerkClass(PerkLib.Regeneration5));
	}
	if(player.tou >= 50 && player.str >= 50) {
		_add(new PerkClass(PerkLib.ImprovedEndurance));
	}
	if(player.tou >= 65 && player.str >= 65 && player.findPerk(ImprovedEndurance) >= 0 && player.newGamePlusMod >= 1) {
		_add(new PerkClass(PerkLib.ImprovedEndurance2));
	}
	if(player.tou >= 80 && player.str >= 80 && player.findPerk(ImprovedEndurance2) >= 0 && player.newGamePlusMod >= 2) {
		_add(new PerkClass(PerkLib.ImprovedEndurance3));
	}
	if(player.tou >= 95 && player.str >= 95 && player.findPerk(ImprovedEndurance3) >= 0 && player.newGamePlusMod >= 3) {
		_add(new PerkClass(PerkLib.ImprovedEndurance4));
	}
	if(player.tou >= 110 && player.str >= 110 && player.findPerk(ImprovedEndurance4) >= 0 && player.newGamePlusMod >= 4) {
		_add(new PerkClass(PerkLib.ImprovedEndurance5));
	}
	if(player.tou >= 20) {
		_add(new PerkClass(PerkLib.JobGuardian));
	}
	//Tier 1 Toughness Perks
	if(player.level >= 6) {
		if(player.findPerk(PerkLib.RefinedBody) >= 0 && player.tou >= 60) {
			_add(new PerkClass(PerkLib.Tank));
		}
		if(player.findPerk(PerkLib.Tank) >= 0 && player.tou >= 80 && player.newGamePlusMod >= 1) {
			_add(new PerkClass(PerkLib.Tank2));
		}
		if(player.findPerk(PerkLib.Tank2) >= 0 && player.tou >= 100 && player.newGamePlusMod >= 2) {
			_add(new PerkClass(PerkLib.Tank3));
		}
		if(player.findPerk(PerkLib.Tank3) >= 0 && player.tou >= 120 && player.newGamePlusMod >= 3) {
			_add(new PerkClass(PerkLib.Tank4));
		}
		if(player.findPerk(PerkLib.Tank4) >= 0 && player.tou >= 140 && player.newGamePlusMod >= 4) {
			_add(new PerkClass(PerkLib.Tank5));
		}
		if(player.findPerk(PerkLib.JobGuardian) >= 0 && player.tou >= 75) {
			_add(new PerkClass(PerkLib.ImmovableObject));
		}
		if(player.findPerk(PerkLib.JobGuardian) >= 0 && player.tou >= 50) {
			_add(new PerkClass(PerkLib.ShieldMastery));
		}
	}
	//Tier 2 Toughness Perks
	if(player.level >= 12) {
		if(player.findPerk(PerkLib.JobGuardian) >= 0 && player.tou >= 75) {
			_add(new PerkClass(PerkLib.Resolute));
		}
		if(player.findPerk(PerkLib.JobGuardian) >= 0 && player.tou >= 75) {
			_add(new PerkClass(PerkLib.Juggernaut));
		}
		if(player.tou >= 60) {
			_add(new PerkClass(PerkLib.IronMan));
		}
	}
	//------------
	// SPEED
	//------------
	//slot 3 - speed perk
	if(player.spe >= 25) {
			_add(new PerkClass(PerkLib.Evade));
	}
	//slot 3 - run perk
	if(player.spe >= 25) {
			_add(new PerkClass(PerkLib.Runner));
	}
	//slot 3 - Double Attack perk
	if(player.findPerk(PerkLib.Evade) >= 0 && player.findPerk(PerkLib.Runner) >= 0 && player.spe >= 50) {
			_add(new PerkClass(PerkLib.DoubleAttack));
	}
	if(player.spe >= 20) {
		_add(new PerkClass(PerkLib.JobArcher));
	}
	//Tier 1 Speed Perks
	if(player.level >= 6) {
		//Speedy Recovery - Regain Fatigue 50% faster speed.
		if(player.findPerk(PerkLib.Evade) >= 0 && player.spe >= 60) {
			_add(new PerkClass(PerkLib.SpeedyRecovery));
		}
		//Agility - A small portion of your speed is applied to your defense rating when wearing light armors.
		if(player.spe > 75 && player.findPerk(PerkLib.Runner) >= 0) {
			_add(new PerkClass(PerkLib.Agility));
		}
		if(player.spe >= 75 && player.findPerk(PerkLib.Evade) >= 0 && player.findPerk(PerkLib.Agility) >= 0) {
				_add(new PerkClass(PerkLib.Unhindered));
		}
		if(player.spe >= 60) {
			_add(new PerkClass(PerkLib.LightningStrikes));
		}
		/*if(player.spe >= 60 && player.str >= 60) {
			_add(new PerkClass(PerkLib.Brawler));
		}*/ //Would it be fitting to have Urta teach you?
	}
	//Tier 2 Speed Perks
	if(player.level >= 12) {
		if(player.findPerk(PerkLib.JobWarrior) >= 0 && player.spe >= 75) {
			_add(new PerkClass(PerkLib.LungingAttacks));
		}
		if(player.findPerk(PerkLib.JobWarrior) >= 0 && player.spe >= 80 && player.str >= 60) {
			_add(new PerkClass(PerkLib.Blademaster));
		}
	}
	//------------
	// INTELLIGENCE
	//------------
	//Slot 4 - precision - -10 enemy toughness for damage calc
	if(player.inte >= 25) {
			_add(new PerkClass(PerkLib.Precision));
	}
	//Spellpower - boosts spell power
	if(player.findPerk(PerkLib.JobSorcerer) >= 0 && player.inte >= 50) {
			_add(new PerkClass(PerkLib.Spellpower));
	}
	if(player.inte >= 20) {
		_add(new PerkClass(PerkLib.JobSorcerer));
	}
	//Tier 1 Intelligence Perks
	if(player.level >= 6) {
		if(player.findPerk(PerkLib.Spellpower) >= 0 && player.inte >= 50) {
			_add(new PerkClass(PerkLib.Mage));
		}
		if(player.inte >= 50)
			_add(new PerkClass(PerkLib.Tactician));
		if(spellCount() > 0 && player.findPerk(PerkLib.Spellpower) >= 0 && player.findPerk(PerkLib.Mage) >= 0 && player.inte >= 60) {
			_add(new PerkClass(PerkLib.Channeling));
		}
		if(player.inte >= 60) {
			_add(new PerkClass(PerkLib.Medicine));
		}
		if(player.findPerk(PerkLib.Channeling) >= 0 && player.inte >= 60) {
				_add(new PerkClass(PerkLib.StaffChanneling));
		}
	}
	//Tier 2 Intelligence perks
	if(player.level >= 12) {
		if(player.findPerk(PerkLib.Mage) >= 0 && player.inte >= 75) {
			_add(new PerkClass(PerkLib.Archmage));
		}
		if(player.inte >= 75) {
				if(player.findPerk(PerkLib.Mage) >= 0)
					_add(new PerkClass(PerkLib.FocusedMind));
				
				if (player.findPerk(PerkLib.Archmage) >= 0 && player.findPerk(PerkLib.Channeling) >= 0  &&
				(player.findStatusAffect(StatusAffects.KnowsWhitefire) >= 0
				|| player.findPerk(PerkLib.FireLord) >= 0 
				|| player.findPerk(PerkLib.Hellfire) >= 0 
				|| player.findPerk(PerkLib.EnlightenedNinetails) >= 0
				|| player.findPerk(PerkLib.CorruptedNinetails) >= 0))
					_add(new PerkClass(PerkLib.RagingInferno));
		}
		// Spell-boosting perks
		// Battlemage: auto-use Might
		if(player.findPerk(PerkLib.Channeling) >= 0 && player.findStatusAffect(StatusAffects.KnowsMight) >= 0 && player.inte >= 80) {
				_add(new PerkClass(PerkLib.Battlemage));
		}
		// Spellsword: auto-use Charge Weapon
		if(player.findPerk(PerkLib.Channeling) >= 0 && player.findStatusAffect(StatusAffects.KnowsCharge) >= 0 && player.inte >= 80) {
				_add(new PerkClass(PerkLib.Spellsword));
		}
	}
	//Tier 3 Intelligence perks
//	if(player.level >= 18) {
//		if(player.findPerk(PerkLib.Archmage) >= 0 && player.inte >= 100) {
//			_add(new PerkClass(PerkLib.GrandArchmage));
//		}
//	}
	
	//Tier 4 Intelligence perks
//	if(player.level >= 24) {
//		if(player.findPerk(PerkLib.GrandArchmage) >= 0 && player.findPerk(PerkLib.FocusedMind) >= 0 && player.inte >= 125) {
//			_add(new PerkClass(PerkLib.GreyArchmage));
//		}
//	}
	
	//------------
	// LIBIDO
	//------------
	//slot 5 - libido perks

	//Slot 5 - Fertile+ increases cum production and fertility (+15%)
	if(player.lib >= 25) {
			_add(new PerkClass(PerkLib.FertilityPlus,15,1.75,0,0));
	}
	//Slot 5 - minimum libido
	if(player.minLust() >= 20) {
			_add(new PerkClass(PerkLib.ColdBlooded,20,0,0,0));
	}
	if(player.lib >= 50) {
			_add(new PerkClass(PerkLib.HotBlooded,20,0,0,0));
	}
	if(player.lib >= 25 && player.inte >= 50) {
		_add(new PerkClass(PerkLib.ImprovedSelfControl));
	}
	if(player.lib >= 25 && player.inte >= 65 && player.findPerk(ImprovedSelfControl) >= 0 && player.newGamePlusMod >= 1) {
		_add(new PerkClass(PerkLib.ImprovedSelfControl2));
	}
	if(player.lib >= 25 && player.inte >= 80 && player.findPerk(ImprovedSelfControl2) >= 0 && player.newGamePlusMod >= 2) {
		_add(new PerkClass(PerkLib.ImprovedSelfControl3));
	}
	if(player.lib >= 25 && player.inte >= 95 && player.findPerk(ImprovedSelfControl3) >= 0 && player.newGamePlusMod >= 3) {
		_add(new PerkClass(PerkLib.ImprovedSelfControl4));
	}
	if(player.lib >= 25 && player.inte >= 110 && player.findPerk(ImprovedSelfControl4) >= 0 && player.newGamePlusMod >= 4) {
		_add(new PerkClass(PerkLib.ImprovedSelfControl5));
	}
	if(player.lib >= 20) {
		_add(new PerkClass(PerkLib.JobSeducer));
	}
	//Tier 1 Libido Perks
	if(player.level >= 6) {
		//Slot 5 - minimum libido
		//Slot 5 - Fertility- decreases cum production and fertility.
		if (player.lib < 25) {
				_add(new PerkClass(PerkLib.FertilityMinus, 15, 0.7, 0, 0));
		}
		if(player.lib >= 60) {
			_add(new PerkClass(PerkLib.WellAdjusted));
		}
		//Slot 5 - minimum libido
		if(player.lib >= 60 && player.cor >= 50) {
			_add(new PerkClass(PerkLib.Masochist));
		}
		if(player.findPerk(PerkLib.JobSeducer) >= 0 && player.lib >= 50) {
			_add(new PerkClass(PerkLib.InhumanDesire));
		}
	}
	//Tier 2 Libido Perks
	if(player.level >= 12) {
		if(player.findPerk(PerkLib.InhumanDesire) >= 0 && player.lib >= 75) {
			_add(new PerkClass(PerkLib.DemonicDesire));
		}
	}
	//------------
	// SENSITIVITY
	//------------
	//Nope.avi
	//------------
	// CORRUPTION
	//------------
	//Slot 7 - Corrupted Libido - lust raises 10% slower.
	if(player.cor >= 25) {
			_add(new PerkClass(PerkLib.CorruptedLibido,20,0,0,0));
	}
	//Slot 7 - Seduction (Must have seduced Jojo
	if(player.cor >= 50) {
			_add(new PerkClass(PerkLib.Seduction));
	}
	//Slot 7 - Nymphomania
	if(player.findPerk(PerkLib.CorruptedLibido) >= 0 && player.cor >= 75) {
			_add(new PerkClass(PerkLib.Nymphomania));
	}
	//Slot 7 - UNFINISHED :3
	if(minLust() >= 20 && player.findPerk(PerkLib.CorruptedLibido) >= 0 && player.cor >= 50) {
			_add(new PerkClass(PerkLib.Acclimation));
	}
	//Tier 1 Corruption Perks - acclimation over-rides
	if(player.level >= 6)
	{
		if(player.cor >= 60 && player.findPerk(PerkLib.CorruptedLibido) >= 0) {
			_add(new PerkClass(PerkLib.Sadist));
		}
		if(player.findPerk(PerkLib.CorruptedLibido) >= 0 && player.cor >= 70) {
			_add(new PerkClass(PerkLib.ArousingAura));
		}
	}
	//------------
	// MISCELLANEOUS
	//------------
	//Tier 1
	if(player.level >= 6) {
		_add(new PerkClass(PerkLib.Resistance));
		if (flags[kFLAGS.HUNGER_ENABLED] > 0) _add(new PerkClass(PerkLib.Survivalist));
	}
	//Tier 2
	if(player.level >= 12 && player.findPerk(PerkLib.Survivalist) > 0) {
		if (flags[kFLAGS.HUNGER_ENABLED] > 0) _add(new PerkClass(PerkLib.Survivalist2));
	}
	//Tier 4
//	if(player.level >= 24 && player.findPerk(PerkLib.JobArcher) > 0 && player.findPerk(PerkLib.JobGuardian) > 0 && player.findPerk(PerkLib.JobSeducer) > 0 && player.findPerk(PerkLib.JobSorcerer) > 0 && player.findPerk(PerkLib.JobWarrior) > 0 && player.str >= 100 && player.tou >= 100 && player.spe >= 100 && player.inte >= 100 && player.lib >= 50) {
//		_add(new PerkClass(PerkLib.JobMunchkin));
//	}	(Still need some other related stuff added to make PC true Munchkin)
	// FILTER PERKS
	perkList = perkList.filter(
			function(perk:*,idx:int,array:Array):Boolean{
				return player.findPerk(perk.perk.ptype) < 0;
			});
	mainView.aCb.dataProvider = new DataProvider(perkList);
	return perkList;
}

public function applyPerk(perk:PerkClass):void {
	clearOutput();
	player.perkPoints--;
	//Apply perk here.
	outputText("<b>" + perk.perkName + "</b> gained!");
	player.createPerk(perk.ptype, perk.value1, perk.value2, perk.value3, perk.value4);
	if (perk.ptype == PerkLib.StrongBack2) player.itemSlot5.unlocked = true;
	if (perk.ptype == PerkLib.StrongBack) player.itemSlot4.unlocked = true;
	if (perk.ptype == PerkLib.Tank) {
		HPChange(player.tou, false);
		statScreenRefresh();
	}
	doNext(playerMenu);
}

public function buttonIsVisible(index:int):Boolean {
	if( index < 0 || index > 14 ) {
		return undefined;
	}
	else {
		return mainView.bottomButtons[index].visible;
	}
};

public function buttonText(buttonName:String):String {
	var matches:*,
		buttonIndex:int;

	if(buttonName is String) {
		if( /^buttons\[[0-9]\]/.test( buttonName ) ) {
			matches = /^buttons\[([0-9])\]/.exec( buttonName );
			buttonIndex = parseInt( matches[ 1 ], 10 );
		}
		else if( /^b[0-9]Text$/.test( buttonName ) ) {
			matches = /^b([0-9])Text$/.exec( buttonName );
			buttonIndex = parseInt( matches[ 1 ], 10 );

			buttonIndex = buttonIndex === 0 ? 9 : buttonIndex - 1;
		}
	}

	return (getButtonText(buttonIndex) || "NULL");
}

public function buttonTextIsOneOf(index:int, possibleLabels:Array):Boolean {
	var label:String,
	buttonText:String;

	buttonText = this.getButtonText(index);

	return (possibleLabels.indexOf(buttonText) != -1);
}

public function getButtonText(index:int):String {
	var matches:*;

	if(index < 0 || index > 14) {
		return '';
	}
	else {
		return mainView.bottomButtons[index].labelText;
	}
}

/*public function setButtonToolTip(button:int, header:String = "", text:String = ""):void {
	if (header == "") {
		header = mainView.bottomButtons[button].labelText;
	}
	mainView.bottomButtons[button].toolTipHeader = header;
	mainView.bottomButtons[button].toolTipText = text;
}*/

public function getButtonToolTipHeader(buttonText:String):String
{
	var toolTipHeader:String;
	
	if (buttonText.indexOf(" x") != -1)
	{
		buttonText = buttonText.split(" x")[0];
	}
	
	//Get items
	var itype:ItemType = ItemType.lookupItem(buttonText);
	var temp:String = "";
	if (itype != null) temp = itype.longName;
	itype = ItemType.lookupItemByShort(buttonText);
	if (itype != null) temp = itype.longName;
	if (temp != "") {
		temp = capitalizeFirstLetter(temp);
		toolTipHeader = temp;
	}
	
	//Set tooltip header to button.
	if (toolTipHeader == null) {
		toolTipHeader = buttonText;
	}
	
	return toolTipHeader;
}

// Returns a string or undefined.
public function getButtonToolTipText(buttonText:String):String
{
	var toolTipText :String;

	buttonText = buttonText || '';

	//Items
	//if (/^....... x\d+$/.test(buttonText)){
	//	buttonText = buttonText.substring(0,7);
	//}
	
	// Fuck your regex
	if (buttonText.indexOf(" x") != -1)
	{
		buttonText = buttonText.split(" x")[0];
	}
	
	var itype:ItemType = ItemType.lookupItem(buttonText);
	if (itype != null) toolTipText = itype.description;
	itype = ItemType.lookupItemByShort(buttonText);
	if (itype != null) toolTipText = itype.description;

	//------------
	// COMBAT 
	//------------
	if(buttonText.indexOf("Defend") != -1) { //Not used at the moment.
		toolTipText = "Selecting defend will reduce the damage you take by 66 percent, but will not affect any lust incurred by your enemy's actions.";
	}
	//Urta's specials - MOVED
	//P. Special attacks - MOVED
	//M. Special attacks - MOVED

	//------------
	// MASTURBATION 
	//------------
	//Masturbation Toys
	if(buttonText == "Masturbate") {
		toolTipText = "Selecting this option will make you attempt to manually masturbate in order to relieve your lust buildup.";
	}
	if(buttonText == "Meditate") {
		toolTipText = "Selecting this option will make you attempt to meditate in order to reduce lust and corruption.";
	}
	if(buttonText.indexOf("AN Stim-Belt") != -1) {
		toolTipText = "This is an all-natural self-stimulation belt.  The methods used to create such a pleasure device are unknown.  It seems to be organic in nature.";
	}
	if(buttonText.indexOf("Stim-Belt") != -1) {
		toolTipText = "This is a self-stimulation belt.  Commonly referred to as stim-belts, these are clockwork devices designed to pleasure the female anatomy.";
	}
	if(buttonText.indexOf("AN Onahole") != -1) {
		toolTipText = "An all-natural onahole, this device looks more like a bulbous creature than a sex-toy.  Nevertheless, the slick orifice it presents looks very inviting.";
	}
	if(buttonText.indexOf("D Onahole") != -1) {
		toolTipText = "This is a deluxe onahole, made of exceptional materials and with the finest craftsmanship in order to bring its user to the height of pleasure.";
	}
	if(buttonText.indexOf("Onahole") != -1) {
		toolTipText = "This is what is called an 'onahole'.  This device is a simple textured sleeve designed to fit around the male anatomy in a pleasurable way.";
	}
	if(buttonText.indexOf("Dual Belt") != -1) {
		toolTipText = "This is a strange masturbation device, meant to work every available avenue of stimulation.";
	}
	if(buttonText.indexOf("C. Pole") != -1) {
		toolTipText = "This 'centaur pole' as it's called appears to be a sex-toy designed for females of the equine persuasion.  Oddly, it's been sculpted to look like a giant imp, with an even bigger horse-cock.";
	}
	if(buttonText.indexOf("Fake Mare") != -1) {
		toolTipText = "This fake mare is made of metal and wood, but the anatomically correct vagina looks as soft and wet as any female centaur's.";
	}
	//Books
	if(buttonText.indexOf("Dangerous Plants") != -1) {
		toolTipText = "This is a book titled 'Dangerous Plants'.  As explained by the title, this tome is filled with information on all manner of dangerous plants from this realm.";
	}
	if(buttonText.indexOf("Traveler's Guide") != -1) {
		toolTipText = "This traveler's guide is more of a pamphlet than an actual book, but it still contains some useful information on avoiding local pitfalls.";
	}
	if(buttonText.indexOf("Yoga Guide") != -1) {
		toolTipText = "This leather-bound book is titled 'Yoga for Non-Humanoids.' It contains numerous illustrations of centaurs, nagas and various other oddly-shaped beings in a variety of poses.";
	}
	if(buttonText.indexOf("Hentai Comic") != -1) {
		toolTipText = "This oddly drawn comic book is filled with images of fornication, sex, and overly large eyeballs.";
	}
	//------------
	// TITLE SCREEN 
	//------------
	if(buttonText.indexOf("ASPLODE") != -1) {
		toolTipText = "MAKE SHIT ASPLODE";
	}
	return toolTipText;
}


// Hah, finally a place where a dictionary is actually required!
import flash.utils.Dictionary;
private var funcLookups:Dictionary = null;


private function buildFuncLookupDict(object:*=null,prefix:String=""):void
{
	import flash.utils.*;
	trace("Building function <-> function name mapping table for "+((object==null)?"CoC.":prefix));
	// get all methods contained
	if (object == null) object = this;
	var typeDesc:XML = describeType(object);
	//trace("TypeDesc - ", typeDesc)

	for each (var node:XML in typeDesc..method) 
	{
		// return the method name if the thisObject of f (t) 
		// has a property by that name 
		// that is not null (null = doesn't exist) and 
		// is strictly equal to the function we search the name of
		//trace("this[node.@name] = ", this[node.@name], " node.@name = ", node.@name)
		if (object[node.@name] != null)
			this.funcLookups[object[node.@name]] = prefix+node.@name;
	}
	for each (node in typeDesc..variable)
	{
		if (node.@type.toString().indexOf("classes.Scenes.") == 0 ||
				node.metadata.@name.contains("Scene")){
			if (object[node.@name]!=null){
				buildFuncLookupDict(object[node.@name],node.@name+".");
			}
		}
	}
}

public function getFunctionName(f:Function):String
{
	// trace("Getting function name")
	// get the object that contains the function (this of f)
	//var t:Object = flash.sampler.getSavedThis(f); 
	if (this.funcLookups == null)
	{
		trace("Rebuilding lookup object");
		this.funcLookups = new Dictionary();
		this.buildFuncLookupDict();
	}


	if (f in this.funcLookups)
		return(this.funcLookups[f]);
	
	// if we arrive here, we haven't found anything... 
	// maybe the function is declared in the private namespace?
	return null;
}


private function logFunctionInfo(func:Function, arg:* = null, arg2:* = null, arg3:* = null):void
{
	var logStr:String = "";
	if (arg is Function)
	{
		logStr += "Calling = " + getFunctionName(func) + " Param = " +  getFunctionName(arg);
	}
	else
	{
		logStr += "Calling = " + getFunctionName(func) + " Param = " +  arg;
	}
	CoC_Settings.appendButtonEvent(logStr);
	trace(logStr)
}


// returns a function that takes no arguments, and executes function `func` with argument `arg`
public function createCallBackFunction(func:Function, arg:*, arg2:* = null, arg3:* = null):Function
{
	if (func == null) {
		CoC_Settings.error("createCallBackFunction(null," + arg + ")");
	}
	if( arg == -9000 || arg == null )
	{
/*		if (func == eventParser){
			CoC_Settings.error("createCallBackFunction(eventParser,"+arg+")");
		} */
		return function ():*
		{ 
			if (CoC_Settings.haltOnErrors) 
				logFunctionInfo(func, arg);
			return func(); 
		};
	}
	else
	{
		if (arg2 == -9000 || arg2 == null)
		{
			return function ():*
			{ 
				if (CoC_Settings.haltOnErrors) 
					logFunctionInfo(func, arg);
				return func( arg ); 
			};
		}
		else 
		{
			if (arg3 == -9000 || arg3 == null)
			{
				return function ():*
				{ 
					if (CoC_Settings.haltOnErrors) 
						logFunctionInfo(func, arg, arg2);
					return func(arg, arg2); 
				};
			}
			else 
			{
				return function ():*
				{ 
					if (CoC_Settings.haltOnErrors) 
						logFunctionInfo(func, arg, arg2, arg3);
					return func(arg, arg2, arg3); 
				};
			}
		}
	}
}
public function createCallBackFunction2(func:Function,...args):Function
{
	if (func == null){
		CoC_Settings.error("createCallBackFunction(null,"+args+")");
	}
	return function():*
	{
		if (CoC_Settings.haltOnErrors) logFunctionInfo(func,args);
		return func.apply(null,args);
	}
}

/**
 * Adds a button.
 * @param	pos Determines the position. Starts at 0. (First row is 0-4, second row is 5-9, third row is 10-14.)
 * @param	text Determines the text that will appear on button.
 * @param	func1 Determines what function to trigger.
 * @param	arg1 Pass argument #1 to func1 parameter.
 * @param	arg2 Pass argument #1 to func1 parameter.
 * @param	arg3 Pass argument #1 to func1 parameter.
 * @param	toolTipText The text that will appear on tooltip when the mouse goes over the button.
 * @param	toolTipHeader The text that will appear on the tooltip header. If not specified, it defaults to button text.
 */
public function addButton(pos:int, text:String = "", func1:Function = null, arg1:* = -9000, arg2:* = -9000, arg3:* = -9000, toolTipText:String = "", toolTipHeader:String = ""):void {
	if (func1==null) return;
	var callback:Function;

	/* Let the mainView decide if index is valid
		if(pos > 14) {
			trace("INVALID BUTTON");
			return;
		}
	*/
	//Removes sex-related button in SFW mode.
	if (flags[kFLAGS.SFW_MODE] > 0) {
		if (text.indexOf("Sex") != -1 || text.indexOf("Threesome") != -1 ||  text.indexOf("Foursome") != -1 || text == "Watersports" || text == "Make Love" || text == "Use Penis" || text == "Use Vagina" || text.indexOf("Fuck") != -1 || text.indexOf("Ride") != -1 || (text.indexOf("Mount") != -1 && text.indexOf("Mountain") == -1) || text.indexOf("Vagina") != -1) {
			trace("Button removed due to SFW mode.");
			return;
		}
	}
	callback = createCallBackFunction(func1, arg1, arg2, arg3);

	if (toolTipText == "") toolTipText = getButtonToolTipText(text);
	if (toolTipHeader == "") toolTipHeader = getButtonToolTipHeader(text);
	mainView.bottomButtons[pos].alpha = 1; // failsafe to avoid possible problems with dirty hack
	mainView.showBottomButton(pos, text, callback, toolTipText, toolTipHeader);
	//mainView.setOutputText( currentText );
	flushOutputTextToGUI();
}

public function addButtonDisabled(pos:int, text:String = "", toolTipText:String = "", toolTipHeader:String = ""):void {
	//Removes sex-related button in SFW mode.
	if (flags[kFLAGS.SFW_MODE] > 0) {
		if (text.indexOf("Sex") != -1 || text.indexOf("Threesome") != -1 ||  text.indexOf("Foursome") != -1 || text == "Watersports" || text == "Make Love" || text == "Use Penis" || text == "Use Vagina" || text.indexOf("Fuck") != -1 || text.indexOf("Ride") != -1 || (text.indexOf("Mount") != -1 && text.indexOf("Mountain") == -1) || text.indexOf("Vagina") != -1) {
			trace("Button removed due to SFW mode.");
			return;
		}
	}

	if (toolTipText == "") toolTipText = getButtonToolTipText(text);
	if (toolTipHeader == "") toolTipHeader = getButtonToolTipHeader(text);
	mainView.showBottomButtonDisabled(pos, text, toolTipText, toolTipHeader);
	flushOutputTextToGUI();
}

public function setButtonTooltip(index:int, toolTipHeader:String = "", toolTipText:String = ""):void {
	mainView.showBottomButton(index, mainView.bottomButtons[index].labelText, mainView.bottomButtons[index].callback, toolTipText, toolTipHeader);
}

public function hasButton(arg:*):Boolean {
	if( arg is String )
		return mainView.hasButton( arg as String );
	else
		return false;
}

/**
 * Removes a button.
 * @param	arg The position to remove a button. (First row is 0-4, second row is 5-9, third row is 10-14.)
 */
public function removeButton(arg:*):void {
	var buttonToRemove:int = 0;
	if(arg is String) {
		buttonToRemove = mainView.indexOfButtonWithLabel( arg as String );
	}
	if(arg is Number) {
		if(arg < 0 || arg > 14) return;
		buttonToRemove = Math.round(arg);
	}
	mainView.hideBottomButton( buttonToRemove );
}

/**
 * Hides all bottom buttons.
 */
public function menu():void { //The newer, simpler menu - blanks all buttons so addButton can be used
	for (var i:int = 0; i <= 14; i++) {
		mainView.hideBottomButton(i);
		mainView.bottomButtons[i].alpha = 1; // Dirty hack.
	}
	flushOutputTextToGUI();
}

/**
 * Adds buttons that can be chosen. 
 * 
 * I highly recommend you <b>DO NOT</b> use this for new content. Use addButton() instead.
 */
public function choices(text1:String, butt1:Function,
						text2:String, butt2:Function,
						text3:String, butt3:Function,
						text4:String, butt4:Function,
						text5:String, butt5:Function,
						text6:String, butt6:Function,
						text7:String, butt7:Function,
						text8:String, butt8:Function,
						text9:String, butt9:Function,
						text0:String, butt0:Function):void { //New typesafe version
							
	menu();	
	addButton(0, text1, butt1);
	addButton(1, text2, butt2);
	addButton(2, text3, butt3);
	addButton(3, text4, butt4);
	addButton(4, text5, butt5);
	addButton(5, text6, butt6);
	addButton(6, text7, butt7);
	addButton(7, text8, butt8);
	addButton(8, text9, butt9);
	addButton(9, text0, butt0);
/*
	var callback :Function;
	var toolTipText :String;

	var textLabels :Array;
	var j :int;

	textLabels = [
		text1,
		text2,
		text3,
		text4,
		text5,
		text6,
		text7,
		text8,
		text9,
		text0
	];

	//Transfer event code to storage
	buttonEvents[0] = butt1;
	buttonEvents[1] = butt2;
	buttonEvents[2] = butt3;
	buttonEvents[3] = butt4;
	buttonEvents[4] = butt5;
	buttonEvents[5] = butt6;
	buttonEvents[6] = butt7;
	buttonEvents[7] = butt8;
	buttonEvents[8] = butt9;
	buttonEvents[9] = butt0;

	var tmpJ:int;

	// iterate over the button options, and only enable the ones which have a corresponding event number
	menu();
	for (tmpJ = 0; tmpJ < 10; tmpJ += 1)
	{
		if(buttonEvents[tmpJ] == -9000 || buttonEvents[tmpJ] == 0 || buttonEvents[tmpJ] == null) {
			mainView.hideBottomButton( tmpJ );
		}
		else {
			if (buttonEvents[tmpJ] is Number) {
				addButton(tmpJ, textLabels[tmpJ], eventParser, buttonEvents[tmpJ]);
				//callback = createCallBackFunction(eventParser, buttonEvents[tmpJ] );
			} else {
				addButton(tmpJ, textLabels[tmpJ], buttonEvents[tmpJ]);
				//callback = createCallBackFunction(buttonEvents[tmpJ], null);
			}
			toolTipText = getButtonToolTipText( textLabels[ tmpJ ] );

			//mainView.showBottomButton( tmpJ, textLabels[ tmpJ ], callback, toolTipText );
		}

	}
	// funcs = new Array();
	// args = new Array();
	//mainView.setOutputText( currentText );
	flushOutputTextToGUI();
*/
}

/****
	This function is made for multipage menus of unpredictable length,
	say a collection of items or places or people that can change
	depending on certain events, past choices, the time of day, or whatever.

	This is not the best for general menu use.  Use choices() for that.

	This is a bit confusing, so here's usage instructions.
	Pay attention to all the braces.

	This is made to be used with an array that you create before calling it,
	so that you can push as many items on to that array as you like
	before passing that array off to this function.

	So you can do something like this:
		var itemsInStorage :Array = new Array();

		// The extra square braces are important.
		itemsInStorage.push( [ "Doohicky", useDoohickyFunc ] );
		itemsInStorage.push( [ "Whatsit", useWhatsitFunc ] );
		itemsInStorage.push( [ "BagOfDicks", eatBagOfDicks ] );
		...

		// see notes about cancelFunc
		multipageChoices( cancelFunc, itemsInStorage );

	cancelfunc is a function (A button event function, specifically)
	that exits the menu.  Provide this if you want a Back button to appear
	in the bottom right.

	If you do not need a cancel function, perhaps because some or all
	of the choices will exit the menu, then you can
	pass null or 0 for the cancelFunction.

		// This menu shows no Back button.
		multipageChoices( null, itemsInStorage );

	You can call it directly if you want, but that's ridiculous.
		multipageChoices( justGoToCamp, [
			[ "Do this", doThisEvent ],
			[ "Do that", doThatEvent ],
			[ "Do something", doSomethingEvent ],
			[ "Fap", goFapEvent ],
			[ "Rape Jojo", jojoRape ],
			// ... more items here...
			[ "What", goWhat ],
			[ "Margle", gurgleFluidsInMouthEvent ] // no comma on last item.
		]);
****/
public function multipageChoices( cancelFunction :*, menuItems :Array ) :void {
	const itemsPerPage :int = 8;

	var currentPageIndex :int;
	var pageCount :int;

	function getPageOfItems( pageIndex :int ) :Array {
		var startItemIndex:int = pageIndex * itemsPerPage;

		return menuItems.slice( startItemIndex, startItemIndex + itemsPerPage );
	}

	function flatten( pageItems :Array ) :Array {
		var i:int, l:int;
		var flattenedItems:Array = [];

		for( i = 0, l = pageItems.length; i < l; ++i ) {
			flattenedItems = flattenedItems.concat( pageItems[ i ] );
		}

		return flattenedItems;
	}

	function showNextPage() :void {
		showPage( (currentPageIndex + 1) % pageCount );
	}

	function showPage( pageIndex :int ) :void {
		var currentPageItems :Array; // holds the current page of items.

		if( pageIndex < 0 )
			pageIndex = 0;
		if( pageIndex >= pageCount )
			pageIndex = pageCount - 1;

		currentPageIndex = pageIndex;
		currentPageItems = getPageOfItems( pageIndex );

		// I did it this way so as to use only one actual menu setting function.
		// I figured it was safer until the menu functions stabilize.

		// insert page functions.
		// First pad out the items so it's always in a predictable state.
		while( currentPageItems.length < 8 ) {
			currentPageItems.push( [ "", 0 ] );
		}

		// Insert next button.
		currentPageItems.splice( 4, 0, [
			"See page " +
				String( ((currentPageIndex + 1) % pageCount) + 1 ) + // A compelling argument for 1-indexing?
				'/' +
				String( pageCount ),
			pageCount > 1 ? showNextPage : 0
			// "Next Page", pageCount > 1 ? showNextPage : 0
			]);

		// Cancel/Back button always appears in bottom right, like in the inventory.
		currentPageItems.push([
			"Back", cancelFunction || 0
			]);

		choices.apply( null, flatten( currentPageItems ) );
	}

	pageCount = Math.ceil( menuItems.length / itemsPerPage );

	if( typeof cancelFunction != 'function' )
		cancelFunction = 0;

	showPage( 0 );
}

// simpleChoices and doYesNo are convenience functions. They shouldn't re-implement code from choices()
/**
 * Adds five button that can be chosen. 
 * 
 * I highly recommend you <b>DO NOT</b> use this for new content. Use addButton() instead.
 */
public function simpleChoices(text1:String, butt1:Function, 
						text2:String, butt2:Function, 
						text3:String, butt3:Function, 
						text4:String, butt4:Function, 
						text5:String, butt5:Function):void { //New typesafe version

	//trace("SimpleChoices");
/*	choices(text1,butt1,
			text2,butt2,
			text3,butt3,
			text4,butt4,
			text5,butt5,
			"",0,
			"",0,
			"",0,
			"",0,
			"",0);*/
	menu();
	addButton(0, text1, butt1);
	addButton(1, text2, butt2);
	addButton(2, text3, butt3);
	addButton(3, text4, butt4);
	addButton(4, text5, butt5);
}

/**
 * Clears all button and adds a 'Yes' and a 'No' button.
 * @param	eventYes The event parser or function to call if 'Yes' button is pressed.
 * @param	eventNo The event parser or function to call if 'No' button is pressed.
 */
public function doYesNo(eventYes:Function, eventNo:Function):void { //New typesafe version
	menu();
	addButton(0, "Yes", eventYes);
	addButton(1, "No", eventNo);
/*
	//Make buttons 1-2 visible and hide the rest.

	//trace("doYesNo");
	choices("Yes",eventYes,
			"No",eventNo,
			"",0,
			"",0,
			"",0,
			"",0,
			"",0,
			"",0,
			"",0,
			"",0);

}
*/
}

/**
 * Clears all button and adds a 'Next' button.
 * @param	event The event function to call if the button is pressed.
 */
public function doNext(event:Function):void { //Now typesafe
	//Prevent new events in combat from automatically overwriting a game over. 
	if (mainView.getButtonText(0).indexOf("Game Over") != -1) {
		trace("Do next setup cancelled by game over");
		return;
	}
	
	//trace("DoNext have item:", eventNo);
	//choices("Next", event, "", 0, "", 0, "", 0, "", 0, "", 0, "", 0, "", 0, "", 0, "", 0); 
	menu();
	addButton(0, "Next", event);
}

/* Was never called
public function doNextClear(eventNo:*):void 
{
	outputText("", true, true);
	//trace("DoNext Clearing display");
	//trace("DoNext have item:", eventNo);
	choices("Next", eventNo, "", 0, "", 0, "", 0, "", 0, "", 0, "", 0, "", 0, "", 0, "", 0);
}
*/

public function invertGo():void{ 
	mainView.invert();
}

/**
 * Used to update the display of statistics
 */
public function statScreenRefresh():void {
	mainView.statsView.show(); // show() method refreshes.
	mainViewManager.refreshStats();
}
/**
 * Show the stats pane. (Name, stats and attributes)
 */
public function showStats():void {
	mainView.statsView.show();
	mainViewManager.refreshStats();
	mainViewManager.tweenInStats();
}
/**
 * Hide the stats pane. (Name, stats and attributes)
 */
public function hideStats():void {
	if (!mainViewManager.buttonsTweened) mainView.statsView.hide();
	mainViewManager.tweenOutStats();
}

/**
 * Hide the top buttons.
 */
public function hideMenus():void {
	mainView.hideAllMenuButtons();
}

/**
 * Hides the up/down arrow on stats pane.
 */
public function hideUpDown():void {
	mainView.statsView.hideUpDown();
	//Clear storage values so up/down arrows can be properly displayed
	oldStats.oldStr = 0;
	oldStats.oldTou = 0;
	oldStats.oldSpe = 0;
	oldStats.oldInte = 0;
	oldStats.oldLib = 0;
	oldStats.oldSens = 0;
	oldStats.oldCor = 0;  
	oldStats.oldHP = 0;
	oldStats.oldLust = 0;
	oldStats.oldFatigue = 0;
	oldStats.oldHunger = 0;
}

public function physicalCost(mod:Number):Number {
	var costPercent:Number = 100;
	if(player.findPerk(PerkLib.IronMan) >= 0) costPercent -= 50;
	mod *= costPercent/100;
	return mod;
}

public function spellCost(mod:Number):Number {
	//Addiditive mods
	var costPercent:Number = 100;
	if(player.findPerk(PerkLib.SpellcastingAffinity) >= 0) costPercent -= player.perkv1(PerkLib.SpellcastingAffinity);
	if(player.findPerk(PerkLib.WizardsEndurance) >= 0) costPercent -= player.perkv1(PerkLib.WizardsEndurance);
	
	//Limiting it and multiplicative mods
	if(player.findPerk(PerkLib.BloodMage) >= 0 && costPercent < 50) costPercent = 50;
	
	mod *= costPercent/100;
	
	if(player.findPerk(PerkLib.HistoryScholar) >= 0) {
		if(mod > 2) mod *= .8;
	}
	if(player.findPerk(PerkLib.BloodMage) >= 0 && mod < 5) mod = 5;
	else if(mod < 2) mod = 2;
	
	mod = Math.round(mod * 100)/100;
	return mod;
}

//Modify fatigue
//types:
//  0 - normal
//	1 - magic
//	2 - physical
//	3 - non-bloodmage magic
public function fatigue(mod:Number,type:Number  = 0):void {
	//Spell reductions
	if(type == 1) {
		mod = spellCost(mod);
		
		//Blood mages use HP for spells
		if(player.findPerk(PerkLib.BloodMage) >= 0) {
			takeDamage(mod);
			statScreenRefresh();
			return;
		}                
	}
	//Physical special reductions
	if(type == 2) {
		mod = physicalCost(mod);
	}
	if(type == 3) {
		mod = spellCost(mod);
	}
	if(player.fatigue >= player.maxFatigue() && mod > 0) return;
	if(player.fatigue <= 0 && mod < 0) return;
	//Fatigue restoration buffs!
	if (mod < 0) {
		var multi:Number = 1;
		
		if (player.findPerk(PerkLib.HistorySlacker) >= 0) multi *= 1.2;
		if (player.findPerk(PerkLib.ControlledBreath) >= 0 && player.cor < (30 + player.corruptionTolerance())) multi *= 1.1;
		if (player.findPerk(PerkLib.SpeedyRecovery) >= 0) multi *= 1.5;
		
		mod *= multi;
	}
	player.fatigue += mod;
	if(mod > 0) {
		mainView.statsView.showStatUp( 'fatigue' );
		// fatigueUp.visible = true;
		// fatigueDown.visible = false;
	}
	if(mod < 0) {
		mainView.statsView.showStatDown( 'fatigue' );
		// fatigueDown.visible = true;
		// fatigueUp.visible = false;
	}
	dynStats("lus", 0, "resisted", false); //Force display fatigue up/down by invoking zero lust change.
	if(player.fatigue > player.maxFatigue()) player.fatigue = player.maxFatigue();
	if(player.fatigue < 0) player.fatigue = 0;
	statScreenRefresh();
}
//function changeFatigue
public function changeFatigue(changeF:Number):void {
	fatigue(changeF);
}
public function minLust():Number {
	return player.minLust();
}

public function displayStats(e:MouseEvent = null):void
{
	spriteSelect(-1);
	clearOutput();
	displayHeader("Stats");
	// Begin Combat Stats
	var combatStats:String = "";
	
	if (player.hasKeyItem("Bow") >= 0 || player.hasKeyItem("Kelt's Bow") >= 0)
		combatStats += "<b>Bow Skill:</b> " + Math.round(player.statusAffectv1(StatusAffects.Kelt)) + " / 100\n";
		
	combatStats += "<b>Damage Resistance:</b> " + (100 - Math.round(player.damagePercent(true))) + "-" + (100 - Math.round(player.damagePercent(true) - player.damageToughnessModifier(true))) + "% (Higher is better.)\n";

	combatStats += "<b>Lust Resistance:</b> " + (100 - Math.round(lustPercent())) + "% (Higher is better.)\n";
	
	combatStats += "<b>Spell Effect Multiplier:</b> " + Math.round(100 * spellMod()) + "%\n";
	
	combatStats += "<b>Spell Cost:</b> " + spellCost(100) + "%\n";
	
	if (flags[kFLAGS.RAPHAEL_RAPIER_TRANING] > 0)
		combatStats += "<b>Rapier Skill:</b> " + flags[kFLAGS.RAPHAEL_RAPIER_TRANING] + " / 4\n";
	
	if (player.teaseLevel < 5)
		combatStats += "<b>Tease Skill:</b>  " + player.teaseLevel + " / 5 (Exp: " + player.teaseXP + " / "+ (10 + (player.teaseLevel + 1) * 5 * (player.teaseLevel + 1))+ ")\n";
	else
		combatStats += "<b>Tease Skill:</b>  " + player.teaseLevel + " / 5 (Exp: MAX)\n";	
		
	if (combatStats != "")
		outputText("<b><u>Combat Stats</u></b>\n" + combatStats, false);
	// End Combat Stats
	
	if (prison.inPrison || flags[kFLAGS.PRISON_CAPTURE_COUNTER] > 0) prison.displayPrisonStats();
	
	// Begin Children Stats
	var childStats:String = "";
	
	if (player.statusAffectv1(StatusAffects.Birthed) > 0)
		childStats += "<b>Times Given Birth:</b> " + player.statusAffectv1(StatusAffects.Birthed) + "\n";
		
	if (flags[kFLAGS.AMILY_MET] > 0)
		childStats += "<b>Litters With Amily:</b> " + (flags[kFLAGS.AMILY_BIRTH_TOTAL] + flags[kFLAGS.PC_TIMES_BIRTHED_AMILYKIDS]) + "\n";

	if (flags[kFLAGS.BEHEMOTH_CHILDREN] > 0)
		childStats += "<b>Children With Behemoth:</b> " + flags[kFLAGS.BEHEMOTH_CHILDREN] + "\n";

	if (flags[kFLAGS.BENOIT_EGGS] > 0)
		childStats += "<b>Benoit Eggs Laid:</b> " + flags[kFLAGS.BENOIT_EGGS] + "\n";
	if (flags[kFLAGS.FEMOIT_EGGS_LAID] > 0)
		childStats += "<b>Benoite Eggs Produced:</b> " + flags[kFLAGS.FEMOIT_EGGS_LAID] + "\n";
		
	if (flags[kFLAGS.COTTON_KID_COUNT] > 0)
		childStats += "<b>Children With Cotton:</b> " + flags[kFLAGS.COTTON_KID_COUNT] + "\n";
	
	if (flags[kFLAGS.EDRYN_NUMBER_OF_KIDS] > 0)
		childStats += "<b>Children With Edryn:</b> " + flags[kFLAGS.EDRYN_NUMBER_OF_KIDS] + "\n";
		
	if (flags[kFLAGS.EMBER_CHILDREN_MALES] > 0)
		childStats += "<b>Ember Offspring (Males):</b> " + flags[kFLAGS.EMBER_CHILDREN_MALES] + "\n";
	if (flags[kFLAGS.EMBER_CHILDREN_FEMALES] > 0)
		childStats += "<b>Ember Offspring (Females):</b> " + flags[kFLAGS.EMBER_CHILDREN_FEMALES] + "\n";
	if (flags[kFLAGS.EMBER_CHILDREN_HERMS] > 0)
		childStats += "<b>Ember Offspring (Herms):</b> " + flags[kFLAGS.EMBER_CHILDREN_HERMS] + "\n";
	if (emberScene.emberChildren() > 0)
		childStats += "<b>Total Children With Ember:</b> " + (emberScene.emberChildren()) + "\n";
	
	if (flags[kFLAGS.EMBER_EGGS] > 0)
		childStats += "<b>Ember Eggs Produced:</b> " + flags[kFLAGS.EMBER_EGGS] + "\n";
		
	if (isabellaScene.totalIsabellaChildren() > 0) {
		if (isabellaScene.getIsabellaChildType(IsabellaScene.OFFSPRING_HUMAN_BOYS) > 0)
			childStats += "<b>Children With Isabella (Human, Males):</b> " + isabellaScene.getIsabellaChildType(IsabellaScene.OFFSPRING_HUMAN_BOYS) + "\n";
		if (isabellaScene.getIsabellaChildType(IsabellaScene.OFFSPRING_HUMAN_GIRLS) > 0)
			childStats += "<b>Children With Isabella (Human, Females):</b> " + isabellaScene.getIsabellaChildType(IsabellaScene.OFFSPRING_HUMAN_GIRLS) + "\n";
		if (isabellaScene.getIsabellaChildType(IsabellaScene.OFFSPRING_HUMAN_HERMS) > 0)
			childStats += "<b>Children With Isabella (Human, Herms):</b> " + isabellaScene.getIsabellaChildType(IsabellaScene.OFFSPRING_HUMAN_HERMS) + "\n";
		if (isabellaScene.getIsabellaChildType(IsabellaScene.OFFSPRING_COWGIRLS) > 0)
			childStats += "<b>Children With Isabella (Cowgirl, Females):</b> " + isabellaScene.getIsabellaChildType(IsabellaScene.OFFSPRING_COWGIRLS) + "\n";
		if (isabellaScene.getIsabellaChildType(IsabellaScene.OFFSPRING_COWFUTAS) > 0)
			childStats += "<b>Children With Isabella (Cowgirl, Herms):</b> " + isabellaScene.getIsabellaChildType(IsabellaScene.OFFSPRING_COWFUTAS) + "\n";
		childStats += "<b>Total Children With Isabella:</b> " + isabellaScene.totalIsabellaChildren() + "\n"
	}
		
		
	if (flags[kFLAGS.IZMA_CHILDREN_SHARKGIRLS] > 0)
		childStats += "<b>Children With Izma (Sharkgirls):</b> " + flags[kFLAGS.IZMA_CHILDREN_SHARKGIRLS] + "\n";
	if (flags[kFLAGS.IZMA_CHILDREN_TIGERSHARKS] > 0)
		childStats += "<b>Children With Izma (Tigersharks):</b> " + flags[kFLAGS.IZMA_CHILDREN_TIGERSHARKS] + "\n";
	if (flags[kFLAGS.IZMA_CHILDREN_SHARKGIRLS] > 0 && flags[kFLAGS.IZMA_CHILDREN_TIGERSHARKS] > 0)
		childStats += "<b>Total Children with Izma:</b> " + (flags[kFLAGS.IZMA_CHILDREN_SHARKGIRLS] + flags[kFLAGS.IZMA_CHILDREN_TIGERSHARKS]) + "\n";
		
	if (joyScene.getTotalLitters() > 0)
		childStats += "<b>Litters With " + (flags[kFLAGS.JOJO_BIMBO_STATE] >= 3 ? "Joy" : "Jojo") + ":</b> " + joyScene.getTotalLitters() + "\n";
		
	if (flags[kFLAGS.KELLY_KIDS_MALE] > 0)
		childStats += "<b>Children With Kelly (Males):</b> " + flags[kFLAGS.KELLY_KIDS_MALE] + "\n";
	if (flags[kFLAGS.KELLY_KIDS] - flags[kFLAGS.KELLY_KIDS_MALE] > 0)
		childStats += "<b>Children With Kelly (Females):</b> " + (flags[kFLAGS.KELLY_KIDS] - flags[kFLAGS.KELLY_KIDS_MALE]) + "\n";
	if (flags[kFLAGS.KELLY_KIDS] > 0)
		childStats += "<b>Total Children With Kelly:</b> " + flags[kFLAGS.KELLY_KIDS] + "\n";
	if (kihaFollower.pregnancy.isPregnant)
		childStats += "<b>Kiha's Pregnancy:</b> " + kihaFollower.pregnancy.incubation + "\n";
	if (flags[kFLAGS.KIHA_CHILDREN_BOYS] > 0)
		childStats += "<b>Kiha Offspring (Males):</b> " + flags[kFLAGS.KIHA_CHILDREN_BOYS] + "\n";
	if (flags[kFLAGS.KIHA_CHILDREN_GIRLS] > 0)
		childStats += "<b>Kiha Offspring (Females):</b> " + flags[kFLAGS.KIHA_CHILDREN_GIRLS] + "\n";
	if (flags[kFLAGS.KIHA_CHILDREN_HERMS] > 0)
		childStats += "<b>Kiha Offspring (Herms):</b> " + flags[kFLAGS.KIHA_CHILDREN_HERMS] + "\n";
	if (kihaFollower.totalKihaChildren() > 0)
		childStats += "<b>Total Children With Kiha:</b> " + kihaFollower.totalKihaChildren() + "\n";
		
	if (mountain.salon.lynnetteApproval() != 0)
		childStats += "<b>Lynnette Children:</b> " + flags[kFLAGS.LYNNETTE_BABY_COUNT] + "\n";
		
	if (flags[kFLAGS.MARBLE_KIDS] > 0)
		childStats += "<b>Children With Marble:</b> " + flags[kFLAGS.MARBLE_KIDS] + "\n";
		
	if (flags[kFLAGS.MINERVA_CHILDREN] > 0)
		childStats += "<b>Children With Minerva:</b> " + flags[kFLAGS.MINERVA_CHILDREN] + "\n";
		
	if (flags[kFLAGS.ANT_KIDS] > 0)
		childStats += "<b>Ant Children With Phylla:</b> " + flags[kFLAGS.ANT_KIDS] + "\n";
	if (flags[kFLAGS.PHYLLA_DRIDER_BABIES_COUNT] > 0)
		childStats += "<b>Drider Children With Phylla:</b> " + flags[kFLAGS.PHYLLA_DRIDER_BABIES_COUNT] + "\n";
	if (flags[kFLAGS.ANT_KIDS] > 0 && flags[kFLAGS.PHYLLA_DRIDER_BABIES_COUNT] > 0)
		childStats += "<b>Total Children With Phylla:</b> " + (flags[kFLAGS.ANT_KIDS] + flags[kFLAGS.PHYLLA_DRIDER_BABIES_COUNT]) + "\n";
		
	if (flags[kFLAGS.SHEILA_JOEYS] > 0)
		childStats += "<b>Children With Sheila (Joeys):</b> " + flags[kFLAGS.SHEILA_JOEYS] + "\n";
	if (flags[kFLAGS.SHEILA_IMPS] > 0)
		childStats += "<b>Children With Sheila (Imps):</b> " + flags[kFLAGS.SHEILA_IMPS] + "\n";
	if (flags[kFLAGS.SHEILA_JOEYS] > 0 && flags[kFLAGS.SHEILA_IMPS] > 0)
		childStats += "<b>Total Children With Sheila:</b> " + (flags[kFLAGS.SHEILA_JOEYS] + flags[kFLAGS.SHEILA_IMPS]) + "\n";
		
	if (flags[kFLAGS.SOPHIE_ADULT_KID_COUNT] > 0 || flags[kFLAGS.SOPHIE_DAUGHTER_MATURITY_COUNTER] > 0) 
	{
		childStats += "<b>Children With Sophie:</b> ";
		var sophie:int = 0;
		if (flags[kFLAGS.SOPHIE_DAUGHTER_MATURITY_COUNTER] > 0) sophie++;
		sophie += flags[kFLAGS.SOPHIE_ADULT_KID_COUNT];
		if (flags[kFLAGS.SOPHIE_CAMP_EGG_COUNTDOWN] > 0) sophie++;
		childStats += sophie + "\n";
	}
	
	if (flags[kFLAGS.SOPHIE_EGGS_LAID] > 0)
		childStats += "<b>Eggs Fertilized For Sophie:</b> " + (flags[kFLAGS.SOPHIE_EGGS_LAID] + sophie) + "\n";
		
	if (flags[kFLAGS.TAMANI_NUMBER_OF_DAUGHTERS] > 0)
		childStats += "<b>Children With Tamani:</b> " + flags[kFLAGS.TAMANI_NUMBER_OF_DAUGHTERS] + " (after all forms of natural selection)\n";
		
	if (urtaPregs.urtaKids() > 0)
		childStats += "<b>Children With Urta:</b> " + urtaPregs.urtaKids() + "\n";
		
	//Mino sons
	if (flags[kFLAGS.UNKNOWN_FLAG_NUMBER_00326] > 0)
		childStats += "<b>Number of Adult Minotaur Offspring:</b> " + flags[kFLAGS.UNKNOWN_FLAG_NUMBER_00326] + "\n";
	
	if (childStats != "")
		outputText("\n<b><u>Children</u></b>\n" + childStats, false);
	// End Children Stats

	// Begin Body Stats
	var bodyStats:String = "";

	if (flags[kFLAGS.HUNGER_ENABLED] > 0 || flags[kFLAGS.IN_PRISON] > 0)
	{
		bodyStats += "<b>Satiety:</b> " + Math.floor(player.hunger) + " / 100 (";
		if (player.hunger <= 0) bodyStats += "<font color=\"#ff0000\">Dying</font>";
		if (player.hunger > 0 && player.hunger < 10) bodyStats += "<font color=\"#C00000\">Starving</font>";
		if (player.hunger >= 10 && player.hunger < 25) bodyStats += "<font color=\"#800000\">Very hungry</font>";
		if (player.hunger >= 25 && player.hunger < 50) bodyStats += "Hungry";
		if (player.hunger >= 50 && player.hunger < 75) bodyStats += "Not hungry";
		if (player.hunger >= 75 && player.hunger < 90) bodyStats += "<font color=\"#008000\">Satiated</font>";
		if (player.hunger >= 90 && player.hunger < 100) bodyStats += "<font color=\"#00C000\">Full</font>";
		if (player.hunger >= 100) bodyStats += "<font color=\"#00C000\">Very full</font>";
		bodyStats += ")\n";
	}

	bodyStats += "<b>Anal Capacity:</b> " + Math.round(player.analCapacity()) + "\n";
	bodyStats += "<b>Anal Looseness:</b> " + Math.round(player.ass.analLooseness) + "\n";
	
	bodyStats += "<b>Fertility (Base) Rating:</b> " + Math.round(player.fertility) + "\n";
	bodyStats += "<b>Fertility (With Bonuses) Rating:</b> " + Math.round(player.totalFertility()) + "\n";
	
	if (player.cumQ() > 0)
		bodyStats += "<b>Virility Rating:</b> " + Math.round(player.virilityQ() * 100) + "\n";
		if (flags[kFLAGS.HUNGER_ENABLED] >= 1) bodyStats += "<b>Cum Production:</b> " + addComma(Math.round(player.cumQ())) + " / " + addComma(Math.round(player.cumCapacity())) + "mL (" + Math.round((player.cumQ() / player.cumCapacity()) * 100) + "%) \n";
		else bodyStats += "<b>Cum Production:</b> " + addComma(Math.round(player.cumQ())) + "mL\n";
	if (player.lactationQ() > 0)
		bodyStats += "<b>Milk Production:</b> " + addComma(Math.round(player.lactationQ())) + "mL\n";
	
	if (player.findStatusAffect(StatusAffects.Feeder) >= 0) {
		bodyStats += "<b>Hours Since Last Time Breastfed Someone:</b>  " + player.statusAffectv2(StatusAffects.Feeder);
		if (player.statusAffectv2(StatusAffects.Feeder) >= 72)
			bodyStats += " (Too long! Sensitivity Increasing!)";
		
		bodyStats += "\n";
	}
	
	bodyStats += "<b>Pregnancy Speed Multiplier:</b> ";
	var preg:Number = 1;
	if (player.findPerk(PerkLib.Diapause) >= 0)
		bodyStats += "? (Variable due to Diapause)\n";
	else {
		if (player.findPerk(PerkLib.MaraesGiftFertility) >= 0) preg++;
		if (player.findPerk(PerkLib.BroodMother) >= 0) preg++;
		if (player.findPerk(PerkLib.FerasBoonBreedingBitch) >= 0) preg++;
		if (player.findPerk(PerkLib.MagicalFertility) >= 0) preg++;
		if (player.findPerk(PerkLib.FerasBoonWideOpen) >= 0 || player.findPerk(PerkLib.FerasBoonMilkingTwat) >= 0) preg++;
		bodyStats += preg + "\n";
	}
	
	if (player.cocks.length > 0) {
		bodyStats += "<b>Total Cocks:</b> " + player.cocks.length + "\n";

		var totalCockLength:Number = 0;
		var totalCockGirth:Number = 0;
		
		for (var i:Number = 0; i < player.cocks.length; i++) {
				totalCockLength += player.cocks[i].cockLength;
				totalCockGirth += player.cocks[i].cockThickness
		}
				
		bodyStats += "<b>Total Cock Length:</b> " + Math.round(totalCockLength) + " inches\n";
		bodyStats += "<b>Total Cock Girth:</b> " + Math.round(totalCockGirth) + " inches\n";
		
	}
	
	if (player.vaginas.length > 0)
		bodyStats += "<b>Vaginal Capacity:</b> " + Math.round(player.vaginalCapacity()) + "\n" + "<b>Vaginal Looseness:</b> " + Math.round(player.looseness()) + "\n";

	if (player.findPerk(PerkLib.SpiderOvipositor) >= 0 || player.findPerk(PerkLib.BeeOvipositor) >= 0)
		bodyStats += "<b>Ovipositor Total Egg Count: " + player.eggs() + "\nOvipositor Fertilized Egg Count: " + player.fertilizedEggs() + "</b>\n";
		
	if (player.findStatusAffect(StatusAffects.SlimeCraving) >= 0) {
		if (player.statusAffectv1(StatusAffects.SlimeCraving) >= 18)
			bodyStats += "<b>Slime Craving:</b> Active! You are currently losing strength and speed.  You should find fluids.\n";
		else {
			if (player.findPerk(PerkLib.SlimeCore) >= 0)
				bodyStats += "<b>Slime Stored:</b> " + ((17 - player.statusAffectv1(StatusAffects.SlimeCraving)) * 2) + " hours until you start losing strength.\n";
			else
				bodyStats += "<b>Slime Stored:</b> " + (17 - player.statusAffectv1(StatusAffects.SlimeCraving)) + " hours until you start losing strength.\n";
		}
	}
	
	if (bodyStats != "")
		outputText("\n<b><u>Body Stats</u></b>\n" + bodyStats, false);
	// End Body Stats

	// Begin Misc Stats
	var miscStats:String = "";

	if (camp.getCampPopulation() > 0)
		miscStats += "<b>Camp Population:</b> " + camp.getCampPopulation() + "\n";
	
	if (flags[kFLAGS.CORRUPTED_GLADES_DESTROYED] > 0) {
		if (flags[kFLAGS.CORRUPTED_GLADES_DESTROYED] < 100)
			miscStats += "<b>Corrupted Glades Status:</b> " + (100 - flags[kFLAGS.CORRUPTED_GLADES_DESTROYED]) + "% remaining\n";
		else 
			miscStats += "<b>Corrupted Glades Status:</b> Extinct\n";
	}
		
	if (flags[kFLAGS.EGGS_BOUGHT] > 0)
		miscStats += "<b>Eggs Traded For:</b> " + flags[kFLAGS.EGGS_BOUGHT] + "\n";
	
	if (flags[kFLAGS.TIMES_AUTOFELLATIO_DUE_TO_CAT_FLEXABILITY] > 0)
		miscStats += "<b>Times Had Fun with Feline Flexibility:</b> " + flags[kFLAGS.TIMES_AUTOFELLATIO_DUE_TO_CAT_FLEXABILITY] + "\n";
	
	if (flags[kFLAGS.FAP_ARENA_SESSIONS] > 0)
		miscStats += "<b>Times Circle Jerked in the Arena:</b> " + flags[kFLAGS.FAP_ARENA_SESSIONS] + "\n<b>Victories in the Arena:</b> " + flags[kFLAGS.FAP_ARENA_VICTORIES] + "\n";
	
	if (flags[kFLAGS.SPELLS_CAST] > 0)
		miscStats += "<b>Spells Cast:</b> " + flags[kFLAGS.SPELLS_CAST] + "\n";
	
	if (flags[kFLAGS.TIMES_BAD_ENDED] > 0)
		miscStats += "<b>Times Bad-Ended:</b> " + flags[kFLAGS.TIMES_BAD_ENDED] + "\n";
	
	if (flags[kFLAGS.TIMES_ORGASMED] > 0)
		miscStats += "<b>Times Orgasmed:</b> " + flags[kFLAGS.TIMES_ORGASMED] + "\n";
	
	if (miscStats != "")
		outputText("\n<b><u>Miscellaneous Stats</u></b>\n" + miscStats);
	// End Misc Stats
	
	// Begin Addition Stats
	var addictStats:String = "";
	//Marble Milk Addition
	if (player.statusAffectv3(StatusAffects.Marble) > 0) {
		addictStats += "<b>Marble Milk:</b> ";
		if (player.findPerk(PerkLib.MarbleResistant) < 0 && player.findPerk(PerkLib.MarblesMilk) < 0)
			addictStats += Math.round(player.statusAffectv2(StatusAffects.Marble)) + "%\n";
		else if (player.findPerk(PerkLib.MarbleResistant) >= 0)
			addictStats += "0%\n";
		else
			addictStats += "100%\n";
	}
	
	// Corrupted Minerva's Cum Addiction
	if (flags[kFLAGS.MINERVA_CORRUPTION_PROGRESS] >= 10 && flags[kFLAGS.MINERVA_CORRUPTED_CUM_ADDICTION] > 0) {
		addictStats += "<b>Minerva's Cum:</b> " + (flags[kFLAGS.MINERVA_CORRUPTED_CUM_ADDICTION] * 20) + "%";
	}
	
	// Mino Cum Addiction
	if (flags[kFLAGS.UNKNOWN_FLAG_NUMBER_00340] > 0 || flags[kFLAGS.MINOTAUR_CUM_ADDICTION_TRACKER] > 0 || player.findPerk(PerkLib.MinotaurCumAddict) >= 0 || player.findPerk(PerkLib.MinotaurCumResistance) >= 0) {
		if (player.findPerk(PerkLib.MinotaurCumAddict) < 0)
			addictStats += "<b>Minotaur Cum:</b> " + Math.round(flags[kFLAGS.MINOTAUR_CUM_ADDICTION_TRACKER] * 10)/10 + "%\n";
		else if (player.findPerk(PerkLib.MinotaurCumResistance) >= 0)
			addictStats += "<b>Minotaur Cum:</b> 0% (Immune)\n";
		else
			addictStats += "<b>Minotaur Cum:</b> 100+%\n";
	}
	
	if (addictStats != "")
		outputText("\n<b><u>Addictions</u></b>\n" + addictStats, false);
	// End Addition Stats
	
	// Begin Interpersonal Stats
	var interpersonStats:String = "";
	
	if (flags[kFLAGS.ARIAN_PARK] > 0)
		interpersonStats += "<b>Arian's Health:</b> " + Math.round(arianScene.arianHealth()) + "\n";
		
	if (flags[kFLAGS.ARIAN_VIRGIN] > 0)
		interpersonStats += "<b>Arian Sex Counter:</b> " + Math.round(flags[kFLAGS.ARIAN_VIRGIN]) + "\n";
	
	if (bazaar.benoit.benoitAffection() > 0)
		interpersonStats += "<b>" + bazaar.benoit.benoitMF("Benoit", "Benoite") + " Affection:</b> " + Math.round(bazaar.benoit.benoitAffection()) + "%\n";
	
	if (flags[kFLAGS.BROOKE_MET] > 0)
		interpersonStats += "<b>Brooke Affection:</b> " + Math.round(telAdre.brooke.brookeAffection()) + "\n";
		
	if (flags[kFLAGS.UNKNOWN_FLAG_NUMBER_00218] + flags[kFLAGS.UNKNOWN_FLAG_NUMBER_00219] + flags[kFLAGS.UNKNOWN_FLAG_NUMBER_00220] > 0)
		interpersonStats += "<b>Body Parts Taken By Ceraph:</b> " + (flags[kFLAGS.UNKNOWN_FLAG_NUMBER_00218] + flags[kFLAGS.UNKNOWN_FLAG_NUMBER_00219] + flags[kFLAGS.UNKNOWN_FLAG_NUMBER_00220]) + "\n";
		
	if (emberScene.emberAffection() > 0)
		interpersonStats += "<b>Ember Affection:</b> " + Math.round(emberScene.emberAffection()) + "%\n";
	
	if (helFollower.helAffection() > 0)
		interpersonStats += "<b>Helia Affection:</b> " + Math.round(helFollower.helAffection()) + "%\n";
	if (helFollower.helAffection() >= 100)
		interpersonStats += "<b>Helia Bonus Points:</b> " + Math.round(flags[kFLAGS.HEL_BONUS_POINTS]) + "\n";
	
	if (flags[kFLAGS.ISABELLA_AFFECTION] > 0) {
		interpersonStats += "<b>Isabella Affection:</b> ";
		
		if (!isabellaFollowerScene.isabellaFollower())
			interpersonStats += Math.round(flags[kFLAGS.ISABELLA_AFFECTION]) + "%\n", false;
		else
			interpersonStats += "100%\n";
	}
	
	if (flags[kFLAGS.JOJO_BIMBO_STATE] >= 3) {
		interpersonStats += "<b>Joy's Intelligence:</b> " + flags[kFLAGS.JOY_INTELLIGENCE];
		if (flags[kFLAGS.JOY_INTELLIGENCE] >= 50) interpersonStats += " (MAX)"
		interpersonStats += "\n";
	}
	
	if (flags[kFLAGS.KATHERINE_UNLOCKED] >= 4) {
		interpersonStats += "<b>Katherine Submissiveness:</b> " + telAdre.katherine.submissiveness() + "\n";
	}

	if (player.findStatusAffect(StatusAffects.Kelt) >= 0 && flags[kFLAGS.KELT_BREAK_LEVEL] == 0 && flags[kFLAGS.KELT_KILLED] == 0) {
		if (player.statusAffectv2(StatusAffects.Kelt) >= 130)
			interpersonStats += "<b>Submissiveness To Kelt:</b> " + 100 + "%\n";
		else
			interpersonStats += "<b>Submissiveness To Kelt:</b> " + Math.round(player.statusAffectv2(StatusAffects.Kelt) / 130 * 100) + "%\n";
			
	}
	
	if (flags[kFLAGS.ANEMONE_KID] > 0)
		interpersonStats += "<b>Kid A's Confidence:</b> " + anemoneScene.kidAXP() + "%\n";

	if (flags[kFLAGS.KIHA_AFFECTION_LEVEL] == 2) {
		if (kihaFollower.followerKiha())
			interpersonStats += "<b>Kiha Affection:</b> " + 100 + "%\n";
		else
			interpersonStats += "<b>Kiha Affection:</b> " + Math.round(flags[kFLAGS.KIHA_AFFECTION]) + "%\n";
	}
	//Lottie stuff
	if (flags[kFLAGS.UNKNOWN_FLAG_NUMBER_00281] > 0)
		interpersonStats += "<b>Lottie's Encouragement:</b> " + telAdre.lottie.lottieMorale() + " (higher is better)\n" + "<b>Lottie's Figure:</b> " + telAdre.lottie.lottieTone() + " (higher is better)\n";
	
	if (mountain.salon.lynnetteApproval() != 0)
		interpersonStats += "<b>Lynnette's Approval:</b> " + mountain.salon.lynnetteApproval() + "\n";
		
	if (flags[kFLAGS.OWCAS_ATTITUDE] > 0)
		interpersonStats += "<b>Owca's Attitude:</b> " + flags[kFLAGS.OWCAS_ATTITUDE] + "\n";
		
	if (telAdre.rubi.rubiAffection() > 0)
		interpersonStats += "<b>Rubi's Affection:</b> " + Math.round(telAdre.rubi.rubiAffection()) + "%\n" + "<b>Rubi's Orifice Capacity:</b> " + Math.round(telAdre.rubi.rubiCapacity()) + "%\n";

	if (flags[kFLAGS.SHEILA_XP] != 0) {
		interpersonStats += "<b>Sheila's Corruption:</b> " + sheilaScene.sheilaCorruption();
		if (sheilaScene.sheilaCorruption() > 100)
			interpersonStats += " (Yes, it can go above 100)";
		interpersonStats += "\n";
	}
	
	if (valeria.valeriaFluidsEnabled()) {
		interpersonStats += "<b>Valeria's Fluid:</b> " + flags[kFLAGS.VALERIA_FLUIDS] + "%\n"
	}
	
	if (flags[kFLAGS.URTA_COMFORTABLE_WITH_OWN_BODY] != 0) {
		if (urta.urtaLove()) {
			if (flags[kFLAGS.URTA_QUEST_STATUS] == -1) interpersonStats += "<b>Urta Status:</b> <font color=\"#800000\">Gone</font>\n";
			if (flags[kFLAGS.URTA_QUEST_STATUS] == 0) interpersonStats += "<b>Urta Status:</b> Lover\n";
			if (flags[kFLAGS.URTA_QUEST_STATUS] == 1) interpersonStats += "<b>Urta Status:</b> <font color=\"#008000\">Lover+</font>\n";
		}
		else if (flags[kFLAGS.URTA_COMFORTABLE_WITH_OWN_BODY] == -1)
			interpersonStats += "<b>Urta Status:</b> Ashamed\n";
		else if (flags[kFLAGS.URTA_PC_AFFECTION_COUNTER] < 30)
			interpersonStats += "<b>Urta's Affection:</b> " + Math.round(flags[kFLAGS.URTA_PC_AFFECTION_COUNTER] * 3.3333) + "%\n";
		else
			interpersonStats += "<b>Urta Status:</b> Ready To Confess Love\n";
	}
	
	if (interpersonStats != "")
		outputText("\n<b><u>Interpersonal Stats</u></b>\n" + interpersonStats, false);
	// End Interpersonal Stats
	
	// Begin Ongoing Stat Effects
	var statEffects:String = "";
	
	if (player.inHeat)
		statEffects += "Heat - " + Math.round(player.statusAffectv3(StatusAffects.Heat)) + " hours remaining\n";
		
	if (player.inRut)
		statEffects += "Rut - " + Math.round(player.statusAffectv3(StatusAffects.Rut)) + " hours remaining\n";
		
	if (player.statusAffectv1(StatusAffects.Luststick) > 0)
		statEffects += "Luststick - " + Math.round(player.statusAffectv1(StatusAffects.Luststick)) + " hours remaining\n";
		
	if (player.statusAffectv1(StatusAffects.LustStickApplied) > 0)
		statEffects += "Luststick Application - " + Math.round(player.statusAffectv1(StatusAffects.LustStickApplied)) + " hours remaining\n";
		
	if (player.statusAffectv1(StatusAffects.LustyTongue) > 0)
		statEffects += "Lusty Tongue - " + Math.round(player.statusAffectv1(StatusAffects.LustyTongue)) + " hours remaining\n";
		
	if (player.statusAffectv1(StatusAffects.BlackCatBeer) > 0)
		statEffects += "Black Cat Beer - " + player.statusAffectv1(StatusAffects.BlackCatBeer) + " hours remaining (Lust resistance 20% lower, physical resistance 25% higher.)\n";

	if (player.statusAffectv1(StatusAffects.AndysSmoke) > 0)
		statEffects += "Andy's Pipe Smoke - " + player.statusAffectv1(StatusAffects.AndysSmoke) + " hours remaining (Speed temporarily lowered, intelligence temporarily increased.)\n";
		
	if (player.statusAffectv1(StatusAffects.IzumisPipeSmoke) > 0) 
		statEffects += "Izumi's Pipe Smoke - " + player.statusAffectv1(StatusAffects.IzumisPipeSmoke) + " hours remaining. (Speed temporarily lowered.)\n";

	if (player.statusAffectv1(StatusAffects.UmasMassage) > 0) 
		statEffects += "Uma's Massage - " + player.statusAffectv3(StatusAffects.UmasMassage) + " hours remaining.\n";
		
	if (player.statusAffectv1(StatusAffects.Dysfunction) > 0) 
		statEffects += "Dysfunction - " + player.statusAffectv1(StatusAffects.Dysfunction) + " hours remaining. (Disables masturbation)\n";

	if (statEffects != "")
		outputText("\n<b><u>Ongoing Status Effects</u></b>\n" + statEffects, false);
	// End Ongoing Stat Effects
	menu();
	if (player.statPoints > 0) {
		outputText("\n\n<b>You have " + num2Text(player.statPoints) + " attribute point" + (player.statPoints == 1 ? "" : "s") + " to distribute.");
		addButton(1, "Stat Up", attributeMenu);
	}
	doNext(playerMenu);
}

public function openURL(url:String):void
{
    navigateToURL(new URLRequest(url), "_blank");
}

/**
 * Awards the achievement. Will display a blue text if achievement hasn't been earned.
 * @param	title The name of the achievement.
 * @param	achievement The achievement to be awarded.
 * @param	display Determines if achievement earned should be displayed.
 * @param	nl Inserts a new line before the achievement text.
 * @param	nl2 Inserts a new line after the achievement text.
 */
public function awardAchievement(title:String, achievement:*, display:Boolean = true, nl:Boolean = false, nl2:Boolean = true):void {
	if (achievements[achievement] != null) {
		if (achievements[achievement] <= 0) {
			achievements[achievement] = 1;
			if (nl && display) outputText("\n");
			if (display) outputText("<b><font color=\"#000080\">Achievement unlocked: " + title + "</font></b>");
			if (nl2 && display) outputText("\n");
			kGAMECLASS.saves.savePermObject(false); //Only save if the achievement hasn't been previously awarded.
		}
	}
	else outputText("\n<b>ERROR: Invalid achievement!</b>");
}

public function lustPercent():Number {
	var lust:Number = 100;
	var minLustCap:Number = 25;
	if (flags[kFLAGS.NEW_GAME_PLUS_LEVEL] > 0 && flags[kFLAGS.NEW_GAME_PLUS_LEVEL] < 3) minLustCap -= flags[kFLAGS.NEW_GAME_PLUS_LEVEL] * 5;
	else if (flags[kFLAGS.NEW_GAME_PLUS_LEVEL] >= 3) minLustCap -= 15;
	//2.5% lust resistance per level - max 75.
	if (player.level < 100) {
		if (player.level <= 11) lust -= (player.level - 1) * 3;
		else if (player.level > 11 && player.level <= 21) lust -= (30 + (player.level - 11) * 2);
		else if (player.level > 21 && player.level <= 31) lust -= (50 + (player.level - 21) * 1);
		else if (player.level > 31) lust -= (60 + (player.level - 31) * 0.2);
	}
	else lust = 25;
	
	//++++++++++++++++++++++++++++++++++++++++++++++++++
	//ADDITIVE REDUCTIONS
	//THESE ARE FLAT BONUSES WITH LITTLE TO NO DOWNSIDE
	//TOTAL IS LIMITED TO 75%!
	//++++++++++++++++++++++++++++++++++++++++++++++++++
	//Corrupted Libido reduces lust gain by 10%!
	if(player.findPerk(PerkLib.CorruptedLibido) >= 0) lust -= 10;
	//Acclimation reduces by 15%
	if(player.findPerk(PerkLib.Acclimation) >= 0) lust -= 15;
	//Purity blessing reduces lust gain
	if(player.findPerk(PerkLib.PurityBlessing) >= 0) lust -= 5;
	//Resistance = 10%
	if(player.findPerk(PerkLib.Resistance) >= 0) lust -= 10;
	if (player.findPerk(PerkLib.ChiReflowLust) >= 0) lust -= UmasShop.NEEDLEWORK_LUST_LUST_RESIST;
	
	if(lust < minLustCap) lust = minLustCap;
	if(player.statusAffectv1(StatusAffects.BlackCatBeer) > 0) {
		if(lust >= 80) lust = 100;
		else lust += 20;
	}
	lust += Math.round(player.perkv1(PerkLib.PentUp)/2);
	//++++++++++++++++++++++++++++++++++++++++++++++++++
	//MULTIPLICATIVE REDUCTIONS
	//THESE PERKS ALSO RAISE MINIMUM LUST OR HAVE OTHER
	//DRAWBACKS TO JUSTIFY IT.
	//++++++++++++++++++++++++++++++++++++++++++++++++++
	//Bimbo body slows lust gains!
	if((player.findStatusAffect(StatusAffects.BimboChampagne) >= 0 || player.findPerk(PerkLib.BimboBody) >= 0) && lust > 0) lust *= .75;
	if(player.findPerk(PerkLib.BroBody) >= 0 && lust > 0) lust *= .75;
	if(player.findPerk(PerkLib.FutaForm) >= 0 && lust > 0) lust *= .75;
	//Omnibus' Gift reduces lust gain by 15%
	if(player.findPerk(PerkLib.OmnibusGift) >= 0) lust *= .85;
	//Luststick reduces lust gain by 10% to match increased min lust
	if(player.findPerk(PerkLib.LuststickAdapted) >= 0) lust *= 0.9;
	if(player.findStatusAffect(StatusAffects.Berzerking) >= 0) lust *= .6;
	if (player.findPerk(PerkLib.PureAndLoving) >= 0) lust *= 0.95;
	
	//Items
	if (player.jewelryEffectId == JewelryLib.PURITY) lust *= 1 - (player.jewelryEffectMagnitude / 100);
	if (player.armor == armors.DBARMOR) lust *= 0.9;
	if (player.weapon == weapons.HNTCANE) lust *= 0.75;
	// Lust mods from Uma's content -- Given the short duration and the gem cost, I think them being multiplicative is justified.
	// Changing them to an additive bonus should be pretty simple (check the static values in UmasShop.as)
	var statIndex:int = player.findStatusAffect(StatusAffects.UmasMassage);
	if (statIndex >= 0)
	{
		if (player.statusAffect(statIndex).value1 == UmasShop.MASSAGE_RELIEF || player.statusAffect(statIndex).value1 == UmasShop.MASSAGE_LUST)
		{
			lust *= player.statusAffect(statIndex).value2;
		}
	}
	
	lust = Math.round(lust);
	return lust;
}

// returns OLD OP VAL
public function applyOperator(old:Number, op:String, val:Number):Number {
	switch(op) {
		case "=":
			return val;
		case "+":
			return old + val;
		case "-":
			return old - val;
		case "*":
			return old * val;
		case "/":
			return old / val;
		default:
			trace("applyOperator(" + old + ",'" + op + "'," + val + ") unknown op");
			return old;
	}
}

public function testDynStatsEvent():void {
	outputText("Old: "+player.str+" "+player.tou+" "+player.spe+" "+player.inte+" "+player.lib+" "+player.sens+" "+player.lust+"\n",true);
	dynStats("tou", 1, "spe+", 2, "int-", 3, "lib*", 2, "sen=", 25,"lust/",2);
	outputText("Mod: 0 1 +2 -3 *2 =25 /2\n");
	outputText("New: "+player.str+" "+player.tou+" "+player.spe+" "+player.inte+" "+player.lib+" "+player.sens+" "+player.lust+"\n");
	doNext(playerMenu);
}

/**
 * Modify stats.
 *
 * Arguments should come in pairs nameOp:String, value:Number/Boolean <br/>
 * where nameOp is ( stat_name + [operator] ) and value is operator argument<br/>
 * valid operators are "=" (set), "+", "-", "*", "/", add is default.<br/>
 * valid stat_names are "str", "tou", "spe", "int", "lib", "sen", "lus", "cor" or their full names; also "resisted"/"res" (apply lust resistance, default true) and "noBimbo"/"bim" (do not apply bimbo int gain reduction, default false)
 */
public function dynStats(... args):void
{
	// Check num of args, we should have a multiple of 2
	if ((args.length % 2) != 0)
	{
		trace("dynStats aborted. Keys->Arguments could not be matched");
		return;
	}
	
	var argNamesFull:Array 	= 	["strength", "toughness", "speed", "intellect", "libido", "sensitivity", "lust", "corruption", "resisted", "noBimbo"]; // In case somebody uses full arg names etc
	var argNamesShort:Array = 	["str", 	"tou", 	"spe", 	"int", 	"lib", 	"sen", 	"lus", 	"cor", 	"res", 	"bim"]; // Arg names
	var argVals:Array = 		[0, 		0,	 	0, 		0, 		0, 		0, 		0, 		0, 		true, 	false]; // Default arg values
	var argOps:Array = 			["+",	"+",    "+",    "+",    "+",    "+",    "+",    "+",    "=",    "="];   // Default operators
	
	for (var i:int = 0; i < args.length; i += 2)
	{
		if (typeof(args[i]) == "string")
		{
			// Make sure the next arg has the POSSIBILITY of being correct
			if ((typeof(args[i + 1]) != "number") && (typeof(args[i + 1]) != "boolean"))
			{
				trace("dynStats aborted. Next argument after argName is invalid! arg is type " + typeof(args[i + 1]));
				continue;
			}
			
			var argIndex:int = -1;
			
			// Figure out which array to search
			var argsi:String = (args[i] as String);
			if (argsi == "lust") argsi = "lus";
			if (argsi == "sens") argsi = "sen";
			if (argsi == "inte") argsi = "int";
			if (argsi.length <= 4) // Short
			{
				argIndex = argNamesShort.indexOf(argsi.slice(0, 3));
				if (argsi.length == 4 && argIndex != -1) argOps[argIndex] = argsi.charAt(3);
			}
			else // Full
			{
				if ("+-*/=".indexOf(argsi.charAt(argsi.length - 1)) != -1) {
					argIndex = argNamesFull.indexOf(argsi.slice(0, argsi.length - 1));
					if (argIndex != -1) argOps[argIndex] = argsi.charAt(argsi.length - 1);
				} else {
					argIndex = argNamesFull.indexOf(argsi);
				}
			}
			
			if (argIndex == -1) // Shit fucked up, welp
			{
				trace("Couldn't find the arg name " + argsi + " in the index arrays. Welp!");
				continue;
			}
			else // Stuff the value into our "values" array
			{
				argVals[argIndex] = args[i + 1];
			}
		}
		else
		{
			trace("dynStats aborted. Expected a key and got SHIT");
			return;
		}
	}
	// Got this far, we have values to statsify
	var newStr:Number = applyOperator(player.str, argOps[0], argVals[0]);
	var newTou:Number = applyOperator(player.tou, argOps[1], argVals[1]);
	var newSpe:Number = applyOperator(player.spe, argOps[2], argVals[2]);
	var newInte:Number = applyOperator(player.inte, argOps[3], argVals[3]);
	var newLib:Number = applyOperator(player.lib, argOps[4], argVals[4]);
	var newSens:Number = applyOperator(player.sens, argOps[5], argVals[5]);
	var newLust:Number = applyOperator(player.lust, argOps[6], argVals[6]);
	var newCor:Number = applyOperator(player.cor, argOps[7], argVals[7]);
	// Because lots of checks and mods are made in the stats(), calculate deltas and pass them. However, this means that the '=' operator could be resisted
	// In future (as I believe) stats() should be replaced with dynStats(), and checks and mods should be made here
	stats(newStr - player.str,
		  newTou - player.tou,
		  newSpe - player.spe,
		  newInte - player.inte,
		  newLib - player.lib,
		  newSens - player.sens,
		  newLust - player.lust,
		  newCor - player.cor,
		  argVals[8],argVals[9]);
	
}

public function stats(stre:Number, toug:Number, spee:Number, intel:Number, libi:Number, sens:Number, lust2:Number, corr:Number, resisted:Boolean = true, noBimbo:Boolean = false):void
{
	//Easy mode cuts lust gains!
	if (flags[kFLAGS.EASY_MODE_ENABLE_FLAG] == 1 && lust2 > 0 && resisted) lust2 /= 2;
	
	//Set original values to begin tracking for up/down values if
	//they aren't set yet.
	//These are reset when up/down arrows are hidden with 
	//hideUpDown();
	//Just check str because they are either all 0 or real values
	if(oldStats.oldStr == 0) {
		oldStats.oldStr = player.str;
		oldStats.oldTou = player.tou;
		oldStats.oldSpe = player.spe;
		oldStats.oldInte = player.inte;
		oldStats.oldLib = player.lib;
		oldStats.oldSens = player.sens;
		oldStats.oldCor = player.cor;
		oldStats.oldHP = player.HP;
		oldStats.oldLust = player.lust;
		oldStats.oldFatigue = player.fatigue;
		oldStats.oldHunger = player.hunger;
	}
	//MOD CHANGES FOR PERKS
	//Bimbos learn slower
	if(!noBimbo)
	{
		if(player.findPerk(PerkLib.FutaFaculties) >= 0 || player.findPerk(PerkLib.BimboBrains) >= 0  || player.findPerk(PerkLib.BroBrains) >= 0) {
			if(intel > 0) intel /= 2;
			if(intel < 0) intel *= 2;
		}
		if(player.findPerk(PerkLib.FutaForm) >= 0 || player.findPerk(PerkLib.BimboBody) >= 0  || player.findPerk(PerkLib.BroBody) >= 0) {
			if(libi > 0) libi *= 2;
			if(libi < 0) libi /= 2;
		}
	}
	
	// Uma's Perkshit
	if (player.findPerk(PerkLib.ChiReflowSpeed)>=0 && spee < 0) spee *= UmasShop.NEEDLEWORK_SPEED_SPEED_MULTI;
	if (player.findPerk(PerkLib.ChiReflowLust)>=0 && libi > 0) libi *= UmasShop.NEEDLEWORK_LUST_LIBSENSE_MULTI;
	if (player.findPerk(PerkLib.ChiReflowLust)>=0 && sens > 0) sens *= UmasShop.NEEDLEWORK_LUST_LIBSENSE_MULTI;
	
	//Apply lust changes in NG+.
	if (resisted) lust2 *= 1 + (player.newGamePlusMod() * 0.2);
	
	//lust resistance
	if(lust2 > 0 && resisted) lust2 *= lustPercent()/100;
	if(libi > 0 && player.findPerk(PerkLib.PurityBlessing) >= 0) libi *= 0.75;
	if(corr > 0 && player.findPerk(PerkLib.PurityBlessing) >= 0) corr *= 0.5;
	if(corr > 0 && player.findPerk(PerkLib.PureAndLoving) >= 0) corr *= 0.75;
	if (corr > 0 && player.weapon == weapons.HNTCANE) corr *= 0.5;
	if (player.findPerk(PerkLib.AscensionMoralShifter) >= 0) corr *= 1 + (player.perkv1(PerkLib.AscensionMoralShifter) * 0.2);
	//Change original stats
	player.str+=stre;
	player.tou+=toug;
	player.spe+=spee;
	player.inte+=intel;
	player.lib += libi;
	
	if(player.sens > 50 && sens > 0) sens/=2;
	if(player.sens > 75 && sens > 0) sens/=2;
	if(player.sens > 90 && sens > 0) sens/=2;
	if(player.sens > 50 && sens < 0) sens*=2;
	if(player.sens > 75 && sens < 0) sens*=2;
	if(player.sens > 90 && sens < 0) sens*=2;
	
	player.sens+=sens;
	player.lust+=lust2;
	player.cor += corr;
	
	//Bonus gain for perks!
	if(player.findPerk(PerkLib.Strong) >= 0 && stre >= 0) player.str+=stre*player.perk(player.findPerk(PerkLib.Strong)).value1;
	if(player.findPerk(PerkLib.Tough) >= 0 && toug >= 0) player.tou+=toug*player.perk(player.findPerk(PerkLib.Tough)).value1;
	if(player.findPerk(PerkLib.Fast) >= 0 && spee >= 0) player.spe+=spee*player.perk(player.findPerk(PerkLib.Fast)).value1;
	if(player.findPerk(PerkLib.Smart) >= 0 && intel >= 0) player.inte+=intel*player.perk(player.findPerk(PerkLib.Smart)).value1;
	if(player.findPerk(PerkLib.Lusty) >= 0 && libi >= 0) player.lib+=libi*player.perk(player.findPerk(PerkLib.Lusty)).value1;
	if (player.findPerk(PerkLib.Sensitive) >= 0 && sens >= 0) player.sens += sens * player.perk(player.findPerk(PerkLib.Sensitive)).value1;

	// Uma's Str Cap from Perks (Moved to max stats)
	/*if (player.findPerk(PerkLib.ChiReflowSpeed) >= 0)
	{
		if (player.str > UmasShop.NEEDLEWORK_SPEED_STRENGTH_CAP)
		{
			player.str = UmasShop.NEEDLEWORK_SPEED_STRENGTH_CAP;
		}
	}
	if (player.findPerk(PerkLib.ChiReflowDefense) >= 0)
	{
		if (player.spe > UmasShop.NEEDLEWORK_DEFENSE_SPEED_CAP)
		{
			player.spe = UmasShop.NEEDLEWORK_DEFENSE_SPEED_CAP;
		}
	}*/
	
	//Keep stats in bounds
	if(player.cor < 0) player.cor = 0;
	if(player.cor > 100) player.cor= 100;
	if(player.str > player.getMaxStats("str")) player.str = player.getMaxStats("str");
	if(player.str < 1) player.str = 1;
	if(player.tou > player.getMaxStats("tou")) player.tou = player.getMaxStats("tou");
	if(player.tou < 1) player.tou = 1;
	if(player.spe > player.getMaxStats("spe")) player.spe = player.getMaxStats("spe");
	if(player.spe < 1) player.spe = 1;
	if(player.inte > player.getMaxStats("inte")) player.inte = player.getMaxStats("inte");
	if(player.inte < 1) player.inte = 1;
	if(player.lib > player.getMaxStats("libi")) player.lib = player.getMaxStats("libi");
	if(player.lib < 0) player.lib = 0;
	//Minimum libido. Rewritten.
	var minLib:Number = 0;
	
	if (player.gender > 0) minLib = 15;
	else minLib = 10;
	
	if (player.armorName == "lusty maiden's armor") {
		if (minLib < 50)
		{
			minLib = 50;
		}
	}
	if (minLib < (minLust() * 2 / 3))
	{
		minLib = (minLust() * 2 / 3);
	}
	if (player.jewelryEffectId == JewelryLib.PURITY)
	{
		minLib -= player.jewelryEffectMagnitude;
	}
	if (player.findPerk(PerkLib.PurityBlessing) >= 0) {
		minLib -= 2;
	}
	if (player.findPerk(PerkLib.HistoryReligious) >= 0) {
		minLib -= 2;
	}
	//Applies minimum libido.
	if (player.lib < minLib)
	{
		player.lib = minLib;
	}
	
	//Minimum sensitivity.
	if(player.sens > 100) player.sens = 100;
	if(player.sens < 10) player.sens = 10;
	
	//Add HP for toughness change.
	if (player.tou < 20) HPChange(toug*2, false);
	else if (player.tou >= 20 && player.tou < 40) HPChange(toug*3, false);
	else if (player.tou >= 40 && player.tou < 60) HPChange(toug*4, false);
	else if (player.tou >= 60 && player.tou < 80) HPChange(toug*5, false);
	else (player.tou >= 80) HPChange(toug*6, false);
	//Reduce hp if over max
	if(player.HP > maxHP()) player.HP = maxHP();
	
	//Combat bounds
	if(player.lust > player.maxLust()) player.lust = player.maxLust();
	//if(player.lust < player.lib) {
	//        player.lust=player.lib;
	//
	//Update to minimum lust if lust falls below it.
	if(player.lust < minLust()) player.lust = minLust();
	//worms moved to minLust() in Player.as.
	if(player.lust > player.maxLust()) player.lust = player.maxLust();
	if(player.lust < 0) player.lust = 0;

	//Refresh the stat pane with updated values
	//mainView.statsView.showUpDown();
	showUpDown();
	statScreenRefresh();
}
	
public function showUpDown():void { //Moved from StatsView.
	function _oldStatNameFor(statName:String):String {
		return 'old' + statName.charAt(0).toUpperCase() + statName.substr(1);
	}

	var statName:String,
		oldStatName:String,
		allStats:Array;

	mainView.statsView.upDownsContainer.visible = true;

	allStats = ["str", "tou", "spe", "inte", "lib", "sens", "cor", "HP", "lust", "fatigue", "hunger"];

	for each(statName in allStats) {
		oldStatName = _oldStatNameFor(statName);

		if(player[statName] > oldStats[oldStatName]) {
			mainView.statsView.showStatUp(statName);
		}
		if(player[statName] < oldStats[oldStatName]) {
			mainView.statsView.showStatDown(statName);
		}
	}
}

public function range(min:Number, max:Number, round:Boolean = false):Number 
{
	var num:Number = (min + Math.random() * (max - min));

	if (round) return Math.round(num);
	return num;
}

public function cuntChangeOld(cIndex:Number, vIndex:Number, display:Boolean):void {
	//Virginity check
	if(player.vaginas[vIndex].virgin) {
		if(display) outputText("\nYour " + vaginaDescript(vIndex) + " loses its virginity!", false);
		player.vaginas[vIndex].virgin = false;
	}        
	//If cock is bigger than unmodified vagina can hold - 100% stretch!
	if(player.vaginas[vIndex].capacity() <= monster.cocks[cIndex].cArea()) {
		if(player.vaginas[vIndex] < 5) {
			trace("CUNT STRETCHED: By cock larger than it's total capacity.");
			if(display) {
				if(player.vaginas[vIndex].vaginalLooseness == VAGINA_LOOSENESS_GAPING_WIDE) outputText("<b>Your " + vaginaDescript(0) + " is stretched even further, capable of taking even the largest of demons and beasts.</b>  ", false);
				if(player.vaginas[vIndex].vaginalLooseness == VAGINA_LOOSENESS_GAPING) outputText("<b>Your " + vaginaDescript(0) + " painfully stretches, gaping wide-open.</b>  ", false);
				if(player.vaginas[vIndex].vaginalLooseness == VAGINA_LOOSENESS_LOOSE) outputText("<b>Your " + vaginaDescript(0) + " is now very loose.</b>  ", false);
				if(player.vaginas[vIndex].vaginalLooseness == VAGINA_LOOSENESS_NORMAL) outputText("<b>Your " + vaginaDescript(0) + " is now loose.</b>  ", false);
				if(player.vaginas[vIndex].vaginalLooseness == VAGINA_LOOSENESS_TIGHT) outputText("<b>Your " + vaginaDescript(0) + " loses its virgin-like tightness.</b>  ", false);
			}
			player.vaginas[vIndex].vaginalLooseness++;
		}
	}
	//If cock is within 75% of max, streeeeetch 33% of the time
	if(player.vaginas[vIndex].capacity() * .75 <= monster.cocks[cIndex].cArea()) {
		if(player.vaginas[vIndex] < 5) {
			trace("CUNT STRETCHED: By cock @ 75% of capacity.");
			if(display) {
				if(player.vaginas[vIndex].vaginalLooseness == VAGINA_LOOSENESS_GAPING_WIDE) outputText("<b>Your " + vaginaDescript(0) + " is stretched even further, capable of taking even the largest of demons and beasts.</b>  ", false);
				if(player.vaginas[vIndex].vaginalLooseness == VAGINA_LOOSENESS_GAPING) outputText("<b>Your " + vaginaDescript(0) + " painfully stretches, gaping wide-open.</b>  ", false);
				if(player.vaginas[vIndex].vaginalLooseness == VAGINA_LOOSENESS_LOOSE) outputText("<b>Your " + vaginaDescript(0) + " is now very loose.</b>  ", false);
				if(player.vaginas[vIndex].vaginalLooseness == VAGINA_LOOSENESS_NORMAL) outputText("<b>Your " + vaginaDescript(0) + " is now loose.</b>  ", false);
				if(player.vaginas[vIndex].vaginalLooseness == VAGINA_LOOSENESS_TIGHT) outputText("<b>Your " + vaginaDescript(0) + " loses its virgin-like tightness.</b>  ", false);
			}
			player.vaginas[vIndex].vaginalLooseness++;
		}
	}
}

/**
 * Returns true if you're on SFW mode.
 */
public function doSFWloss():Boolean {
	clearOutput();
	if (flags[kFLAGS.SFW_MODE] > 0) {
		if (player.HP <= 0) outputText("You collapse from your injuries.");
		else outputText("You collapse from your overwhelming desires.");
		if (inCombat) cleanupAfterCombat();
		else doNext(camp.returnToCampUseOneHour)
		return true;
	}
	else return false;
}

public function doNothing():void {
	//This literally does nothing.
}

public function spriteSelect(choice:Number = 0):void {
	var type:int = flags[kFLAGS.SPRITE_STYLE]; //0 for new, 1 for old.
	if (flags[kFLAGS.SHOW_SPRITES_FLAG] == 0)
	{
		mainView.selectSprite(choice, type);
	}
	else
	{
		if (choice >= 0)
		{
			trace ("hiding sprite because flags");
			mainView.selectSprite(-1);
		}
	}
}
