package states.editors.content;

import objects.Note;
import shaders.RGBPalette;
import flixel.util.FlxDestroyUtil;

class MetaNote extends Note
{
	public static var noteTypeTexts:Map<Int, FlxText> = [];
	public var isEvent:Bool = false;
	public var songData:Array<Dynamic>;
	public var sustainSprite:FlxSprite;
	public var sustainSpriteEnd:FlxSprite;
	public var chartY:Float = 0;
	public var chartNoteData:Int = 0;

	public function new(time:Float, data:Int, songData:Array<Dynamic>)
	{
		super(time, data, null, false, true);
		this.songData = songData;
		this.strumTime = time;
		this.chartNoteData = data;
	}

	public function changeNoteData(v:Int)
	{
		this.chartNoteData = v;
		this.songData[1] = v;
		this.noteData = v % ChartingState.GRID_COLUMNS_PER_PLAYER;
		this.mustPress = (v < ChartingState.GRID_COLUMNS_PER_PLAYER);
		
		if(!PlayState.isPixelStage)
			loadNoteAnims();
		else
			loadPixelNoteAnims();

		if(Note.globalRgbShaders.contains(rgbShader.parent))
			rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(noteData));

		animation.play(Note.colArray[this.noteData % Note.colArray.length] + 'Scroll');
		updateHitbox();
		if(width > height)
			setGraphicSize(ChartingState.GRID_SIZE);
		else
			setGraphicSize(0, ChartingState.GRID_SIZE);
		updateHitbox();

		if(sustainSprite != null && sustainSpriteEnd != null)
			_loadSustainTexture();
	}

	public function setStrumTime(v:Float)
	{
		this.songData[0] = v;
		this.strumTime = v;
	}

	var _lastZoom:Float = -1;
	var _sustainHeight:Float = 0;

	public function setSustainLength(v:Float, stepCrochet:Float, zoom:Float = 1)
	{
		_lastZoom = zoom;
		v = Math.round(v / (stepCrochet / 2)) * (stepCrochet / 2);
		songData[2] = sustainLength = Math.max(Math.min(v, stepCrochet * 128), 0);

		if(sustainLength > 0)
		{
			if(sustainSprite == null)
			{
				sustainSprite = new FlxSprite();
				sustainSprite.scrollFactor.x = 0;
				sustainSpriteEnd = new FlxSprite();
				sustainSpriteEnd.scrollFactor.x = 0;
				_loadSustainTexture();
			}
			_sustainHeight = Math.max(ChartingState.GRID_SIZE / 4, (Math.round((v * ChartingState.GRID_SIZE + ChartingState.GRID_SIZE) / stepCrochet) * zoom) - ChartingState.GRID_SIZE / 2);
		}
	}

	function _loadSustainTexture()
	{
		if(sustainSprite == null || sustainSpriteEnd == null) return;

		var col:String = Note.colArray[chartNoteData % Note.colArray.length];
		if(PlayState.isPixelStage)
		{
			var colIdx:Int = chartNoteData % Note.colArray.length;
			sustainSprite.loadGraphic(Paths.image('pixelUI/NOTE_hold_assets'), true, 16, 16);
			sustainSprite.animation.add('hold', [colIdx + Note.colArray.length], 0);
			sustainSprite.animation.play('hold');

			sustainSpriteEnd.loadGraphic(Paths.image('pixelUI/NOTE_hold_assets'), true, 16, 16);
			sustainSpriteEnd.animation.add('holdend', [colIdx + Note.colArray.length * 2], 0);
			sustainSpriteEnd.animation.play('holdend');
		}
		else
		{
			sustainSprite.frames = Paths.getSparrowAtlas('noteSkins/NOTE_assets');
			sustainSprite.animation.addByPrefix('hold', col + ' hold piece', 24, true);
			sustainSprite.animation.play('hold');
			if(sustainSprite.animation.curAnim != null)
				sustainSprite.animation.curAnim.curFrame = 0;

			sustainSpriteEnd.frames = Paths.getSparrowAtlas('noteSkins/NOTE_assets');
			sustainSpriteEnd.animation.addByPrefix('holdend', col + ' hold end', 24, true);
			sustainSpriteEnd.animation.play('holdend');
			if(sustainSpriteEnd.animation.curAnim != null)
				sustainSpriteEnd.animation.curAnim.curFrame = 0;
		}

		if(Note.globalRgbShaders != null && rgbShader != null)
		{
			sustainSprite.shader = rgbShader.parent.shader;
			sustainSpriteEnd.shader = rgbShader.parent.shader;
		}
	}

	public var hasSustain(get, never):Bool;
	function get_hasSustain() return (!isEvent && sustainLength > 0);

	public function updateSustainToZoom(stepCrochet:Float, zoom:Float = 1)
	{
		if(_lastZoom == zoom) return;
		setSustainLength(sustainLength, stepCrochet, zoom);
	}

	public function updateSustainToStepCrochet(stepCrochet:Float)
	{
		if(_lastZoom < 0) return;
		setSustainLength(sustainLength, stepCrochet, _lastZoom);
	}
	
	var _noteTypeText:FlxText;
	public function findNoteTypeText(num:Int)
	{
		var txt:FlxText = null;
		if(num != 0)
		{
			if(!noteTypeTexts.exists(num))
			{
				txt = new FlxText(0, 0, ChartingState.GRID_SIZE, (num > 0) ? Std.string(num) : '?', 16);
				txt.autoSize = false;
				txt.alignment = CENTER;
				txt.borderStyle = SHADOW;
				txt.shadowOffset.set(2, 2);
				txt.borderColor = FlxColor.BLACK;
				txt.scrollFactor.x = 0;
				noteTypeTexts.set(num, txt);
			}
			else txt = noteTypeTexts.get(num);
		}
		return (_noteTypeText = txt);
	}

	override function draw()
	{
		if(sustainSprite != null && sustainSpriteEnd != null && sustainSprite.exists && sustainSprite.visible && sustainLength > 0)
		{
			var sx:Float = this.x + this.width / 2;
			var sy:Float = this.y + this.height / 2;
			var targetW:Int = Std.int(ChartingState.GRID_SIZE * 0.4);

			sustainSpriteEnd.alpha = this.alpha;
			if(sustainSpriteEnd.animation.curAnim != null)
				sustainSpriteEnd.animation.curAnim.curFrame = 0;
			sustainSpriteEnd.setGraphicSize(targetW, 0);
			sustainSpriteEnd.updateHitbox();

			var realEndH:Float = sustainSpriteEnd.height;
			var bodyH:Float = Math.max(0, _sustainHeight - realEndH);

			sustainSprite.alpha = this.alpha;
			if(sustainSprite.animation.curAnim != null)
				sustainSprite.animation.curAnim.curFrame = 0;

			sustainSprite.setGraphicSize(targetW, Std.int(bodyH + 1));
			sustainSprite.updateHitbox();
			sustainSprite.x = sx - sustainSprite.width / 2;
			sustainSprite.y = sy;
			sustainSprite.draw();

			sustainSpriteEnd.x = sx - sustainSpriteEnd.width / 2;
			sustainSpriteEnd.y = sy + bodyH;
			sustainSpriteEnd.draw();
		}
		super.draw();

		if(_noteTypeText != null && _noteTypeText.exists && _noteTypeText.visible)
		{
			_noteTypeText.x = this.x + this.width / 2 - _noteTypeText.width / 2;
			_noteTypeText.y = this.y + this.height / 2 - _noteTypeText.height / 2;
			_noteTypeText.alpha = this.alpha;
			_noteTypeText.draw();
		}
	}

	override function destroy()
	{
		sustainSprite = FlxDestroyUtil.destroy(sustainSprite);
		sustainSpriteEnd = FlxDestroyUtil.destroy(sustainSpriteEnd);
		super.destroy();
	}
}

class EventMetaNote extends MetaNote
{
	public var eventText:FlxText;
	public function new(time:Float, eventData:Dynamic)
	{
		super(time, -1, eventData);
		this.isEvent = true;
		events = eventData[1];
		
		loadGraphic(Paths.image('editors/eventIcon'));
		setGraphicSize(ChartingState.GRID_SIZE);
		updateHitbox();

		eventText = new FlxText(0, 0, 400, '', 12);
		eventText.setFormat(Paths.font('vcr.ttf'), 12, FlxColor.WHITE, RIGHT);
		eventText.scrollFactor.x = 0;
		updateEventText();
	}
	
	override function draw()
	{
		if(eventText != null && eventText.exists && eventText.visible)
		{
			eventText.y = this.y + this.height / 2 - eventText.height / 2;
			eventText.alpha = this.alpha;
			eventText.draw();
		}
		super.draw();
	}

	override function setSustainLength(v:Float, stepCrochet:Float, zoom:Float = 1) {}

	public var events:Array<Array<String>>;
	public function updateEventText()
	{
		var myTime:Float = Math.floor(this.strumTime);
		if(events.length == 1)
		{
			var event = events[0];
			eventText.text = 'Event: ${event[0]} ($myTime ms)\nValue 1: ${event[1]}\nValue 2: ${event[2]}';
		}
		else if(events.length > 1)
		{
			var eventNames:Array<String> = [for (event in events) event[0]];
			eventText.text = '${events.length} Events ($myTime ms):\n${eventNames.join(', ')}';
		}
		else eventText.text = 'ERROR FAILSAFE';
	}

	override function destroy()
	{
		eventText = FlxDestroyUtil.destroy(eventText);
		super.destroy();
	}
}