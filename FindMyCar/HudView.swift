//
//  HudView.swift
//  FindMyCar
//
//  Created by Pei Qin on 4/8/17.
//  Copyright © 2017 Pei Qin. All rights reserved.
//

import UIKit

class HudView: UIView {
    var text = ""
    
    class func hud(inView view: UIView, animated: Bool) -> HudView {
        let hudView = HudView(frame: view.bounds)
        hudView.isOpaque = false
        view.addSubview(hudView)
        //view.isUserInteractionEnabled = false
        hudView.show(inView: view, animated: animated)
        return hudView
    }
    
    func show(inView view: UIView, animated: Bool) {
        if animated {
            alpha = 0
            transform = CGAffineTransform(scaleX: 1.3, y: 1.3)

            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.alpha = 1
                self.transform = CGAffineTransform.identity
            }, completion: { (finished) in
                UIView.animate(withDuration: 1, delay: 1, options: .curveEaseInOut, animations: {
                    self.alpha = 0
                }, completion: { (finished) in
                    //view.isUserInteractionEnabled = true
                    self.removeFromSuperview()
                })
            })
        }
    }

    override func draw(_ rect: CGRect) {
        let boxWidth: CGFloat = 96
        let boxHeight: CGFloat = 96
        
        let boxRect = CGRect(x: round((bounds.size.width - boxWidth) / 2), y: round((bounds.size.height - boxHeight) / 2), width: boxWidth, height: boxHeight)
        let roundedRect = UIBezierPath(roundedRect: boxRect, cornerRadius: 10)
        UIColor(white: 0.2, alpha: 0.8).setFill()
        roundedRect.fill()
        
        if let image = UIImage(named: "Checkmark") {
            let imagePoint = CGPoint(x: center.x - round(image.size.width / 2), y: center.y - round(image.size.height / 2) - boxHeight / 8)
            image.draw(at: imagePoint)
        }
        
        let attributes = [ NSFontAttributeName: UIFont.systemFont(ofSize: 16), NSForegroundColorAttributeName: UIColor.white ]
        let textSize = text.size(attributes: attributes)
        let textPoint = CGPoint(x: center.x - round(textSize.width / 2), y: center.y - round(textSize.height / 2) + boxHeight / 4)
        text.draw(at: textPoint, withAttributes: attributes)
    }
}
