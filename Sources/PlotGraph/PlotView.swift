//
//  PlotView.swift
//  Graph
//
//  Created by Ulf Akerstedt-Inoue on 2019/05/18.
//  Copyright © 2019 hakkabon software. All rights reserved.
//

import UIKit

@available(iOS 8.2, *)
public class PlotView: UIView {

    /// Represent the x- and the y-axis values for each point in a chart series.
    typealias PlotPoint = (x: CGFloat, y: CGFloat)

    public struct Annotation {
        var title: String
        var y: String
        var x: String
        
        public init(title: String, y: String, x: String) {
            self.title = title
            self.y = y
            self.x = x
        }
    }
    
    public enum LineStyle {
        case none
        case solid
        // case dashed
        // case dotdash
        // case dashdot
    }

    /// Text used for annotating data on xy-axis.
    open var annotation: Annotation = Annotation(title: "", y: "", x: "") {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Font used for annotating data on xy-axis.
    open var annotationFont: UIFont = UIFont.italicSystemFont(ofSize: 14)
    
    /// Text color used for annotation on xy-axis.
    @IBInspectable var annotationTextColor: UIColor = UIColor.black
    
    /// Font used for the labels on each axis.
    open var axisFont: UIFont = UIFont.systemFont(ofSize: 12, weight: .regular)

    /// Color of the axes.
    @IBInspectable var axisColor: UIColor = UIColor.black
    
    /// Color of the grid.
    @IBInspectable var gridColor: UIColor = UIColor.gray.withAlphaComponent(0.3)

    /// Color of the grid.
    @IBInspectable var showGridLines: Bool = true
    
    /// Line thickness.
    @IBInspectable var lineWidth: CGFloat = 1

    /// Thickness of XY-axis.
    @IBInspectable var axisLineWidth: CGFloat = 1

    /// Size of data points relative thickness of graph line.
    @IBInspectable var pointScale: CGFloat = 1.5

    /// Margins to separate annotation and labels on axes.
    var insets: UIEdgeInsets = UIEdgeInsets(top: 60, left: 60, bottom: 60, right: 60)

    // Set lower bound of plot range[min, max].
    var min: PlotPoint? {
        didSet {
            plotObjects.forEach {
                if let min = min {
                    var xRange = $0.plotRange.x
                    var yRange = $0.plotRange.y
                    if min.x < $0.plotData.min.x {
                        xRange = PlotRange(min: min.x, max: $0.plotRange.x.max)
                    }
                    if min.y < $0.plotData.min.y {
                        yRange = PlotRange(min: min.y, max: $0.plotRange.y.max)
                    }
                    $0.plotRange = (x: xRange, y: yRange)
                }
            }
            setNeedsDisplay()
        }
    }

    // Set upper bound of plot range[min, max].
    var max: PlotPoint? {
        didSet {
            plotObjects.forEach {
                if let max = max {
                    var xRange = $0.plotRange.x
                    var yRange = $0.plotRange.y
                    if $0.plotData.max.x < max.x {
                        xRange = PlotRange(min: $0.plotRange.x.min, max: max.x)
                    }
                    if $0.plotData.max.y < max.y {
                        yRange = PlotRange(min: $0.plotRange.y.min, max: max.y)
                    }
                    $0.plotRange = (x: xRange, y: yRange)
                }
            }
            setNeedsDisplay()
        }
    }

    var plotObjects: [PlotObject] = [PlotObject]()
    var chartTransform: CGAffineTransform?
    
    lazy var titleAnnotation: UILabel = {
        let label = UILabel()
        label.font = annotationFont
        label.textColor = annotationTextColor
        return label
    }()
    
    lazy var xAnnotation: UILabel = {
        let label = UILabel()
        label.font = annotationFont
        label.textColor = annotationTextColor
        return label
    }()
    
    lazy var yAnnotation: UILabel = {
        let label = UILabel()
        label.font = annotationFont
        label.textColor = annotationTextColor
        return label
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    func initialize() {
        backgroundColor = UIColor.clear
        contentMode = .redraw // redraw rects on bounds change

        // Add subviews.
        addSubview( titleAnnotation )
        addSubview( xAnnotation )
        addSubview( yAnnotation )

        yAnnotation.transform = CGAffineTransform(rotationAngle: -.pi / 2)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()

        // This is problematic if several unrelated plot objects are plotted.
        for (i,plotObject) in plotObjects.enumerated() {
            if i == 0 { setTransform(for: plotObject) }
            plotObject.layers.point.frame = bounds
            plotObject.layers.line.frame = bounds
            plot(object: plotObject)
        }
        drawAnnotation()
    }

    /// Plot given data points on xy plane.
    ///
    /// - Parameters:
    ///   - points: The data points to plot.
    ///   - lineColor: The color of the line connecting data points.
    ///   - lineStyle: The style used for drawing lines.
    public func plot(data points: PlotData, lineColor: UIColor = .gray, lineStyle: LineStyle = .solid) {
        let plotObject = PlotObject(plotData: points, lineStyle: lineStyle, layers: (
            {
                let shapeLayer = CAShapeLayer()
                shapeLayer.lineWidth = pointScale
                shapeLayer.fillColor = lineColor.cgColor
                shapeLayer.strokeColor = lineColor.cgColor
                self.layer.addSublayer(shapeLayer)
                return shapeLayer
            }(),
            {
                let shapeLayer = CAShapeLayer()
                shapeLayer.fillColor = UIColor.clear.cgColor
                shapeLayer.strokeColor = lineColor.cgColor
                self.layer.addSublayer(shapeLayer)
                return shapeLayer
            }())
        )
        if self.chartTransform == nil { setTransform(for: plotObject) }
        self.plotObjects.append(plotObject)
        plot(object: plotObject)
    }
    
    /// Method for plotting data points and the lines connecting the data points.
    ///
    /// - Parameter plotObject: The object to be plotted.
    func plot(object plotObject: PlotObject) {
        if plotObject.plotData.pointStyle != .none {
            plotObject.layers.point.path = nil
            plotObject.layers.point.path = plot(points: plotObject.plotData.xy, style: plotObject.plotData.pointStyle, withTransform: chartTransform!)
        }
        if plotObject.lineStyle != .none {
            plotObject.layers.line.path = nil
            let linePath = CGMutablePath()
            linePath.addLines(between: plotObject.plotData.xy, transform: chartTransform!)
            plotObject.layers.line.path = linePath
        }
    }
    
    /// Method that creates geometric shapes of the data points that can be
    /// rendered in the plot.
    ///
    /// - Parameters:
    ///   - points: The data points to plot.
    ///   - style: The geometric shape of the data points.
    ///   - t: The affine transform applied to the graph.
    /// - Returns: The path object describing the shape of the data points.
    func plot(points: [CGPoint], style: PlotData.PointStyle, withTransform t: CGAffineTransform) -> CGPath {
        let path = CGMutablePath()
        let radius = lineWidth * pointScale
        for pt in points {
            let p = pt.applying(t)
            let rect = CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2)

            switch style {
            case .none: break
            case .cross: path.addCross(rect)
            case .circle: path.addEllipse(in: rect)
            case .prism: path.addPrism(rect)
            case .square: path.addRect(rect)
            case .star: path.addStar(rect)
            case .triangle: path.addTriangle(rect)
            }
        }
        return path
    }

    /// This method is going to construct the affine transform used for drawing the axes and all the points.
    ///
    /// - Parameter plotObject: The object to be plotted.
    func setTransform(for plotObject: PlotObject) {
        // Plot range
        let range = (x: plotObject.plotRange.x.range, y: plotObject.plotRange.y.range)
    
        // Calculate scale factor for xy-plane plot area.
        let width = self.bounds.width - insets.left - insets.right
        let height = self.bounds.height - insets.top - insets.bottom
        let scale = (x: width / range.x, y: height / range.y)

        // Retrieve min points.
        let minX = plotObject.plotRange.x.min
        let minY = plotObject.plotRange.y.min

        // Calculate dynamic margins depending on the font used and the actual spaced occupied by tick labels.
        let leftMargin = insets.left
        let topMargin = insets.top

        // Setup transform.
        chartTransform = CGAffineTransform(a: scale.x, b: 0, c: 0, d: -scale.y,
                                           tx: leftMargin - (minX / range.x) * width,
                                           ty: topMargin + height + (minY / range.y) * height)
    }
    
    override public func draw(_ rect: CGRect) {
        // Before drawing, check the preconditions first. We simply cannot draw the axes
        // if any of these are not met.
        guard
            let context = UIGraphicsGetCurrentContext(),
            let t = chartTransform,
            !plotObjects.isEmpty
        else { return }

        // let data = self.plotObjects[0].plotData
        let range = self.plotObjects[0].plotRange
        let labelAttributes: [NSAttributedString.Key : Any] = [.font: axisFont, .foregroundColor: axisColor]

        context.saveGState()
    
        // make two paths, one for thick lines, one for thin
        let axisLine = CGMutablePath()
        let tickLines = CGMutablePath()
        let gridLines = CGMutablePath()

        // x-axis line bottom, applied with transform.
        var p0 = CGPoint(x: range.x.min, y: range.y.min)
        var p1 = CGPoint(x: range.x.max, y: range.y.min)
        axisLine.addLines(between: [p0, p1], transform: t)
        // x-axis line top, applied with transform.
        p0 = CGPoint(x: range.x.min, y: range.y.max)
        p1 = CGPoint(x: range.x.max, y: range.y.max)
        axisLine.addLines(between: [p0, p1], transform: t)
        // y-axis line left, applied with transform.
        p0 = CGPoint(x: range.x.min, y: range.y.min)
        p1 = CGPoint(x: range.x.min, y: range.y.max)
        axisLine.addLines(between: [p0, p1], transform: t)
        // y-axis line right, applied with transform.
        p0 = CGPoint(x: range.x.max, y: range.y.min)
        p1 = CGPoint(x: range.x.max, y: range.y.max)
        axisLine.addLines(between: [p0, p1], transform: t)

        // x-axis ticks
        for x in stride(from: range.x.min, through: range.x.max, by: range.x.delta) {
            
            // Ticks on x-axis are drawn as either small ticks or full lines.
            let ticksBottom = [CGPoint(x: x, y: range.y.min).applying(t), CGPoint(x: x, y: range.y.min).applying(t).adding(y: -5)]
            let ticksTop = [CGPoint(x: x, y: range.y.max).applying(t), CGPoint(x: x, y: range.y.max).applying(t).adding(y: 5)]
            let gridLine = [CGPoint(x: x, y: range.y.min).applying(t), CGPoint(x: x, y: range.y.max).applying(t)]
            
            tickLines.addLines(between: ticksBottom)
            tickLines.addLines(between: ticksTop)
            gridLines.addLines(between: gridLine)

            if drawLabel(at: x) {
                let label = String(format: "%.1f", x)
                let labelSize = label.size(withSystemFontSize: axisFont.pointSize)
                let labelDrawPoint = CGPoint(x: x, y: range.y.min).applying(t)
                    .adding(x: -labelSize.width/2)
                    .adding(y: 5)
                
                label.draw(at: labelDrawPoint, withAttributes: labelAttributes)
            }
        }
    
        // y-axis ticks
        for y in stride(from: range.y.min, through: range.y.max, by: range.y.delta) {
            
            // Ticks on y-axis are drawn as either small ticks or full lines.
            let ticksLeft = [CGPoint(x: range.x.min, y: y).applying(t), CGPoint(x: range.x.min, y: y).applying(t).adding(x: 5)]
            let ticksRight = [CGPoint(x: range.x.max, y: y).applying(t), CGPoint(x: range.x.max, y: y).applying(t).adding(x: -5)]
            let gridLine = [CGPoint(x: range.x.min, y: y).applying(t), CGPoint(x: range.x.max, y: y).applying(t)]

            tickLines.addLines(between: ticksLeft)
            tickLines.addLines(between: ticksRight)
            gridLines.addLines(between: gridLine)

            if drawLabel(at: y) {
                let label = String(format: "%.1f", y)
                let labelSize = label.size(withSystemFontSize: axisFont.pointSize)
                let labelDrawPoint = CGPoint(x: range.x.min, y: y).applying(t)
                    .adding(x: -labelSize.width - 10)
                    .adding(y: -labelSize.height/2)
                
                label.draw(at: labelDrawPoint, withAttributes: labelAttributes)
            }
        }
    
        // Render axis lines and ticks
        context.setStrokeColor(axisColor.cgColor)
        context.setLineWidth(axisLineWidth)
        context.addPath(axisLine)
        context.strokePath()
    
        context.setStrokeColor(axisColor.cgColor)
        context.setLineWidth(axisLineWidth)
        context.addPath(tickLines)
        context.strokePath()

        if showGridLines {
            context.setStrokeColor(gridColor.cgColor)
            context.setLineWidth(axisLineWidth/2)
            context.addPath(gridLines)
            context.strokePath()
        }

        // graphics context you should save it prior and restore it
        // if we were using a context other than draw(rect) we would have to also end the graphics context
        context.restoreGState()
    }

    func drawAnnotation() {
        titleAnnotation.center = CGPoint(x: self.bounds.midX, y: annotationFont.pointSize)
        titleAnnotation.font = UIFont.italicSystemFont(ofSize: yAnnotation.font.pointSize + 4)
        titleAnnotation.text = annotation.title
        titleAnnotation.sizeToFit()

        yAnnotation.center = CGPoint(x: 0, y: self.bounds.midY)
        yAnnotation.text = annotation.y
        yAnnotation.sizeToFit()

        xAnnotation.center = CGPoint(x: self.bounds.midX, y: self.bounds.height - annotationFont.pointSize/2)
        xAnnotation.text = annotation.x
        xAnnotation.sizeToFit()
    }
    
    func drawLabel(at point: CGFloat) -> Bool {
        return true
    }
}

@available(iOS 8.2, *)
public class PlotObject {
    var plotData: PlotData
    var plotRange: (x: PlotRange, y: PlotRange)
    var lineStyle: PlotView.LineStyle
    var layers: (point: CAShapeLayer, line: CAShapeLayer)
    public init(plotData: PlotData, lineStyle: PlotView.LineStyle, layers: (point: CAShapeLayer, line: CAShapeLayer)) {
        self.plotData = plotData
        self.plotRange = (x: PlotRange(min: plotData.min.x, max: plotData.max.x), y: PlotRange(min: plotData.min.y, max: plotData.max.y))
        self.lineStyle = lineStyle
        self.layers = layers
    }
}

public class PlotLabel: UILabel {
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.font = UIFont.boldSystemFont(ofSize: 10.0)
        self.backgroundColor = UIColor.clear
        self.textAlignment = NSTextAlignment.center
    }
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder: NSCode) has not been implemented.")
    }
}

extension String {
    func size(withSystemFontSize pointSize: CGFloat) -> CGSize {
        return self.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: pointSize)])
    }
}

extension CGPoint {
    func adding(x: CGFloat) -> CGPoint { return CGPoint(x: self.x + x, y: self.y) }
    func adding(y: CGFloat) -> CGPoint { return CGPoint(x: self.x, y: self.y + y) }
}
