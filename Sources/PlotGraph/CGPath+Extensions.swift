//
//  CGPath+Extensions.swift
//  Graph
//
//  Created by Ulf Akerstedt-Inoue on 2019/06/17.
//  Copyright © 2019 hakkabon software. All rights reserved.
//

import UIKit

extension CGMutablePath {
    private func addRegularPolygon(sides: Int, in rect: CGRect) {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = rect.width / 2
        let theta = 2.0 * CGFloat.pi / CGFloat(sides)

        let path = CGMutablePath()
        let p = CGPoint(x: center.x, y: center.y - radius)
        path.move(to: p, transform: .identity)
        for k in 1 ..< sides {
            let x = radius * sin(CGFloat(k) * theta)
            let y = radius * cos(CGFloat(k) * theta)
            path.addLine(to: CGPoint(x: center.x+x, y: center.y-y))
        }
        path.closeSubpath()
        self.addPath( path )
    }
    func addTriangle(_ rect: CGRect, transform: CGAffineTransform = .identity) {
        addRegularPolygon(sides: 3, in: rect)
    }
    func addStar(_ rect: CGRect, transform: CGAffineTransform = .identity) {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let w = rect.width
        let r = w / 2
        let flip: CGFloat = -1.0 // Mac OS thing
        let theta = 2.0 * CGFloat.pi * (2.0 / 5.0) // 144 degrees
        
        let path = CGMutablePath()
        let p = CGPoint(x: center.x, y: r * flip + center.y)
        path.move(to: p, transform: .identity)
        for k in 1 ..< 5 {
            let x = r * sin(CGFloat(k) * theta)
            let y = r * cos(CGFloat(k) * theta)
            path.addLine(to: CGPoint(x: x + center.x, y: y * flip + center.y))
        }
        
        path.closeSubpath()
        self.addPath( path )
    }
    func addPrism(_ rect: CGRect, transform: CGAffineTransform = .identity) {
        addRegularPolygon(sides: 4, in: rect)
    }
    func addCross(_ rect: CGRect, transform: CGAffineTransform = .identity) {
        let p1 = CGPoint(x: rect.minX, y: rect.minY) // clockwise turn
        let p2 = CGPoint(x: rect.maxX, y: rect.minY)
        let p3 = CGPoint(x: rect.maxX, y: rect.maxY)
        let p4 = CGPoint(x: rect.minX, y: rect.maxY)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let path = CGMutablePath()
        path.move(to: p1, transform: .identity)
        path.addLine(to: center)
        path.addLine(to: p2)
        path.addLine(to: center)
        path.addLine(to: p3)
        path.addLine(to: center)
        path.addLine(to: p4)
        path.addLine(to: center)
        path.addLine(to: p1)
        path.closeSubpath()
        self.addPath( path )
    }
}
