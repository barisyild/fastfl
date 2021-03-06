package openfl.display._internal;

import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.CanvasRenderer;
import openfl.display.TileContainer;
import openfl.display.Tilemap;
import openfl.display.Tileset;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
#if lime
// TODO: Avoid use of private APIs
import lime._internal.graphics.ImageCanvasUtil;
#end

@:access(lime.graphics.ImageBuffer)
@:access(openfl.display.BitmapData)
@:access(openfl.display.Tile)
@:access(openfl.display.TileContainer)
@:access(openfl.display.Tilemap)
@:access(openfl.display.Tileset)
@:access(openfl.geom.Matrix)
@:access(openfl.geom.Rectangle)
@SuppressWarnings("checkstyle:FieldDocComment")
class CanvasTilemap
{
	public static inline function render(tilemap:Tilemap, renderer:CanvasRenderer):Void
	{
		#if (js && html5)
		if (!tilemap.__renderable || tilemap.__group.__tiles.length == 0) return;

		var alpha = renderer.__getAlpha(tilemap.__worldAlpha);
		if (alpha <= 0) return;

		var context = renderer.context;

		renderer.__setBlendMode(tilemap.__worldBlendMode);
		renderer.__pushMaskObject(tilemap);

		var rect = Rectangle.__pool.get();
		rect.setTo(0, 0, tilemap.__width, tilemap.__height);
		renderer.__pushMaskRect(rect, tilemap.__renderTransform);

		if (!renderer.__allowSmoothing || !tilemap.smoothing)
		{
			context.imageSmoothingEnabled = false;
		}

		renderTileContainer(tilemap, tilemap.__group, renderer, tilemap.__renderTransform, tilemap.__tileset, (renderer.__allowSmoothing && tilemap.smoothing),
			tilemap.tileAlphaEnabled, alpha, tilemap.tileBlendModeEnabled, tilemap.__worldBlendMode, null, null, rect);

		if (!renderer.__allowSmoothing || !tilemap.smoothing)
		{
			context.imageSmoothingEnabled = true;
		}

		renderer.__popMaskRect();
		renderer.__popMaskObject(tilemap);

		Rectangle.__pool.release(rect);
		#end
	}

	@SuppressWarnings("checkstyle:Dynamic")
	private static function renderTileContainer(tilemap:Tilemap, group:TileContainer, renderer:CanvasRenderer, parentTransform:Matrix, defaultTileset:Tileset, smooth:Bool,
			alphaEnabled:Bool, worldAlpha:Float, blendModeEnabled:Bool, defaultBlendMode:BlendMode, cacheBitmapData:BitmapData, source:Dynamic,
			rect:Rectangle, containerX:Float = 0.0, containerY:Float = 0.0):Void
	{
		#if (js && html5)
		var context = renderer.context;
		var roundPixels = renderer.__roundPixels;

		var tileTransform = Matrix.__pool.get();

		var tiles = group.__tiles;
		var length = group.__length;

		var tile,
			tileset,
			alpha,
			visible,
			blendMode = null,
			id = 0,
			tileData,
			tileRect = null,
			bitmapData;

		var actualWidth, actualHeight, actualX, actualY;
		var tilemapWidth = tilemap.__width,
		tilemapHeight = tilemap.__height;

		for (i in 0...length)
		{
			tile = tiles[i];

			tileset = tile.tileset;

			if(tileset == null)
				tileset = defaultTileset;

			if(tile.__length == 0)
			{
				if (tileset == null) continue;

				id = tile.id;

				if (id == -1)
				{
					tileRect = tile.__rect;
					if (tileRect == null || tileRect.width <= 0 || tileRect.height <= 0) continue;
				}
				else
				{
					tileData = tileset.__data[id];
					if (tileData == null) continue;

					rect.setTo(tileData.x, tileData.y, tileData.width, tileData.height);
					tileRect = rect;
				}

				actualWidth = tileRect.width;
				actualHeight = tileRect.height;

				actualX = containerX + tile.x;
				actualY = containerY + tile.y;

				if(actualX + actualWidth < 0 || actualX > tilemapWidth || actualY + actualHeight < 0 || actualY > tilemapHeight)
				{
					continue;
				}
			}

			tileTransform.setTo(1, 0, 0, 1, -tile.originX, -tile.originY);
			tileTransform.concat(tile.matrix);
			tileTransform.concat(parentTransform);

			if (roundPixels)
			{
				tileTransform.tx = Math.round(tileTransform.tx);
				tileTransform.ty = Math.round(tileTransform.ty);
			}

			alpha = tile.alpha * worldAlpha;
			visible = tile.visible;
			if (!visible || alpha <= 0) continue;

			if (!alphaEnabled) alpha = 1;

			if (blendModeEnabled)
			{
				blendMode = (tile.__blendMode != null) ? tile.__blendMode : defaultBlendMode;
			}

			if (tile.__length > 0)
			{
				renderTileContainer(tilemap, cast tile, renderer, tileTransform, tileset, smooth, alphaEnabled, alpha, blendModeEnabled, blendMode, cacheBitmapData,
					source, rect, containerX + tile.x, containerY + tile.y);
			}
			else
			{
				bitmapData = tileset.__bitmapData;
				if (bitmapData == null) continue;

				if (bitmapData != cacheBitmapData)
				{
					if (bitmapData.image.buffer.__srcImage == null)
					{
						ImageCanvasUtil.convertToCanvas(bitmapData.image);
					}

					source = bitmapData.image.src;
					cacheBitmapData = bitmapData;
				}

				context.globalAlpha = alpha;

				if (blendModeEnabled)
				{
					renderer.__setBlendMode(blendMode);
				}

				renderer.setTransform(tileTransform, context);
				context.drawImage(source, tileRect.x, tileRect.y, tileRect.width, tileRect.height, 0, 0, tileRect.width, tileRect.height);
			}
		}

		Matrix.__pool.release(tileTransform);
		#end
	}
}
