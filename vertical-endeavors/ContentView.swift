//
//  ContentView.swift
//  vertical-endeavors
//
//  Created by   on 7/28/23.
//

import SwiftUI
import CoreData

enum PEG_STATE {
    case empty, hovered, selected, player_played, opponent_played
}
enum BUTTON_STATE {
    case pressed, not_pressed
}
enum SIDE {
    case left, right, none
}

struct Peg {
    var pegState: PEG_STATE = .empty
    var side: SIDE = .none
}

let SHAKE_TIME: Double = 2

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    @State private var message = ""
    @State private var grid: [[Peg]] = Array(repeating: Array(repeating: Peg(), count: 7), count: 7)
    @State private var leftButtons: [BUTTON_STATE] = Array(repeating: .not_pressed, count: 7)
    @State private var rightButtons: [BUTTON_STATE] = Array(repeating: .not_pressed, count: 7)
    @State private var isPlayerTurn: Bool = true
    @State private var sendButtonIsPressed: Bool = false
    @State private var LButtonIsPressed: Bool = false
    @State private var RButtonIsPressed: Bool = false
    @State private var playMoveButtonIsPressed: Bool = false
    @State private var isLeftBoardShaking: Bool = false
    @State private var isRightBoardShaking: Bool = false
    
    /*
     DONE: 4) Add peg change animation
     DONE: 5) Add shake function logic
     DONE: 6) Add shadow animation to buttons: L, R, SendMsg, and PlayMove
     DONE: 7) Add shaking animation to game board
     TODO: 8) Add a player waiting animation to VE (with randomness AI???)
     
     TODO: IDEA) krazy kooky AI (aka randomness AI but it can play 2-4 moves a turn)
     TODO: IDEA) strategic AI who tries to block the longest opponent path
     TODO: IDEA) all of this game logic could sure use graph construction to its benefits
     */
    
    var body: some View {
        VStack {
            Spacer()
            
            /// Game Area Code
            HStack(spacing: 0) {
                /// Left Side Buttons
                VStack(spacing: 0) {
                    ForEach(leftButtons.indices, id: \.self) { index in
                        Button(action: {
                            leftButtons[index] = .pressed
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                leftButtons[index] = .not_pressed
                            }
                            
                            addToRow(rowIndex: index, side: .left)
                        }){
                            CircleButtonView(buttonState: $leftButtons[index])
                        }.buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.leading, 2)
                
                /// Main Grid
                VStack(spacing: 0) {
                    ForEach(grid.indices, id: \.self) { index in
                        PegRow(pegStateArray: $grid[index], isLShaking: $isLeftBoardShaking, isRShaking: $isRightBoardShaking)
                    }
                }
                .padding(.vertical, 4)
                .padding(.leading, isLeftBoardShaking ? 0 : 2)
                .padding(.trailing, isRightBoardShaking ? 0 : 2)
                .background(
                    Rectangle()
                        .foregroundColor(Color(red: 1.0, green: 216/255, blue: 168/255))
                        .cornerRadius(10)
                )
                .edgesIgnoringSafeArea(.all)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black, lineWidth: 2)
                )
                .padding(.leading, isLeftBoardShaking ? 3 : 2)
                .padding(.trailing, isRightBoardShaking ? 3 : 2)
                .animation(Animation.linear(duration: 0.03), value: isLeftBoardShaking)
                .animation(Animation.linear(duration: 0.03), value: isRightBoardShaking)
                
                
                /// Right Side Buttons
                VStack(spacing: 0) {
                    ForEach(rightButtons.indices, id: \.self) { index in
                        Button(action: {
                            rightButtons[index] = .pressed
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                rightButtons[index] = .not_pressed
                            }
                            
                            addToRow(rowIndex: index, side: .right)
                        }){
                            CircleButtonView(buttonState: $rightButtons[index])
                        }.buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.trailing, 2)
            }
            
            /// Play Move Button
            Button(action: {
                playMoveButtonIsPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    playMoveButtonIsPressed = false
                }
                
                pressPlay()
            }) {
                Text("Play Move!")
                    .foregroundColor(.black)
                    .font(.largeTitle)
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.shadow(.inner(color: playMoveButtonIsPressed ? .white : .black, radius: 2, x: -1, y: -1)))
                    .foregroundColor(Color(red: playMoveButtonIsPressed ? 140/255 : 165/255, green: playMoveButtonIsPressed ? 191/255 : 216/255, blue: playMoveButtonIsPressed ? 230/255 : 1.0))
            )
            .edgesIgnoringSafeArea(.all)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(red: 47/255, green: 158/255, blue: 68/255), lineWidth: 1)
            )
            
            /// Board Shake Code
            HStack(spacing: 0) {
                Button(action: {
                    LButtonIsPressed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + SHAKE_TIME) {
                        LButtonIsPressed = false
                    }
                    
                    shakeGrid(side: .left)
                    shakeGridUI(side: .left)
                }) {
                    Text("L")
                        .foregroundColor(.black)
                        .font(.title)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 18)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.shadow(.inner(color: LButtonIsPressed ? .white : .black, radius: 2, x: -1, y: -1)))
                        .foregroundColor(Color(red: LButtonIsPressed ? 222/255 : 247/255, green: LButtonIsPressed ? 106/255 : 131/255, blue: LButtonIsPressed ? 147/255 : 172/255))
                        .cornerRadius(10)
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    Text("Shake Board")
                        .foregroundColor(.black)
                        .font(.title2)
                        .padding(.bottom, 6)
                    Text("One Time Use Only!")
                        .foregroundColor(Color(red: 224/255, green: 49/255, blue: 49/255))
                        .font(.callout)
                }
                .padding(.horizontal, 15)
                
                Button(action: {
                    RButtonIsPressed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + SHAKE_TIME) {
                        RButtonIsPressed = false
                    }
                    
                    shakeGrid(side: .right)
                    shakeGridUI(side: .right)
                }) {
                    Text("R")
                        .foregroundColor(.black)
                        .font(.title)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 18)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.shadow(.inner(color: RButtonIsPressed ? .white : .black, radius: 2, x: -1, y: -1)))
                        .foregroundColor(Color(red: RButtonIsPressed ? 222/255 : 247/255, green: RButtonIsPressed ? 106/255 : 131/255, blue: RButtonIsPressed ? 147/255 : 172/255))
                        .cornerRadius(10)
                )
                .edgesIgnoringSafeArea(.all)
                
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(
                Rectangle()
                    .foregroundColor(Color(red: 238/255, green: 252/255, blue: 151/255))
                    .cornerRadius(10)
            )
            .edgesIgnoringSafeArea(.all)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(red: 30/255, green: 30/255, blue: 30/255), lineWidth: 2)
            )
            
            /// Text Area
            HStack {
                Button(action: pressPlay) {
                    Text("sly plays at R1\npuffin plays at L4\nsly: nice one!\nsly SHAKES the table!\npuffin: oh no!\npluffin plays at L4")
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                }
                .padding(.leading, 15)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: 150)
            .background(
                Rectangle()
                    .foregroundColor(.white)
                    .cornerRadius(10)
            )
            .edgesIgnoringSafeArea(.all)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.black)
            )
            .padding(.horizontal, 15)
            
            /// Message Send Area
            HStack {
                /// Message Field
                TextField("Send a message by typing here...", text: $message)
                    .padding(.leading, 4)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 1)
                    )
                    .padding(.leading, 15)
                
                /// Send Button
                Button(action: {
                    sendButtonIsPressed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        sendButtonIsPressed = false
                    }
                    
                    pressPlay()
                }) {
                    Circle()
                        .fill(Color(red: sendButtonIsPressed ? 140/255 : 165/255, green: sendButtonIsPressed ? 191/255 : 216/255, blue: sendButtonIsPressed ? 230/255 : 1.0)
                            .shadow(.inner(color: sendButtonIsPressed ? .white : .black, radius: 2, x: -1, y: -1)))
                        .frame(width: 39, height: 39)
                        .edgesIgnoringSafeArea(.all)
                        .overlay(
                            Circle()
                                .stroke(Color(red: 47/255, green: 158/255, blue: 68/255), lineWidth: 1)
                        )
                }
                .padding(.trailing, 15)
            }
            
            Spacer()
        }
        .background(Color(red: 227/255, green: 250/255, blue: 252/255))
    }
    
    private func shakeGridUI(side: SIDE) {
        if side == .left {
            DispatchQueue.main.async { isLeftBoardShaking = true }
            
            Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { timer in
                if !LButtonIsPressed {
                    timer.invalidate()
                }
                
                DispatchQueue.main.async { isLeftBoardShaking.toggle() }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { isLeftBoardShaking = false }
        }
        if side == .right {
            DispatchQueue.main.async { isRightBoardShaking = true }
            
            Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { timer in
                if !RButtonIsPressed {
                    timer.invalidate()
                }
                
                DispatchQueue.main.async { isRightBoardShaking.toggle() }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { isRightBoardShaking = false }
        }
    }
    
    private func shakeGrid(side: SIDE) {
        for colIndex in grid.indices {
            let col = side == .right ? (grid.count - 1) - colIndex : colIndex
            var lowPointer = grid.count - 1
            var highPointer = lowPointer - 1
            while highPointer >= 0 {
                if grid[lowPointer][col].pegState == .empty {
                    if grid[highPointer][col].pegState != .empty {
                        if grid[highPointer][col].side == side {
                            grid[lowPointer][col] = grid[highPointer][col]
                            grid[highPointer][col] = Peg()
                        } else {
                            lowPointer = highPointer - 1
                            highPointer = lowPointer - 1
                        }
                    }
                    else {
                        highPointer -= 1
                    }
                }
                else {
                    lowPointer -= 1
                    if highPointer >= lowPointer {
                        highPointer = lowPointer - 1
                    }
                }
            }
        }
    }
    
    private func addToRow(rowIndex: Int, side: SIDE) {
        addToGrid(rowIndex: rowIndex, side: side)
    }
    
    private func addToGrid(rowIndex: Int, side: SIDE) {
        var played: Bool = false
        
        switch(side) {
        case .left:
            for colIndex in 0..<grid[rowIndex].count {
                if grid[rowIndex][colIndex].pegState == .empty {
                    grid[rowIndex][colIndex].pegState = isPlayerTurn ? .player_played : .opponent_played
                    grid[rowIndex][colIndex].side = side
                    played = true
                    break
                }
            }
        case .right:
            for colIndex in (0..<grid[rowIndex].count).reversed() {
                if grid[rowIndex][colIndex].pegState == .empty {
                    grid[rowIndex][colIndex].pegState = isPlayerTurn ? .player_played : .opponent_played
                    grid[rowIndex][colIndex].side = side
                    played = true
                    break
                }
            }
        case .none:
            fatalError("No side indicated")
        }
        
        if played {
            isPlayerTurn.toggle()
        }
        else {
            print("Failed to add a piece!")
        }
    }
    
    private func pressPlay() {
        print("Pressed Play Move! Button")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

struct CircleButtonView: View {
    @Binding var buttonState: BUTTON_STATE
    
    var body: some View {
        Circle()
            .fill(Color.blue
                .shadow(.inner(color: buttonState == .pressed ? .white : .black, radius: 2, x: -1, y: -1)))
            .frame(width: 39, height: 39)
            .padding(.vertical, 3)
            .padding(.horizontal, 5)
    }
}

struct PegRow: View {
    @Binding var pegStateArray: [Peg]
    @Binding var isLShaking: Bool
    @Binding var isRShaking: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(pegStateArray.indices, id: \.self) { index in
                PegView(pegState: $pegStateArray[index].pegState, isLShaking: $isLShaking, isRShaking: $isRShaking)
            }
        }
        .padding(.vertical, 2)
    }
}

struct PegView: View {
    @Binding var pegState: PEG_STATE
    @Binding var isLShaking: Bool
    @Binding var isRShaking: Bool
    
    var body: some View {
        ZStack {
            /// Blue Game Piece (if player played)
            Circle()
                .fill(Color.blue)
                .frame(width: 36, height: 36)
                .overlay(
                    Circle()
                        .stroke(Color(red: 60/255, green: 60/255, blue: 60/255), lineWidth: 4)
                )
                .padding(1)
                .opacity((pegState == .player_played) ? 1 : 0)
                .animation(.easeInOut(duration: isLShaking || isRShaking ? SHAKE_TIME : 0.5), value: pegState)
            /// Red Piece (if opponent played)
            Circle()
                .fill(Color.red)
                .frame(width: 36, height: 36)
                .overlay(
                    Circle()
                        .stroke(Color(red: 60/255, green: 60/255, blue: 60/255), lineWidth: 4)
                )
                .padding(1)
                .opacity((pegState == .opponent_played) ? 1 : 0)
                .animation(.easeInOut(duration: isLShaking || isRShaking ? SHAKE_TIME : 0.5), value: pegState)
            /// Empty Peg
            Text("・")
                .foregroundColor(.black)
                .font(.largeTitle)
                .padding(.horizontal, 4)
                .opacity((pegState == .empty) ? 1 : 0)
                .animation(.easeInOut(duration: 0.5), value: pegState)
        }
    }
}
