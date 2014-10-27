package ddls.data.math;

import ddls.data.Constants;
import ddls.data.graph.Graph;
import ddls.data.graph.GraphEdge;
import ddls.data.graph.GraphNode;
import ddls.data.math.Point2D;

import flash.display.BitmapData;
import flash.display.Shape;
import flash.geom.Point;

class Potrace
{

	inline public static var MAX_INT:Int = 0x7FFFFFFF;
	
	public static var maxDistance:Float = 1;
	
	public static function buildShapes(bmpData:BitmapData
									  , debugBmp:BitmapData=null
									  , debugShape:Shape=null):Array<Array<Float>>
	{
		// OUTLINES STEP-LIKE SHAPES GENERATION
		var shapes:Array<Array<Float>> = new Array<Array<Float>>();
		var dictPixelsDone = new Map<String, Bool>();
		for (row in 1...bmpData.height - 1)
		{
			for (col in 0...bmpData.width - 1)
			{
				if (bmpData.getPixel(col, row) == 0xFFFFFF && bmpData.getPixel(col + 1, row) < 0xFFFFFF)
				{
					if (!dictPixelsDone[(col + 1) + "_" + row])
						shapes.push(buildShape(bmpData, row, col + 1, dictPixelsDone, debugBmp, debugShape));
				}
			}
		}
		
		return shapes;
	}
	
	public static function buildShape(bmpData:BitmapData, fromPixelRow:Int, fromPixelCol:Int, dictPixelsDone:Map<String, Bool>
									   , debugBmp:BitmapData=null, debugShape:Shape=null):Array<Float>
	{
		var path:Array<Float> = new Array<Float>();
		var newX:Float = fromPixelCol;
		var newY:Float = fromPixelRow;
		path.push(newX);
		path.push(newY);
		dictPixelsDone[newX + "_" + newY] = true;
		
		var curDir:Point = new Point(0, 1);
		var newDir:Point = new Point();
		var newPixelRow:Int;
		var newPixelCol:Int;
		var count:Int = -1;
		while (true)
		{
			if (debugBmp != null)
			{
				debugBmp.setPixel32(fromPixelCol, fromPixelRow, 0xFFFF0000);
			}
			
			// take the pixel at right
			newPixelRow = fromPixelRow + Std.int(curDir.x) + Std.int(curDir.y);
			newPixelCol = fromPixelCol + Std.int(curDir.x) - Std.int(curDir.y);
			// if the pixel is not white
			if (bmpData.getPixel(newPixelCol, newPixelRow) < 0xFFFFFF)
			{
				// turn the direction right
				newDir.x = -curDir.y;
				newDir.y = curDir.x;
			}
				// if the pixel is white
			else
			{
				// take the pixel straight
				newPixelRow = fromPixelRow + Std.int(curDir.y);
				newPixelCol = fromPixelCol + Std.int(curDir.x);
				// if the pixel is not white
				if (bmpData.getPixel(newPixelCol, newPixelRow) < 0xFFFFFF)
				{
					// the direction stays the same
					newDir.x = curDir.x;
					newDir.y = curDir.y;
				}
					// if the pixel is white
				else
				{
					// pixel stays the same
					newPixelRow = fromPixelRow;
					newPixelCol = fromPixelCol;
					// turn the direction left
					newDir.x = curDir.y;
					newDir.y = -curDir.x;
				}
			}
			newX = newX + curDir.x;
			newY = newY + curDir.y;
			
			if (newX == path[0] && newY == path[1])
			{
				break;
			}
			else
			{
				path.push(newX);
				path.push(newY);
				dictPixelsDone[newX + "_" + newY] = true;
				fromPixelRow = newPixelRow;
				fromPixelCol = newPixelCol;
				curDir.x = newDir.x;
				curDir.y = newDir.y;
			}
			
			count--;
			if (count == 0)
			{
				break;
			}
		}
		
		if (debugShape != null)
		{
			debugShape.graphics.lineStyle(0.5, 0x00FF00);
			debugShape.graphics.moveTo(path[0], path[1]);
			var i = 2;
			while (i < path.length) {
				debugShape.graphics.lineTo(path[i], path[i + 1]);
				i += 2;
			}
			debugShape.graphics.lineTo(path[0], path[1]);
		}
		
		return path;
	}
	
	public static function buildGraph(shape:Array<Float>):Graph
	{
		//TODO: check casts in this class
		var i:Int;
		var graph:Graph = new Graph();
		var node:GraphNode;
		var i = 0;
		while (i < shape.length)
		{
			node = graph.insertNode();
			node.data = new NodeData();
			(node.data).index = i;
			(node.data).point = new Point2D(shape[i], shape[i + 1]);
			i += 2;
		}
		
		var node1:GraphNode;
		var node2:GraphNode;
		var subNode:GraphNode;
		var distSqrd:Float;
		var sumDistSqrd:Float;
		var count:Int;
		var isValid:Bool;
		var edge:GraphEdge;
		var edgeData:EdgeData;
		node1 = graph.node;
		while (node1 != null)
		{
			node2 = node1.next != null ? node1.next : graph.node;
			while (node2 != node1)
			{
				isValid = true;
				subNode = node1.next != null ? node1.next : graph.node;
				count = 2;
				sumDistSqrd = 0;
				while (subNode != node2)
				{
					var subNodeData = subNode.data;
					distSqrd = Geom2D.distanceSquaredPointToSegment((subNode.data).point.x, (subNode.data).point.y
																		, (node1.data).point.x, (node1.data).point.y
																		, (node2.data).point.x, (node2.data).point.y);
					if (distSqrd < 0)
						distSqrd= 0;
					if (distSqrd >= maxDistance)
					{
						//subNode not valid
						isValid = false;
						break;
					}
					
					count++;
					sumDistSqrd += distSqrd;
					subNode = subNode.next != null ? subNode.next : graph.node;
				}
				
				if (!isValid)
				{
					//segment not valid
					break;
				}
				
				edge = graph.insertEdge(node1, node2);
				edgeData = new EdgeData();
				edgeData.sumDistancesSquared = sumDistSqrd;
				edgeData.length = (node1.data).point.distanceTo((node2.data).point);
				edgeData.nodesCount = count;
				edge.data = edgeData;
				
				node2 = node2.next != null ? node2.next : graph.node;
			}
			
			node1 = node1.next;
		}
		
		return graph;
	}
	
	public static function buildPolygon(graph:Graph, debugShape:Shape=null):Array<Float>
	{
		var polygon:Array<Float> = new Array<Float>();
		
		var currNode:GraphNode;
		var minNodeIndex:Int = MAX_INT;
		var edge:GraphEdge;
		var score:Float;
		var higherScore:Float;
		var lowerScoreEdge:GraphEdge = null;
		currNode = graph.node;
		while ((currNode.data).index < minNodeIndex)
		{
			minNodeIndex = (currNode.data).index;
			
			polygon.push((currNode.data).point.x);
			polygon.push((currNode.data).point.y);
			//TODO: check this min value
			higherScore = 0;
			edge = currNode.outgoingEdge;
			while (edge != null)
			{
				score = (edge.data).nodesCount - (edge.data).length*Math.sqrt((edge.data).sumDistancesSquared/((edge.data).nodesCount));
				if (score > higherScore)
				{
					higherScore = score;
					lowerScoreEdge = edge;
				}
				
				edge = edge.rotNextEdge;
			}
			
			currNode = lowerScoreEdge.destinationNode;
		}
		
		if (Geom2D.getDirection(polygon[polygon.length-2], polygon[polygon.length-1], polygon[0], polygon[1], polygon[2], polygon[3]) == 0)
		{
			polygon.shift();
			polygon.shift();
		}
		
		if (debugShape != null)
		{
			debugShape.graphics.lineStyle(0.5, 0x0000FF);
			debugShape.graphics.moveTo(polygon[0], polygon[1]);
			var i = 2;
			while (i < polygon.length) {
				debugShape.graphics.lineTo(polygon[i], polygon[i + 1]);
				i += 2;
			}
			debugShape.graphics.lineTo(polygon[0], polygon[1]);
		}
		
		return polygon;
	}

}


class EdgeData
{
	public var sumDistancesSquared:Float;
	public var length:Float;
	public var nodesCount:Int;
	
	public function new()
	{
		
	}
}

class NodeData
{
	public var index:Int;
	public var point:Point2D;
	
	public function new()
	{
		
	}
}