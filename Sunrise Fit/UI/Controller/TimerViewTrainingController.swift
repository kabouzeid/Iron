//
//  TimerViewTrainingController.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 23.12.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

public class TimerViewTrainingController {
    var training: Training?

    init(training: Training? = nil) {
        self.training = training
    }
    
    func checkShowTimer(_ timerView: TimerView, animated: Bool) {
        if training?.start != nil {
            timerView.showTimer(animated: animated)
        } else {
            timerView.hideTimer(animated: animated)
        }
    }
}

extension TimerViewTrainingController: TimerViewDelegate {
    func elapsedTime(_ timerView: TimerView) -> TimeInterval {
        return -(training?.start?.timeIntervalSinceNow ?? 0.0)
    }
    
    func timerViewButtonPressed(_ timerView: TimerView) {
        if training?.start == nil {
            training?.start = Date()
        }
        checkShowTimer(timerView, animated: true)
    }
}
