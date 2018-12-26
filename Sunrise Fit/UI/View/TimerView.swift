//
//  TimerView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 22.12.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit

@IBDesignable class TimerView: UIView {
    var button: UIButton!
    var title: UILabel!
    var time: UILabel!
    
    var refreshFrequency = 1.0
    
    var durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    var delegate: TimerViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSubViews()
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 44)
    }
    
    private func initSubViews() {
        button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        
        title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        addSubview(title)

        time = UILabel()
        time.translatesAutoresizingMaskIntoConstraints = false
        addSubview(time)

        // constraints

        button.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        button.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true

        title.centerYAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerYAnchor).isActive = true
        title.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        self.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: title.trailingAnchor, constant: 16).isActive = true
        
        time.centerYAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerYAnchor).isActive = true
        time.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        self.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: time.trailingAnchor, constant: 16).isActive = true
        
        // style
        backgroundColor = tintColor
        button.setTitleColor(UIColor.white, for: .normal)
        
        title.textColor = UIColor.white
        title.textAlignment = .left
        
        time.textColor = UIColor.white
        time.font = time.font.monospacedDigitFont
        time.textAlignment = .right
        
        hideTimer(animated: false)

        // functionality
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        
        // default values
        button.setTitle("Start timer", for: .normal)
        title.text = "Elapsed time"
        time.text = durationFormatter.string(from: 0)
    }

    @objc private func buttonPressed() {
        delegate?.timerViewButtonPressed(self)
    }
    
    func showTimer(animated: Bool) {
        UIView.animate(withDuration: animated ? 0.3 : 0) {
            self.button.isHidden = true
            self.button.alpha = 0
            self.time.isHidden = false
            self.time.alpha = 1
            self.title.isHidden = false
            self.title.alpha = 1
        }
        startUpdateTimeLabel()
    }
    
    func hideTimer(animated: Bool) {
        UIView.animate(withDuration: animated ? 0.3 : 0) {
            self.button.isHidden = false
            self.button.alpha = 1
            self.time.isHidden = true
            self.time.alpha = 0
            self.title.isHidden = true
            self.title.alpha = 0
        }
        stopUpdateTimeLabel()
    }
    
    private var timer: Timer?
    
    private func startUpdateTimeLabel() {
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: refreshFrequency, repeats: true, block: { _ in
                if let elapsedTime = self.delegate?.elapsedTime(self) {
                    self.time.text = self.durationFormatter.string(from: elapsedTime)
                }
            })
        }
        timer?.fire()
    }
    
    private func stopUpdateTimeLabel() {
        timer?.invalidate()
        timer = nil
    }
}

protocol TimerViewDelegate {
    func elapsedTime(_ timerView: TimerView) -> TimeInterval
    func timerViewButtonPressed(_ timerView: TimerView)
}
