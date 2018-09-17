//
//  AgniScene.swift
//  Agni
//
//  Created by Michael Ginn on 1/2/18.
//  Copyright © 2018 Michael Ginn. All rights reserved.
//

import UIKit
import SpriteKit

class AgniScene: SKScene {
    
    override init(size: CGSize) {
        super.init(size: size)
        
        self.backgroundColor = UIColor.white
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func didMove(to view: SKView) {
        // make scene's size == view's size
        scaleMode = .resizeFill
        

    }
    
}
