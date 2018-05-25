//
//  ExerciseDetailViewController.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 24.01.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit

class ExerciseDetailViewController: UITableViewController {
    
    var exercise: Exercise? {
        didSet {
            updateSectionKeys()
            tableView?.reloadData()
            self.title = exercise?.title
        }
    }

    private enum SectionKey {
        case image
        case description
        case muscles
        case steps
        case tips
        case references
    }

    private var sectionKeys = [SectionKey]()

    private func updateSectionKeys() {
        sectionKeys.removeAll()
        if let exercise = exercise {
            if !exercise.png.isEmpty {
                sectionKeys.append(.image)
            }
            if !exercise.description.isEmpty {
                sectionKeys.append(.description)
            }
            if !(exercise.primaryMuscleCommonName.isEmpty && exercise.secondaryMuscleCommonName.isEmpty) {
                sectionKeys.append(.muscles)
            }
            if !exercise.steps.isEmpty {
                sectionKeys.append(.steps)
            }
            if !exercise.tips.isEmpty {
                sectionKeys.append(.tips)
            }
            if !exercise.references.isEmpty {
                sectionKeys.append(.references)
            }
        }
    }

    private var cachedImagesExerciseId = -1
    private var cachedImages = [UIImage]()

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        cachedImagesExerciseId = -1
        cachedImages.removeAll()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if sectionKeys[indexPath.section] == .image {
            return tableView.frame.width * (1/1.61) // golden ratio
        }
        return UITableViewAutomaticDimension
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionKeys.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let exercise = self.exercise! // should never be nil at this point
        switch sectionKeys[section] {
        case .image:
            return exercise.png.isEmpty ? 0 : 1
        case .description:
            return exercise.description.isEmpty ? 0 : 1
        case .muscles:
            return exercise.primaryMuscleCommonName.count + exercise.secondaryMuscleCommonName.count
        case .steps:
            return exercise.steps.count
        case .tips:
            return exercise.tips.count
        case .references:
            return exercise.references.count
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch sectionKeys[section] {
        case .muscles:
            return "Muscles"
        case .steps:
            return "Steps"
        case .tips:
            return "Tips"
        case .references:
            return "References"
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let exercise = self.exercise! // should never be nil at this point
        switch sectionKeys[indexPath.section] {
        case .image:
            let cell = tableView.dequeueReusableCell(withIdentifier: "image cell", for: indexPath) as! ExerciseImageTableViewCell

            if cachedImagesExerciseId != exercise.id {
                cachedImages.removeAll()
                for png in exercise.png {
                    let url = Bundle.main.bundleURL.appendingPathComponent("everkinetic-data").appendingPathComponent(png)
                    if let imageData = try? Data(contentsOf: url), let image = UIImage(data: imageData) {
                        cachedImages.append(image)
                    }
                }
                cachedImagesExerciseId = exercise.id
            }

            cell.exerciseImage.animationImages = cachedImages
            cell.exerciseImage.animationDuration = 2.5
            cell.exerciseImage.startAnimating()

            return cell
        case .description:
            let cell = tableView.dequeueReusableCell(withIdentifier: "text cell", for: indexPath)
            cell.textLabel?.text = exercise.description
            return cell
        case .muscles:
            let cell = tableView.dequeueReusableCell(withIdentifier: "muscle cell", for: indexPath)
            
            if exercise.primaryMuscleCommonName.count > indexPath.row {
                cell.textLabel?.text = "Primary"
                cell.detailTextLabel?.text = exercise.primaryMuscleCommonName[indexPath.row].capitalized
            } else {
                cell.textLabel?.text = "Secondary"
                cell.detailTextLabel?.text = exercise.secondaryMuscleCommonName[indexPath.row - exercise.primaryMuscleCommonName.count].capitalized
            }
            
            return cell
        case .steps:
            let cell = tableView.dequeueReusableCell(withIdentifier: "text cell", for: indexPath)
            cell.textLabel?.text = exercise.steps[indexPath.row]
            return cell
        case .tips:
            let cell = tableView.dequeueReusableCell(withIdentifier: "text cell", for: indexPath)
            cell.textLabel?.text = exercise.tips[indexPath.row]
            return cell
        case .references:
            let cell = tableView.dequeueReusableCell(withIdentifier: "link cell", for: indexPath)
            cell.textLabel?.text = exercise.references[indexPath.row]
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if sectionKeys[indexPath.section] == .references,
            let url = URL(string: exercise!.references[indexPath.row]) {
            UIApplication.shared.open(url)
            // somehow the cell doesn't get deselected automatically
            if let indexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
}
