//
//  BigramCipherEngine.swift
//  BigramCipher
//
//  Core cipher logic: text normalization, bigram construction,
//  and Playfair encryption/decryption using the three standard rules.
//
//  PURPOSE:
//  This file contains the heart of the Playfair bigram cipher algorithm.
//  It is responsible for three stages of processing:
//
//    Stage 1 — NORMALIZATION:
//      Raw input text is cleaned into cipher-ready uppercase letters.
//      Non-letter characters (spaces, punctuation, digits) are stripped.
//      The letter 'J' is replaced with 'I' to match the 25-letter alphabet.
//
//    Stage 2 — BIGRAM SPLITTING:
//      The normalized text is split into consecutive pairs of characters.
//      Unlike classic English Playfair, identical-letter pairs (e.g., "LL")
//      are NOT split with a filler. They are kept as valid bigrams and will
//      follow the same-column rule during encryption/decryption.
//      A filler character ('X') is only appended at the END if the text
//      has an odd number of characters.
//
//    Stage 3 — TRANSFORMATION:
//      Each bigram is encrypted or decrypted using one of three Playfair rules,
//      determined by the relative positions of its two characters in the matrix:
//
//      ┌─────────────────┬────────────────────────┬────────────────────────┐
//      │ Condition        │ Encrypt                │ Decrypt                │
//      ├─────────────────┼────────────────────────┼────────────────────────┤
//      │ Same row         │ Shift columns RIGHT    │ Shift columns LEFT     │
//      │ Same column      │ Shift rows DOWN        │ Shift rows UP          │
//      │ Rectangle        │ Swap column indices    │ Swap column indices    │
//      └─────────────────┴────────────────────────┴────────────────────────┘
//
//      The "same column" rule also applies to identical letter pairs (e.g., OO),
//      since both characters occupy the same row AND same column — the column
//      check matches first, and each character shifts down (or up) by one row.
//
//  DESIGN:
//  All functions are static and fully parameterized — no stored state, no global
//  variables. Every piece of data needed for processing is passed as a parameter.
//
//  Created by Oleksandr Siholaiev on 01.09.2026.
//

import Foundation

/// Engine that performs Playfair bigram cipher operations.
///
/// Provides three stages of processing:
/// 1. **Normalization** — clean raw text into cipher-ready uppercase letters.
/// 2. **Bigram splitting** — pair characters into bigrams.
/// 3. **Transformation** — apply Playfair rules to encrypt or decrypt bigram pairs.
///
/// All methods are static and take all required data as parameters,
/// satisfying the structured programming criterion of no global variables.
struct BigramCipherEngine {

    // MARK: - Stage 1: Text Normalization

    /// Normalizes raw input text for Playfair cipher processing.
    ///
    /// The normalization pipeline:
    /// 1. Convert every character to uppercase.
    /// 2. Replace the excluded character ('J' → 'I').
    /// 3. Strip all non-ASCII-letter characters (spaces, punctuation, digits).
    ///
    /// **Important:** This is a lossy transformation — the original spacing,
    /// punctuation, and letter casing cannot be recovered after normalization.
    /// This is an inherent property of the Playfair cipher, not a bug.
    ///
    /// - Parameters:
    ///   - text: The raw input text from the file.
    ///   - replacedChar: The character to replace (e.g., 'J').
    ///   - replacementChar: The substitute character (e.g., 'I').
    /// - Returns: A clean uppercase string containing only valid alphabet letters.
    static func normalizeText(
        _ text: String,
        replacedChar: Character,
        replacementChar: Character
    ) -> String {
        var result = ""

        for char in text.uppercased() {
            if char == replacedChar {
                // Replace excluded character with its substitute (J → I)
                result.append(replacementChar)
            } else if char.isLetter && char.isASCII {
                // Keep only ASCII letters — this filters out digits, punctuation,
                // spaces, emoji, and any non-English Unicode characters
                result.append(char)
            }
            // All other characters (spaces, punctuation, digits) are silently discarded
        }

        return result
    }

    /// Counts how many non-letter characters will be stripped during normalization.
    ///
    /// Used to display a warning to the user when their input contains characters
    /// that the Playfair cipher cannot preserve (spaces, punctuation, digits, etc.).
    ///
    /// - Parameter text: The raw input text before normalization.
    /// - Returns: The number of characters that will be removed during normalization.
    static func countStrippedCharacters(in text: String) -> Int {
        var count = 0
        for char in text {
            // Count characters that are NOT ASCII letters (and not whitespace-only lines)
            if !(char.isLetter && char.isASCII) && !char.isNewline {
                count += 1
            }
        }
        return count
    }

    // MARK: - Stage 2: Bigram Construction

    /// Splits normalized text into sequential bigram pairs.
    ///
    /// Characters are grouped strictly left-to-right: `[(0,1), (2,3), (4,5), ...]`.
    ///
    /// **Key difference from classic Playfair:** Identical-letter pairs (e.g., `OO`)
    /// are **NOT** split with a filler character. They remain as valid bigrams and
    /// will follow the same-column Playfair rule during transformation.
    /// This matches the lab specification.
    ///
    /// If the text has an odd number of characters, the filler character is appended
    /// to complete the final pair. For example: `"HELLO"` → `[HE] [LL] [OX]`.
    ///
    /// - Parameters:
    ///   - text: The normalized text (uppercase ASCII letters only).
    ///   - fillerCharacter: Character to append if text length is odd (typically 'X').
    /// - Returns: An array of character pairs representing the bigrams.
    static func makeBigrams(
        from text: String,
        fillerCharacter: Character
    ) -> [(Character, Character)] {
        var characters = Array(text)

        // Pad with filler if the total character count is odd
        if characters.count % 2 != 0 {
            characters.append(fillerCharacter)
        }

        // Group into sequential pairs — two characters at a time
        var bigrams: [(Character, Character)] = []
        var index = 0
        while index < characters.count {
            let first = characters[index]
            let second = characters[index + 1]
            bigrams.append((first, second))
            index += 2
        }

        return bigrams
    }

    // MARK: - Stage 3: Encryption & Decryption

    /// Processes an array of bigrams through the Playfair cipher rules.
    ///
    /// For each bigram, the two characters' positions in the matrix are looked up,
    /// and one of three rules is applied based on their geometric relationship:
    ///
    /// **Rule 1 — Same Row:**
    /// Both characters are in the same row of the matrix.
    /// Each character is replaced by the character to its right (encrypt)
    /// or left (decrypt), wrapping around to the beginning/end of the row.
    /// ```
    /// Example (encrypt): In row [C I P H E], pair (C, H) → (I, E)
    /// ```
    ///
    /// **Rule 2 — Same Column (including identical letters):**
    /// Both characters are in the same column of the matrix.
    /// Each character is replaced by the character below it (encrypt)
    /// or above it (decrypt), wrapping around to the top/bottom of the column.
    /// This rule also applies when both characters are identical (e.g., LL),
    /// since they trivially occupy the same row AND column.
    /// ```
    /// Example (encrypt): In column [C R G O V], pair (C, G) → (R, O)
    /// ```
    ///
    /// **Rule 3 — Rectangle:**
    /// The two characters form opposite corners of a rectangle in the matrix.
    /// Each character is replaced by the character in the same row but at the
    /// other character's column. This rule is symmetric — it works the same
    /// for both encryption and decryption.
    /// ```
    /// Example: Pair (H, K) forms a rectangle:
    ///   H is at (0,3), K is at (2,1)
    ///   H → grid[0][1] = I,  K → grid[2][3] = M
    ///   Result: (I, M)
    /// ```
    ///
    /// - Parameters:
    ///   - bigrams: Array of character pairs to transform.
    ///   - matrix: The Playfair key matrix used for coordinate lookups.
    ///   - colCount: Number of columns in the matrix (for modular arithmetic).
    ///   - rowCount: Number of rows in the matrix (for modular arithmetic).
    ///   - shiftStep: The offset magnitude for row/column shifts (typically 1).
    ///   - encrypt: `true` for encryption (positive shift), `false` for decryption (negative shift).
    /// - Returns: The transformed text as a `String`.
    static func processBigrams(
        _ bigrams: [(Character, Character)],
        matrix: PlayfairMatrix,
        colCount: Int,
        rowCount: Int,
        shiftStep: Int,
        encrypt: Bool
    ) -> String {
        var result = ""

        // Determine shift direction: positive for encrypt, negative for decrypt
        let direction = encrypt ? shiftStep : -shiftStep

        for (first, second) in bigrams {
            // Look up positions of both characters in the matrix
            guard let pos1 = matrix.position(of: first),
                  let pos2 = matrix.position(of: second) else {
                // Defensive fallback: if a character is not found in the matrix,
                // preserve it unchanged (this should never happen with proper normalization)
                result.append(first)
                result.append(second)
                continue
            }

            let newFirst: Character
            let newSecond: Character

            if pos1.row == pos2.row {
                // ── RULE 1: Same Row ──
                // Shift each character's column index with wrapping.
                // Encrypt: shift right (+1), Decrypt: shift left (-1).
                // Adding `colCount` before modulo ensures no negative indices.
                let newCol1 = (pos1.col + direction + colCount) % colCount
                let newCol2 = (pos2.col + direction + colCount) % colCount
                newFirst = matrix.grid[pos1.row][newCol1]
                newSecond = matrix.grid[pos2.row][newCol2]

            } else if pos1.col == pos2.col {
                // ── RULE 2: Same Column (also handles identical letter pairs) ──
                // Shift each character's row index with wrapping.
                // Encrypt: shift down (+1), Decrypt: shift up (-1).
                let newRow1 = (pos1.row + direction + rowCount) % rowCount
                let newRow2 = (pos2.row + direction + rowCount) % rowCount
                newFirst = matrix.grid[newRow1][pos1.col]
                newSecond = matrix.grid[newRow2][pos2.col]

            } else {
                // ── RULE 3: Rectangle ──
                // Swap column indices while keeping the original row indices.
                // This operation is its own inverse — symmetric for encrypt and decrypt.
                newFirst = matrix.grid[pos1.row][pos2.col]
                newSecond = matrix.grid[pos2.row][pos1.col]
            }

            result.append(newFirst)
            result.append(newSecond)
        }

        return result
    }

    // MARK: - Display Formatting

    /// Formats bigram pairs into a human-readable string for display.
    ///
    /// Each pair is shown in square brackets, separated by spaces.
    /// Example output: `[HE] [LL] [OW] [OR] [LD]`
    ///
    /// - Parameter bigrams: The array of character pairs to format.
    /// - Returns: A formatted string showing each bigram in brackets.
    static func formatBigrams(_ bigrams: [(Character, Character)]) -> String {
        return bigrams.map { "[\(String($0.0))\(String($0.1))]" }.joined(separator: " ")
    }

    /// Formats cipher output text into space-separated bigram groups for readability.
    ///
    /// Inserts a space after every two characters so the output mirrors the
    /// bigram structure. For example: `"CFSVSNAB"` → `"CF SV SN AB"`.
    ///
    /// - Parameter text: The encrypted or decrypted text string.
    /// - Returns: The text with a space inserted after every two characters.
    static func formatOutputText(_ text: String) -> String {
        var formatted = ""
        for (index, char) in text.enumerated() {
            formatted.append(char)
            // Insert a space after every second character (except at the very end)
            if index % 2 == 1 && index < text.count - 1 {
                formatted.append(" ")
            }
        }
        return formatted
    }
}
