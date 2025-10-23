package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import Section.SwagSection;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import openfl.utils.Assets;
import haxe.Json;
import haxe.format.JsonParser;

using StringTools;

typedef CharacterFile = {
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
}

typedef AnimArray = {
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

class Character extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var colorTween:FlxTween;
	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; //Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; //Character use "danceLeft" and "danceRight" instead of "idle"

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];

	//Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];
	public var alreadyLoaded:Bool = true; //Used by "Change Character" event

	public static var DEFAULT_CHARACTER:String = 'bf'; //In case a character is missing, it will use BF on its place
	
	public var canAutoAnim:Bool = true;
	public var canAutoIdle:Bool = true;

	// 3D
	public var modelView:ModelView;
	public var beganLoading:Bool = false;
	public var modelName:String = "";
	public var modelScale:Float = 1;
	public var model:ModelThing;
	public var initYaw:Float = 0;
	public var initPitch:Float = 0;
	public var initRoll:Float = 0;
	public var xOffset:Float = 0;
	public var yOffset:Float = 0;
	public var zOffset:Float = 0;
	public var ambient:Float = 1;
	public var specular:Float = 1;
	public var diffuse:Float = 1;
	public var animSpeed:Map<String, Float> = new Map<String, Float>();
	public var noLoopList:Array<String> = [];
	public var geoMap:Map<String, String> = new Map<String, String>();
	public var atf:Bool = false;
	public var light:Bool = false;
	public var jointsPerVertex:Int = 4;

	public function new(modelView:ModelView, x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(x, y);

		#if (haxe >= "4.0.0")
		animOffsets = new Map();
		#else
		animOffsets = new Map<String, Array<Dynamic>>();
		#end
		curCharacter = character;
		this.isPlayer = isPlayer;
		antialiasing = ClientPrefs.globalAntialiasing;

		var library:String = null;
		switch (curCharacter)
		{
			//case 'your character name in case you want to hardcode him instead':

			case 'bf':
				modelName = 'bf';
				modelScale = 1;
				animSpeed = ["default" => 1];
				noLoopList = ["idle", "singUP", "singLEFT", "singRIGHT", "singDOWN"];
				ambient = 0;
				specular = 0;
				diffuse = 1;
				initYaw = 65;
				zOffset = 150;
				geoMap = [
					"singUP" => "singUP",
					"singRIGHT" => "singRIGHT",
					"singDOWN" => "singDOWN",
					"idle" => "default",
					"idleEnd" => "default",
					"singLEFT" => "singUP"
				];
				atf = true;
			case 'gf':
				modelName = 'gf';
				modelScale = 1;
				animSpeed = ["default" => 1];
				noLoopList = ["danceLEFT", "danceRIGHT"];
				ambient = 0;
				specular = 0;
				diffuse = 1;
				xOffset = -100;
				yOffset = -20;
				atf = true;
			case 'senpai':
				modelName = 'senpai';
				modelScale = 1;
				animSpeed = ["default" => 1];
				noLoopList = ["idle", "singUP", "singLEFT", "singRIGHT", "singDOWN"];
				ambient = 0;
				specular = 0;
				diffuse = 1;
				initYaw = -65;
				zOffset = -150;
				yOffset = 70;
				geoMap = [
					"singUP" => "singUP",
					"singRIGHT" => "singRIGHT",
					"singDOWN" => "singDOWN",
					"singLEFT" => "singLEFT",
					"idle" => "default",
					"idleEnd" => "default"
				];
				antialias = false;
			case 'senpai-angry':
				modelName = 'senpai-angry';
				modelScale = 1;
				animSpeed = ["default" => 1];
				noLoopList = ["idle", "singUP", "singLEFT", "singRIGHT", "singDOWN"];
				ambient = 0;
				specular = 0;
				diffuse = 1;
				initYaw = -65;
				zOffset = -150;
				yOffset = 70;
				geoMap = [
					"singUP" => "singUP",
					"singRIGHT" => "singRIGHT",
					"singDOWN" => "singDOWN",
					"singLEFT" => "singLEFT",
					"idle" => "default",
					"idleEnd" => "default"
				];
				antialias = false;
			case 'hydra':
				modelName = 'hydra';
				modelScale = 1;
				animSpeed = ["default" => 1];
				noLoopList = ["idle", "singUP", "singLEFT", "singRIGHT", "singDOWN"];
				ambient = 0.5;
				specular = 0.5;
				diffuse = 1;
				initYaw = 0;
				xOffset = -150;
				yOffset = 120;
				atf = true;
				light = true;
				jointsPerVertex = 1;
			default:
				var characterPath:String = 'characters/' + curCharacter + '.json';
				#if MODS_ALLOWED
				var path:String = Paths.modFolders(characterPath);
				if (!FileSystem.exists(path)) {
					path = Paths.getPreloadPath(characterPath);
				}

				if (!FileSystem.exists(path))
				#else
				var path:String = Paths.getPreloadPath(characterPath);
				if (!Assets.exists(path))
				#end
				{
					path = Paths.getPreloadPath('characters/' + DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
				}

				#if MODS_ALLOWED
				var rawJson = File.getContent(path);
				#else
				var rawJson = Assets.getText(path);
				#end

				var json:CharacterFile = cast Json.parse(rawJson);
				if(Assets.exists(Paths.getPath('images/' + json.image + '.txt', TEXT))) {
					frames = Paths.getPackerAtlas(json.image);
				} else {
					frames = Paths.getSparrowAtlas(json.image);
				}
				imageFile = json.image;

				if(json.scale != 1) {
					jsonScale = json.scale;
					setGraphicSize(Std.int(width * jsonScale));
					updateHitbox();
				}

				positionArray = json.position;
				cameraPosition = json.camera_position;

				healthIcon = json.healthicon;
				singDuration = json.sing_duration;
				flipX = !!json.flip_x;
				if(json.no_antialiasing) {
					antialiasing = false;
					noAntialiasing = true;
				}

				if(json.healthbar_colors != null && json.healthbar_colors.length > 2)
					healthColorArray = json.healthbar_colors;

				antialiasing = !noAntialiasing;
				if(!ClientPrefs.globalAntialiasing) antialiasing = false;

				animationsArray = json.animations;
				if(animationsArray != null && animationsArray.length > 0) {
					for (anim in animationsArray) {
						var animAnim:String = '' + anim.anim;
						var animName:String = '' + anim.name;
						var animFps:Int = anim.fps;
						var animLoop:Bool = !!anim.loop; //Bruh
						var animIndices:Array<Int> = anim.indices;
						if(animIndices != null && animIndices.length > 0) {
							animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
						} else {
							animation.addByPrefix(animAnim, animName, animFps, animLoop);
						}

						if(anim.offsets != null && anim.offsets.length > 1) {
							addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
						}
					}
				} else {
					quickAnimAdd('idle', 'BF idle dance');
				}
				//trace('Loaded file to character ' + curCharacter);
		}

		this.modelView = modelView;
		model = new ModelThing(modelView, modelName, 'awd', animSpeed, noLoopList, modelScale, initYaw, initPitch, initRoll, xOffset, yOffset, zOffset, false,
			antialias, atf, ambient, specular, light, jointsPerVertex);

		originalFlipX = flipX;

		recalculateDanceIdle();
		dance();

		if (isPlayer)
		{
			flipX = !flipX;

			/*// Doesn't flip for BF, since his are already in the right place???
			if (!curCharacter.startsWith('bf'))
			{
				// var animArray
				if(animation.getByName('singLEFT') != null && animation.getByName('singRIGHT') != null)
				{
					var oldRight = animation.getByName('singRIGHT').frames;
					animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
					animation.getByName('singLEFT').frames = oldRight;
				}

				// IF THEY HAVE MISS ANIMATIONS??
				if (animation.getByName('singLEFTmiss') != null && animation.getByName('singRIGHTmiss') != null)
				{
					var oldMiss = animation.getByName('singRIGHTmiss').frames;
					animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
					animation.getByName('singLEFTmiss').frames = oldMiss;
				}
			}*/
		}
	}

	override function update(elapsed:Float)
	{
		if (model == null || !model.fullyLoaded)
			return;

		if (model != null && model.fullyLoaded && modelView != null)
		{
			model.update();
		}

		if(!debugMode && animation.curAnim != null)
		{
			if(heyTimer > 0)
			{
				heyTimer -= elapsed;
				if(heyTimer <= 0)
				{
					if(specialAnim && animation.curAnim.name == 'hey' || animation.curAnim.name == 'cheer')
					{
						specialAnim = false;
						dance();
					}
					heyTimer = 0;
				}
			} else if(specialAnim && animation.curAnim.finished)
			{
				specialAnim = false;
				dance();
			}

			if (!isPlayer)
			{
				if (animation.curAnim.name.startsWith('sing'))
				{
					holdTimer += elapsed;
				}

				if (holdTimer >= Conductor.stepCrochet * 0.001 * singDuration)
				{
					dance();
					holdTimer = 0;
				}
			}

			if(animation.curAnim.finished && animation.getByName(animation.curAnim.name + '-loop') != null)
			{
				playAnim(animation.curAnim.name + '-loop');
			}
		}
		super.update(elapsed);
	}

	public var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance()
	{
		if (!model.fullyLoaded)
			return;

		if (!debugMode || ignoreDebug)
		{
			switch (curCharacter)
			{
				case 'gf' | 'gf-car' | 'gf-christmas' | 'gf-pixel':
					if (!getCurAnim().startsWith('hair'))
					{
						danced = !danced;

						if (danced)
							playAnim('danceRIGHT', true);
						else
							playAnim('danceLEFT', true);
					}
				default:
					if (holdTimer == 0)
					{
						if (model == null)
						{
							trace("NO DANCE - NO MODEL");
							return;
						}
						if (!model.fullyLoaded)
						{
							trace("NO DANCE - NO FULLY LOAD");
							return;
						}
						if (!noLoopList.contains('idle'))
							return;
						playAnim('idle', true);
					}
			}
		}
		else if (holdTimer == 0)
		{
			if (model == null)
			{
				trace("NO DANCE - NO MODEL");
				return;
			}
			if (!model.fullyLoaded)
			{
				trace("NO DANCE - NO FULLY LOAD");
				return;
			}
			if (!noLoopList.contains('idle'))
				return;
			playAnim('idle', true);
		}
	}

	public function idleEnd(?ignoreDebug:Bool = false)
	{
		if (PlayState.instance.endingSong)
			return;

		if (!model.fullyLoaded)
			return;

		if ((!debugMode || ignoreDebug))
		{
			if (animExists(getCurAnim() + "End"))
				playAnim(getCurAnim() + "End", true, false);
			else if (animExists('idleEnd'))
				playAnim('idleEnd', true, false);
			else
				playAnim('idle', true);
		}
	}

	var curAtlasAnim:String;

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;
		animation.play(AnimName, Force, Reversed, Frame);

		if (!model.fullyLoaded)
			return;

		if (AnimName.endsWith('-alt') && !animExists(AnimName))
		{
			AnimName = AnimName.substring(0, AnimName.length - 4);
		}

		if (AnimName.contains('sing'))
			canAutoIdle = true;

		var geo:String = "";
		if (geoMap[AnimName] != null)
			geo = geoMap[AnimName];

		if (AnimName.endsWith('miss'))
		{
			if (!animExists(AnimName))
				AnimName = AnimName.substring(0, AnimName.length - 4);
			geo = "miss";
			model.modelMaterial.colorTransform.redMultiplier = 0.2;
			model.modelMaterial.colorTransform.greenMultiplier = 0.2;
			model.modelMaterial.colorTransform.blueMultiplier = 0.75;
		}
		else
		{
			model.modelMaterial.colorTransform.redMultiplier = 1;
			model.modelMaterial.colorTransform.greenMultiplier = 1;
			model.modelMaterial.colorTransform.blueMultiplier = 1;
		}

		if (model != null && model.fullyLoaded)
		{
			model.playAnim(AnimName, Force, Frame, geo);
		}

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName))
		{
			offset.set(daOffset[0], daOffset[1]);
		}
		else
			offset.set(0, 0);

		if (curCharacter.startsWith('gf'))
		{
			if (AnimName == 'singLEFT')
			{
				danced = true;
			}
			else if (AnimName == 'singRIGHT')
			{
				danced = false;
			}

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
			{
				danced = !danced;
			}
		}
	}

	public function getCurAnim()
	{
		if (model != null && model.fullyLoaded)
			return model.currentAnim;
		else
			return "";
	}

	public function animExists(anim:String)
	{
		if (model != null && model.fullyLoaded)
			return model.animationSetSkeleton.hasAnimation(anim);
		else
			return false;
	}

	public function recalculateDanceIdle() {
		danceIdle = (animation.getByName('danceLeft' + idleSuffix) != null && animation.getByName('danceRight' + idleSuffix) != null);
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		animation.addByPrefix(name, anim, 24, false);
	}

	override public function destroy()
	{
		if (model != null)
			model.destroy();
		model = null;
		modelView = null;
		if (animSpeed != null)
		{
			animSpeed.clear();
			animSpeed = null;
		}
		super.destroy();
	}
}
