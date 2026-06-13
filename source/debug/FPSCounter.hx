package debug;

import flixel.FlxG;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System;
import openfl.display.Shape;
import openfl.display.Sprite; 


class FPSCounter extends Sprite
{

  public var currentFPS(default, null):Int;

  public var memoryMegas(get, never):Float;

  public var textField:TextField; 

  @:noCompletion private var times:Array<Float>;
  public var fpsHistory:Array<Int> = [];
  public  var graph:Shape;
  private var graphWidth:Int = 120;
  private var graphHeight:Int = 40;

  public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
  {
    super();

    this.x = x;
    this.y = y;

    currentFPS = 0;

    textField = new TextField();
    textField.selectable = false;
    textField.mouseEnabled = false;
    textField.defaultTextFormat = new TextFormat("_sans", 14, color);
    textField.autoSize = LEFT;
    textField.multiline = true;
    textField.text = "FPS: ";
    addChild(textField);

    times = [];

    graph = new Shape();
    addChild(graph);
    graph.x = 0;
    graph.y = 40;
  }

  var deltaTimeout:Float = 0.0;

  private override function __enterFrame(deltaTime:Float):Void
  {
    final now:Float = haxe.Timer.stamp() * 1000;
    times.push(now);
    while (times[0] < now - 1000) times.shift();
    
    if (deltaTimeout < 50) {
      deltaTimeout += deltaTime;
      return;
    }

    currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;  

    if (backend.ClientPrefs.data != null && !backend.ClientPrefs.data.fpsGraph)
    {
      if (graph.visible) {
        graph.visible = false;
        fpsHistory = [];
        graph.graphics.clear();
      }
    }
    else 
    {
      if (!graph.visible) graph.visible = true;

      fpsHistory.push(currentFPS);
      if(fpsHistory.length > graphWidth)
        fpsHistory.shift();

      drawGraph();
    }

    updateText();
    deltaTimeout = 0.0;
  }

  public dynamic function updateText():Void { 
    if (backend.ClientPrefs.data != null && !backend.ClientPrefs.data.showFPS) {
        this.visible = false;
        return;
    }
    this.visible = true;
    textField.text = 'FPS: ${currentFPS}'
    + '\nMemory: ${flixel.util.FlxStringUtil.formatBytes(memoryMegas)}';

    textField.textColor = 0xFFFFFFFF;
    if (currentFPS < FlxG.drawFramerate * 0.5)
      textField.textColor = 0xFFFF0000;
  }

  private function drawGraph():Void
  {
    graph.graphics.clear();

    if(fpsHistory.length < 2)
      return;

    var col:Int = 0x00FF00;

    if(currentFPS < FlxG.drawFramerate * 0.8)
      col = 0xFFFF00;

    if(currentFPS < FlxG.drawFramerate * 0.5)
      col = 0xFF0000;

    graph.graphics.lineStyle(1.5, col);

    for(i in 0...fpsHistory.length)
    {
      var x = i;

      var y = graphHeight - (fpsHistory[i] / FlxG.drawFramerate) * graphHeight;

      if(y < 0)
        y = 0;

      if(i == 0)
        graph.graphics.moveTo(x, y);
      else
        graph.graphics.lineTo(x, y);
    }
  }

  inline function get_memoryMegas():Float
    return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
}