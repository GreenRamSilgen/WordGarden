//
//  ContentView.swift
//  WordGarden
//
//  Created by Kiran Shrestha on 1/12/26.
//

import SwiftUI
import AVFAudio

struct ContentView: View {
    private static let maximumGuesses = 8
    
    private let wordsToGuess = ["SWIFT", "CAT", "DOG"]
    
    @State private var wordsGuessed = 0
    @State private var wordsMissed = 0
    @State private var gameStatusMessage = "How Many Guesses to Uncover the Hidden Word?"
    @State private var currentWordIndex = 0
    @State private var wordToGuess = ""
    @State private var guessedLetter = ""
    @State private var lettersGuessed = ""
    @State private var guessesRemaining = Self.maximumGuesses
    @State private var imageName = "flower8"
    @State private var playAgainHidden = true
    @State private var playAgainButtonLabel = "Another Word?"
    @State private var revealedWord = ""
    @State private var audioPlayer : AVAudioPlayer!
    
    @FocusState private var isKeyboardFocused
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Words Guessed: \(wordsGuessed)")
                    Text("Words Missed: \(wordsMissed)")
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Words to Guess: \(wordsToGuess.count - (wordsGuessed + wordsMissed))")
                    Text("Words in Game: \(wordsToGuess.count)")
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            Text(gameStatusMessage)
                .multilineTextAlignment(.center)
                .font(.title)
                .minimumScaleFactor(0.5)
                .padding()
                .frame(height: 80)
            
            //TODO: - Switch to wordsToGuess[currentWord] -
            Text(revealedWord)
            
            if playAgainHidden {
                HStack {
                    TextField("", text: $guessedLetter)
                        .focused($isKeyboardFocused)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 30)
                        .overlay {
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(.gray, lineWidth: 2)
                        }
                        .keyboardType(.asciiCapable)
                        .submitLabel(.done)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                        .onChange(of: guessedLetter) {
                            guessedLetter = guessedLetter.trimmingCharacters(in: .letters.inverted)
                            guard let lastChar = guessedLetter.last else { return }
                            
                            guessedLetter = String(lastChar).uppercased()
                        }
                        .onSubmit {
                            guard guessedLetter != "" else { return }
                            guessALetter()
                            updateGameplay()
                        }
                    
                    Button("Guess A Letter") {
                        guard guessedLetter != "" else { return }
                        guessALetter()
                        updateGameplay()
                    }
                    .buttonStyle(.bordered)
                    .tint(.mint)
                    .disabled(guessedLetter.isEmpty)
                }
            }
            else {
                Button(playAgainButtonLabel) {
                    if currentWordIndex == wordsToGuess.count {
                        currentWordIndex = 0
                        wordsGuessed = 0
                        wordsMissed = 0
                        playAgainButtonLabel = "Another Word?"
                    }
                    
                    wordToGuess = wordsToGuess[currentWordIndex]
                    revealedWord = Array(repeating: "_", count: wordsToGuess[currentWordIndex].count).joined(separator: " ")
                    lettersGuessed = ""
                    guessesRemaining = Self.maximumGuesses
                    imageName = "flower\(guessesRemaining)"
                    gameStatusMessage = "How Many Guesses to Uncover the Hidden Word?"
                    playAgainHidden = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint)
                
            }
            
            Image(imageName)
                .resizable()
                .scaledToFit()
                .animation(.easeIn(duration: 0.75), value: imageName)
            Spacer()
        }
        .ignoresSafeArea(edges:.bottom)
        .onAppear {
            wordToGuess = wordsToGuess[currentWordIndex]
            // My way, using Array repeating.
            revealedWord = Array(repeating: "_", count: wordsToGuess[currentWordIndex].count).joined(separator: " ")
        }
    }
    
    func guessALetter() {
        isKeyboardFocused = false
        lettersGuessed += guessedLetter
        revealedWord = wordsToGuess[currentWordIndex].map { lettersGuessed.contains($0) ? "\($0)" : "_" }
            .joined(separator: " ")
    }
    
    func updateGameplay(){
        // Player guess a wrong LETTER
        if !wordToGuess.contains(guessedLetter) {
            guessesRemaining -= 1
            imageName = "wilt\(guessesRemaining)"
            playSound("incorrect")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                imageName = "flower\(guessesRemaining)"
            }
        }else {
            //TODO: - Fix issue where player guessing same letter over and over is allowed... -
            playSound("correct")
        }
        
        // Player guessed the WORD correctly
        if !revealedWord.contains("_") {
            gameStatusMessage = "You Guessed It! It Took You \(lettersGuessed.count) Guesses to Guess the Word."
            wordsGuessed += 1
            currentWordIndex += 1
            playAgainHidden = false
            playSound("word-guessed")
        }
        else if guessesRemaining == 0 { // MISSED WORD, OUT OF GUESSES
            gameStatusMessage = "So Sorry, You're All Out of Guesses"
            wordsMissed += 1
            currentWordIndex += 1
            playAgainHidden = false
            playSound("word-not-guessed")
        }
        else {
            //TODO: Redo this with LocalizedStringKey & Inflect
            gameStatusMessage = "You've Made \(lettersGuessed.count) Guess\(lettersGuessed.count == 1 ? "" : "es")"
        }
        
        if currentWordIndex == wordsToGuess.count {
            playAgainButtonLabel = "Restart Game?"
            gameStatusMessage = gameStatusMessage + "\nYou've Tried All the Words. Restart from the Beginning?"
        }
        guessedLetter = ""
    }
    
    func playSound(_ soundName : String){
        if audioPlayer != nil && audioPlayer.isPlaying {
            audioPlayer.stop()
        }
        guard let soundFile = NSDataAsset(name: soundName) else { return }
        do {
            audioPlayer = try AVAudioPlayer(data: soundFile.data)
            audioPlayer.play()
        } catch {
            fatalError()
        }
    }
}

#Preview {
    ContentView()
}
