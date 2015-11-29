import Foundation
import SpriteKit

// MARK: - Public

/// Structure that acts as a high-level wrapper of Core Graphics' drawing APIs
public struct Shape {
    /// The color the lines of the shape should be stroked with
    public var strokeColor: SKColor
    /// The width of the shape's lines
    public var lineWidth: CGFloat
    /// The total size of the shape, in which all of its lines will fit
    public private(set) var size: CGSize
    /// The point at which the shape is first drawn at
    public private(set) var originPoint: CGPoint
    /// The current point that the shape is being drawn at
    public private(set) var currentPoint: CGPoint
    
    private var drawingOperations: [ShapeDrawingOperation]
    
    /// Create a new instance of Shape, it won't have a stroke color and a 1 line width
    public init() {
        self.strokeColor = SKColor.clearColor()
        self.lineWidth = 1
        self.size = CGSize()
        self.originPoint = CGPoint()
        self.currentPoint = CGPoint()
        self.drawingOperations = []
    }
    
    /// Move to a point in the shape (will set the `currentPoint` property)
    public mutating func moveToPoint(point: CGPoint) {
        self.currentPoint = point
    }
    
    /// Add a line from the current point to a target point
    public mutating func addLineToPoint(point: CGPoint) {
        self.appendDrawingOperation(.LineTo(point), isDrawing: true)
    }
    
    /// Add a line by moving a certain distance in the shape
    public mutating func addLineByMovingByX(deltaX: CGFloat, y deltaY: CGFloat) {
        self.appendDrawingOperation(.LineByMovingByX(deltaX, y: deltaY), isDrawing: true)
    }
    
    /// Add a rectangle with a certain size
    public mutating func addRectangleWithWidth(width: CGFloat, height: CGFloat) {
        self.appendDrawingOperation(.LineByMovingByX(0, y: height), isDrawing: true)
        self.appendDrawingOperation(.LineByMovingByX(width, y: 0), isDrawing: true)
        self.appendDrawingOperation(.LineByMovingByX(0, y: -height), isDrawing: true)
        self.appendDrawingOperation(.LineByMovingByX(-width, y: 0), isDrawing: true)
    }
    
    /// Add a square with a certain size
    public mutating func addSquareWithSize(size: CGFloat) {
        self.addRectangleWithWidth(size, height: size)
    }
    
    /// Close the shape, drawing a line to the origin point of the shape
    public mutating func close() {
        self.appendDrawingOperation(.Close, isDrawing: true)
    }
    
    /// Inset the shape, effectively adding padding on both sides in either dimension
    public mutating func insetByX(x: CGFloat, y: CGFloat) {
        self.drawingOperations.insert(.MoveTo(CGPoint(x: x, y: y)), atIndex: 0)
        self.originPoint = self.originPoint.pointOffsetByX(x, y: y)
        self.size.width += x * 2
        self.size.height += y * 2
    }
    
    /// Generate a CGImage representation of the shape, using the size of the shape itself
    public func toCGImage() -> CGImageRef? {
        return self.toCGImageWithSize(self.size)
    }
    
    /// Generate a CGImage representation of the shape with a certain size. The shape will be scaled to fit the size.
    public func toCGImageWithSize(size: CGSize) -> CGImageRef? {
        let xScale = size.width / self.size.width
        let yScale = size.height / self.size.height
        
        let context = CGContext.bitmapContextWithSize(size)
        CGContextMoveToPoint(context, 0, 0)
        
        for operation in self.drawingOperations {
            switch operation {
            case .MoveTo(let point):
                CGContextMoveToPoint(context, point.x * xScale, point.y * yScale)
            case .LineTo(let point):
                CGContextAddLineToPoint(context, point.x * xScale, point.y * yScale)
            case .LineByMovingByX(let x, let y):
                let targetPoint = CGContextGetPathCurrentPoint(context).pointOffsetByX(x * xScale, y: y * yScale)
                CGContextAddLineToPoint(context, targetPoint.x, targetPoint.y)
            case .Close:
                CGContextAddLineToPoint(context, self.originPoint.x * xScale, self.originPoint.y * yScale)
            }
        }
        
        CGContextSetStrokeColorWithColor(context, self.strokeColor.CGColor)
        CGContextSetLineWidth(context, self.lineWidth)
        CGContextStrokePath(context)
        
        return CGBitmapContextCreateImage(context)
    }
    
    private mutating func appendDrawingOperation(operation: ShapeDrawingOperation, isDrawing: Bool) {
        if isDrawing && self.drawingOperations.isEmpty {
            self.originPoint = self.currentPoint
        }
        
        let targetPoint = operation.targetPointWithOperationOriginPoint(self.currentPoint, shapeOriginPoint: self.originPoint)
        
        if isDrawing {
            if self.currentPoint.x > self.size.width {
                self.size.width = self.currentPoint.x
            }
            
            if self.currentPoint.y > self.size.height {
                self.size.height = self.currentPoint.y
            }
            
            if targetPoint.x > self.size.width {
                self.size.width = targetPoint.x
            }
            
            if targetPoint.y > self.size.height {
                self.size.height = targetPoint.y
            }
        }
        
        self.drawingOperations.append(operation)
        self.currentPoint = targetPoint
    }
}

// MARK: - Private

private enum ShapeDrawingOperation {
    case MoveTo(CGPoint)
    case LineTo(CGPoint)
    case LineByMovingByX(CGFloat, y: CGFloat)
    case Close
}

extension ShapeDrawingOperation {
    func targetPointWithOperationOriginPoint(operationOriginPoint: CGPoint, shapeOriginPoint: CGPoint) -> CGPoint {
        switch self {
        case .MoveTo(let point):
            return point
        case .LineTo(let point):
            return point
        case .LineByMovingByX(let x, let y):
            return operationOriginPoint.pointOffsetByX(x, y: y)
        case .Close:
            return shapeOriginPoint
        }
    }
}