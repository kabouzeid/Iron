//
//  SummaryView.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 13.05.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit

@IBDesignable class SummaryView: UIView {
    private var stackView: UIStackView!
    var entries = [SummaryEntryView]()

    @IBInspectable var entryCount: Int = 3 {
        didSet {
            initEntries()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSubViews()
    }

    private func initSubViews() {
        stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = UIStackView.spacingUseSystem
        stackView.distribution = .fillEqually

        addSubview(stackView)

        // constraints
        stackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 8).isActive = true
        stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8).isActive = true
        self.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 8).isActive = true
        self.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 8).isActive = true

        initEntries()
    }

    private func initEntries() {
        // clean up
        for entry in entries {
            stackView.removeArrangedSubview(entry)
            entry.removeFromSuperview()
        }
        entries.removeAll()

        // create new items
        for _ in 0..<entryCount {
            let entry = SummaryEntryView()
            entries.append(entry)
            stackView.addArrangedSubview(entry)
        }
    }
}

class SummaryEntryView: UIView {
    var text: UILabel!
    var detail: UILabel!
    var title: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSubViews()
    }

    private func initSubViews() {
        let rootStackView = UIStackView()
        rootStackView.translatesAutoresizingMaskIntoConstraints = false
        rootStackView.axis = .vertical
        rootStackView.spacing = UIStackView.spacingUseSystem
        addSubview(rootStackView)
        // constraints
        rootStackView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        rootStackView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        rootStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        rootStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true

        let textStackView = UIStackView()
        textStackView.axis = .vertical
        textStackView.spacing = 0
        text = UILabel()
        text.textAlignment = .center
        text.font = UIFont.preferredFont(forTextStyle: .title2)
        text.textColor = UIColor.label
        
        detail = UILabel()
        detail.textAlignment = .center
        detail.font = UIFont.preferredFont(forTextStyle: .body)
        detail.textColor = UIColor.tertiaryLabel
        textStackView.addArrangedSubview(text)
        textStackView.addArrangedSubview(detail)

        title = UILabel()
        title.textAlignment = .center
        title.numberOfLines = 0
        title.font = UIFont.preferredFont(forTextStyle: .subheadline)
        title.textColor = UIColor.secondaryLabel

        rootStackView.addArrangedSubview(textStackView)
        rootStackView.addArrangedSubview(title)

        detail.isHidden = true
    }
}
