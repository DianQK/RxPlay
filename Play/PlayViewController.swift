//
//  PlayViewController.swift
//  IntroRxSwift
//
//  Created by 宋宋 on 7/26/16.
//  Copyright © 2016 T. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

enum SpiritState {
    case appear
    case running
    case disappear
}

let Grid = CGPoint(x: 13, y: 7)

let imgs = [1, 2, 3].map { "pet\($0)" }.flatMap { UIImage(named: $0) }

class PlayViewController: UIViewController {

    @IBOutlet private weak var gridView: UIView!
    @IBOutlet private weak var autoRunButton: UIButton!
    @IBOutlet private weak var oneStepButton: UIButton!
    
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        let steps: [CGPoint] = [
            CGPoint(x: 1,y: 0), CGPoint(x: 1,y: 0),
            CGPoint(x: 1,y: 0), CGPoint(x: 0,y: 1),
            CGPoint(x: 0,y: 1), CGPoint(x: 0,y: 1),
            CGPoint(x: 1,y: 0), CGPoint(x: 1,y: 0),
            CGPoint(x: 1,y: 0), CGPoint(x: 1,y: 0),
            CGPoint(x: 0,y: -1), CGPoint(x: 0,y: -1),
            CGPoint(x: 1,y: 0), CGPoint(x: 1,y: 0),
            CGPoint(x: 1,y: 0)
        ]
        
        let updateXYConstraints: (view: UIView, location: CGPoint) -> Void = { [unowned self] view, location in
            let width = self.gridView.frame.size.width / Grid.x
            let height = self.gridView.frame.size.height / Grid.y
            let x = location.x * width
            let y = location.y * height
            view.frame = CGRect(x: x, y: y, width: width, height: height)
        }
        
        let startPoint = CGPoint(x: 1, y: 2)
        
        let spiritCount = steps.count + 1
        (0..<spiritCount)
            .map { i -> UIImageView in
                let spiritView = UIImageView()
                spiritView.tag = i
                spiritView.animationImages = imgs
                spiritView.animationDuration = 1
                spiritView.alpha = 0
                return spiritView
            }
            .forEach { [unowned self] (spiritView) in
                self.gridView.addSubview(spiritView)
                updateXYConstraints(view: spiritView, location: startPoint)
            }
        
        typealias Info = (index: Int, state: SpiritState, offset: CGPoint)

        autoRunButton.rx_tap
            .flatMapLatest {
                Observable<Int>.interval(1, scheduler: MainScheduler.instance)
            }
            .map { step -> Observable<(index: Int, step: Int)> in
                return (0...step)
                    .flatMap { currentStep -> (index: Int, step: Int)? in
                        if currentStep > steps.count {
                            return nil
                        }
                        let index = step - currentStep
                        if index > steps.count {
                            return nil
                        }
                        let info = (index: index, step: currentStep)
                        return info
                    }
                    .toObservable()
            }
            .merge()
            .map { index, step -> Info in
                if step == 0 {
                    return Info(index: index, state: SpiritState.appear, offset: startPoint)
                }
                if step < steps.count - 1 {
                    return Info(index: index, state: SpiritState.running, offset: steps[step - 1])
                }
                return Info(index: index, state: SpiritState.disappear, offset: steps[step - 1])
            }
            .scan(Info(index: 0, state: SpiritState.appear, offset: startPoint)) { acc, x -> Info in
                switch x.state {
                case .appear:
                    return Info(index: x.index, state: SpiritState.appear, offset: startPoint)
                default:
                    return Info(index: x.index, state: x.state, offset: CGPoint(x: acc.offset.x + x.offset.x, y: acc.offset.y + x.offset.y))
                }
            }
            .subscribeNext { info in
                let spirit = self.gridView.viewWithTag(info.index) as! UIImageView
                switch info.state {
                case .appear:
                    updateXYConstraints(view: spirit, location: info.offset)
                    UIView.animateWithDuration(1) {
                        spirit.alpha = 1
                    }
                    spirit.startAnimating()
                case .running:
                    UIView.animateWithDuration(1) {
                        updateXYConstraints(view: spirit, location: info.offset)
                    }
                case .disappear:
                    UIImageView.animateWithDuration(1, animations: { 
                        spirit.alpha = 0
                        }, completion: { _ in
                            spirit.stopAnimating()
                    })
                }
            }
            .addDisposableTo(disposeBag)

    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

}
