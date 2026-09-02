//
//  PlayfairMatrix.swift
//  BigramCipher
//
//  Constructs the Playfair 5×5 key matrix from a keyword and provides
//  coordinate lookup for individual characters within the grid.
//
//  HOW THE PLAYFAIR MATRIX IS BUILT:
//  The matrix is a 5×5 grid filled with all 25 letters of the English alphabet
//  (with J merged into I). The construction process is:
//
//    1. Take the keyword (e.g., "MONARCHY") and normalize it:
//       - Convert to uppercase
//       - Replace J with I
//    2. Remove duplicate letters, keeping only the first occurrence:
//       "MONARCHY" → M, O, N, A, R, C, H, Y (all unique, so nothing removed)
//    3. Fill the matrix left-to-right, top-to-bottom with keyword letters first,
//       then append the remaining unused alphabet letters in order:
//
//       M O N A R        ← keyword letters fill first
//       C H Y B D        ← 'B' is the first unused alphabet letter after keyword
//       E F G I K        ← continuing with remaining letters
//       L P Q S T
//       U V W X Z
//
//  The resulting matrix is the "key" for the entire cipher — both encryption
//  and decryption use the same matrix built from the same keyword.
//
//  Created by Oleksandr Siholaiev on 01.09.2026.
//

import Foundation

/// Represents the 5×5 Playfair key matrix built from a keyword.
///
/// This is a pure value type — its state is fully determined at initialization
/// and it holds no mutable or global references. The matrix can be inspected
/// via `prettyPrint()` and queried via `position(of:)`.
struct PlayfairMatrix {

    // MARK: - Properties

    /// The 2D grid of characters, indexed as `grid[row][col]`.
    ///
    /// For a 5×5 matrix, valid indices are `grid[0...4][0...4]`.
    /// Each cell contains exactly one unique character from the alphabet.
    let grid: [[Character]]

    /// Number of rows in the matrix (used for bounds checking and modular arithmetic).
    let rowCount: Int

    /// Number of columns in the matrix (used for bounds checking and modular arithmetic).
    let colCount: Int

    // MARK: - Initialization

    /// Creates a Playfair matrix from the given keyword and alphabet.
    ///
    /// The construction algorithm:
    /// 1. Normalize the keyword (uppercase, replace excluded character).
    /// 2. Walk through the normalized keyword and collect unique characters
    ///    (first occurrence only, preserving order).
    /// 3. Append remaining alphabet characters not already used by the keyword.
    /// 4. Arrange the resulting 25-character sequence into a 2D grid.
    ///
    /// - Parameters:
    ///   - keyword: The user-supplied encryption key (may contain duplicates, mixed case).
    ///   - alphabet: The full set of valid characters (25 English letters without J).
    ///   - rowCount: Number of rows in the grid (5 for standard Playfair).
    ///   - colCount: Number of columns in the grid (5 for standard Playfair).
    ///   - replacedChar: Character to replace during normalization ('J').
    ///   - replacementChar: Character to substitute in place of `replacedChar` ('I').
    init(keyword: String,
         alphabet: String,
         rowCount: Int,
         colCount: Int,
         replacedChar: Character,
         replacementChar: Character) {

        self.rowCount = rowCount
        self.colCount = colCount

        // Step 1: Normalize keyword — uppercase and replace excluded character (J → I)
        let normalizedKeyword = keyword.uppercased().map { char -> Character in
            return char == replacedChar ? replacementChar : char
        }

        // Step 2–3: Build ordered unique sequence — keyword chars first, then remaining
        var seen = Set<Character>()       // Tracks which characters have been placed
        var linearSequence: [Character] = [] // The final 25-character sequence

        // Add unique keyword characters (preserving their original order)
        for char in normalizedKeyword {
            if alphabet.contains(char) && !seen.contains(char) {
                seen.insert(char)
                linearSequence.append(char)
            }
        }

        // Fill remaining cells with alphabet characters not used by the keyword
        for char in alphabet {
            if !seen.contains(char) {
                seen.insert(char)
                linearSequence.append(char)
            }
        }

        // Step 4: Arrange the linear sequence into a 2D grid (row-major order)
        var matrix: [[Character]] = []
        for rowIndex in 0..<rowCount {
            let startIndex = rowIndex * colCount
            let endIndex = min(startIndex + colCount, linearSequence.count)
            let row = Array(linearSequence[startIndex..<endIndex])
            matrix.append(row)
        }

        self.grid = matrix
    }

    // MARK: - Coordinate Lookup

    /// Finds the row and column position of a character in the matrix.
    ///
    /// This is the core operation used by the cipher engine to determine
    /// which Playfair rule to apply (same row, same column, or rectangle).
    ///
    /// - Parameter character: The character to locate in the grid.
    /// - Returns: A tuple `(row, col)` if the character is found, or `nil` if
    ///            the character does not exist in the matrix.
    func position(of character: Character) -> (row: Int, col: Int)? {
        for row in 0..<rowCount {
            for col in 0..<colCount {
                if grid[row][col] == character {
                    return (row, col)
                }
            }
        }
        return nil
    }

    // MARK: - Display

    /// Returns a formatted multi-line string representation of the matrix,
    /// suitable for printing to the console.
    ///
    /// Each row is printed with characters separated by spaces.
    ///
    /// Example output for keyword "CIPHER":
    /// ```
    /// C I P H E
    /// R A B D F
    /// G K L M N
    /// O Q S T U
    /// V W X Y Z
    /// ```
    func prettyPrint() -> String {
        return grid.map { row in
            row.map { String($0) }.joined(separator: " ")
        }.joined(separator: "\n")
    }
}
