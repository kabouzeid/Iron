//
//  BalloonMarker.swift
//  ChartsDemo-Swift
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//
//  modified by Karim Abou Zeid (2018)
//

import Foundation
import Charts

class BalloonMarker: IMarker
{
    weak var chartView: ChartViewBase?
    var valueFormatter: BalloonValueFormatter?

    private var size: CGSize = CGSize()
    private var insets: UIEdgeInsets
    private var xySpacing: CGFloat = 0
    private var xLabel: String?
    private var yLabel: String?
    private var xLabelSize: CGSize = CGSize()
    private var yLabelSize: CGSize = CGSize()
    private var xDrawAttributes = [NSAttributedString.Key : AnyObject]()
    private var yDrawAttributes = [NSAttributedString.Key : AnyObject]()
    
    public init(chartView: ChartViewBase, valueFormatter: BalloonValueFormatter? = nil)
    {
        self.chartView = chartView
        self.valueFormatter = valueFormatter

        insets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        // attributes of the label
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
        paragraphStyle?.alignment = .center
        xDrawAttributes[.font] = UIFont.systemFont(ofSize: 12)
        xDrawAttributes[.paragraphStyle] = paragraphStyle
        xDrawAttributes[.foregroundColor] = UIColor.white.withAlphaComponent(1/3)
        yDrawAttributes[.font] = UIFont.boldSystemFont(ofSize: 14)
        yDrawAttributes[.paragraphStyle] = paragraphStyle
        yDrawAttributes[.foregroundColor] = UIColor.white // TODO: change to UIColor.black depending on chartView.tintColor
    }
    
    private func setLabels(xLabel: String?, yLabel: String?)
    {
        self.xLabel = xLabel
        self.yLabel = yLabel

        xLabelSize = xLabel?.size(withAttributes: xDrawAttributes) ?? CGSize.zero
        yLabelSize = yLabel?.size(withAttributes: yDrawAttributes) ?? CGSize.zero

        xySpacing = xLabelSize.width > 0 && yLabelSize.width > 0 ? 4 : 0

        var size = CGSize()
        size.width = xySpacing + xLabelSize.width + yLabelSize.width + self.insets.left + self.insets.right
        size.height = max(xLabelSize.height, yLabelSize.height) + self.insets.top + self.insets.bottom
        self.size = size
    }

    // MARK: - IMarker

    var offset: CGPoint = CGPoint()

    func offsetForDrawing(atPoint point: CGPoint) -> CGPoint
    {
        var offset = self.offset
        guard let chartView = chartView else { return offset }

        var origin = point
        origin.x -= size.width / 2

        if origin.x + offset.x - (chartView.layoutMargins.left - 8) < 0.0
        {
            offset.x = (chartView.layoutMargins.left - 8) - origin.x
        }
        else if origin.x + size.width + offset.x + (chartView.layoutMargins.right - 5) > chartView.bounds.size.width
        {
            offset.x = chartView.bounds.size.width - origin.x - size.width - (chartView.layoutMargins.right - 5) // corner radius = 5
        }

        offset.y = max(chartView.layoutMargins.top, offset.y - size.height)

        return offset
    }

    func draw(context: CGContext, point: CGPoint)
    {
        if xLabel == nil && yLabel == nil { return }
        guard let chartView = chartView else { return }

        let offset = self.offsetForDrawing(atPoint: point)
        let size = self.size

        var rect = CGRect(
            origin: CGPoint(
                x: point.x + offset.x,
                y: offset.y),
            size: size)
        rect.origin.x -= size.width / 2.0

        context.saveGState()

        context.setFillColor(chartView.tintColor.cgColor)
        context.addPath(UIBezierPath(roundedRect: rect, cornerRadius: 5.0).cgPath)
        context.fillPath()

        rect.origin.y += insets.top
        rect.origin.x += insets.left

        rect.size.height -= insets.top + insets.bottom
        let xLabelOriginY = rect.origin.y + (rect.size.height - xLabelSize.height) / 2
        let yLabelOriginY = rect.origin.y + (rect.size.height - yLabelSize.height) / 2

        UIGraphicsPushContext(context)

        rect.origin.y = xLabelOriginY
        rect.size.width = xLabelSize.width
        xLabel?.draw(in: rect, withAttributes: xDrawAttributes)

        rect.origin.y = yLabelOriginY
        rect.origin.x += xLabelSize.width + xySpacing
        rect.size.width = yLabelSize.width
        yLabel?.draw(in: rect, withAttributes: yDrawAttributes)

        UIGraphicsPopContext()

        context.restoreGState()
    }

    func refreshContent(entry: ChartDataEntry, highlight: Highlight)
    {
        if let valueFormatter = valueFormatter {
            setLabels(xLabel: valueFormatter.stringForXValue(x: entry.x), yLabel: valueFormatter.stringForYValue(y: entry.y))
        } else {
            setLabels(xLabel: "\(entry.x)", yLabel: "\(entry.y)")
        }
    }
}

protocol BalloonValueFormatter {
    func stringForXValue(x: Double) -> String?
    func stringForYValue(y: Double) -> String?
}
