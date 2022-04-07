//
//  ScheduleTableViewCell.swift
//  JSUFitness
//
//  Created by Chao Jiang on 3/22/22.
//

import UIKit
import Alamofire

class ScheduleTableViewCell: UITableViewCell {
    
    let titleLabel: UILabel = {
        let lb = UILabel()
        lb.font = .boldSystemFont(ofSize: 15)
        lb.textAlignment = .left
        lb.text = "Event title"
        return lb
    }()
    
    let timeStampLabel: UILabel = {
        let lb = UILabel()
        lb.font = .systemFont(ofSize: 12)
        lb.textAlignment = .right
        lb.text = "13:15"
        return lb
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLabelsLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
}


//MARK: - Set up auto layout
extension ScheduleTableViewCell {
    
    func setupLabelsLayout() {
        titleLabelLayoutSetup()
        timeStampLabelLayoutSetup()
    }
    
    func titleLabelLayoutSetup() {
        self.addSubview(titleLabel)
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            titleLabel.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.5),
            titleLabel.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.75)
        ])
    }
    
    func timeStampLabelLayoutSetup() {
        self.addSubview(timeStampLabel)
        timeStampLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            timeStampLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            timeStampLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            timeStampLabel.heightAnchor.constraint(equalTo: titleLabel.heightAnchor),
            timeStampLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8)
        ])
    }
}
