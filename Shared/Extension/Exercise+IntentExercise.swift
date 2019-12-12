//
//  Exercise+IntentExercise.swift
//  IronIntents
//
//  Created by Karim Abou Zeid on 08.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import Intents
import WorkoutDataKit

extension Exercise {
    var intentExercise: IntentExercise {
        let intentExercise = IntentExercise(identifier: uuid.uuidString, display: title, pronunciationHint: makeVoiceCompatible(string: title))
        intentExercise.alternativeSpeakableMatches =
            alias.map { alias in
                INSpeakableString(vocabularyIdentifier: alias, spokenPhrase: alias, pronunciationHint: makeVoiceCompatible(string: alias))
            } +
            alias.map { alias in
                INSpeakableString(spokenPhrase: makeVoiceCompatible(string: alias))
            } +
            [ INSpeakableString(spokenPhrase: makeVoiceCompatible(string: title)) ]
        return intentExercise
    }
    
    private func makeVoiceCompatible(string: String) -> String {
        string.components(separatedBy: .init(charactersIn: ":()")).joined()
    }
}
