//
//  TerminalFuncs.swift
//  dupes
//
//  Created by James Lawton on 4/3/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

/// Display a prompt at the terminal and wait for a response
/// Returns nil if there was a problem. Returns the default choice on ENTER
func prompt(message: String, defaultChoice: Character? = nil) -> Character? {
    guard isatty(fileno(stdin)) == 1 else {
        return nil
    }

    print(message, terminator: " ")
    fflush(stdout)

    while true {
        guard let key = GetKeyPress() else {
            return nil
        }

        switch key {
        case .Char("\n"), .Char("\r"):
            print("")
            return defaultChoice
        case .Char(let c):
            print("")
            return c
        default: break
        }
    }
}

enum KeyPress {
    case Char(Character)
    case UpArrow, DownArrow, LeftArrow, RightArrow
    case Escape, Backspace, DeleteForwards, TabBackwards
}

func GetKeyPress() -> KeyPress? {
    var oldT = ttySetCbreak(STDIN_FILENO)
    if oldT != nil {
        defer {
            if tcsetattr(STDIN_FILENO, TCSANOW, &oldT!) == -1 {
                perror("tcsetattr")
            }
        }

        var result: [UInt8] = [0,0,0]
        let len = read(STDIN_FILENO, &result, result.count)

        if len == 1 {
            switch result[0] {
            case 27: return .Escape
            case 127: return .Backspace
            default: return .Char(Character(UnicodeScalar(result[0])))
            }
        } else if len == 2 {
            #if DEBUG
                print("Unknown keypress: \(result[0..<2])")
            #endif
        } else if len == 3 {
            switch (result[0], result[1], result[2]) {
            case (27, 91, 65): return .UpArrow
            case (27, 91, 66): return .DownArrow
            case (27, 91, 67): return .RightArrow
            case (27, 91, 68): return .LeftArrow
            case (27, 91, 51): return .DeleteForwards // fn-delete
            case (27, 91, 90): return .TabBackwards   // Shift-Tab
            default:
                #if DEBUG
                    print("Unknown keypress: \(result)")
                #endif
            }
        }
    }
    return nil
}

private func ttySetCbreak(fd: Int32) -> termios? {
    var oldT = termios()
    if tcgetattr(fd, &oldT) == -1 {
        perror("tcgetattr")
        return nil
    }

    var newT = oldT
    newT.c_lflag &= ~UInt(ICANON | ECHO)  // Don't do line input, don't echo
    newT.c_lflag |= UInt(ISIG)  // Allow signals
    newT.c_iflag &= ~UInt(ICRNL)  // Don't convert CR to NL

    newT.c_cc.4 = 1  // VMIN Character-at-a-time input
    newT.c_cc.5 = 0  // VTIME with blocking

    if tcsetattr(fd, TCSAFLUSH, &newT) == -1 {
        perror("tcsetattr")
        return nil
    }

    return oldT
}
